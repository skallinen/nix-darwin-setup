        ({pkgs, ...}: {
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
          fonts.fonts = [(pkgs.nerdfonts.override {fonts = ["Meslo"];})];
          services.nix-daemon.enable = true;
          system.defaults.finder.AppleShowAllExtensions = true;
          system.defaults.finder._FXShowPosixPathInTitle = true;
          system.defaults.dock.autohide = true;
          system.defaults.NSGlobalDomain.AppleShowAllExtensions = true;
          system.defaults.NSGlobalDomain.InitialKeyRepeat = 14;
          system.defaults.NSGlobalDomain.KeyRepeat = 1;
          # backwards compat; don't change
          system.stateVersion = 4;
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.samikallinen = {pkgs, ...}: {
              # Don't change this when you change package input. Leave it alone.
              home.stateVersion = "22.11";
              # specify my home-manager configs
              home.packages = [pkgs.ripgrep pkgs.fd pkgs.curl pkgs.less];
              home.sessionVariables = {
                PAGER = "less";
                CLICLOLOR = 1;
                EDITOR = "zile";
              };
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
