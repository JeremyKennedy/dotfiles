# Raspberry Pi Deployment Guide

## Recommended: Build Custom SD Card Image

This method creates a ready-to-use image with your configuration already included.

### 1. Build the Image

```bash
cd /home/jeremy/dotfiles

# Build SD card image (cross-compiles on x86_64)
nix build .#packages.aarch64-linux.pi-sd-image

# Image location: ./result/sd-image/nixos-pi-*.img
```

### 2. Flash to SD Card

```bash
# Find your SD card
lsblk

# Flash the image (no decompression needed)
sudo dd if=./result/sd-image/pi.img of=/dev/sda bs=4M status=progress

# Eject safely
sudo eject /dev/sda
```

### 3. Boot and Verify

```bash
# Insert SD card and boot Pi
# SSH using configured credentials
ssh root@192.168.1.230

# Verify deployment
systemctl status
tailscale status
```

## Alternative: Using Generic Image + nixos-rebuild

### 1. Flash Generic Image

```bash
# Download generic ARM64 image
wget https://hydra.nixos.org/build/latest/nixos-sd-image-aarch64-linux/download/1/nixos-sd-image-aarch64-linux.img.zst

# Flash to SD card (compressed)
zstd -d nixos-sd-image-*.img.zst -c | sudo dd of=/dev/sda bs=4M status=progress
```

### 2. Boot and Configure

```bash
# Boot Pi with generic image
# Default user: nixos (no password)
# Enable SSH: sudo systemctl start sshd
# Set root password: sudo passwd root
```

### 3. Deploy Configuration

```bash
# From Pi:
git clone https://github.com/yourusername/dotfiles.git
cd dotfiles
sudo nixos-rebuild switch --flake .#pi
```

## Subsequent Updates

```bash
just deploy pi
```

## How It Works

The repo has two separate build targets for the Pi:

1. **Regular Pi configuration** (`just deploy pi`) - For updates after initial install
2. **SD card image** (`nix build .#packages.aarch64-linux.pi-sd-image`) - For initial install only

The SD image builder uses the same Pi configuration but packages it as a bootable `.img` file.

If you add a second Pi (e.g., `pi2`), you'd:
1. Create `hosts/pi2/default.nix` importing the same `pi-sd-image.nix` module
2. Add a `pi2-sd-image` package to the flake
3. Build and flash the image once, then use `just deploy pi2` for updates

## Troubleshooting

- **Build hangs on man-cache**: Already fixed with `documentation.enable = false` in Pi config
- **nixos-anywhere fails**: Don't use it on running Pi - use custom image or nixos-rebuild instead
- **Cross-compilation**: Requires `boot.binfmt.emulatedSystems = [ "aarch64-linux" ];` on build host
- **Boot issues**: Pi needs `/boot/firmware` FAT32 partition and extlinux bootloader