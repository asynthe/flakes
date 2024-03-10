{ config, ... }: {

    imports = [

	# Disko
	../../modules/disko/ext4.nix

	../../modules/redteam/boot.nix # Grub.
	../../modules/redteam/console.nix # Bigger font console.
	../../modules/redteam/pkgs.nix # Packages.
	../../modules/redteam/system.nix # System configuration.
	../../modules/redteam/user.nix # Users.

	# Desktop Environment
	../../modules/redteam/desktop/xfce.nix
	#../../modules/redteam/desktop/i3.nix # In progress.
	#../../modules/redteam/desktop/xmonad.nix # In progress.

	# Security Tool Box
	# https://fabaff.github.io/nix-security-box/

        #../../modules/redteam/security/1_all.nix # Full package set.
        #../../modules/redteam/security/bluetooth.nix
        #../../modules/redteam/security/cloud.nix
        #../../modules/redteam/security/code.nix
        #../../modules/redteam/security/container.nix
        #../../modules/redteam/security/dns.nix
        #../../modules/redteam/security/exploits.nix
        #../../modules/redteam/security/forensics.nix
        #../../modules/redteam/security/fuzzers.nix
        #../../modules/redteam/security/generic.nix
        #../../modules/redteam/security/hardware.nix
        #../../modules/redteam/security/host.nix
        #../../modules/redteam/security/information-gathering.nix
        #../../modules/redteam/security/kubernetes.nix
        #../../modules/redteam/security/ldap.nix
        #../../modules/redteam/security/load-testing.nix
        #../../modules/redteam/security/malware.nix
        #../../modules/redteam/security/misc.nix
        #../../modules/redteam/security/mobile.nix
        #../../modules/redteam/security/network.nix
        #../../modules/redteam/security/packet-generators.nix
        #../../modules/redteam/security/password.nix
        #../../modules/redteam/security/port-scanners.nix
        #../../modules/redteam/security/proxies.nix
        #../../modules/redteam/security/services.nix
        #../../modules/redteam/security/smartcards.nix
        #../../modules/redteam/security/terminals.nix
        #../../modules/redteam/security/tls.nix
        #../../modules/redteam/security/traffic.nix
        #../../modules/redteam/security/tunneling.nix
        #../../modules/redteam/security/voip.nix
        #../../modules/redteam/security/web.nix
        #../../modules/redteam/security/windows.nix
        #../../modules/redteam/security/wireless.nix

    ];
}
