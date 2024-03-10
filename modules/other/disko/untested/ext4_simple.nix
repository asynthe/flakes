{
    disko.devices = {
        disk = {
            # ext4
            ext4-simple = {
                device = "/dev/disk/vda";
                type = "disk"
                content.type = "gpt";
                content.partitions = {
            
                    # EFI partition
                    ESP.type = "EF00";
                    ESP.size = "500M";
                    ESP.content.type = "filesystem";
                    ESP.content.format = "vfat";
                    ESP.content.mountpoint = "/boot";
                    
                    # Root partition
                    root.size = "100%";
                    root.content.type = "filesystem";
                    root.content.format = "ext4";
                    root.content.mountpoint = "/";
	        };
            };
        };
    };
}
