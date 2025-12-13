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
