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
    ];
  };

  programs.zsh.initContent = lib.mkAfter ''
    if [ -f "$HOME/.config/home-manager/secrets/gwc-nixos.env" ]; then
      source "$HOME/.config/home-manager/secrets/gwc-nixos.env"
    fi
  '';
}
