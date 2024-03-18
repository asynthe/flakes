{
    description = "Minimal nixOS flake";

    # Inputs
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
        nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.11";
        impermanence.url = "github:nix-community/impermanence";
        sops-nix.url = "github:Mic92/sops-nix";

	# disko
        disko = {
            url = "github:nix-community/disko";
            inputs.nixpkgs.follows = "nixpkgs";
        };

	# nixos-generators
        nixos-generators = {
            url = "github:nix-community/nixos-generators";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    # Outputs
    outputs = inputs @ {
        self,
        nixpkgs,
        nixpkgs-stable,
        impermanence,
        sops-nix,
        disko,
        nixos-generators,
    }: {

        nixosConfigurations = {

            # Blue Team and images
	    blueteam = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                specialArgs = { inherit
                    inputs
                    ;
                    hostname = "blueteam";
            	    username = "blue";
                    device = "/dev/vda";
                };
                modules = [
                    ./hosts/blueteam
                    disko.nixosModules.disko
                    impermanence.nixosModules.impermanence
                ];
	    };

	    # QEMU (qcow2)
	    blueteam-qemu = nixos-generators.lib.qemu {
	        inherit nixpkgs;
		baseConfig = self.nixosConfigurations.blueteam;
		diskSize = "10G";
		firmware = "ovmf"; # UEFI firmware.
	    };

	    # Amazon EC2 Image
	    #blueteam-ec2 = nixos-generators.lib.ec2 {
	        #inherit nixpkgs;
		#baseConfig = self.nixosConfigurations.blueteam;
		#instanceType = "t2.micro"; # ADJUST
		#region = "us-west-2"; # ADJUST
		#diskSize = 10; # ADJUST
		#sshPublicKey = "/path/to/public/key.pub" # ADJUST
	    #};
	};

	# Blue Team - Images
	packages.x86_64-linux = {

	    # Amazon EC2 Image (.ec2)
	    blueteam-ec2 = nixos-generators.nixosGenerate {
                system = "x86_64-linux";
                format = "amazon"; # ?
                specialArgs = { inherit
                    inputs
                    ;
            	    username = "blue";
                    hostname = "blueteam";
                    device = "/dev/vda";
                };
                modules = [
                    ./hosts/blueteam
                    disko.nixosModules.disko
                    impermanence.nixosModules.impermanence
                ];
            };

	    # Azure (.vhd)
	    blueteam-azure = nixos-generators.nixosGenerate {
                system = "x86_64-linux";
                format = "azure"; # ?
                specialArgs = { inherit
                    inputs
                    ;
            	    username = "blue";
                    hostname = "blueteam";
                    device = "/dev/vda";
                };
                modules = [
                    ./hosts/blueteam
                    disko.nixosModules.disko
                    impermanence.nixosModules.impermanence
                ];
            };

	    # QEMU (.qcow2)
	    blueteam-qemu = nixos-generators.nixosGenerate {
                system = "x86_64-linux";
                format = "qcow-efi"; # ?
                specialArgs = { inherit
                    inputs
                    ;
            	    username = "blue";
                    hostname = "blueteam";
                    device = "/dev/vda";
                };
                modules = [
                    ./hosts/blueteam
                    disko.nixosModules.disko
                    impermanence.nixosModules.impermanence
                ];
	    };

	    # Virtualbox (.?)
	    blueteam-vbox = nixos-generators.nixosGenerate {
                system = "x86_64-linux";
                format = "virtualbox"; # ?
                specialArgs = { inherit
                    inputs
                    ;
            	    username = "blue";
                    hostname = "blueteam";
                    device = "/dev/vda";
                };
                modules = [
                    ./hosts/blueteam
                    disko.nixosModules.disko
                    impermanence.nixosModules.impermanence
                ];
	    };

	    # vmware (.vmdk)
	    blueteam-vmware = nixos-generators.nixosGenerate {
                system = "x86_64-linux";
                format = "vmware";
                specialArgs = { inherit
                    inputs
                    ;
            	    username = "blue";
                    hostname = "blueteam";
                    device = "/dev/vda";
                };
                modules = [
                    ./hosts/blueteam
                    disko.nixosModules.disko
                    impermanence.nixosModules.impermanence
                ];
	    };
	};

        # Anywhere
        #nixosConfigurations.anywhere = nixpkgs.lib.nixosSystem {
            #system = "x86_64-linux";
            #specialArgs = { inherit
                #inputs
                #;
                #hostname = "testing";
            	#device = "/dev/vda";
            #};
            #modules = [
                #./hosts/anywhere
                #disko.nixosModules.disko
                #impermanence.nixosModules.impermanence
            #];
        #};

        # Red Team
        #nixosConfigurations.redteam = nixpkgs.lib.nixosSystem {
            #system = "x86_64-linux";
            #specialArgs = { inherit
                #inputs
                #;
                #hostname = "redteam";
            	#username = "red";
            	#device = "/dev/vda";
            #};
            #modules = [
                #./hosts/redteam
                #disko.nixosModules.disko
                #impermanence.nixosModules.impermanence
            #];
        #};

	# Red Team - Image (qcow2, vdi, ...)
        #packages.x86_64-linux.redteam = nixos-generators.nixosGenerate {
            #system = "x86_64-linux";
            #format = "qcow-efi"; # ALL?
            #specialArgs = { inherit
                #inputs
                #;
                #hostname = "red";
            #};
            #modules = [
                #./images/redteam
                #disko.nixosModules.disko
                #impermanence.nixosModules.impermanence
            #];
        #};
    };
}
