{
  fileSystems."/mnt/tower/appdata" = {
    device = "192.168.1.240:/mnt/user/appdata";
    fsType = "nfs";
  };
  fileSystems."/mnt/tower/general" = {
    device = "192.168.1.240:/mnt/user/general";
    fsType = "nfs";
  };
  fileSystems."/mnt/tower/backups" = {
    device = "192.168.1.240:/mnt/user/backups";
    fsType = "nfs";
  };
}
