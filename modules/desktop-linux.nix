{
  config,
  pkgs,
  lib,
  ...
}:
{
  home = {
    username = "eiji";
    homeDirectory = "/home/eiji";
    packages = with pkgs; [
      antigravity  # Antigravity CLI (agy) — Linux only
      cloudflared
      code-cursor
      cursor-cli
      dbeaver-bin
      herdr
      mysql80
      trash-cli
      wl-clipboard
      vulkan-tools
      codex
      lima
      tsm
      ghostty
      hicolor-icon-theme
      devcontainer
    ];
  };

  # eiji と eiji.346 (uid 1000 を共有する Cloudflare Access SSH 用エイリアス) の
  # どちらでログインしても $USER を getpwuid(1000) の正式名 "eiji" に固定する。
  # ibus-daemon は $USER と getpwuid()->pw_name の不一致を sudo/su 経由の
  # 起動とみなして拒否するため、eiji.346 でログインすると日本語入力が起動しない。
  #
  # environment.d では USER/LOGNAME/HOME を上書きできない (systemd が予約済み)。
  # IBus の user unit に Environment= を足す。home.sessionVariables も同じ理由で不可。
  home.file.".config/systemd/user/org.freedesktop.IBus.session.GNOME.service.d/10-user-identity.conf".text = ''
    [Service]
    Environment=USER=eiji
    Environment=LOGNAME=eiji
    Environment=USERNAME=eiji
  '';

  # NVIDIA + mutter 50: ロック/DPMS のあと hardware cursor の atomic commit が
  # 失敗し、カーソルもクリックもシェルが受け付けなくなる。
  # ソフトウェアカーソルにすれば再発しにくい。次回ログインから有効。
  home.file.".config/environment.d/20-mutter-sw-cursor.conf".text = ''
    MUTTER_DEBUG_DISABLE_HW_CURSORS=1
  '';

  # Managed tunnel config; credentials stay as real files under ~/.cloudflared/.
  home.file.".cloudflared/config.yml".text = ''
    tunnel: 165756a9-9276-481b-a2c1-0cf45009f750
    credentials-file: /home/eiji/.cloudflared/165756a9-9276-481b-a2c1-0cf45009f750.json

    ingress:
      - hostname: banto.mishiro.dev
        service: http://127.0.0.1:4000
      - hostname: nixos.confide.jp
        service: ssh://127.0.0.1:22
      - service: http_status:404
  '';

  # NVIDIA HDMI は DPMS Off で EDID / GBM が壊れ、画面が消えたまま VRAM が埋まる。
  # 2 秒ごとに消灯を打ち消し、2560x1080 から外れたら戻す。
  systemd.user.services.restore-display-on-unlock = {
    Unit = {
      Description = "Restore ultrawide mode after GNOME unlock (NVIDIA EDID drop)";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.writeShellApplication {
        name = "restore-display-on-unlock";
        runtimeInputs = [
          pkgs.glib
          pkgs.gnugrep
          pkgs.gnused
          pkgs.coreutils
        ];
        text = ''
          connector() {
            sed -n 's/.*<connector>\([^<]*\)<.*/\1/p' "$HOME/.config/monitors.xml" | head -1
          }
          wanted_mode() {
            local width height rate
            width=$(sed -n 's/.*<width>\([^<]*\)<.*/\1/p' "$HOME/.config/monitors.xml" | head -1)
            height=$(sed -n 's/.*<height>\([^<]*\)<.*/\1/p' "$HOME/.config/monitors.xml" | head -1)
            rate=$(sed -n 's/.*<rate>\([^<]*\)<.*/\1/p' "$HOME/.config/monitors.xml" | head -1)
            echo "''${width:-2560}x''${height:-1080}@''${rate:-119.881}"
          }
          scale() {
            sed -n 's/.*<scale>\([^<]*\)<.*/\1/p' "$HOME/.config/monitors.xml" | head -1
          }

          powersave_on() {
            gdbus call --session \
              --dest org.gnome.Mutter.DisplayConfig \
              --object-path /org/gnome/Mutter/DisplayConfig \
              --method org.freedesktop.DBus.Properties.Set \
              org.gnome.Mutter.DisplayConfig PowerSaveMode "<int32 0>" >/dev/null 2>&1 || true
          }

          current_state() {
            gdbus call --session \
              --dest org.gnome.Mutter.DisplayConfig \
              --object-path /org/gnome/Mutter/DisplayConfig \
              --method org.gnome.Mutter.DisplayConfig.GetCurrentState
          }

          apply_mode() {
            local connector=$1 mode=$2 scale=$3 state serial
            state=$(current_state) || return 1
            echo "$state" | grep -q "'$mode'" || return 1
            serial=$(printf '%s\n' "$state" | sed -n 's/^(uint32 \([0-9]*\),.*/\1/p')
            [ -n "$serial" ] || return 1
            gdbus call --session \
              --dest org.gnome.Mutter.DisplayConfig \
              --object-path /org/gnome/Mutter/DisplayConfig \
              --method org.gnome.Mutter.DisplayConfig.ApplyMonitorsConfig \
              "$serial" \
              2 \
              "[(0, 0, $scale, uint32 0, true, [('$connector', '$mode', @a{sv} {})])]" \
              "@a{sv} {}" >/dev/null
          }

          dpms_off() {
            local dpms enabled
            dpms=$(cat /sys/class/drm/card1-HDMI-A-1/dpms 2>/dev/null || echo On)
            enabled=$(cat /sys/class/drm/card1-HDMI-A-1/enabled 2>/dev/null || echo enabled)
            [ "$dpms" != On ] || [ "$enabled" != enabled ]
          }

          tick() {
            local connector mode scale state
            connector=$(connector)
            mode=$(wanted_mode)
            scale=$(scale)
            connector=''${connector:-HDMI-1}
            scale=''${scale:-1}

            # HDMI を落とすと NVIDIA が EDID / GBM を壊すので、ロック中でも消灯しない。
            powersave_on

            state=$(current_state) || return 0
            if echo "$state" | grep -q "'$mode'[^)]*'is-current': <true>"; then
              dpms_off || return 0
            fi

            if echo "$state" | grep -q "'$mode'"; then
              if apply_mode "$connector" "$mode" "$scale"; then
                return 0
              fi
            fi

            # CRTC が死んで VRAM が埋まっているときは、小さいモードで起こしてから戻す。
            apply_mode "$connector" "800x600@60.317" "$scale" || true
            sleep 1
            apply_mode "$connector" "$mode" "$scale" || true
          }

          while true; do
            tick || true
            sleep 2
          done
        '';
      }}/bin/restore-display-on-unlock";
      Restart = "on-failure";
      RestartSec = "3";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.cloudflared = {
    Unit = {
      Description = "Cloudflare Tunnel (banto)";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --config %h/.cloudflared/config.yml --no-autoupdate run";
      Restart = "on-failure";
      RestartSec = "5s";
      Environment = [ "TUNNEL_LOGLEVEL=debug" ];
    };
    Install.WantedBy = [ "default.target" ];
  };

  programs.zsh.initContent = lib.mkAfter ''
    if [ -f "$HOME/.config/home-manager/secrets/gwc-nixos.env" ]; then
      source "$HOME/.config/home-manager/secrets/gwc-nixos.env"
    fi
  '';
}
