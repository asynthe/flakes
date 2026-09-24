{ ... }:
{
    flake.modules.nixos.sarten-filesystems = { ... }:
    let
        rootDisk = "/dev/disk/by-id/ata-ST2000NM0018-2F3130_ZDS154KD";
    in {
        boot.loader.grub.devices = [ rootDisk ];

        fileSystems."/" = {
            device = "/dev/disk/by-label/root";
            fsType = "ext4";
        };

        swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];

        # ─────────────── tank ───────────────
        boot.zfs.extraPools = [ "tank" "scratch" "vm" ];

        boot.zfs.forceImportRoot = false;

        services.zfs.autoScrub = {
            enable   = true;
            interval = "weekly";
        };

        fileSystems."/srv/media" = {
            device  = "tank/media";
            fsType  = "zfs";
            options = [ "nofail" ];
        };

        fileSystems."/srv/archive" = {
            device  = "tank/archive";
            fsType  = "zfs";
            options = [ "nofail" ];
        };

        fileSystems."/srv/wazuh" = {
            device  = "tank/wazuh";
            fsType  = "zfs";
            options = [ "nofail" ];
        };

        # nofail keeps a missing pool from stopping boot; RequiresMountsFor keeps
        # docker from starting on an empty /var/lib/docker on root instead.
        fileSystems."/var/lib/docker" = {
            device  = "tank/docker";
            fsType  = "zfs";
            options = [ "nofail" ];
        };

        systemd.services.docker.unitConfig.RequiresMountsFor = [ "/var/lib/docker" ];

        # ─────────────── scratch ───────────────
        # The tail of the root disk, single vdev and no redundancy: it shares a
        # spindle with the OS and dies with it. Staging and re-acquirable media
        # only, nothing that is not also somewhere else.
        fileSystems."/srv/scratch" = {
            device  = "scratch/data";
            fsType  = "zfs";
            options = [ "nofail" ];
        };
    };
}
