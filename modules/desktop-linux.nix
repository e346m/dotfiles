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

  # NVIDIA HDMI はロック時の DPMS で EDID が読めなくなり、mutter が
  # ウルトラワイド (2560x1080 21:9) を 1024x768 (4:3) に落とす。
  # 解除後に EDID が戻っても解像度は復元されないので、解除を監視して戻す。
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
          restore() {
            local connector width height rate scale mode serial state
            connector=$(sed -n 's/.*<connector>\([^<]*\)<.*/\1/p' "$HOME/.config/monitors.xml" | head -1)
            width=$(sed -n 's/.*<width>\([^<]*\)<.*/\1/p' "$HOME/.config/monitors.xml" | head -1)
            height=$(sed -n 's/.*<height>\([^<]*\)<.*/\1/p' "$HOME/.config/monitors.xml" | head -1)
            rate=$(sed -n 's/.*<rate>\([^<]*\)<.*/\1/p' "$HOME/.config/monitors.xml" | head -1)
            scale=$(sed -n 's/.*<scale>\([^<]*\)<.*/\1/p' "$HOME/.config/monitors.xml" | head -1)
            connector=''${connector:-HDMI-1}
            mode="''${width:-2560}x''${height:-1080}@''${rate:-119.881}"
            scale=''${scale:-1}

            state=$(gdbus call --session \
              --dest org.gnome.Mutter.DisplayConfig \
              --object-path /org/gnome/Mutter/DisplayConfig \
              --method org.gnome.Mutter.DisplayConfig.GetCurrentState) || return 0

            # フォールバック解像度のときだけ戻す。ユーザーが意図して変えた場合は触らない。
            echo "$state" | grep -qE "'(1024x768|800x600|640x480)@[0-9.]+'[^)]*'is-current': <true>" || return 0

            serial=$(printf '%s\n' "$state" | sed -n 's/^(uint32 \([0-9]*\),.*/\1/p')
            [ -n "$serial" ] || return 0

            gdbus call --session \
              --dest org.gnome.Mutter.DisplayConfig \
              --object-path /org/gnome/Mutter/DisplayConfig \
              --method org.gnome.Mutter.DisplayConfig.ApplyMonitorsConfig \
              "$serial" \
              2 \
              "[(0, 0, $scale, uint32 0, true, [('$connector', '$mode', @a{sv} {})])]" \
              "@a{sv} {}" >/dev/null || true
          }

          restore
          gdbus monitor --session \
            --dest org.gnome.ScreenSaver \
            --object-path /org/gnome/ScreenSaver |
          while IFS= read -r line; do
            case "$line" in
              *'ActiveChanged (false,'*)
                sleep 1
                restore
                ;;
            esac
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
