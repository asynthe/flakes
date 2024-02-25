{
  description = "Minimal nixOS flake";

inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.11";
  impermanence.url = "github:nix-community/impermanence";
  sops-nix.url = "github:Mic92/sops-nix";
  disko = {
    url = "github:nix-community/disko";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  nixos-generators = {
    url = "github:nix-community/nixos-generators";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};

outputs = inputs @ {
    self,
    nixpkgs,
    nixpkgs-stable,
    disko,
    impermanence,
    sops-nix,
    nixos-generators,
}:
{
nixosConfigurations = {

server = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = { inherit
    username
    hostname
    inputs
    ;
    hostname = "server"
  };
  modules = [
    ./hosts/linux/server
    disko.nixosModules.disko
    impermanence.nixosModules.impermanence
  ];
};

redteam = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  #format = "all" # How to do this?
  specialArgs = { inherit
    inputs
    ;
    hostname = "server"
  };
  modules = [
    ./hosts/linux/server
    disko.nixosModules.disko
    impermanence.nixosModules.impermanence
  ];
};

blueteam = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  #format = "all" # How to do this?
  specialArgs = { inherit
    inputs
    ;
  };
  modules = [
    ./hosts/hyperv
    disko.nixosModules.disko
    impermanence.nixosModules.impermanence
  ];
};

hyperv = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  format = "hyperv";
  specialArgs = { inherit
    inputs
    ;
    #hostname = "hyperv";
  };
  modules = [
    ./hosts/hyperv
    disko.nixosModules.disko
    impermanence.nixosModules.impermanence
  ];
};

};
  };
}
