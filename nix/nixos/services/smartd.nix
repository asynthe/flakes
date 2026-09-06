{ ... }:
{
    flake.modules.nixos.smartd = { ... }: {
        services.smartd = {
            enable        = true;
            autodetect    = true;
            defaults.monitored = "-a -o on -S on -s (S/../.././02|L/../../6/03)";
        };
    };
}
