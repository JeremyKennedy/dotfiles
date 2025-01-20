# https://github.com/Misterio77/nix-starter-configs/blob/main/standard/nixos/configuration.nix
# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').
{
  inputs,
  outputs,
  config,
  pkgs,
  secrets,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./nvidia.nix
    ./filesystems.nix
    ./network.nix
    ./ledger.nix
    ./waybar.nix
    ./programs.nix
    ./hyprland.nix
    ./shell.nix

    # Import home-manager's NixOS module
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    extraSpecialArgs = {inherit inputs outputs secrets;};
    users = {
      # Import your home-manager configuration
      jeremy = import ../home-manager/home.nix;
    };
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.stable-packages
      outputs.overlays.unstable-packages
      outputs.overlays.master-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];

    config = {
      allowUnfree = true;
      permittedInsecurePackages = [
        "nodejs-16.20.2"
        "electron-25.9.0"
      ];
    };
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 20;
  boot.loader.efi.canTouchEfiVariables = true;

  # Set your time zone.
  time.timeZone = "America/Toronto";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_CA.UTF-8";

  # Disable X11 (since we're using Wayland/Hyprland)
  services.xserver.enable = false;

  environment.systemPackages = with pkgs; [
    # Core utilities
    vim
    git
  ];

  # Essential services
  services.dbus.enable = true;

  environment.sessionVariables = {
    # Wayland
    NIXOS_OZONE_WL = "1"; # Electron apps
    WLR_NO_HARDWARE_CURSORS = "1"; # Fix cursor rendering
    XDG_SESSION_TYPE = "wayland";

    # NVIDIA
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.avahi.enable = true; # runs the Avahi daemon
  services.avahi.nssmdns4 = true; # enables the mDNS NSS plug-in
  services.avahi.openFirewall = true; # opens the firewall for UDP port 5353

  # Enable sound with pipewire.
  # sound.enable = true;
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
  };

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.jeremy = {
    isNormalUser = true;
    description = "Jeremy";
    extraGroups = ["networkmanager" "wheel" "ftp" "adbusers" "docker"];
  };

  # docker
  virtualisation.docker.enable = true;
  hardware.nvidia-container-toolkit.enable = true;

  # enable flatpak
  services.flatpak.enable = true;

  # Enable OpenGL
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  services.earlyoom = {
    enable = true;
    freeMemThreshold = 5;
    enableNotifications = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

  nix.settings = {
    # Enable flakes and new 'nix' command
    experimental-features = "nix-command flakes";
    # Deduplicate and optimize nix store
    auto-optimise-store = true;

    trusted-users = ["root" "jeremy"];
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];
}
