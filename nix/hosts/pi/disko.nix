# Simple disko configuration for Raspberry Pi
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/mmcblk0";  # SD card on Pi
      content = {
        type = "gpt";
        partitions = {
          # Raspberry Pi needs specific firmware partition
          firmware = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot/firmware";
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}