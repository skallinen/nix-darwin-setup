({pkgs, ...}:
  let
    brewPkgs = [
      "sox"
      "libtool"
      "syncthing"
      "yt-dlp"
      "mpv"
      "ollama"
      "poppler"
      "node"
      "glib"
      "mu"
      "pkg-config"
      "cairo"
      "pango"
      "libpng"
      "jpeg"
      "giflib"
      "librsvg"
      "python-setuptools"
      "pkg-config"
      # following needed to install pdf-tools on macos
      "poppler"
      "autoconf"
      "automake"
      "zlib"
      "tree-sitter"
      "gcc"
      "libgccjit"
      "isl"
      "mpfr"
      "libmpc"
      # "d12frosted/emacs-plus/emacs-plus@30" 

    ];
    brewCasks = [
      "pdf-pals"
      "keycastr"
      "vlc"
      "supercollider"
      "blackhole-2ch"
      "caffeine"
      "calibre"
      "dropbox"
      "google-chrome"
      "firefox"
      "telegram"
      "zoom"
      "krita"
      "signal"
      "obs"
      "spaceid"
      "slack"
      "discord"
      "1password"
      "1password-cli"
      "nordlayer"
      "mongodb-compass"
      "audacity"
      "google-drive"
      "pharo-launcher"
      "opencpn"
      "meshlab"
      "aerospace"
      "inkscape"
      "claude"


    ];
    nixPkgs = with pkgs; [
      isync
      pandoc
      cmdstan
      mob
      tdlib
      kitty
      w3m
      html-tidy
      arp-scan
      ripgrep
      awscli2
      bat
      coreutils
      curl
      diff-so-fancy
      fd
      fzf
      git-filter-repo
      gnumake
      cmake
      gnupg
      iftop
      pngpaste
      jc
      jq
      m-cli
      nmap
      python3
      ripgrep
      rsync
      silver-searcher
      terminal-notifier
      tokei
      tldr
      tree
      wget
      mu
      graphviz
      tdlib
      matterbridge
      gvfs
      graphviz
      clojure

    ];

  in
    {
      networking.hostName = "Samis-MacBook-Air";
      launchd =
        let
          runEvery = StartInterval: {
            inherit StartInterval;
            Nice = 5;
            LowPriorityIO = true;
            AbandonProcessGroup = true;
          };
          runCommand = command: {
            inherit command;
            serviceConfig.RunAtLoad = true;
            serviceConfig.KeepAlive = true;
          }; in {

            user.agents = {
              obsidianBackup = {
                script = ''

        '';
                serviceConfig = (runEvery 86400) // { RunAtLoad = true; UserName = "samikallinen"; StandardOutPath = "/Users/samikallinen/backstdout.log"; StandardErrorPath = "/Users/samikallinen/backstderr.log"; };
              };
            };
          };

      homebrew = {
        enable = true;
        extraConfig = ''
    brew "d12frosted/emacs-plus/emacs-plus@30", args: ["with-xwidgets"]
  '';
        global.brewfile = true;
        brewPrefix = "/opt/homebrew/bin";
        onActivation = {
          autoUpdate = true;
          upgrade = true;
          cleanup = "zap";
        };
        taps = [
          "railwaycat/emacsmacport"
          "pharo-project/pharo"
          "koekeishiya/formulae"
          "brewsci/homebrew-science"
          "nikitabobko/tap"
          "d12frosted/emacs-plus"
        ];
        brews = brewPkgs;
        casks = brewCasks;
        masApps = {
          # search for ids with commandline `mas search "app name"
          # Xcode = 497799835;
          # "1Password for Safari" = 1569813296;
          "GarageBand" = 682658836;
          # "DaVinci Resolve" = 571213070;

          # https://apps.apple.com/fi/app/davinci-resolve/id571213070?mt=12
         # "Turtle Beach Audio Hub"=  948410748; Redownload issue with Mac App Store
        };
      };
      # here go the darwin preferences and config items
      programs.zsh = {
        enable = true;
        # This makes zsh a login option
        enableCompletion = true;
      };

      # Add this to specify your default shell:
      users.users.samikallinen.shell = pkgs.zsh;
      # environment.shells = [pkgs.bash pkgs.zsh];
      # environment.loginShell = pkgs.zsh;
      # environment.systemPackages = [pkgs.coreutils];
      nix.extraOptions = ''
            experimental-features = nix-command flakes
          '';
      system.keyboard.enableKeyMapping = true;
      system.keyboard.remapCapsLockToEscape = true;
      fonts.packages = with pkgs; [
        fira-code
        font-awesome
        inconsolata
        nerdfonts
        recursive
        roboto
        roboto-mono
      ];
      services = {
        nix-daemon.enable = true;
      };
      system.defaults.finder.AppleShowAllExtensions = true;
      system.defaults.finder._FXShowPosixPathInTitle = true;
      system.defaults.dock.autohide = true;
      system.defaults.NSGlobalDomain.AppleShowAllExtensions = true;
      system.defaults.NSGlobalDomain.InitialKeyRepeat = 14;
      system.defaults.NSGlobalDomain.KeyRepeat = 1;
      system.defaults.spaces.spans-displays = false;
      # backwards compat; don't change
      system.stateVersion = 4;
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.samikallinen = {pkgs, ...}: {
          # Don't change this when you change package input. Leave it alone.
          home.stateVersion = "22.11";
          # specify my home-manager configs
          home.homeDirectory = pkgs.lib.mkForce "/Users/samikallinen";
          home.file."Library/Application Support/Claude/claude_desktop_config.json".text = builtins.toJSON {
            mcpServers = {
              clojure-mcp = {
                command = "bash";
                args = [
                  "-c"
                  "cd /Users/samikallinen/projects/clojure-mcp-dev/clojure-mcp && nix develop --command clojure -X:mcp :port 61321 2>/dev/null"
                ];
              };
            };
          };
          home.packages = nixPkgs;
          home.sessionVariables = {
            PAGER = "less";
            CLICLOLOR = 1;
            EDITOR = "zile";
            SSH_AUTH_SOCK = "~/Library/Group\\ Containers/2BUA8C4S2C.com.1password/t/agent.sock";
          };
          # services.syncthing.enable = true; # FIX ME
          programs.bat.enable = true;
          programs.bat.config.theme = "TwoDark";
          programs.fzf.enable = true;
          programs.fzf.enableZshIntegration = true;
          programs.eza.enable = true;
          programs.git.enable = true;
          programs.starship.enable = true;
          programs.starship.enableZshIntegration = true;
          programs.alacritty = {
            enable = true;
            settings.font.normal.family = "MesloLGS Nerd Font Mono";
            settings.font.size = 16;
          };
          programs.zsh = {
            enable = true;
            enableCompletion = true;       # Optional
          };
        };
      };
    })
