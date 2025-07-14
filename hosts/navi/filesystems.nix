# https://nixos.wiki/wiki/NFS
let
  inherit (import ../../modules/core/hosts.nix) hosts;
in {
  fileSystems."/mnt/tower/appdata" = {
    device = "${hosts.tower.ip}:/mnt/user/appdata";
    fsType = "nfs";
    options = ["noatime"];
  };
  fileSystems."/mnt/tower/general" = {
    device = "${hosts.tower.ip}:/mnt/user/general";
    fsType = "nfs";
    options = ["noatime"];
  };
  fileSystems."/mnt/tower/backups" = {
    device = "${hosts.tower.ip}:/mnt/user/backups";
    fsType = "nfs";
    options = ["noatime"];
  };
  fileSystems."/mnt/tower/temp" = {
    device = "${hosts.tower.ip}:/mnt/user/temp";
    fsType = "nfs";
    options = ["noatime" "x-systemd.automount" "noauto"];
  };
  fileSystems."/mnt/tower/media" = {
    device = "${hosts.tower.ip}:/mnt/user/media";
    fsType = "nfs";
    options = ["noatime" "x-systemd.automount" "noauto"];
  };
}
