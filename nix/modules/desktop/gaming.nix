# Gaming and streaming configuration
{...}: {
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
}
