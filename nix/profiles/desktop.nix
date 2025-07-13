# Common desktop profile - imports core modules plus desktop essentials
{
  config,
  lib,
  pkgs,
  inputs,
  outputs,
  ...
}: {
  imports = [
    ../modules/core # Core modules for ALL hosts
    ../modules/desktop # Desktop modules (graphics, hyprland, waybar, ledger)
  ];

  # Home-manager configuration for desktop
  home-manager = {
    extraSpecialArgs = {inherit inputs outputs;};
    users = {
      jeremy = import ../home-manager/home.nix;
    };
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  # Desktop-specific defaults
  services.xserver.enable = lib.mkDefault true;

  # Enable sound with PipeWire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    jack.enable = true;
  };


  # Don't auto-upgrade desktops (user should control this)
  system.autoUpgrade.enable = lib.mkDefault false;
}
