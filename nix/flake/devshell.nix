# `nix develop` -- the tools that drive this repo but belong on no machine.
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
