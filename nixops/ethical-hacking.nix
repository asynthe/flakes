# pfSense download link
# https://sgpfiles.netgate.com/mirror/downloads/pfSense-CE-2.7.2-RELEASE-amd64.iso.gz

# Ubuntu download link
# https://ubuntu.com/download/desktop/thank-you?version=22.04.4&architecture=amd64

# Metasploitable 2.0 (msfadmin/msfadmin)
# https://sourceforge.net/projects/metasploitable/files/latest/download

# Kali Linux
# https://cdimage.kali.org/kali-2023.4/kali-linux-2023.4-installer-amd64.iso

{
  network.description = "Internal Network Lab";

  pfSense = { config, pkgs, lib, ... }: {
    deployment.targetEnv = "virtualBox";
    deployment.virtualBox.headless = true;
    deployment.virtualBox.networks = [
      { adapterType = "82540EM"; attachedTo = "Bridged"; hostInterface = "wlp3s0"; } # Bridged Network to wlan card.
      { adapterType = "82540EM"; attachedTo = "IntNet"; hostInterface = "Internal LAN"; }
    ];
  };

  kali-vm = { config, pkgs, lib, ... }: {
    deployment.targetEnv = "virtualBox";
    deployment.virtualBox.headless = true;
    deployment.virtualBox.memorySize = 2048; # Adjust as needed
    # Define the network to attach to the internal network
    deployment.virtualBox.networks = [
      { adapterType = "82540EM"; attachedTo = "IntNet"; hostInterface = "Internal LAN"; }
    ];
  };

  ubuntu-vm = { config, pkgs, lib, ... }: {
    deployment.targetEnv = "virtualBox";
    deployment.virtualBox.headless = false;  # Assuming you may want UI access
    deployment.virtualBox.memorySize = 2048; # Adjust as needed
    # Define the network to attach to the internal network
    deployment.virtualBox.networks = [
      { adapterType = "82540EM"; attachedTo = "IntNet"; hostInterface = "Internal LAN"; }
    ];
  };

  ubuntu-vm = { config, pkgs, lib, ... }: {
    deployment.targetEnv = "virtualBox";
    deployment.virtualBox.headless = false;  # Assuming you may want UI access
    deployment.virtualBox.memorySize = 2048; # Adjust as needed
    # Define the network to attach to the internal network
    deployment.virtualBox.networks = [
      { adapterType = "82540EM"; attachedTo = "IntNet"; hostInterface = "Internal LAN"; }
    ];
  };
}
