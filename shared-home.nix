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
      ssh -o StrictHostKeyChecking=no samikallinen@192.168.64.1 /opt/homebrew/bin/op "$@"
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

  home.stateVersion = "22.11";
}
