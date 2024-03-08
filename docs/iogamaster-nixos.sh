curl -L github:nix-community/ ... | tar -xzf- -C /root

/root/kexec/run

# Script waits for a system with a hostname `nixos` to come online.
while true; do ping -c1 nixos > /dev/null && break; done

# Copy hardware config to our system using this command.
nixos-generate-config --show-hardware-config --root /mnt

# Now we are ready to install the system, this command handles the rest.
nix run github:nix-community/nixos-anywhere -- --flake .#name root@nixos

# DEPLOY RS
# deploy .#hostname
# deploy .#hostname --skip-checks

# Run an automated test for disko, to see if it will install.
# nix build .#nixosConfigurations.<machine>.config.system.build.installTest -L
