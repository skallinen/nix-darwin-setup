{ pkgs, lib, config, ... }:

{
  networking.hostName = "Samis-MacBook-Air";

  # Required in nix-darwin 25.11+ for user-scoped options (homebrew, defaults, etc.)
  system.primaryUser = "samikallinen";

  # --- System Defaults & Keyboard ---
  system.defaults.finder.AppleShowAllExtensions = true;
  system.defaults.finder._FXShowPosixPathInTitle = true;
  system.defaults.dock.autohide = true;
  system.defaults.NSGlobalDomain.AppleShowAllExtensions = true;
  system.defaults.NSGlobalDomain.InitialKeyRepeat = 14;
  system.defaults.NSGlobalDomain.KeyRepeat = 1;
  system.defaults.spaces.spans-displays = false;

  # Spotlight & Input Source Shortcuts (Cmd+Space / Cmd+D)
  # Note: postUserActivation removed in 25.11; all activation now runs as root
  system.activationScripts.postActivation.text = ''
    # Spotlight -> Cmd+Space (Standard Default)
    /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 '{enabled = 1; value = {parameters = (32, 49, 1048576); type = standard;};}'
    
    # Spotlight Window (Finder Search) -> Disabled
    /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 65 '{enabled = 0;}'
    
    # Input Source -> Cmd+Space (Karabiner intercepts this, but we keep it standard)
    /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 61 '{enabled = 1; value = {parameters = (32, 49, 1048576); type = standard;};}'

    # Disable "Switch to Desktop" 1-10 to avoid conflict with Aerospace (Cmd+Num)
    ${pkgs.lib.concatMapStringsSep "\n" (i: 
      "/usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add ${toString i} '{enabled = 0;}'"
    ) (pkgs.lib.range 118 127)}

    # Force reload of settings
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    killall cfprefsd 2>/dev/null || true
    killall SystemUIServer 2>/dev/null || true

    # Enable Remote Login (SSH) for VM access
    if /usr/sbin/systemsetup -getremotelogin | grep -q "Off"; then
      sudo /usr/sbin/systemsetup -f -setremotelogin on
    fi
  '';

  # --- Homebrew Tap Trust (runs BEFORE `brew bundle`) ---
  #
  # Homebrew refuses to LOAD formulae/casks from untrusted third-party taps, and
  # that is not merely a "cannot install" failure. `brew bundle cleanup` resolves
  # an unreadable formula to ZERO dependencies and then uninstalls those
  # dependencies as orphans. That is exactly how emacs-plus@30 lost all 19 of its
  # libraries on 2026-08-04 and began dying at launch with
  #   dyld: Library not loaded: /opt/homebrew/opt/librsvg/lib/librsvg-2.2.dylib
  #
  # `brew trust` REWRITES ~/.homebrew/trust.json wholesale instead of appending,
  # so granting trust by hand un-trusts every tap not named in that one command.
  # Deriving the list from `homebrew.taps` and passing it in a SINGLE invocation
  # makes that footgun structurally impossible: the trusted set cannot drift from
  # the declared set, and a fresh machine is correct on its first rebuild.
  #
  # preActivation is deliberate. postActivation runs AFTER the bundle step, which
  # is far too late — the damage happens during the bundle.
  system.activationScripts.preActivation.text = lib.optionalString (config.homebrew.taps != [ ]) ''
    if [ -x /opt/homebrew/bin/brew ]; then
      echo "trusting homebrew taps..." >&2
      if ! sudo --user=${config.system.primaryUser} --set-home \
             /opt/homebrew/bin/brew trust \
             --taps ${lib.concatMapStringsSep " " (t: lib.escapeShellArg t.name) config.homebrew.taps}; then
        echo -e "\e[1;31mwarning: 'brew trust' failed. Third-party taps may be unreadable, which lets" >&2
        echo -e "'brew bundle cleanup' silently uninstall their dependencies (2026-08-04 emacs-plus incident).\e[0m" >&2
      fi
    fi
  '';

  # --- Homebrew Configuration ---
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      # `cleanup = "zap"` is CURRENTLY A NO-OP that also makes every
      # `darwin-rebuild switch` exit 1 (observed 2026-08-04). nix-darwin
      # implements it by passing `--cleanup` to `brew bundle install`, and
      # current Homebrew answers:
      #   Warning: Calling the `--cleanup` switch is deprecated! There is no
      #   replacement.
      # It then only PRINTS "Would uninstall …" and returns non-zero. Nothing is
      # removed, and the non-zero return fails the activation script even though
      # the bundle itself reported "complete!".
      # So undeclared packages must be removed by hand for now:
      #   brew bundle cleanup --file=<the generated Brewfile> --force
      # (and see the tap-trust trap above — that command lies about success when
      # an untrusted tap aborts it).
      #
      # CORRECTION (2026-08-04, later the same day): the "exit 1" half of the
      # note above no longer reproduces. With tap trust granted in preActivation,
      # two consecutive `darwin-rebuild switch` runs exit 0. The deprecation
      # warning is still printed, but it is only a warning now — activation is
      # not failed by it. The earlier exit 1 was most likely the untrusted tap
      # aborting the bundle, not `--cleanup` itself.
      # Still verified true: nothing is actually removed, so undeclared packages
      # must be pruned by hand.
      cleanup = "zap";
    };

    # TRAP (hit 2026-08-04): current Homebrew refuses to load formulae/casks
    # from untrusted third-party taps, which makes `brew bundle` — and therefore
    # the whole `darwin-rebuild switch` activation — fail. Trust must be granted
    # once per machine, OUTSIDE nix:
    #
    #   brew trust --taps wedow/tools d12frosted/emacs-plus nikitabobko/tap
    #
    # Two things that cost real time:
    #   1. `brew trust` REWRITES ~/.homebrew/trust.json wholesale — it does not
    #      append. Trusting one tap silently un-trusts every other. Always pass
    #      every tap in a SINGLE invocation.
    #   2. `brew bundle cleanup --force` prints "Uninstalled N casks" and exits 0
    #      even when an untrusted tap made it abort before removing anything.
    #      The summary line is not evidence; check /opt/homebrew/Caskroom.
    taps = [
      # Removed: anomalyco/tap (opencode is in homebrew-core now)
      # Removed: railwaycat/emacsmacport (using emacs-plus, not emacs-mac)
      # Removed: brewsci/homebrew-science (nothing installed from it)
      # Removed: koekeishiya/formulae (using aerospace, not yabai/skhd)
      # Commented out 2026-08-04: only fed the pharo-launcher cask, which is
      # no longer installed (manual uninstall to reclaim disk).
      # "pharo-project/pharo"
      "nikitabobko/tap"
      "d12frosted/emacs-plus"
      "wedow/tools"
    ];

    # CLI Packages via Brew (only what can't move to Nix)
    brews = [
      "opencode"              # Nix version too old (1.1.14 vs brew 1.4.10)
      "mpv"                   # Nix build fails versionCheckPhase on macOS
      "wedow/tools/ticket"    # Custom tap, no Nix package
      "librtlsdr"             # SDR radio library

      # emacs-plus@30 runtime libraries.
      #
      # WHY EVERY ONE OF THESE IS LISTED (incident 2026-08-04): emacs-plus@30 is
      # declared in `extraConfig` below, from the third-party d12frosted tap. When
      # `brew bundle cleanup --force` ran, Homebrew could not read that tap's
      # formula (see the tap-trust trap above), so it resolved emacs-plus to ZERO
      # dependencies and uninstalled all 19 of them. Emacs then died at launch with
      #   dyld: Library not loaded: /opt/homebrew/opt/librsvg/lib/librsvg-2.2.dylib
      # The binary hard-links these absolute paths (`otool -L …/MacOS/Emacs`), so a
      # missing one is an instant SIGABRT, not a degraded feature.
      #
      # Declaring them here makes them first-class Brewfile entries, so cleanup
      # protects them (and their transitive deps: pango, nettle, unbound, …) even
      # while the tap stays unreadable. Do not "tidy" these away as redundant —
      # they are load-bearing precisely because the tap's dep list is untrustworthy.
      # Re-check with: otool -L /opt/homebrew/opt/emacs-plus@30/Emacs.app/Contents/MacOS/Emacs
      "librsvg"               # SVG rendering — the library that broke 2026-08-04
      "gdk-pixbuf"            # image loading
      "gnutls"                # TLS for network.el / package.el
      "gmp"                   # bignum arithmetic
      "libgccjit"             # native compilation (comp.el)
      "tree-sitter@0.25"      # treesit.el — the binary links libtree-sitter.0.25.dylib
                              #   by soname, so the unversioned formula will NOT do
      "cairo"                 # rendering
      "glib"                  # gio/gobject/glib
      "gettext"               # libintl
      "little-cms2"           # color management
      "zlib"                  # keg-only, but linked by absolute path
      "sqlite"                # sqlite.el
      "jpeg"                  # image format support
      "libtiff"
      "libpng"
      "giflib"
      "webp"
    ];

    # GUI Applications
    #
    # 2026-08-04 disk-space audit: the operator manually uninstalled a number of
    # apps to reclaim space. Everything commented out below was still DECLARED
    # here but no longer present on disk — with `onActivation.cleanup = "zap"`
    # and `upgrade = true`, the next `darwin-rebuild switch` would have silently
    # reinstalled all of them (~several GB). Each line is kept, not deleted, so
    # re-enabling is a one-character edit.
    #
    # Verified by artifact, not by `brew list` — brew's registry still lists a
    # cask after the .app is dragged to the Trash, so the registry lies here.
    casks = [
      # mouse
      "logi-options+"
      # Browsers
      # "firefox"            # uninstalled 2026-08-04
      "google-chrome"

      # Communication
      # "discord"            # uninstalled 2026-08-04
      # "signal"             # uninstalled 2026-08-04
      # "slack"              # uninstalled 2026-08-04
      "telegram"
      # "zoom"               # uninstalled 2026-08-04 (pkg receipt remains, app gone)

      # Creative & Media
      # "audacity"           # uninstalled 2026-08-04
      # "calibre"            # uninstalled 2026-08-04 (~/Calibre Library kept)
      # "inkscape"           # uninstalled 2026-08-04
      # "krita"              # uninstalled 2026-08-04
      # "meshlab"            # uninstalled 2026-08-04
      "obs"
      # "vlc"                # uninstalled 2026-08-04 (mpv brew formula still present)

      # Cloud & Sync
      "dropbox" "google-drive" "aws-vpn-client"
      # tailscale-app: mesh VPN to the assistant VPS (hel1). The cask, not pkgs.tailscale
      # — nixpkgs ships only the CLI+daemon and nix-darwin has no services.tailscale
      # module for macOS, so the nix route would mean hand-rolling a launchd job.
      # Lets the server close port 22 entirely: everything it does is outbound, so with
      # Tailscale SSH it needs no inbound port at all.
      "tailscale-app"
      # "utm"                # uninstalled 2026-08-04 — NOTE: its 33 GB NixOS VM
      #                      #   still sits in ~/Library/Containers/com.utmapp.UTM

      # Developer & Utilities
      # 1password-cli now provided by Nix (pkgs._1password-cli)
      # "mongodb-compass"    # uninstalled 2026-08-04
      # "pharo-launcher"     # uninstalled 2026-08-04 (tap also disabled above)
      "aerospace" "blackhole-2ch" "caffeine" "docker-desktop"
      "karabiner-elements" "keycastr" "antigravity" "copilot-cli"
      { name = "nordlayer"; greedy = true; }
      # "pdf-pals"           # uninstalled 2026-08-04
      "spaceid" "opencode-desktop" "codex"
      # "vnc-viewer"         # uninstalled 2026-08-04

      # Security & Misc
      "1password" "claude" "displaylink"
      # "opencpn"            # uninstalled 2026-08-04 (pkg receipt remains, app gone)
      # "supercollider"      # uninstalled 2026-08-04
    ];

    masApps = {
      # GarageBand removed — App Store download fails and blocks brew bundle
      #
      # Xcode is deliberately NOT declared here. It is already installed at
      # /Applications/Xcode.app (4.7 GB) via the App Store. Declaring it would
      # make every activation depend on a `mas` download that needs an Apple ID
      # — exactly the failure mode that forced GarageBand out above.
      # Remaining manual step (needs sudo, so not automated):
      #   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
      #   sudo xcodebuild -runFirstLaunch
      # `xcode-select -p` currently still points at the nix apple-sdk.
    };

    extraConfig = ''
      brew "d12frosted/emacs-plus/emacs-plus@30", args: ["with-xwidgets"]
    '';
  };

  # --- Nix Configuration ---
  # services.nix-daemon.enable removed in 25.11 (now unconditional when nix.enable is on)
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
  
  # Set State Version to 5 to avoid the error you saw earlier
  system.stateVersion = 4;

  # Pin nixbld GID to match existing system (nix-darwin 25.11 changed default from 30000 → 350)
  ids.gids.nixbld = 350;

  # --- Security ---
  # Renamed in nix-darwin 25.11
  security.pam.services.sudo_local.touchIdAuth = true;

  # --- User Setup ---
  users.users.samikallinen.home = "/Users/samikallinen";
  users.users.samikallinen.shell = pkgs.zsh;
  programs.zsh = {
    enable = true;
    interactiveShellInit = ''
      if [ -d /opt/homebrew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      fi
    '';
  }; 

  # --- Home Manager (Mac Specifics) ---
  home-manager.backupFileExtension = "backup";
  home-manager.users.samikallinen = { pkgs, ... }: {
    imports = [ ./shared-home.nix ];

    # Mac-only packages (Not in shared-home.nix)
    home.packages = with pkgs; [
      pngpaste
      terminal-notifier
      m-cli
      cmake
      libtool
      nodejs          # moved from Homebrew
      _1password-cli  # moved from Homebrew cask
      emacs-lsp-booster  # LSP I/O proxy for faster TypeScript
      vscode-js-debug    # DAP debug adapter for dape
    ];

    # Config Files
    home.file.".config/aerospace/aerospace.toml".source = ./aerospace/aerospace.toml;
    home.file.".config/karabiner/karabiner.json".text = builtins.toJSON {
      profiles = [
        {
          name = "Default";
          selected = true;
          complex_modifications = {
            rules = [
              {
                description = "Cmd+Space -> Toggle Input Source (US <-> Swedish)";
                manipulators = [
                  {
                    type = "basic";
                    conditions = [
                      {
                        type = "input_source_if";
                        input_sources = [{ language = "^en.*$"; }];
                      }
                    ];
                    from = {
                      key_code = "spacebar";
                      modifiers = { mandatory = ["left_command"]; };
                    };
                    to = [{ select_input_source = { language = "sv"; }; }];
                  }
                  {
                    type = "basic";
                    conditions = [
                      {
                        type = "input_source_if";
                        input_sources = [{ language = "^sv$"; }];
                      }
                    ];
                    from = {
                      key_code = "spacebar";
                      modifiers = { mandatory = ["left_command"]; };
                    };
                    to = [{ select_input_source = { language = "en"; }; }];
                  }
                  # Fallback if neither matches (assume we want English)
                  {
                    type = "basic";
                    from = {
                      key_code = "spacebar";
                      modifiers = { mandatory = ["left_command"]; };
                    };
                    to = [{ select_input_source = { language = "en"; }; }];
                  }
                ];
              }
              {
                description = "Cmd+D -> Cmd+Space (Spotlight)";
                manipulators = [
                  {
                    type = "basic";
                    from = {
                      key_code = "d";
                      modifiers = { mandatory = ["left_command"]; };
                    };
                    to = [
                      {
                        key_code = "spacebar";
                        modifiers = ["left_command"];
                      }
                    ];
                  }
                ];
              }
              {
                description = "Right Cmd → Super when UTM focused";
                manipulators = [
                  {
                    type = "basic";
                    conditions = [
                      {
                        type = "frontmost_application_if";
                        bundle_identifiers = ["^com\\.utmapp\\.UTM$"];
                      }
                    ];
                    from = { key_code = "right_command"; };
                    to = [{ key_code = "left_gui"; }];
                  }
                ];
              }
              {
                description = "Caps Lock -> Left Command";
                manipulators = [
                  {
                    type = "basic";
                    from = {
                      key_code = "caps_lock";
                      modifiers = { optional = ["any"]; };
                    };
                    to = [{ key_code = "left_command"; }];
                  }
                ];
              }
            ];
          };
          simple_modifications = [
            {
              from = { key_code = "caps_lock"; };
              to = [{ key_code = "left_command"; }];
            }
            {
              from = { key_code = "right_command"; };
              to = [{ key_code = "left_gui"; }];
            }
          ];
          virtual_hid_keyboard = { keyboard_type_v2 = "ansi"; };
        }
      ];
    };

  
  };
  
  # --- Fonts ---
  fonts.packages = with pkgs; [
    nerd-fonts.roboto-mono
  ];
}
