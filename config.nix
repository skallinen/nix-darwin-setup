({pkgs, ...}:
  let
    brewPkgs = [
      # --- Build toolchain ----------------------------------------------------
      "autoconf"
      "automake"
      "libtool"
      "pkg-config"
      "tree-sitter"

      # --- Compilers & math ---------------------------------------------------
#      "gcc"
      "isl"
#      "libgccjit"
      "libmpc"
      "mpfr"

      # --- Runtimes & language tooling ---------------------------------------
      "node"
      "python-setuptools"

      # --- System & imaging libs ---------------------------------------------
      "giflib"
      "glib"
      "jpeg"
      "libpng"
      "zlib"

      # --- Graphics & rendering ----------------------------------------------
      "cairo"
      "librsvg"
      "pango"
      "poppler"

      # --- Media tools --------------------------------------------------------
      "mpv"
      "sox"
      "yt-dlp"

      # --- Sync / network / AI -----------------------------------------------
      "ollama"
      "syncthing"
    ];

    brewCasks = [
      # --- Browsers -----------------------------------------------------------
      "firefox"
      "google-chrome"

      # --- Communication ------------------------------------------------------
      "discord"
      "signal"
      "slack"
      "telegram"
      "zoom"

      # --- Media & creative ---------------------------------------------------
      "audacity"
      "calibre"
      "inkscape"
      "krita"
      "meshlab"
      "obs"
      "vlc"

      # --- Cloud & sync -------------------------------------------------------
      "dropbox"
      "google-drive"

      # --- Developer tools ----------------------------------------------------
      "1password-cli"
      "mongodb-compass"
      "pharo-launcher"

      # --- System utilities ---------------------------------------------------
      "aerospace"
      "blackhole-2ch"
      "caffeine"
      "docker-desktop"          # Docker Desktop
      "karabiner-elements"      # Needed for Caps Lock -> Command remapping
      "keycastr"
        { name = "nordlayer"; greedy = true; }
      "pdf-pals"
      "spaceid"

      # --- Security & passwords ----------------------------------------------
      "1password"

      # --- Audio/code/research miscellany ------------------------------------
      "claude"
      "opencpn"
      "supercollider"
    ];

    nixPkgs = with pkgs; [
      # --- Languages ----------------------------------------------------------
      clojure
      python3

      # --- Build & VCS --------------------------------------------------------
      cmake
      git-filter-repo
      gnumake

      # --- CLI essentials -----------------------------------------------------
      awscli2
      bat
      coreutils
      curl
      diff-so-fancy
      fd
      fzf
      gnupg
      jc
      jq
      pngpaste
      terminal-notifier
      tldr
      tokei
      tree
      wget

      # --- Search & text ------------------------------------------------------
      html-tidy
      ripgrep
      silver-searcher
      w3m

      # --- Networking ---------------------------------------------------------
      arp-scan
      iftop
      m-cli
      nmap
      rsync
      caddy

      # --- Email & docs -------------------------------------------------------
      isync
      mu
      pandoc

      # --- Visualization ------------------------------------------------------
      graphviz

      # --- Misc & tools -------------------------------------------------------
      cmdstan
      gvfs
      kitty
      matterbridge
      mob
      tdlib
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
  # Emacs 29 is stable and works with current tree-sitter/gcc versions
  brew "d12frosted/emacs-plus/emacs-plus@29", args: ["with-xwidgets", "with-native-comp"]
'';
#     extraConfig = ''
#        brew "d12frosted/emacs-plus/emacs-plus@30", args: ["with-xwidgets"]
#      '';
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
    # system.keyboard.remapCapsLockToEscape = true; # DISABLED: Handling via Karabiner below

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

        home.file.".config/aerospace/aerospace.toml".source = ./aerospace/aerospace.toml;

        # --- UPDATED: Karabiner Configuration ---
        # Remaps CapsLock to Left Command ONLY (No Escape)
        home.file.".config/karabiner/karabiner.json".text = builtins.toJSON {
          global = {
            check_for_updates_on_startup = true;
            show_in_menu_bar = true;
            show_profile_name_in_menu_bar = false;
          };
          profiles = [
            {
              name = "Default";
              selected = true;
              complex_modifications = {
                rules = [
                  {
                    description = "Caps Lock -> Left Command";
                    manipulators = [
                      {
                        type = "basic";
                        from = {
                          key_code = "caps_lock";
                          modifiers = { optional = [ "any" ]; };
                        };
                        to = [ { key_code = "left_command"; } ];
                      }
                    ];
                  }
                ];
              };
              devices = [];
              fn_function_keys = [];
              simple_modifications = [];
              virtual_hid_keyboard = {
                keyboard_type_v2 = "ansi";
              };
            }
          ];
        };
        # ----------------------------------------

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
              local local_flake="$HOME/src/system-config"
              local remote_flake="''${NIX_SWITCH_REMOTE_FLAKE:-github:skallinen/nix-darwin-setup}"
              local origin="local"
              local host=""

              while [ $# -gt 0 ]; do
                case "$1" in
                  --remote) origin="remote"; shift ;;
                  --local)  origin="local";  shift ;;
                  -h|--help) echo "Usage: nix-switch [--local|--remote] [HOST] [extra args]"; return 0 ;;
                  /) if [ -z "$host" ]; then host="$1"; shift; else break; fi ;;
                esac
              done

              [ -z "$host" ] && host="$(scutil --get LocalHostName 2>/dev/null || hostname -s)"
              local flake; [ "$origin" = "local" ] && flake="$local_flake" || flake="$remote_flake"
              darwin-rebuild switch --flake "$flake#$host" "$@"
            }
          '';
        };
      };
    };
  })
