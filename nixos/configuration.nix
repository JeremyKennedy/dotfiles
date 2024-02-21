# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "nodejs-16.20.2"
    "electron-25.9.0"
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "JeremyDesktop"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Toronto";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_CA.UTF-8";

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # Configure keymap in X11
  services.xserver = {
    xkb.layout = "us";
    xkb.variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.avahi.enable = true; # runs the Avahi daemon
  services.avahi.nssmdns = true; # enables the mDNS NSS plug-in
  services.avahi.openFirewall = true; # opens the firewall for UDP port 5353

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Enable automatic login for the user.
  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = "jeremy";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jeremy = {
    isNormalUser = true;
    description = "Jeremy";
    extraGroups = ["networkmanager" "wheel" "ftp" "adbusers"];
    packages = with pkgs; [
      firefox
      kate
      bitwarden
      vscode
      spotify
      discord
      filezilla
      obsidian
      telegram-desktop
      jetbrains-toolbox
      jetbrains.webstorm
      jetbrains.datagrip
      smartgithg
      kcalc
      gamemode
      winetricks
      unstable.bambu-studio
      steamtinkerlaunch
      parsec-bin
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    git
  ];

  # enable kde connect
  programs.kdeconnect.enable = true;

  # enable steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
  };

  # enable fish
  programs.fish.enable = true;
  # appears to not work
  programs.fish.promptInit = ''
    any-nix-shell fish --info-right | source
  '';
  programs.fish.interactiveShellInit = ''direnv hook fish | source'';
  users.defaultUserShell = pkgs.fish;
  environment.shells = with pkgs; [fish];

  # enable starship (applies to all shells)
  programs.starship.enable = true;

  # enable flatpak
  services.flatpak.enable = true;

  # Enable OpenGL
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    # Modesetting is needed most of the time
    modesetting.enable = true;

    # Enable power management (do not disable this unless you have a reason to).
    # Likely to cause problems on laptops and with screen tearing if disabled.
    powerManagement.enable = true;

    # Use the NVidia open source kernel module (which isn't “nouveau”).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    open = false;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.beta;

    # force old nvidia
    #package = (config.boot.kernelPackages.nvidiaPackages.stable.overrideAttrs {
    # src = pkgs.fetchurl {
    #   url = "https://download.nvidia.com/XFree86/Linux-x86_64/525.125.06/NVIDIA-Linux-x86_64-525.125.06.run";
    #   sha256 = "17av8nvxzn5af3x6y8vy5g6zbwg21s7sq5vpa1xc6cx8yj4mc9xm";
    # };
    #});
    #package = (config.boot.kernelPackages.nvidiaPackages.stable.overrideAttrs {
    #  src = pkgs.fetchurl {
    #    url = "https://download.nvidia.com/XFree86/Linux-x86_64/535.104.05/NVIDIA-Linux-x86_64-535.104.05.run";
    #    sha256 = "1jgdrczy70jlg9ybi1z8mm9q5vg78rf66dknfppbww573nfn179g";
    #  };
    #});
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  fileSystems."/mnt/tower/appdata" = {
    device = "192.168.1.240:/mnt/user/appdata";
    fsType = "nfs";
  };
  fileSystems."/mnt/tower/general" = {
    device = "192.168.1.240:/mnt/user/general";
    fsType = "nfs";
  };

  # Enable the OpenSSH daemon.

  services.openssh = {
    enable = true;
    # require public key authentication for better security
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
    #settings.PermitRootLogin = "yes";
    allowSFTP = true;
  };

  # ftp user
  users.users.ftp = {
    isNormalUser = false;
    isSystemUser = true;
    home = "/home/ftp";
    group = "ftp";
    description = "FTP user";
    #extraGroups  = [ "wheel" "networkmanager" ];
    #openssh.authorizedKeys.keys  = [ "ssh-dss AAAAB3Nza... alice@foobar" ];
  };

  programs.adb.enable = true;

  # ftp server
  services.vsftpd = {
    enable = true;
    writeEnable = true;
    localUsers = true;
    userlist = ["ftp"];
    userlistEnable = true;
    extraConfig = ''
      pasv_enable=Yes
      pasv_min_port=51000
      pasv_max_port=51999
    '';
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [
    3000 # dev server
    21 # ftp
  ];
  networking.firewall.allowedTCPPortRanges = [
    {
      from = 51000;
      to = 51999;
    } # ftp
  ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

  # enable the experimental nix command
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
