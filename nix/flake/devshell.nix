{ inputs, ... }:
{
    perSystem = { pkgs, system, ... }: {
        devShells.default = pkgs.mkShell {
            packages = [
                inputs.deploy-rs.packages.${system}.default
                pkgs.age
                pkgs.nix-output-monitor
                pkgs.sops
                pkgs.ssh-to-age
            ];
        };
    };
}
