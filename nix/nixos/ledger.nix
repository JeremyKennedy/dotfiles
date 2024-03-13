{
  # https://valh.io/p/get-ledger-live-working-on-nixos/
  users.groups.plugdev = {};
  users.users.jeremy.extraGroups = ["plugdev"];

  hardware.ledger.enable = true;

  # Required for Ledger Live to detect Ledger Nano S via USB
  # services.udev.extraRules = ''
  #   # https://raw.githubusercontent.com/LedgerHQ/udev-rules/master/add_udev_rules.sh
  #   # HW.1, Nano
  #   SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="1b7c|2b7c|3b7c|4b7c", TAG+="uaccess", TAG+="udev-acl"

  #   # Blue, NanoS, Aramis, HW.2, Nano X, NanoSP, Stax, Ledger Test,
  #   SUBSYSTEMS=="usb", ATTRS{idVendor}=="2c97", TAG+="uaccess", TAG+="udev-acl"

  #   # Same, but with hidraw-based library (instead of libusb)
  #   KERNEL=="hidraw*", ATTRS{idVendor}=="2c97", MODE="0666"
  # '';

  # might need to run these manually after
  # sudo udevadm control --reload-rules
  # sudo udevadm trigger
}
