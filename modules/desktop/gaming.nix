# Gaming and streaming configuration
{pkgs, ...}: {
  # GameMode polkit rules - allows gamemode to run without sudo
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "com.feralinteractive.GameMode" &&
          subject.isInGroup("users")) {
        return polkit.Result.YES;
      }
    });
  '';

  # Sunshine game streaming server
  services.sunshine = {
    enable = true;
    openFirewall = true;
    capSysAdmin = true; # Required for some streaming features
  };

  # Gaming tools and utilities
  environment.systemPackages = with pkgs; [
    gamemode
    mangohud
    prismlauncher # Minecraft launcher
    steamtinkerlaunch

    # Wine and compatibility layers
    wine
    winetricks
    lutris

    # Remote gaming
    parsec-bin
  ];
}
