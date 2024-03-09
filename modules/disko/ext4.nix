let

    device = "/dev/vda";

in {
    disko.devices.disk.main = {
        device = "${device}";
	type = "disk";
	content = {
	    type = "gpt";
	    partitions = {

	        # ESP
		ESP.type = "EF00";
		ESP.size = "500M";
		ESP.content.type = "filesystem";
		ESP.content.format = "vfat";
		ESP.content.mountpoint = "/boot";

		# Swap
		#swap.type = "8200";
		#swap.size = "2G";
		#swap.content.type = "swap";

		# Root partition
		root.size = "100%";
		root.content.type = "filesystem";
		root.content.format = "ext4";
		root.content.mountpoint = "/";

	    };
        };
    };
}
