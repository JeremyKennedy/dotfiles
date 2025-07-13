# Desktop terminal configuration
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    alacritty # terminal emulator
  ];

  # Note: Alacritty configuration better handled in home-manager for user customization
}
