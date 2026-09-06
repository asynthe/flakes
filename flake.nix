{
    description = "asynthe's machines -- dendritic";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

        # Dendritic pattern: flake-parts is the entry point, import-tree walks
        # ./nix so no file is ever imported by hand.
        flake-parts.url = "github:hercules-ci/flake-parts";
        flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
        import-tree.url = "github:vic/import-tree";

        deploy-rs.url = "github:serokell/deploy-rs";
        deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

        sops-nix.url = "github:Mic92/sops-nix";

        # Unused by sarten, kept for the next machine's install.
        disko.url = "github:nix-community/disko";
        disko.inputs.nixpkgs.follows = "nixpkgs";

        # Deliberately not `follows`-ing nixpkgs: the agent's Python closure is
        # built with uv2nix against the nixpkgs it pins, and overriding that is
        # how the build breaks.
        hermes-agent.url = "github:NousResearch/hermes-agent";
    };

    outputs = inputs:
        inputs.flake-parts.lib.mkFlake { inherit inputs; }
            (inputs.import-tree ./nix);
}
