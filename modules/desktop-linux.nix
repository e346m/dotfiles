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
      dbeaver-bin
      mysql80
      trash-cli
      wl-clipboard
      vulkan-tools
      lima
    ];
  };
}
