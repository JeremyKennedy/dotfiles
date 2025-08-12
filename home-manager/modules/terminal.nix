# Terminal emulator configuration
{ pkgs, ... }:

{
  # Ghostty terminal emulator
  programs.ghostty = {
    enable = true;
    settings = {
      # Font configuration
      font-family = "monospace";
      font-size = 12;

      # Performance
      gtk-single-instance = true;

      # Appearance
      theme = "catppuccin-mocha"; # Popular dark themes: Dracula, catppuccin-mocha, GruvboxDark, nord, GruvboxDarkHard, Oxocarbon, Hardcore

      # Window
      window-decoration = true;

      # Behavior
      # copy-on-select = true;
      cursor-style = "block";
      cursor-style-blink = true;

      # Scrollback
      scrollback-limit = 10000;

      # Shell integration
      shell-integration = "detect";
      shell-integration-features = "cursor,sudo,title";
    };
  };
}