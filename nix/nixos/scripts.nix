{
  config,
  pkgs,
  ...
}: {
  # Import custom services
  imports = [
    ./scripts/mqtt-service/service.nix
    ./scripts/grist-payment-updater/service.nix
  ];
}
