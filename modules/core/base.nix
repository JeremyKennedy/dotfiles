{
  config,
  pkgs,
  inputs,
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

  # Set root password for console access (KVM)
  # Using initialHashedPassword - sets password on first boot only
  users.users.root.initialHashedPassword = "$y$j9T$7tHof6eMlrWk9qrOIjM3m1$Tpfd5r.xgKuSxdFlvDWqJv39gGyS0ceiJt8OSYde1N6"; # "nixos"

  # Core system packages are now in packages.nix
}
