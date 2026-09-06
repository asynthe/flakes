# Runs the self-tests that surface a failing disk before the metrics do.
{ ... }:
{
    flake.modules.nixos.smartd = { ... }: {
        services.smartd = {
            enable        = true;
            autodetect    = true;
            # Short test nightly, long test weekly.
            defaults.monitored = "-a -o on -S on -s (S/../.././02|L/../../6/03)";
        };
    };
}
