{
  config,
  pkgs,
  lib,
  ...
}:
{
  home = {
    username = "eijimishiro";
    homeDirectory = "/Users/eijimishiro";
    packages = with pkgs; [
      ffmpeg-full
      git-filter-repo
      devbox
      guard-hook
      mcp-grafana
      oauth2c
    ];
  };

  programs.zsh.shellAliases = lib.optionalAttrs (builtins.pathExists ../secrets/aliases-mac.nix) (
    import ../secrets/aliases-mac.nix
  );
}
