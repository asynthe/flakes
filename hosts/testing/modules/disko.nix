{ inputs, device, ... }: {

    disko.devices.disk = {

        main = {
            ${device}.type = "disk";
            ${device}.content.type = "gpt";
            ${device}.content.partitions = {

                # Boot partition
                boot.name = "boot";
                boot.size = "1M";
                boot.type = "EF02";

		# ESP partition
                esp.name = "ESP";
                esp.size = "500M";
                esp.type = "EF00";
                esp.content.type = "filesystem";
                esp.content.format = "vfat";
                esp.content.mountpoint = "/boot";

		# Swap
                swap.size = "4G";
                swap.content.type = "swap";
                swap.content.resumeDevice = true;

		# Root
                root.name = "root";
                root.size = "100%";
                root.content.type = "lvm_pv";
                root.content.vg = "root_vg";
            };
        };

        lvm_vg = {
            root_vg.type = "lvm_vg";
            root_vg.lvs = {

                root.size = "100%FREE";
                root.content.type = "btrfs";
                root.content.extraArgs = ["-f"];
                root.content.subvolumes = {

	            # Root subvolume
                    subvolumes."/root".mountpoint = "/";

	            # Persist subvolume
                    subvolumes."/persist".mountOptions = ["subvol=persist" "noatime"];
                    subvolumes."/persist".mountpoint = "/persist";

	            # Nix subvolume
                    subvolumes."/nix".mountOptions = ["subvol=nix" "noatime"];
                    subvolumes."/nix".mountpoint = "/nix";
                };
            };
        };
    };
}
