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
      cursor-cli
      dbeaver-bin
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
      whisrs
      # whisrs は uinput で物理キーを送るため CJK が打てない。
      # 録音停止後に whisrs log から最新転写を取り wl-copy → ydotool で Ctrl+V する wrapper。
      # ydotool を選択した理由: GNOME Mutter は wlr-virtual-keyboard-v1 を実装しないので
      # wtype が動かない。ydotool は /dev/uinput 経由なのでコンポジタ非依存で動く。
      (pkgs.writeShellApplication {
        name = "whisrs-toggle";
        runtimeInputs = with pkgs; [ whisrs wl-clipboard ydotool gawk coreutils ];
        text = ''
          state=$(whisrs status 2>/dev/null || echo unknown)

          if [[ "$state" == "idle" ]]; then
            exec whisrs toggle
          fi

          # 既に recording/transcribing → 停止して結果を貼り付ける。
          # 注意: whisrs は status=idle になってから少し遅れて log を書くので、
          # status ではなく log そのものに新エントリが出るのを待つ。
          ts_before=$(whisrs log 2>/dev/null | awk '/^20[0-9][0-9]-/ { print; exit }') || ts_before=""

          whisrs toggle

          # 最大 30 秒、新エントリ出現を 0.1s ごとに polling。
          for _ in $(seq 1 300); do
            ts_after=$(whisrs log 2>/dev/null | awk '/^20[0-9][0-9]-/ { print; exit }') || ts_after=""
            if [[ -n "$ts_after" && "$ts_after" != "$ts_before" ]]; then
              text=$(whisrs log 2>/dev/null | awk '/^  / { sub(/^  /,""); print; exit }')
              if [[ -n "$text" ]]; then
                printf '%s' "$text" | wl-copy
                sleep 0.2
                # 29 = KEY_LEFTCTRL, 42 = KEY_LEFTSHIFT, 47 = KEY_V
                # Ctrl+Shift+V (terminal の paste shortcut)。GUI app は Ctrl+V。
                ydotool key 29:1 42:1 47:1 47:0 42:0 29:0
              fi
              break
            fi
            sleep 0.1
          done
        '';
      })
    ];
  };

  # ydotool が clipboard paste で必要とするバックグラウンドデーモン。
  # /dev/uinput を要求するが、eiji は input グループ所属なのでアクセス可能。
  systemd.user.services.ydotoold = {
    Unit = {
      Description = "ydotool daemon (for whisrs-toggle CJK paste)";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.ydotool}/bin/ydotoold";
      Restart = "on-failure";
      RestartSec = "3";
    };
    Install.WantedBy = [ "default.target" ];
  };

  programs.zsh.initContent = lib.mkAfter ''
    if [ -f "$HOME/.config/home-manager/secrets/gwc-nixos.env" ]; then
      source "$HOME/.config/home-manager/secrets/gwc-nixos.env"
    fi
  '';
}
