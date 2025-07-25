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
  users.users.root.initialPassword = "securenixos";

  # Core system packages are now in packages.nix
}
