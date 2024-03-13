# Problems
# Not enough space? But this is VM bro

sudo su -
nix-shell -p neovim

# Get script
curl https://raw.githubusercontent.com/vimjoyer/impermanent-setup/main/final/disko.nix -o /tmp/disko.nix

# SCRIPT

# disko partition and install command
sudo nix --experimental-features "nix-command flakes" \
run github:nix-community/disko -- \
--mode disko /tmp/disko.nix \
# No need to setup this if specified inside the file.
--arg device '"/dev/vda"' 

# generating nix config
sudo nixos-generate-config --no-filesystems --root /mnt
# move disko config to config folder
sudo mv /tmp/disko.nix /mnt/etc/nixos
cd /mnt/etc/nixos

# Basic flake by vimjoyer
sudo nix --experimental-features "nix-command flakes" \
flake init --template \
github:vimjoyer/impermanent-setup

# I would add, delete configuration.nix and get vimjoyer's one
curl https://raw.githubusercontent.com/vimjoyer/impermanent-setup/main/final/configuration.nix -o configuration.nix
# Remember to edit a little bit
# Disable from fileSystem."/persist".neededForBoot = true; to end

# Copy all to persist
cp -r /mnt/etc/nixos /mnt/persist

# Install nixos
nixos-install --root /mnt \
--flake /mnt/etc/nixos#default

# Reboot
# Now the system will have a regular system and also a /persist folder

# On rebooted system, edit flake.nix and configuration.nix
# For `flake.nix` add the Impermanence input
# For `configuration.nix` uncomment all the `environment.persistence` options.

# Once done, update system through the flake
sudo nixos-rebuild boot --flake /persist/nixos#default
reboot
sudo mkdir -p /etc/
sudo cp -r /persist/nixos /etc
reboot

# Check that it stayed there once rebooted
ls /etc

##### ERROR #####
# Time out waiting for device /mnt-root/persist/var/lib/nixos
# Mounting /mnt-root/persist/system/var/lib/nixos on /var/lib/nixos
# failed: No such file or directory

# - Update flake?
# - Rebuild
