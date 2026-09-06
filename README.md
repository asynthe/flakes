# flakes

Every machine I run except the laptop, which lives in [`dots`](https://github.com/asynthe/dots).
Same [dendritic pattern]: every `.nix` file under `nix/` is a flake-parts module,
auto-imported by [`import-tree`], and nothing is imported by hand.

```
flake.nix                  the only entry point: mkFlake (import-tree ./nix)
nix/
  flake/
    registry.nix           turns on flake.modules.<class>.<name>
    hosts.nix              every `host-*` aspect becomes a nixosConfiguration
    deploy.nix             every host importing `deploy` becomes a deploy-rs node
    checks.nix             `nix flake check` builds every machine
    devshell.nix           deploy-rs, sops, age, ssh-to-age
  nixos/
    options.nix            values that differ between machines
    base/                  what any machine gets: core cli net-base ssh sops boot deploy
    profiles/              role bundles; a host names one instead of thirty aspects
    services/              one file per service
  hosts/
    sarten/                HP ProLiant ML350e Gen8 v2
secrets/                   sops-encrypted, see .sops.yaml
assets/                    wallpapers the homepage dashboard inlines
```

## The mental model

1. Every file under `nix/` is a flake-parts module, auto-imported.
2. Each writes into `flake.modules.nixos.<name>` — the registry. An *aspect* is
   just a named NixOS module sitting in an attrset.
3. A host is a list of names pulled back out of that registry.

**No `enable` options.** A host turns a feature on by importing its aspect, so
the import list in `nix/hosts/<name>/default.nix` is the complete, honest answer
to "what is this machine?". Options exist only for values that differ between
machines.

## Adding a machine

```bash
mkdir nix/hosts/<name>
nixos-generate-config --show-hardware-config > /tmp/hw.nix   # on the box
```

Wrap that in `flake.modules.nixos.<name>-hardware`, then write
`nix/hosts/<name>/default.nix` declaring `flake.modules.nixos.host-<name>`:

```nix
imports = with config.flake.modules.nixos; [
    profile-server
    <name>-hardware
    boot-uefi
];

networking.hostName = "<name>";
system.stateVersion = "26.05";
sys.user = "meow";
sys.ssh.authorizedKeys = [ "ssh-ed25519 ... meow@p1" ];
```

That is the whole registration — `nix/flake/hosts.nix` picks it up by its
`host-` prefix, and `profile-server` brought in `deploy`, so it is a deploy-rs
node too.

## Rebuilding

```bash
nixos-rebuild build  --flake .#sarten          # check it builds, no root
nixos-rebuild switch --flake .#sarten          # on the machine itself
nix flake check                                # builds every host
```

## Deploying

`nix develop` first, or install deploy-rs. Builds happen locally and the closure
is pushed, which is usually faster than building on the target.

```bash
deploy .#sarten            # build, push, activate, verify reachability
deploy .#sarten --dry-activate
deploy                     # every node
deploy .#sarten -- --show-trace
```

Two safety nets are on by default: `autoRollback` reverts a failed activation,
and `magicRollback` reverts if the deployer cannot reach the machine afterwards
— which is what saves a box from a bad firewall or network change. Set
`sys.deploy.magicRollback = false` only for a machine you can physically reach.

Deploy-rs ssh's in as `sys.deploy.sshUser` (default `sys.user`) and sudos to
root. The `deploy` aspect grants that one account passwordless sudo, because a
password prompt mid-deploy hangs rather than fails.

## Secrets

One sops file, `secrets/secrets.yaml`, decrypted on each machine with the age
identity at `sys.sops.ageKeyFile` (`/var/lib/sops/age-keys.txt`). That file has
to exist *before* the first activation — `nixos-anywhere --extra-files` puts it
there on a fresh install, and it is a manual copy on an adopted box.

To give a machine its own key instead of sharing the admin one, see the comment
at the top of `.sops.yaml`.

## Docs

| | |
|---|---|
| [SARTEN.md](docs/SARTEN.md) | the ProLiant: install, disks, secrets, rebuilding |
| [MEDIA.md](docs/MEDIA.md)   | Jellyfin, the arrs, qBittorrent, the by-director tree |
| [WAZUH.md](docs/WAZUH.md)   | the SIEM, and what a rebuild cannot reproduce |
| [LAB.md](docs/LAB.md)       | the SOC lab this box is being built into |
| [HERMES.md](docs/HERMES.md) | the agent |

[dendritic pattern]: https://github.com/mightyiam/dendritic
[`import-tree`]: https://github.com/vic/import-tree
