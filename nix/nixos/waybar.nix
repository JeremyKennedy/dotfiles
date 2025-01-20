{pkgs, ...}: {
  systemd.user.services.waybar = {
    description = "Waybar - Wayland bar for Sway and Wlroots based compositors";
    wantedBy = ["hyprland-session.target"];
    partOf = ["graphical-session.target"];
    after = ["graphical-session.target"];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.waybar}/bin/waybar";
      ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
      Restart = "on-failure";
      RestartSec = 1;
    };
  };
}
