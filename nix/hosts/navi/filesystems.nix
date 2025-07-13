# https://nixos.wiki/wiki/NFS
{
  fileSystems."/mnt/tower/appdata" = {
    device = "192.168.1.240:/mnt/user/appdata";
    fsType = "nfs";
    options = ["noatime"];
  };
  fileSystems."/mnt/tower/general" = {
    device = "192.168.1.240:/mnt/user/general";
    fsType = "nfs";
    options = ["noatime"];
  };
  fileSystems."/mnt/tower/backups" = {
    device = "192.168.1.240:/mnt/user/backups";
    fsType = "nfs";
    options = ["noatime"];
  };
  fileSystems."/mnt/tower/temp" = {
    device = "192.168.1.240:/mnt/user/temp";
    fsType = "nfs";
    options = ["noatime" "x-systemd.automount" "noauto"];
  };
  fileSystems."/mnt/tower/media" = {
    device = "192.168.1.240:/mnt/user/media";
    fsType = "nfs";
    options = ["noatime" "x-systemd.automount" "noauto"];
  };
}
