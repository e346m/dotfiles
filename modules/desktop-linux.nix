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
      opera
      dbeaver-bin
      mysql80
      trash-cli
      wl-clipboard
      vulkan-tools
    ];
  };

  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      theme = "catppuccin-mocha";
      font-size = 16;
    };
  };
}
