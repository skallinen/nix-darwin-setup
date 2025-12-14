{ config, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  # Allow unfree packages (needed for 1Password, etc.)
  nixpkgs.config.allowUnfree = true;

  # --- Boot & Hardware ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = [ "9p" "9pnet" "9pnet_virtio" ];
  
  # --- Filesystems (9p Automounts) ---
  # --- Filesystems (9p Automounts) ---
  # Raw mount of the host share to /mnt/vm-share
  fileSystems."/mnt/vm-share" = {
    device = "share";
    fsType = "9p";
    options = [ "trans=virtio" "version=9p2000.L" "cache=loose" "msize=262144" "noauto" "x-systemd.automount" "x-systemd.idle-timeout=60" ];
  };

  # Bindfs overlay to /home/sakalli/common
  fileSystems."/home/sakalli/common" = {
    device = "/mnt/vm-share";
    fsType = "fuse.bindfs";
    options = [ "force-user=sakalli" "force-group=users" "create-for-user=501" "create-for-group=20" "auto_cache" "noauto" "x-systemd.automount" "x-systemd.idle-timeout=60" ];
  };
  
  # UTM/QEMU Drivers
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # --- Filesystems ---
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/1ac0129f-aeec-46d3-9f14-fdc54d85843f";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/889D-AC5A";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  # --- Networking ---
  networking.hostName = "nixos-vm";
  networking.networkmanager.enable = true;
  services.openssh.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];

  # --- User ---
  users.users.sakalli = {
    isNormalUser = true;
    home = "/home/sakalli";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
    initialPassword = "nixos"; # only used at first creation
  };

  # --- Home Manager Configuration (Inline for VM Specifics) ---
  home-manager.users.sakalli = { pkgs, lib, ... }: {
    imports = [ ./shared-home.nix ];
    
    # --- Linux-Only Packages (Moved from shared-home.nix) ---
    home.packages = with pkgs; [
        # Languages & Build
        clojure
        python3
        cmake
        git-filter-repo
        gnumake

        # Utils
        jc
        awscli2
        
        # Search & Text
        html-tidy
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
        matterbridge
        mob
        tdlib
        
        # GUI / System
        gvfs
        kitty
        
        # 1Password Host Wrapper
        (pkgs.writeShellScriptBin "host-op" ''
          HOST="samikallinen@192.168.64.1"
          SSH_OPTS="-q -t -o StrictHostKeyChecking=no -o ControlMaster=auto -o ControlPath=~/.ssh/host-op-control -o ControlPersist=10m"

          # We use a compound command:
          # 1. 'op signin' (forces authentication in the current shell)
          # 2. 'op "$@"' (executes the requested command with that auth)
          # 3. 'tr -d \r' (strips SSH TTY artifacts so Emacs gets clean JSON)
          
          # Escape arguments locally to preserve them through SSH
          QARGS=$(printf "%q " "$@")
          
          # We ignore the output of signin to keep stdout clean for the actual command
          # We assume the user approves the prompt interactively.
          ssh $SSH_OPTS $HOST "env TERM=xterm-256color /bin/bash -c '/opt/homebrew/bin/op signin --force >/dev/null 2>&1 && /opt/homebrew/bin/op $QARGS'" | tr -d '\r'
        '')
    ];

    # --- SSH Agent Tunnel Service ---
    systemd.user.services.ssh-agent-tunnel = {
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
      SSH_AUTH_SOCK = "/home/sakalli/.1password/agent.sock";
    };
    
    # --- X11 / i3 Configuration (Linux Only) ---
    xresources.properties = {
      "Xft.dpi" = "192";
      "Xcursor.size" = "48";
    };

    xsession.windowManager.i3 = {
      enable = true;
      package = pkgs.i3-gaps;
      config = {
        bars = [ ]; 
      };
      extraConfig = ''
        set $mod Mod4
        font pango:Roboto Mono 14
        floating_modifier $mod
        bindsym $mod+Return exec --no-startup-id kitty
        bindsym $mod+Shift+q kill
        bindsym $mod+d exec --no-startup-id rofi -show run -font "Roboto Mono 20"
        
        # Focus
        bindsym $mod+h focus left
        bindsym $mod+j focus down
        bindsym $mod+k focus up
        bindsym $mod+l focus right
        bindsym $mod+Left  focus left
        bindsym $mod+Down  focus down
        bindsym $mod+Up    focus up
        bindsym $mod+Right focus right

        # Move
        bindsym $mod+Shift+h move left
        bindsym $mod+Shift+j move down
        bindsym $mod+Shift+k move up
        bindsym $mod+Shift+l move right
        bindsym $mod+Shift+Left  move left
        bindsym $mod+Shift+Down  move down
        bindsym $mod+Shift+Up    move up
        bindsym $mod+Shift+Right move right

        # Split/Full/Layout
        bindsym $mod+g split h
        bindsym $mod+v split v
        bindsym $mod+f fullscreen toggle
        bindsym $mod+s layout stacking
        bindsym $mod+Shift+space floating toggle
        bindsym $mod+space        focus mode_toggle
        bindsym $mod+a focus parent

        # Workspaces
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

        # Modes
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

        # Gaps
        gaps inner 10
        gaps outer 0
        smart_gaps on
        for_window [class="^.*"] border pixel 1

        # Colors
        client.focused          #7BADB6 #7BADB6 #ffffff #7BADB6
        client.focused_inactive #333333 #333333 #ffffff #484e50
        client.unfocused        #000000 #111111 #888888 #292d2e
        client.urgent           #2f343a #900000 #ffffff #900000
        client.placeholder      #000000 #0c0c0c #ffffff #000000

        # Floating
        for_window [title="feh \["]        floating enable
        for_window [title="JACK*"]         floating enable
        for_window [title="Skype"]         floating enable
        for_window [title="Buddy List"]    floating enable
        for_window [title="KeePass"]       floating enable
        for_window [class="Uzbl-core"]     focus child, layout tabbed, focus

        # Startup
        exec_always --no-startup-id xrdb ~/.Xresources
        exec_always --no-startup-id spice-vdagent
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
  };

  environment.variables = {
    GDK_SCALE = "2";
    XCURSOR_SIZE = "48";
  };

  # --- X11 + Window Manager (i3) ---
  services.xserver = {
    enable = true;
    desktopManager.xterm.enable = false;
    dpi = 192;
    

    windowManager.i3 = {
      enable = true;
      package = pkgs.i3-gaps;
      extraPackages = with pkgs; [
        dmenu
        i3status
        i3lock
        i3blocks
        rofi
      ];
    };

    xkb.options = "caps:escape";
  };

  # --- Fonts (for i3 / rofi: Roboto Mono) ---
  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "RobotoMono" ]; })
    noto-fonts-emoji
  ];

  # --- 1Password inside VM (GUI + CLI, with polkit) ---
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "sakalli" ];
  };

  # --- System Packages (VM Specific) ---
  environment.systemPackages = with pkgs; [
    bindfs # For valid user permissions on shared folder
    cmake
    libtool
    libvterm
    ((emacsPackagesFor emacs).emacsWithPackages (epkgs: [ epkgs.vterm ]))
    zile
    firefox
    git
    arandr
    xclip
    flameshot
    libnotify
    xkblayout-state
  ];

  programs.zsh.enable = true;

  # --- Nix Configuration ---
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "24.05";
}
