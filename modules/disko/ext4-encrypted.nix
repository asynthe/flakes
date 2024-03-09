let

    device = "/dev/vda";

in {
    disko.devices.disk.main = {
        device = "${device}";
	content.type = "gpt";
	content.partitions


