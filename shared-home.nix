{ pkgs, lib, ... }:

{
  # --- Shared Packages (CLI tools, languages, utilities) ---
  home.packages = with pkgs; [
    # Languages
    clojure
    python3

    # Build & VCS
    cmake
    git-filter-repo
    gnumake

    # CLI essentials
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
    tldr
    tokei
    tree
    wget

    # Search & Text
    html-tidy
    ripgrep
    silver-searcher
    w3m

    # Networking
    arp-scan
    iftop
    nmap
    rsync
    caddy

    # Email & Docs
    isync
    mu
    pandoc

    # Visualization
    graphviz

    # Misc
    # cmdstan
    gvfs
    kitty
    matterbridge
    mob
    tdlib
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    (pkgs.writeShellScriptBin "host-op" ''
      ssh -q -t -o StrictHostKeyChecking=no -o ControlMaster=auto -o ControlPath=~/.ssh/host-op-control -o ControlPersist=10m samikallinen@192.168.64.1 env TERM=xterm-256color /opt/homebrew/bin/op "$@"
    '')
  ];

  # Linux-specific Systemd Service for SSH Agent Tunneling
  systemd.user.services.ssh-agent-tunnel = lib.mkIf pkgs.stdenv.isLinux {
    Unit = {
      Description = "SSH Agent Tunnel to Host 1Password";
      After = [ "network.target" ];
    };
    Service = {
      ExecStartPre = "${pkgs.coreutils}/bin/rm -f %h/.1password/agent.sock";
      ExecStart = "${pkgs.openssh}/bin/ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -N -L %h/.1password/agent.sock:\"/Users/samikallinen/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\" samikallinen@192.168.64.1";
      Restart = "always";
      RestartSec = "5s";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };


  home.sessionVariables = {
    PAGER = "less";
    EDITOR = "zile";
    DOCKER_CONTEXT = "desktop-linux";
  } // lib.optionalAttrs pkgs.stdenv.isLinux {
    SSH_AUTH_SOCK = "/home/sakalli/.1password/agent.sock";
  };

  # --- Shared Program Configurations ---

  programs.bat = {
    enable = true;
    config.theme = "TwoDark";
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.eza.enable = true;
  programs.git = {
    enable = true;
    userName  = "Sami Kallinen";
    userEmail = "notjustsilicon@gmail.com";
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.alacritty = {
    enable = true;
    settings.font.normal.family = "MesloLGS Nerd Font Mono";
    settings.font.size = 16;
  };

programs.ssh = {
  enable = true;
  extraConfig = if pkgs.stdenv.isDarwin then ''
    Host *
      IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

    Host vm
      HostName 192.168.64.5
      User sakalli
      IdentityFile ~/.ssh/antigravity_id_ed25519
      IdentitiesOnly yes
      StrictHostKeyChecking no
      UserKnownHostsFile /dev/null
      ForwardAgent yes
      RemoteForward /home/sakalli/.1password/agent.sock "/Users/samikallinen/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
  '' else '''';
};

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    initExtra = ''
      # Docker Context Switching (macOS only - Docker Desktop)
      if [ "$(uname)" = "Darwin" ] && command -v docker >/dev/null 2>&1; then
        if [ -z "''${DOCKER_HOST:-}" ] && docker context ls >/dev/null 2>&1; then
          cur="$(docker context show 2>/dev/null || true)"
          [ "$cur" != "desktop-linux" ] && docker context use desktop-linux >/dev/null 2>&1 || true
        fi
      fi

      # --- UNIVERSAL NIX SWITCH ---
      # Works on macOS (darwin-rebuild) and NixOS (nixos-rebuild)
      nix-switch() {
        # Local flake path (override with $NIX_SWITCH_LOCAL_FLAKE if you like)
        local local_flake="''${NIX_SWITCH_LOCAL_FLAKE:-$HOME/src/nix-darwin-setup}"
        local remote_flake="''${NIX_SWITCH_REMOTE_FLAKE:-github:skallinen/nix-darwin-setup}"
        local origin="local"
        local host=""
        local target_os=""

        # Detect OS
        if [ "$(uname)" = "Linux" ]; then
          target_os="linux"
        else
          target_os="macos"
        fi

        while [ $# -gt 0 ]; do
          case "$1" in
            --remote) origin="remote"; shift ;;
            --local)  origin="local";  shift ;;
            -h|--help)
              echo "Usage: nix-switch [--local|--remote] [HOST] [extra args]"
              return 0
              ;;
            *)
              if [ -z "$host" ]; then
                host="$1"
                shift
              else
                break
              fi
              ;;
          esac
        done

        # Default hostnames if none provided
        if [ -z "$host" ]; then
          if [ "$target_os" = "linux" ]; then
            host="nixos-vm"
          else
            host="$(scutil --get LocalHostName 2>/dev/null || hostname -s)"
          fi
        fi

        # Select flake source
        local flake
        if [ "$origin" = "local" ]; then
          flake="$local_flake"
        else
          flake="$remote_flake"
        fi

        echo "🚀 Switching $target_os to $flake#$host..."

        # Execute correct rebuild command
        if [ "$target_os" = "linux" ]; then
          sudo nixos-rebuild switch --flake "$flake#$host" "$@"
        else
          darwin-rebuild switch --flake "$flake#$host" "$@"
        fi
      }
    '';
  };

  # --- X11 / i3 Configuration (Linux Only) ---
  xresources.properties = lib.mkIf pkgs.stdenv.isLinux {
    "Xft.dpi" = "192";
    "Xcursor.size" = "48";
  };

  xsession.windowManager.i3 = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    package = pkgs.i3-gaps;
    config = {
      # We use a custom config string to preserve exact manual bindings
      # without translating everything to Nix syntax.
      bars = [ ]; # We define bar manually in extraConfig
    };
    extraConfig = ''
      set $mod Mod4

      # Font (Scaled for HiDPI)
      font pango:Roboto Mono 14

      # Use mouse+$mod to drag floating windows
      floating_modifier $mod

      # start a terminal (Alacritty matches other config, or keep Kitty if preferred)
      bindsym $mod+Return exec --no-startup-id kitty

      # kill focused window
      bindsym $mod+Shift+q kill

      # launcher (rofi) - Scaled Font
      bindsym $mod+d exec --no-startup-id rofi -show run -font "Roboto Mono 20"

      # focus movement
      bindsym $mod+h focus left
      bindsym $mod+j focus down
      bindsym $mod+k focus up
      bindsym $mod+l focus right

      bindsym $mod+Left  focus left
      bindsym $mod+Down  focus down
      bindsym $mod+Up    focus up
      bindsym $mod+Right focus right

      # move windows
      bindsym $mod+Shift+h move left
      bindsym $mod+Shift+j move down
      bindsym $mod+Shift+k move up
      bindsym $mod+Shift+l move right

      bindsym $mod+Shift+Left  move left
      bindsym $mod+Shift+Down  move down
      bindsym $mod+Shift+Up    move up
      bindsym $mod+Shift+Right move right

      # splits
      bindsym $mod+g split h
      bindsym $mod+v split v

      # fullscreen
      bindsym $mod+f fullscreen toggle

      # layouts
      bindsym $mod+s layout stacking
      # bindsym $mod+w layout tabbed
      # bindsym $mod+e layout toggle split

      # tiling / floating
      bindsym $mod+Shift+space floating toggle
      bindsym $mod+space        focus mode_toggle

      # parent container
      bindsym $mod+a focus parent

      # workspaces
      bindsym $mod+1 workspace 1
      bindsym $mod+2 workspace 2
      bindsym $mod+3 workspace 3
      bindsym $mod+4 workspace 4
      bindsym $mod+5 workspace 5
      bindsym $mod+6 workspace 6
      bindsym $mod+7 workspace 7
      bindsym $mod+8 workspace 8
      bindsym $mod+9 workspace 9
      bindsym $mod+0 workspace 10

      bindsym $mod+Shift+1 move container to workspace 1
      bindsym $mod+Shift+2 move container to workspace 2
      bindsym $mod+Shift+3 move container to workspace 3
      bindsym $mod+Shift+4 move container to workspace 4
      bindsym $mod+Shift+5 move container to workspace 5
      bindsym $mod+Shift+6 move container to workspace 6
      bindsym $mod+Shift+7 move container to workspace 7
      bindsym $mod+Shift+8 move container to workspace 8
      bindsym $mod+Shift+9 move container to workspace 9
      bindsym $mod+Shift+0 move container to workspace 10

      bindsym $mod+Tab        workspace next
      bindsym $mod+Shift+Tab  workspace prev

      bindsym $mod+Shift+c reload
      bindsym $mod+Shift+r restart
      bindsym $mod+Shift+e exec "i3-nagbar -t warning -m 'Exit i3?' -b 'Yes' 'i3-msg exit'"

      # resize mode
      mode "resize" {
          bindsym j resize shrink width 10 px or 10 ppt
          bindsym k resize grow height 10 px or 10 ppt
          bindsym l resize shrink height 10 px or 10 ppt
          bindsym h resize grow width 10 px or 10 ppt

          bindsym Left  resize shrink width 10 px or 10 ppt
          bindsym Down  resize grow height 10 px or 10 ppt
          bindsym Up    resize shrink height 10 px or 10 ppt
          bindsym Right resize grow width 10 px or 10 ppt

          bindsym Return mode "default"
          bindsym Escape mode "default"
      }

      bindsym $mod+r mode "resize"

      # Status Bar
      bar {
          status_command ${pkgs.i3status}/bin/i3status
          position top
          colors {
              background #000000
              statusline #ffffff
              separator  #666666
              focused_workspace  #7BADB6 #7BADB6 #000000
              active_workspace   #333333 #333333 #ffffff
              inactive_workspace #333333 #222222 #888888
              urgent_workspace   #aa0000 #990000 #ffffff
          }
      }

      # Gaps & borders
      gaps inner 10
      gaps outer 0
      smart_gaps on
      for_window [class="^.*"] border pixel 1

      # Colours
      client.focused          #7BADB6 #7BADB6 #ffffff #7BADB6
      client.focused_inactive #333333 #333333 #ffffff #484e50
      client.unfocused        #000000 #111111 #888888 #292d2e
      client.urgent           #2f343a #900000 #ffffff #900000
      client.placeholder      #000000 #0c0c0c #ffffff #000000

      # Floating rules
      for_window [title="feh \["]        floating enable
      for_window [title="JACK*"]         floating enable
      for_window [title="Skype"]         floating enable
      for_window [title="Buddy List"]    floating enable
      for_window [title="KeePass"]       floating enable
      for_window [class="Uzbl-core"]     focus child, layout tabbed, focus

      # Load Xresources
      exec_always --no-startup-id xrdb ~/.Xresources
      # Start spice-vdagent
      exec_always --no-startup-id spice-vdagent
      # Force VM resolution sync
      bindsym $mod+Shift+d exec --no-startup-id xrandr --output Virtual-1 --auto
    '';
  };

  programs.i3status = {
    enable = true;
    enableDefault = false;
    general = {
      colors = true;
      interval = 5;
      color_good = "#7BADB6";
      color_degraded = "#ccdc90";
      color_bad = "#FFCFBE";
    };
    modules = {
      "ipv6" = { position = 1; };
      "disk /" = { position = 2; };
      "wireless _first_" = { position = 3; };
      "ethernet _first_" = { position = 4; };
      "battery all" = { position = 5; };
      "load" = { position = 6; };
      "tztime local" = { position = 7; };
    };
  };

  home.stateVersion = "22.11";
}
