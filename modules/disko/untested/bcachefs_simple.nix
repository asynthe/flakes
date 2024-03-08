{
    disko.devices = {
        disk = {
            # bcachefs
            bcachefs-simple = {
                device = "/dev/disk/vda";
                type = "disk";
                content = {
                    content.type = "gpt";
                    content.partitions = {

                        # EFI partition
                        ESP.end = "500M";
                        ESP.type = "EF00";
                        ESP.content.type = "filesystem";
                        ESP.content.format = "vfat";
                        ESP.content.mountpoint = "/boot";

                        # Root partition
                        root.name = "root";
                        root.end = "-0";
                        root.content.type = "filesystem";
                        root.content.format = "bcachefs";
                        root.content.mountpoint = "/";
                    };
                };
            };
        };
    };
}
