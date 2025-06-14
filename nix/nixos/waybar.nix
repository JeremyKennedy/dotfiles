{pkgs, ...}: {
  systemd.user.services.waybar = {
    description = "Waybar - Wayland bar for Sway and Wlroots based compositors";
    wantedBy = ["graphical-session.target"];
    partOf = ["graphical-session.target"];
    after = ["graphical-session.target"];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.waybar}/bin/waybar";
      ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
      Restart = "on-failure";
      RestartSec = 1;
      Environment = [
        "PATH=/run/wrappers/bin:/nix/var/nix/profiles/default/bin:$PATH"
        "XDG_RUNTIME_DIR=/run/user/%U"
      ];
    };
  };
}
