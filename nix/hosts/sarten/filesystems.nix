# Adopted, not disko: nothing here is declarative. docs/SARTEN.md records the mkfs steps.
{ ... }:
{
    flake.modules.nixos.sarten-filesystems = { ... }:
    let
        # by-id, because /dev/sd* is probe order here and reshuffles between reboots.
        rootDisk = "/dev/disk/by-id/ata-MB0500GCEHE_WMAYP6540495";
    in {
        # `boot-bios` turns GRUB on but names no target, and disko is gone.
        boot.loader.grub.devices = [ rootDisk ];

        fileSystems."/" = {
            device = "/dev/disk/by-label/root";
            fsType = "ext4";
        };

        swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];

        # ─────────────── tank ───────────────
        # A hand-made two-disk mirror over the 2TB pair; the root disk stays out of it.
        boot.zfs.extraPools = [ "tank" ];

        # Root is ext4, so never force an import past another machine's claim.
        boot.zfs.forceImportRoot = false;

        # Only a scrub walks the blocks nothing reads, which is where rot hides.
        services.zfs.autoScrub = {
            enable   = true;
            interval = "weekly";
        };

        # Jellyfin's library; `mountpoint=legacy` so systemd owns the mount, not ZFS.
        fileSystems."/srv/media" = {
            device  = "tank/media";
            fsType  = "zfs";
            options = [ "nofail" ];
        };

        # Wazuh's compose checkout, certs and container volumes.
        fileSystems."/srv/wazuh" = {
            device  = "tank/wazuh";
            fsType  = "zfs";
            options = [ "nofail" ];
        };
    };
}
