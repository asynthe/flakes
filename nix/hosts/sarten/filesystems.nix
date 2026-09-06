{ ... }:
{
    flake.modules.nixos.sarten-filesystems = { ... }:
    let
        rootDisk = "/dev/disk/by-id/ata-MB0500GCEHE_WMAYP6540495";
    in {
        boot.loader.grub.devices = [ rootDisk ];

        fileSystems."/" = {
            device = "/dev/disk/by-label/root";
            fsType = "ext4";
        };

        swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];

        # ─────────────── tank ───────────────
        boot.zfs.extraPools = [ "tank" ];

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

        fileSystems."/srv/wazuh" = {
            device  = "tank/wazuh";
            fsType  = "zfs";
            options = [ "nofail" ];
        };
    };
}
