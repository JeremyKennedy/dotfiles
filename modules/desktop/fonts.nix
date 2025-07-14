# Desktop font configuration
{pkgs, ...}: {
  # Desktop fonts
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono # Programming font with icons
  ];
}
