({pkgs, ...}:
  let
    brewPkgs = [
      #    "fileicon"
      "magic-wormhole"
      #    "libvirt"
      #    "virt-manager"
      #    "virt-viewer"
      "libtool"
      "syncthing"
      "helm" # for kp kubernetes,x
      "yt-dlp"
      # "pharo"
      # "gdrive"
      "mpv"
      "ollama"


    ];
    brewCasks = [
      # "emacs-mac"
      #    "ableton-live-suite"
      #    "audacity"
      #    "bluesnooze"
      "caffeine"
      #    "calibre"
      #    "crossover"
      #    "discord"
      #    "dropbox"
      #    "firefox"
      #    "fl-studio"
      "google-chrome"
      #    "iina"
      #    "inkscape"
      #    "keepassxc"
      #    "kitty"
      #    "krita"
      #    "launchcontrol"
      #    "little-snitch"
      #    "loopback"
      #    "lunar"
      #    "mailspring"
      #    "microsoft-outlook"
      #    "native-access"1
      #    "obsidian"
      #    "plugdata"
      #    "rectangle"
      #    "secretive"
      #    "skype"
      #    "slack"
      #    "splice"
      #    "spotify"
      #    "stats"
      #   "steam"
      "telegram"
      #    "vcv-rack"
      #    "visual-studio-code"
      #    "vlc"
      #    "wireshark"
      #    "xournal-plus-plus"
      #    "zoom"
      #    "chromedriver"
          "amethyst"
      # "karabiner-elements"
      "krita"
      "obs"
      "spaceid"
      "slack"
      "discord"
      "1password"
      "1password-cli"
      "emacs-mac"
      "nordlayer"
      "mongodb-compass"
      "audacity"
      "google-drive"
      "pharo-launcher"
      "utm"

    ];
    nixPkgs = with pkgs; [
      #ollama
      #mpv
      tdlib
      w3m
      html-tidy
      arp-scan
      ripgrep
      awscli2
      bat
      clang
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
      jc
      jq
      # lorri
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
      # syncthing
      graphviz
      tdlib
      matterbridge
      gvfs
    ];
    secrets = "/Users/samikallinen/src/system-config/secrets.sh";
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
          # source ${secrets}
        '';
                serviceConfig = (runEvery 86400) // { RunAtLoad = true; UserName = "samikallinen"; StandardOutPath = "/Users/samikallinen/backstdout.log"; StandardErrorPath = "/Users/samikallinen/backstderr.log"; };
              };
            };
          };

      homebrew = {
        enable = true;
        global.brewfile = true;
        brewPrefix = "/opt/homebrew/bin";
        onActivation = {
          autoUpdate = true;
          upgrade = true;
          cleanup = "zap";
        };
        taps = [
          #          "homebrew/core"
          #          "homebrew/cask"
          #          "homebrew/cask-drivers"
          "railwaycat/emacsmacport"
          "pharo-project/pharo"
          "koekeishiya/formulae"
        ];
        brews = brewPkgs;
        casks = brewCasks;
        masApps = {
          # search for ids with commandline `mas search "app name"
          # Xcode = 497799835;
          "1Password for Safari" = 1569813296;
          "GarageBand" = 682658836;
         # "Turtle Beach Audio Hub"=  948410748; Redownload issue with Mac App Store
        };
      };
      # here go the darwin preferences and config items
      programs.zsh.enable = true;
      # environment.shells = [pkgs.bash pkgs.zsh];
      # environment.loginShell = pkgs.zsh;
      # environment.systemPackages = [pkgs.coreutils];
      nix.extraOptions = ''
            experimental-features = nix-command flakes
          '';
      system.keyboard.enableKeyMapping = true;
      system.keyboard.remapCapsLockToEscape = true;
      fonts.fontDir.enable = true; # DANGER
      fonts.fonts = with pkgs; [
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
        # matterbridge.enable = true;
        # matterbridge.configPath = "/Users/samikallinen/src/system-config/";
        # syncthing = {
        #   enable = true;
        #   user = "sakalli";
        #   dataDir = "/Users/sakalli/Documents";    # Default folder for new synced folders
        #   configDir = "/Users/sakalli/.config/syncthing";   # Folder for Syncthing's settings and keys
        # };
      };
      services.karabiner-elements.enable = true;
#      services.yabai.enable = true;
#      services.yabai.enableScriptingAddition = true;
#      services.yabai.config = {
#        layout       = "bsp";
#        auto_balance = "on";
#        window_placement    = "second_child";
#
#        # window border
#        window_border = "on";
#        window_border_width = 2;
#        active_window_border_color = "0xff5c7e81";
#        normal_window_border_color = "0xff505050";
#        insert_window_border_color = "0xffd75f5f";
#
#        # window paddixg
#        top_padding         = 5;
#        bottom_padding      = 5;
#        left_padding        = 5;
#        right_padding       = 5;
#        window_gap          = 5;
#        window_opacity      = "off";
#
#        # mouse setting
#        focus_follows_mouse = "autoraise";
#        mouse_follows_focus = "on";
#        mouse_modifier      = "alt";
#        mouse_action1       = "move";    # left click + drag
#        mouse_action2       = "resize";  # righ click + drag
#        mouse_drop_action   = "swap";
#      };
#      services.yabai.extraConfig = ''
#    yabai -m rule --add app='System Settings' manage=off
#  '';
      #      services.yabai = {
      #        enable = true;
      #        enableScriptingAddition = true;
      #        package = pkgs.yabai;
      #        config = {
      #          focus_follows_mouse = "off";
      #          mouse_follows_focus = "off";
      #          window_placement = "second_child";
      #          window_opacity = "on";
      #          active_window_opacity = 1.0;
      #          normal_window_opacity = 0.9;
      #          top_padding = 3;
      #          bottom_padding = 3;
      #          left_padding = 3;
      #          right_padding = 3;
      #          window_gap = 3;
      #          layout = "bsp";
      #        };
      #      };

      services. skhd = {
        enable = true;
        skhdConfig = builtins.readFile ./skhdrc;
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
          home.packages = nixPkgs;
          home.sessionVariables = {
            PAGER = "less";
            CLICLOLOR = 1;
            EDITOR = "zile";
          };
          # services.syncthing.enable = true; # FIX ME
          programs.bat.enable = true;
          programs.bat.config.theme = "TwoDark";
          programs.fzf.enable = true;
          programs.fzf.enableZshIntegration = true;
          programs.exa.enable = true;
          programs.git.enable = true;
          programs.starship.enable = true;
          programs.starship.enableZshIntegration = true;
          programs.alacritty = {
            enable = true;
            settings.font.normal.family = "MesloLGS Nerd Font Mono";
            settings.font.size = 16;
          };
        };
      };
    })
