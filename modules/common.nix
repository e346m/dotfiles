{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.stateVersion = "24.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  # it's useful to manage all package in home-manager but hard to update channel
  home.packages = with pkgs; [
    gh
    jq
    ripgrep
    fd
    tree
    docker
    jdk8
    gnupg
    git-crypt
    protobuf
    (google-cloud-sdk.withExtraComponents [ google-cloud-sdk.components.gke-gcloud-auth-plugin ])
    google-cloud-sql-proxy
    grpcui
    k9s
    terraform
    kubectx
    grpcurl
    kubeseal
    kustomize
    ollama
    claude-code
    gemini-cli
    graphite-cli
    harlequin
    roc
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = { };

  #Loading snippets files and set as text expression
  # readDir -> return set,  create new set with map iteration.
  xdg.configFile = (
    lib.mapAttrs' (
      name: type:
      lib.nameValuePair "nvim/snippets/${name}" { text = (builtins.readFile ../snippets/${name}); }
    ) (builtins.readDir ../snippets)
  );

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
  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      experimental-features = "nix-command flakes";
    };
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs.fzf = {
    enable = true;
  };

  programs.zsh = {
    enable = true;
    defaultKeymap = "emacs";
    dotDir = "${config.xdg.configHome}/zsh";
    syntaxHighlighting.enable = true;
    history = {
      extended = true;
      path = "${config.xdg.dataHome}/zsh/.zsh_history";
      save = 1000000;
      size = 1000000;
      share = true;
    };
    shellAliases = {
      grep = "grep --colour=auto";
      la = "ls -A";
      ll = "ls -lh";
      vim = "nvim";

      demo-sql-proxy = "cloud-sql-proxy \"upsidr-prod-chronos:asia-northeast1:demo-client-api?port=43306\"";
      staging-sql-proxy = "cloud-sql-proxy \"upsidr-staging-chronos:asia-northeast1:client-api-80?port=13306\"";
      production-read-sql-proxy = "cloud-sql-proxy \"upsidr-prod-chronos:asia-northeast1:client-api-80-replica?port=23306\"";
      production-write-sql-proxy = "cloud-sql-proxy \"upsidr-prod-chronos:asia-northeast1:client-api-80?port=53306\"";
      reward-staging-sql-proxy = "cloud-sql-proxy \"upsidr-staging-chronos:asia-northeast1:reward-point?port=3315\"";
      theseus-staging-sql-proxy = "cloud-sql-proxy \"upsidr-staging-theseus:asia-northeast1:theseus?port=4315\" --auto-iam-authn";
      hermes-staging-sql-proxy = "cloud-sql-proxy \"upsidr-staging-chronos:asia-northeast1:hermes?port=3310\"";
      hermes-prod-sql-proxy = "cloud-sql-proxy \"upsidr-prod-chronos:asia-northeast1:hermes?port=13310\"";
    };
    initContent = ''

      if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
      fi

      eval "$(direnv hook zsh)"

      function cdg()
      {
          cd ./$(git rev-parse --show-cdup)
          if [ $# = 1 ]; then
              cd $1
          fi
      }

      autoload -Uz add-zsh-hook
      autoload -Uz chpwd_recent_dirs cdr
      add-zsh-hook chpwd chpwd_recent_dirs
      chpwd_functions+=chpwd_recent_dirs
      zstyle ':chpwd:*' recent-dirs-max 1000
      zstyle ':chpwd:*' recent-dirs-default true
      zstyle ':completion:*' recent-dirs-insert always


      zstyle ':completion:*' matcher-list 'm:{[:lower:]}={[:upper:]}'

      #補完 メニューの選択モード
      zstyle ':completion:*:default' menu select=2
      function _zf_reload() {
        source ${config.xdg.configHome}/zsh/.zshrc
      }

      function _gcloud_change_project() {
        local proj=$(gcloud config configurations list | fzf --header-lines=1 | awk '{print $1}')
        if [ -n $proj ]; then
          gcloud config configurations activate $proj
          _zf_reload
          return $?
        fi
      }
      alias gcp=_gcloud_change_project
    '';
  };

  programs.starship = {
    enable = true;
    settings = {
      username = {
        show_always = true;
        format = "[$user]($style) ";
      };
      gcloud = {
        symbol = "🇬️ ";
        format = "on [$symbol$active]($style) ";
        style = "bold yellow";
      };
      kubernetes = {
        format = "on [$symbol$context\($namespace\)]($style) ";
        style = "dimmed green";
        disabled = false;
      };
    };
  };

  programs.git = {
    enable = true;
    userName = "Eiji Mishiro";
    userEmail = "eiji346g@gmail.com";
    extraConfig = {
      init = {
        defaultBranch = "main";
      };
      credential.helper = "${pkgs.git.override { withLibsecret = true; }}/bin/git-credential-libsecret";
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
    terminal = "tmux-256color";
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

      set-option -ga terminal-overrides ",xterm-256color:Tc"

      # avoid copy-pipe conflict
      set -s set-clipboard on

      # For Linux
      # if-shell -b "uname | grep -q Linux" {
      #   set -s copy-command "wl-copy"
      # }

      # # For mac
      # if-shell -b "uname | grep -q Darwin" {
      #   set -s copy-command "pbcopy"
      # }

      bind -T copy-mode-vi v send-keys -X begin-selection

      # support y yank
      bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel

      # support y yank via mouse selection
      bind -Tcopy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel


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
    plugins =
      with pkgs.vimPlugins;
      [
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
          p.roc
          # format
          p.yaml
          p.json
          p.toml
          p.vue
          p.glimmer
        ]))

        nvim-lspconfig
        telescope-nvim
        plenary-nvim
        gruvbox-material

        nvim-lint
        conform-nvim

        #snippet
        nvim-snippy

        #cmp
        nvim-cmp
        cmp-nvim-lsp
        cmp-buffer
        cmp-path
        cmp-cmdline
        cmp-snippy

        # lsp
        nvim-lspconfig

        #live preview
        markdown-preview-nvim
        bracey-vim

        # 必要な依存関係
        dressing-nvim
        plenary-nvim
        nui-nvim
        nvim-cmp # オプショナル: コマンド補完用
        nvim-web-devicons # オプショナル: アイコン表示用
        img-clip-nvim # オプショナル: 画像貼り付け機能用
        render-markdown-nvim # オプショナル: マークダウンレンダリング用

        # Better terminal experience for Claude Code
        snacks-nvim
      ]
      ++ [
        pkgs.old.vimPlugins.vim-fern
        pkgs.unstable.vimPlugins.claudecode-nvim
      ];

    extraLuaConfig = lib.fileContents ../init.lua;

    extraPackages = with pkgs; [
      lua-language-server
      nodejs
      nodePackages.typescript-language-server
      gopls
      ccls
      stylua
      zls
      haskellPackages.haskell-language-server
      pyright
      biome
      terraform-ls
      pyright
      htmx-lsp
      roc-ls
    ];
  };

  programs.direnv.enable = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
