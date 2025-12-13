{ pkgs, ... }:

{
  networking.hostName = "Samis-MacBook-Air";

  # --- System Defaults & Keyboard ---
  system.defaults.finder.AppleShowAllExtensions = true;
  system.defaults.finder._FXShowPosixPathInTitle = true;
  system.defaults.dock.autohide = true;
  system.defaults.NSGlobalDomain.AppleShowAllExtensions = true;
  system.defaults.NSGlobalDomain.InitialKeyRepeat = 14;
  system.defaults.NSGlobalDomain.KeyRepeat = 1;
  system.defaults.spaces.spans-displays = false;

  # Spotlight & Input Source Shortcuts (Cmd+Space / Cmd+D)
  system.activationScripts.postUserActivation.text = ''
    /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 61 '{enabled = 1; value = {parameters = (32, 49, 1048576); type = standard;};}'
    /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 '{enabled = 0;}'
    /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 '{enabled = 1; value = {parameters = (100, 2, 1048576); type = standard;};}'
    killall cfprefsd 2>/dev/null || true
    killall SystemUIServer 2>/dev/null || true
  '';

  # --- Homebrew Configuration ---
  homebrew = {
    enable = true;
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
      "local/emacs-deps" # <--- Your Custom Tap
    ];

    # CLI Packages via Brew (Mac-specific or preferred over Nix)
    brews = [
      # Build & Toolchain
      "autoconf" "automake" "libtool" "pkg-config"
      "isl" "libmpc" "mpfr"
      
      # Your custom Tree-sitter build
      "local/emacs-deps/tree-sitter@0.24.3" 

      # Runtimes & Libs
      "node" "python-setuptools"
      "giflib" "glib" "jpeg" "libpng" "zlib"
      "cairo" "librsvg" "pango" "poppler"
      
      # Tools
      "mpv" "sox" "yt-dlp"
      "ollama" "syncthing"
    ];

    # GUI Applications
    casks = [
      # Browsers
      "firefox" "google-chrome"
      
      # Communication
      "discord" "signal" "slack" "telegram" "zoom"
      
      # Creative & Media
      "audacity" "calibre" "inkscape" "krita" "meshlab" "obs" "vlc"
      
      # Cloud & Sync
      "dropbox" "google-drive" "utm"
      
      
      # Developer & Utilities
      "1password-cli" "mongodb-compass" "pharo-launcher"
      "aerospace" "blackhole-2ch" "caffeine" "docker-desktop"
      "karabiner-elements" "keycastr" "antigravity"
      { name = "nordlayer"; greedy = true; }
      "pdf-pals" "spaceid"
      
      # Security & Misc
      "1password" "claude" "opencpn" "supercollider"
    ];

    masApps = {
      "GarageBand" = 682658836;
    };

    # Emacs-Plus Configuration
#    extraConfig = ''
#      # Using manually installed emacs-plus@30
#      brew "d12frosted/emacs-plus/emacs-plus@30", args: ["with-xwidgets"]
#    '';
  };

  # --- Nix Configuration ---
  services.nix-daemon.enable = true;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
  
  # Set State Version to 5 to avoid the error you saw earlier
  system.stateVersion = 4;

  # --- User Setup ---
  users.users.samikallinen.home = "/Users/samikallinen";
  users.users.samikallinen.shell = pkgs.zsh;
  programs.zsh.enable = true; 

  # --- Home Manager (Mac Specifics) ---
  home-manager.users.samikallinen = { pkgs, ... }: {
    imports = [ ./shared-home.nix ];

    # Mac-only packages (Not in shared-home.nix)
    home.packages = with pkgs; [
      pngpaste
      terminal-notifier
      m-cli
    ];

    # Config Files
    home.file.".config/aerospace/aerospace.toml".source = ./aerospace/aerospace.toml;
    
  
  };
}
