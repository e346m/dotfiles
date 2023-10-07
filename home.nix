{ config, pkgs, lib, ... }:
{

  home.username = "eiji";
  home.homeDirectory = "/home/eiji";

  home.stateVersion = "23.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    wl-clipboard # For tmux clipboard on the wayland system
    rnix-lsp
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = { };

  # You can also manage environment variables but you will have to manually
  # source
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/eiji/etc/profile.d/hm-session-vars.sh
  #
  # if you don't want to manage your shell through Home Manager.
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs.zsh = {
    enable = true;
    defaultKeymap = "emacs";
    dotDir = ".config/zsh";
    enableSyntaxHighlighting = true;
    history = {
      extended = true;
      path = "${config.xdg.dataHome}/zsh/.zsh_history";
      save = 1000000;
      size = 1000000;
    };
    shellAliases = {
      grep = "grep --colour=auto";
      la = "ls -A";
      ll = "ls -lh";
      vim = "nvim";
    };
    initExtra = ''
      eval "$(direnv hook zsh)"

      function cdg()
      {
          cd ./$(git rev-parse --show-cdup)
          if [ $# = 1 ]; then
              cd $1
          fi
      }

      autoload -Uz chpwd_recent_dirs cdr

      zstyle ':completion:*' matcher-list 'm:{[:lower:]}={[:upper:]}'

      #補完 メニューの選択モード
      zstyle ':completion:*:default' menu select=2
    '';
  };

  programs.starship = {
    enable = true;
  };

  programs.git = {
    enable = true;
    userName = "Eiji Mishiro";
    userEmail = "eiji346g@gmail.com";
    extraConfig = {
      init = {
        defaultBranch = "main";
      };
    };
    ignores = [
      "*.swp"
      "*.swo"
      ".DS_Store"
      ".direnv*"
      ".envrc"
    ];
  };

  programs.tmux = {
    enable = true;
    historyLimit = 10000;
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "screen-256color";
    keyMode = "vi";
    escapeTime = 10;
    extraConfig = ''
      bind C-b next-window

      bind - split-window -v
      bind | split-window -h

      # resize pane
      bind -r C-h resize-pane -L 5
      bind -r C-l resize-pane -R 5
      bind -r C-j resize-pane -D 5
      bind -r C-k resize-pane -U 5

      # select pane
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -L

      set-option -ga terminal-overrides ",$TERM:Tc"

      # avoid copy-pipe conflict
      set -s set-clipboard off

      set -s copy-command "wl-copy"
      bind -T copy-mode-vi v send-keys -X begin-selection

      # support y yank
      bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel


      # mouse
      set-option -g mouse on
      bind -n WheelUpPane if-shell -F -t = "#{mouse_any_flag}" "send-keys -M" "if -Ft= '#{pane_in_mode}' 'send-keys -M' 'select-pane -t=; copy-mode -e; send-keys -M'"
      bind -n WheelDownPane select-pane -t= \; send-keys -M
    '';
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    plugins = with pkgs.vimPlugins; [
      (nvim-treesitter.withPlugins (p: [
        p.nix
        p.go
        p.typescript
        p.lua
        p.tsx
        p.html
        p.c
        p.css
        p.javascript
        p.rust
        p.graphql
        p.hcl
        p.cpp
        # format
        p.yaml
        p.json
        p.toml
      ]))
      nvim-lspconfig
      telescope-nvim
      plenary-nvim
      gruvbox-material
      fern-vim
      #cmp
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      cmp-cmdline

      # lsp
      nvim-lspconfig
    ];
    extraLuaConfig = lib.fileContents ./init.lua;
    extraPackages = with pkgs; [
      lua-language-server
      nodePackages.typescript-language-server
      rnix-lsp
      gopls
      ccls
    ];
  };

  programs.direnv.enable = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
