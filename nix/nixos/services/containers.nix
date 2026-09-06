{ ... }:
{
    flake.modules.nixos.docker = { config, lib, pkgs, ... }: {
        virtualisation.docker.enable = true;
        users.users = lib.genAttrs config.sys.admins
            (_: { extraGroups = [ "docker" ]; });

        # Upstream compose stacks are driven by hand, so it needs an interactive PATH.
        environment.systemPackages = [ pkgs.docker-compose ];

        # Hardcoding btrfs makes dockerd refuse to start on an ext4 root.
        virtualisation.docker.storageDriver =
            if (config.fileSystems."/".fsType or null) == "btrfs"
            then "btrfs"
            else "overlay2";
    };

    flake.modules.nixos.incus = { config, lib, ... }: {
        virtualisation.incus.enable = true;
        networking.nftables.enable = true;
        users.users = lib.genAttrs config.sys.admins
            (_: { extraGroups = [ "incus-admin" ]; });
    };
}
