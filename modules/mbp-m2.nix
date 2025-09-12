{ config, pkgs, lib, ... }:
{
  home = {
    username = "eijimishiro";
    homeDirectory = "/Users/eijimishiro";
    packages = with pkgs; [
      ffmpeg-full
      git-filter-repo
      devbox
    ];
  };
}
