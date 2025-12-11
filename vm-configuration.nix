{ pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  # --- Boot & Hardware ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
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

  # --- User ---
  users.users.sakalli = {
    isNormalUser = true;
    home = "/home/samikallinen";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
    initialPassword = "nixos"; 
  };

  # --- Window Manager (i3) ---
  services.xserver = {
    enable = true;
    desktopManager.xterm.enable = false;
    windowManager.i3 = {
      enable = true;
      package = pkgs.i3-gaps;
      extraPackages = with pkgs; [ dmenu i3status i3lock i3blocks ];
    };
    xkb.options = "caps:escape"; 
  };

  # --- System Packages (VM Specific) ---
  environment.systemPackages = with pkgs; [
    emacs # Install emacs system-wide
    zile
    firefox
    git
    arandr
  ];

  programs.zsh.enable = true;
  system.stateVersion = "24.05";
}
