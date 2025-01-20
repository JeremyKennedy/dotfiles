{pkgs, ...}: {
  # enable fish
  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;
  environment.shells = with pkgs; [fish];

  # enable starship (applies to all shells)
  programs.starship.enable = true;
}
