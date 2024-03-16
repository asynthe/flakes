# On one level up above the NixOS machine.
Firewall -> block the NixOS CDN 151.101.0.0/16

# Amnesiac System (tmpfs, ext4)
# - System has defined opt-in opt-out.
# - User cannot change this opt-in opt-out.
# Creating partitions -> disko.nix
dev=/dev/vda # replace me with the actual device
sudo parted ${dev} -- mklabel msdos
sudo parted ${dev} -- mkpart primary ext4 1M 512M
sudo parted ${dev} -- set 1 boot on
sudo parted ${dev} -- mkpart primary ext4 512MiB 100%
sudo mkfs.ext4 -L boot ${dev}1
sudo mkfs.ext4 -L nix ${dev}2

# Mounting
sudo mount -t tmpfs none /mnt
sudo mkdir -p /mnt/{boot,nix,etc},var/{lib,log},srv} # /srv is home for services.
sudo mount ${dev}1 /mnt/boot
sudo mount ${dev}2 /mnt/nix

# nix/persist folders
sudo mkdir -p /mnt/nix/persist/{etc/nixos,ssh},var/{lib,log},srv}

# Quick and dirty bind mounts
mount -o bind /mnt/nix/persist/etc/nixos /mnt/etc/nixos
mount -o bind /mnt/nix/persist/var/log /mnt/var/log
