{
  config,
  pkgs,
  ...
}: {
  # Import custom services
  imports = [
    ./services/mqtt-service/service.nix
    ../../modules/services/utility/grist-payment-updater/service.nix
  ];
}
