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
      "poppler"         # for PDF tools
      "autoconf"
      "automake"
      "zlib"
      "tree-sitter"
      "gcc"
      "libgccjit"
      "isl"
      "mpfr"
      "libmpc"
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
      "docker-desktop"          # Docker Desktop
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
        };
      in {
        user.agents = {
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
        "GarageBand" = 682658836;
      };
    };

    programs.zsh = {
      enable = true;
      enableCompletion = true;
    };

    users.users.samikallinen.shell = pkgs.zsh;
    users.users.samikallinen.home = "/Users/samikallinen";

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

    # Configure Spotlight and related shortcuts
    system.defaults.CustomUserPreferences = {
  "com.apple.symbolichotkeys" = {
    AppleSymbolicHotKeys = {
      "60" = { enabled = 0; };
      "61" = { enabled = 1; value = { parameters = [ 32 49 1048576 ]; type = "standard"; }; }; # Cmd+Space for Input Source
      "64" = { enabled = 1; value = { parameters = [ 100 2 1048576 ]; type = "standard"; }; }; # Cmd+D for Spotlight
    };
  };
};

    system.activationScripts.postUserActivation.text = ''
  /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 61 '{enabled = 1; value = {parameters = (32, 49, 1048576); type = standard;};}'
  /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 '{enabled = 0;}'
  /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 '{enabled = 1; value = {parameters = (100, 2, 1048576); type = standard;};}'
  killall cfprefsd 2>/dev/null || true
  killall SystemUIServer 2>/dev/null || true
'';



    system.stateVersion = 4; # do not change

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";
      users.samikallinen = { pkgs, lib, ... }: {
        home.stateVersion = "22.11"; # do not change

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
          DOCKER_CONTEXT = "desktop-linux";
        };

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

        programs.ssh = {
          enable = true;
          extraConfig = ''
            Host *
              IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
          '';
        };

        programs.zsh = {
          enable = true;
          enableCompletion = true;
          initExtra = ''
            if command -v docker >/dev/null 2>&1; then
              if [ -z "''${DOCKER_HOST:-}" ] && docker context ls >/dev/null 2>&1; then
                cur="$(docker context show 2>/dev/null || true)"
                [ "$cur" != "desktop-linux" ] && docker context use desktop-linux >/dev/null 2>&1 || true
              fi
            fi
            nix-switch() {
              local flake="$HOME/src/system-config"
              local host
              if [ -n "$1" ]; then
                host="$1"; shift
              else
                host="$(scutil --get LocalHostName 2>/dev/null || hostname -s)"
              fi
              case "$host" in
                Samis-MacBook-Air|Gmtk-MacBook-Pro) ;;
                /) echo "Unknown host '$host'. Use one of: Samis-MacBook-Air, Gmtk-MacBook-Pro"; return 1;;
              esac
              darwin-rebuild switch --flake "$flake#$host" "$@"
             }

          '';
        };
      };
    };
  })
