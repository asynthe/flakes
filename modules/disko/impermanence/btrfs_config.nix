{ inputs, device, ... }: 

let

    device = "/dev/vda";

in {

    disko.devices = {

        disk.main.${device} = {
            type = "disk";
            content.type = "gpt";
            content.partitions = {

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

	# Root lvm
        lvm_vg.root_vg = {
	    type = "lvm_vg";

            lvs.root.size = "100%FREE";
            lvs.root.content.type = "btrfs";
            lvs.root.content.extraArgs = [ "-f" ];
            lvs.root.content.subvolumes = {

	            # Root subvolume
                    subvolumes."/root".mountpoint = "/";

	            # Persist subvolume
                    subvolumes."/persist".mountOptions = [ "subvol=persist" "noatime" ];
                    subvolumes."/persist".mountpoint = "/persist";

	            # Nix subvolume
                    subvolumes."/nix".mountOptions = [ "subvol=nix" "noatime" ];
                    subvolumes."/nix".mountpoint = "/nix";
	    };
	};
    };
}
