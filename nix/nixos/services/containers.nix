{ ... }:
{
    flake.modules.nixos.docker = { config, lib, pkgs, ... }: {
        virtualisation.docker.enable = true;
        users.users = lib.genAttrs config.sys.admins
            (_: { extraGroups = [ "docker" ]; });

        environment.systemPackages = [ pkgs.docker-compose ];

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

    flake.modules.nixos.k3s = { pkgs, ... }: {
        environment.systemPackages = with pkgs; [ kubectl kubernetes-helm ];

        services.k3s = {
            enable = true;
            role = "server";
            extraFlags = toString [ "--write-kubeconfig-mode=644" ];
        };
    };
}
