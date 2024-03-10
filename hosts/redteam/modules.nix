{ config, ... }: {

    imports = [

	# Disko
	./modules/disko/ext4.nix

	./modules/boot.nix # Grub.
	./modules/system/console.nix # Bigger font console.
	./modules/system/pkgs.nix # Packages.
	./modules/system/system.nix # System configuration.
	./modules/system/user.nix # Users.

	# Security Tool Box

        #./modules/nix-security-box/bluetooth.nix
        #./modules/nix-security-box/cloud.nix
        #./modules/nix-security-box/code.nix
        #./modules/nix-security-box/container.nix
        #./modules/nix-security-box/dns.nix
        #./modules/nix-security-box/exploits.nix
        #./modules/nix-security-box/forensics.nix
        #./modules/nix-security-box/fuzzers.nix
        #./modules/nix-security-box/generic.nix
        #./modules/nix-security-box/hardware.nix
        #./modules/nix-security-box/host.nix
        #./modules/nix-security-box/information-gathering.nix
        #./modules/nix-security-box/kubernetes.nix
        #./modules/nix-security-box/ldap.nix
        #./modules/nix-security-box/load-testing.nix
        #./modules/nix-security-box/malware.nix
        #./modules/nix-security-box/misc.nix
        #./modules/nix-security-box/mobile.nix
        ./modules/nix-security-box/network.nix
        #./modules/nix-security-box/packet-generators.nix
        #./modules/nix-security-box/password.nix
        #./modules/nix-security-box/port-scanners.nix
        #./modules/nix-security-box/proxies.nix
        #./modules/nix-security-box/services.nix
        #./modules/nix-security-box/smartcards.nix
        #./modules/nix-security-box/terminals.nix
        #./modules/nix-security-box/tls.nix
        #./modules/nix-security-box/traffic.nix
        #./modules/nix-security-box/tunneling.nix
        #./modules/nix-security-box/voip.nix
        #./modules/nix-security-box/web.nix
        #./modules/nix-security-box/windows.nix
        #./modules/nix-security-box/wireless.nix

    ];
}
