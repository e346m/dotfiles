{ config, pkgs, lib, ... }:
{
  home = {
    username = "eijimishiro";
    homeDirectory = "/Users/eijimishiro";
    packages = with pkgs; [
      zed-editor
    ];
  };
}
