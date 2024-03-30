{ lib, device, inputs, ... }: {

    disko.devices = {
	nodev."/" = {
	    fsType = "tmpfs";
	    mountOptions = [
	        "size=2G"
		"defaults"
		"mode=0755"
	    ];
	};

        disk.main = {
            device = "${device}";
            type = "disk";

            content = {
                type = "gpt";
                partitions = {
            
		    # Boot partition
		    boot = {
		        priority = 1;
		        name = "boot";
		        size = "512M";
		        type = "EF00";
			content = {
			    type = "filesystem";
			    format = "vfat";
			    mount = "/boot";
			};
		    };

		    data = {
		        size = "100%";
			content.type = "btrfs";
			content.subvolumes = {

			    home.type = "filesystem";
			    home.mountpoint = "/home";
			    home.mountOptions = [ "compress=zstd" ];

			    nix.type = "filesystem";
			    nix.mountpoint = "/nix";
			    nix.mountOptions = [ "compress=zstd" ];

			    persist.type = "filesystem";
			    persist.mountpoint = "/persist";
			    persist.mountOptions = [ "compres=zstd" ];

			    shared.type = "filesystem";
			    shared.mountpoint = "/shared";
			    shared.mountOptions = [ "compres=zstd" ];

			    log.type = "filesystem";
			    log.mountpoint = "/var/log";
			    log.mountOptions = [ "compres=zstd" ];
			};
		    };
                };
	    };
        };
    };

    fileSystems = {
        "/persist".neededForBoot = true;
        "/var/log".neededForBoot = true;
    };

    environment.persistence."/persist" = {
        directories = [
	    "/etc/nixos"
	];
        files = [
	    "/etc/machine-id"
	];
    };

    security.sudo.extraConfig = ''
      # rollback results in sudo lectures after each reboot
      Defaults lecture = never
    '';
}
