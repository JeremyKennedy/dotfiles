{
  config,
  pkgs,
  inputs,
  outputs,
  ...
}: {
  nix.settings = {
    experimental-features = "nix-command flakes";
    auto-optimise-store = true;
    trusted-users = ["root"];
  };

  # Automatic garbage collection and optimization
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Automatic store optimization (deduplication)
  nix.optimise = {
    automatic = true;
    dates = ["weekly"];
  };

  time.timeZone = "America/Toronto";
  i18n.defaultLocale = "en_CA.UTF-8";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
  # Allow specific insecure packages
  nixpkgs.config.permittedInsecurePackages = [
    "libsoup-2.74.3" # Required by bambu-studio and orca-slicer (3D printing slicers)
  ];
  
  # Apply overlays
  nixpkgs.overlays = [
    outputs.overlays.stable-packages
    outputs.overlays.unstable-packages
    outputs.overlays.master-packages
    outputs.overlays.modifications      # Custom modifications last to take precedence
  ];

  # Set root password for console access (KVM)
  users.users.root.initialPassword = "securenixos";

  # Core system packages are now in packages.nix
}
