# Reference

How this repo works, and the traps worth knowing before you trip on them.
[The overview](index.md) is the short version.

## The pattern

This is the [dendritic pattern]. Every `.nix` file under `nix/` is a flake-parts
module, and [`import-tree`] walks the directory and imports all of them, so there
is no `imports = [ ... ]` list to keep in sync anywhere. Adding a file is the
whole act of adding it to the build.

Each of those files writes into `flake.modules.nixos.<name>`. That registry is
the only structure in the repo — a named NixOS module sitting in an attrset is
what this repo calls an *aspect*. A host is then nothing more than a list of
names pulled back out of the registry, and `nix/flake/hosts.nix` turns every
aspect whose name starts with `host-` into a `nixosConfiguration`. Declaring one
is the entire registration; nothing central needs editing.

Two consequences are worth stating outright. There are **no `enable` options**:
a machine turns a feature on by importing its aspect, which makes the import list
in `nix/hosts/<name>/default.nix` the complete and honest answer to "what is this
machine?". And **options exist only for values that genuinely differ between
machines** — a bind address, a media directory, a deploy target. If every machine
would set the same value, it belongs in the aspect, not in an option.

## Layout

```
flake.nix                  the only entry point: mkFlake (import-tree ./nix)
auth.nix                   who may log in, and with which key
nix/
  flake/
    registry.nix           turns on flake.modules.<class>.<name>
    hosts.nix              every `host-*` aspect becomes a nixosConfiguration
    deploy.nix             every host importing `deploy` becomes a deploy-rs node
    checks.nix             `nix flake check` builds every machine
    devshell.nix           deploy-rs, sops, age, ssh-to-age
  nixos/
    options.nix            values that differ between machines
    base/                  what any machine gets: core cli auth net-base ssh sops boot deploy
    profiles/              role bundles; a host names one instead of thirty aspects
    services/              one file per service
  hosts/
    sarten/                the ProLiant
secrets/                   sops-encrypted, see .sops.yaml
assets/                    wallpapers the homepage dashboard inlines
docs/                      the runbooks
```

`profiles/` is the layer that makes more than one machine bearable. `profile-server`
bundles the dozen aspects every box wants — core, cli, auth, networking, ssh,
sops, deploy, tailscale, git, neovim, nh, the node exporter, smartd — so a host
file names that and then only what it actually serves. Sarten's list is thirteen
entries instead of thirty-five.

## Accounts

`auth.nix` at the repo root is the entire user list, and it is shared by every
machine. It is plain data rather than a module: it sits outside `nix/` precisely
so import-tree ignores it, and `nix/nixos/base/auth.nix` is the aspect that reads
it and turns it into accounts. Nothing else in the repo declares a user.

```nix
{
    asynthe = {
        admin       = true;
        passwordKey = "users/asynthe";
        keys = [
            "ssh-ed25519 AAAA... p1"
            "ssh-ed25519 AAAA... s24"
        ];
    };

    kazu = {
        admin       = true;
        passwordKey = "users/kazu";
        keys = [ "ssh-rsa AAAA..." ];
    };
}
```

Four fields, all optional, all defaulting to the least privilege. `keys` is the
list of ssh public keys and defaults to empty — an account with no keys is
created but cannot log in at all. `passwordKey` names where that user's login
hash lives inside `secrets/secrets.yaml` and **defaults to `null`**, which locks
the password: key-only ssh keeps working and `sudo` does not. `groups` is extra
service groups for a user who is not an admin. `admin` defaults to `false`, and
turning it on does two separate things — it puts the account in `wheel`, and it
makes it a nix daemon trusted-user. Both amount to root on the machine.

Because those two are separate powers, an admin without a password used to be a
silent contradiction: `wheel` needs a password, so `sudo` could never succeed,
while `trusted-users` handed out root through the daemon anyway with no password
involved. An assertion now rejects that combination outright — an `admin` must
name a `passwordKey`.

Admins also get every service group an aspect hands out — `media`, `jellyfin`,
`docker`, `incus-admin`, `hermes` — automatically. That is why no aspect anywhere
names a user: they all add their group to `sys.admins`, which `auth.nix`
populates. A non-admin gets none of them, which is what the `groups` field is
for: `groups = [ "media" "jellyfin" ]` gives someone the media library and
nothing else, with no password and no sudo.

Ssh follows the same idea. Password authentication is derived, not configured:
the `ssh` aspect turns it off as soon as any admin has a key, so **the first key
added to `auth.nix` is what closes the door**, not a setting someone has to
remember. Root login is off unconditionally. Passwords in this repo are
therefore never login credentials — they exist for the physical console, for
`su`, and to satisfy `wheel`.

### Adding a user

Write the entry, add the password hash to sops, deploy. The hash is the only
part that is not in git:

```bash
mkpasswd -m yescrypt          # paste the output into the editor below
sops secrets/secrets.yaml     # add it under `users:` as <name>: <hash>
```

Then set `passwordKey` to `"users/<name>"` and add their public keys. RSA keys
are fine alongside ed25519 ones — any current client signs with `rsa-sha2-256`
or `-512`, which OpenSSH still accepts; only the old SHA-1 `ssh-rsa` signature
algorithm is disabled, and that is a client-side detail.

The ordering matters, and sops-nix enforces it for you. A key's *name* is
plaintext in `secrets.yaml` even though its value is not, so
`sops-install-secrets` validates the manifest at **build** time and refuses to
produce a system that names a key the file does not contain:

```
manifest is not valid: secret password-asynthe in ...-secrets.yaml
is not valid: the key 'users/asynthe' cannot be found
```

That is a `nixos-rebuild build` and `nix flake check` failure, not an activation
one, so a forgotten sops entry never reaches the machine. Add the entry first
and the build goes through. A non-admin whose hash is not ready yet can be left
at the default `null` in the meantime; an admin cannot, because of the assertion
above.

The hash is also `neededForUsers`, which means sops decrypts it into
`/run/secrets-for-users` early in activation, before `/home` is necessarily
mounted, so that account creation can use it.

Removing a user is the same file, in reverse — and it is a real removal.
`users.mutableUsers = true` does not protect an account that this flake declared
before and no longer does; `update-users-groups.pl` deletes it on the next
switch and leaves an orphaned `/home/<name>` behind. Move the home directory
first if there is anything in it.

## Secrets

One sops file, `secrets/secrets.yaml`, decrypted on each machine with the age
identity at `sys.sops.ageKeyFile`, which defaults to `/var/lib/sops/age-keys.txt`.
That file has to exist *before* the first activation — `nixos-anywhere --extra-files`
puts it there on a fresh install, and it is a manual `scp` on a box adopted in
place.

Every machine currently shares one age identity. To give a host its own instead,
convert its ssh host key and add it to `.sops.yaml` alongside the admin key:

```bash
ssh-keyscan -t ed25519 <host> | ssh-to-age
sops updatekeys secrets/secrets.yaml
```

A host holding only its own key cannot read another machine's secrets, which is
the point.

### Onboarding another admin

**A new admin needs no age key to build or deploy.** Nix builds are sandboxed
and never see anyone's home directory: `secrets.yaml` is copied into the store
and `sops-install-secrets` only checks that the key *names* it references exist,
which is plaintext. Decryption happens on the target machine at activation,
using the identity already sitting in its `/var/lib/sops/age-keys.txt`. So a
co-admin can clone, edit aspects, `nixos-rebuild build`, and `deploy` on day
one, having exchanged nothing.

An age key is only needed to **read or change a secret**. When that day comes:

```bash
age-keygen -o ~/.config/sops/age/keys.txt     # on their machine
```

That prints a `# public key: age1...` line — the public half, which is the only
part that travels. Add it to `.sops.yaml` as a second anchor, list it in the key
group beside `*admin`, then re-encrypt the file to both recipients and commit:

```bash
sops updatekeys secrets/secrets.yaml
```

Worth being deliberate about, because it is all-or-nothing: `secrets.yaml` is one
file, so a new recipient can read everything in it — every login hash, every API
token. Split it into two files with separate `creation_rules` if that ever stops
being the right answer.

### Passwords

A new admin generates their own hash and sends *that*, so nobody else ever
handles their password:

```bash
mkpasswd -m yescrypt
```

Paste it under `users:` in `secrets.yaml` as `<name>: <hash>`. The hash is not
secret in the way a password is, but it is offline-crackable, so it wants a real
password behind it.

They cannot change it with `passwd` on the machine. `hashedPasswordFile` is
declarative and re-applied on every activation, so a local change survives until
the next switch and then silently reverts. Changing a password means a new hash
in sops.

## Adding a machine

Generate the hardware config on the box and wrap it in an aspect:

```bash
mkdir nix/hosts/<name>
nixos-generate-config --show-hardware-config > /tmp/hw.nix
```

Then write `nix/hosts/<name>/default.nix` declaring `flake.modules.nixos.host-<name>`:

```nix
imports = with config.flake.modules.nixos; [
    profile-server
    <name>-hardware
    boot-uefi
];

networking.hostName = "<name>";
system.stateVersion = "26.05";
sys.deploy.hostname = "<ip or tailnet name>";
```

That is all of it. `nix/flake/hosts.nix` picks the aspect up by its `host-`
prefix, and because `profile-server` pulls in `deploy`, the machine is a
deploy-rs node too. Accounts come from `auth.nix`, so there are none to declare.
Nix only sees files that are `git add`ed, which catches everyone once.

## Rebuilding

```bash
nixos-rebuild build  --flake .#sarten          # check it builds, no root
nixos-rebuild switch --flake .#sarten          # on the machine itself
nix flake check                                # builds every host
```

`nix flake check` is worth running before a deploy: `nix/flake/checks.nix` adds
every host's `system.build.toplevel` as a check, so a machine you are not
currently touching still has to build.

## Deploying

`nix develop` puts deploy-rs, sops, age and ssh-to-age on `$PATH`.

```bash
deploy .#sarten                 # build, push, activate, verify reachability
deploy .#sarten --dry-activate
deploy                          # every node
```

Nodes are derived rather than listed. `nix/flake/deploy.nix` walks
`nixosConfigurations` and builds a node for every host whose config has
`sys.deploy.enabled`, which the `deploy` aspect sets when a machine imports it.
The target address and ssh user are facts about the machine, so they live in that
machine's `sys.deploy.*` rather than in a central table — adding a host needs no
edit to the deploy glue at all.

Builds happen locally and the closure is pushed, because the workstation is
almost always the faster box; set `sys.deploy.remoteBuild = true` for a host
where that is not true. Deploy-rs ssh's in as `sys.deploy.sshUser`, defaulting to
the first admin in `auth.nix`, and sudos to root to activate. The `deploy` aspect
grants every admin passwordless sudo, because deploy-rs cannot answer a password
prompt — it hangs on one until the timeout rather than failing. That is not a
new grant: an admin is already a nix daemon trusted-user, which is root by
another route. It does mean any co-admin can deploy, with
`deploy .#sarten --ssh-user <name>` if they are not the default.

Two rollbacks are on by default. `autoRollback` reverts an activation that fails
outright. `magicRollback` reverts when the deployer cannot reach the machine
*after* activation, which is the net that catches a bad firewall rule or a
network change, and is worth keeping on for anything you cannot walk over to.

## Choices worth knowing

**Inputs.** `hermes-agent` deliberately does not `follows` nixpkgs: its Python
closure is built with uv2nix against the nixpkgs it pins, and overriding that is
how the build breaks. `disko` is an input nothing uses yet, kept because the next
machine will be installed rather than adopted. There is no impermanence anywhere
in this repo — no `/persist`, no `environment.persistence` — which is the main way
these aspects differ from their ancestors in `dots`.

**Boot.** `boot-bios` enables GRUB but names no target disk, and `boot-uefi`
assumes the ESP is at `/boot`. Which disk GRUB installs to is a fact about the
hardware, so it belongs in the host's own `filesystems.nix`; an empty
`boot.loader.grub.devices` installs no bootloader at all and is a silent way to
end up with an unbootable machine.

**Monitoring.** `node-exporter` and `prometheus` are separate aspects on purpose:
every machine runs the exporters, one machine runs the server and scrapes the
rest through `sys.prometheus.extraTargets`. The exporters bind to loopback by
default; a machine being scraped remotely sets `sys.exporters.bind = "0.0.0.0"`,
which the tailnet firewall already fences off from the LAN. The smartctl exporter
holds `CAP_SYS_RAWIO`, so drive health needs no interactive sudo.

**Grafana** generates its `secret_key` on the machine into `/var/lib/grafana`
rather than holding it in sops — 26.05 refuses to start without one, and it never
leaves the box. Point `sys.grafana.secretKeyFile` at a sops path if that ever
stops being true.

**Docker** picks its storage driver from the root filesystem type. Hardcoding
`btrfs`, which is what the laptop wants, makes dockerd refuse to start on
sarten's ext4 root.

**qBittorrent** has its `serverConfig` rewritten on every start, so the save
path, torrent port and web UI address are changed in the aspect and never in the
web UI. That UI has no password because it is firewalled down to ssh reach and
the arrs need its API.

**The dashboard on port 80** is proxied rather than moved: `sys.homepage.proxy`
puts nginx on port 80 in front of `:8082`, because Wazuh's compose stack owns 443
and a bare `http://sarten` would otherwise reach nothing and get upgraded to it.
The proxy rewrites `Host` to `<host>:<port>` — the dashboard checks the header
against `HOMEPAGE_ALLOWED_HOSTS` and would reject the LAN IP or the tailnet name
otherwise.

**The homepage dashboard** inlines its wallpapers as base64 data URIs, downscaled
at build time. Homepage's `settings.yaml` holds exactly one background image, so
rotation is client-side JavaScript over the inlined set, and the assets have to
be inlined at all because the store is read-only.

**These docs are a build artifact.** `docs` renders `docs/` with mdBook at build
time and nginx serves the result out of the store on `:8081`. No daemon reads the
markdown, so a change to a `.md` file appears on the site at the next `deploy`
and not before. `book.toml` sets `src = "."`, which keeps the chapters editable
as plain files on GitHub rather than moving them under a `src/` directory — the
cost is that `SUMMARY.md` has to list every page, and a page missing from it is
built but unreachable from the sidebar.

**The archive is not the media tree.** `archive` creates `/srv/archive` and
nothing else — no service on this box writes there. It is separate from
`/srv/media` because the arr stack renames and deletes inside that tree while the
laptop's `music_send_to_server.py` is a `--delete` mirror; pointed at one
directory, the two would take turns destroying each other's work. See
[ARCHIVE.md](ARCHIVE.md); `tank/archive` is created by hand, not by Nix.

[dendritic pattern]: https://github.com/mightyiam/dendritic
[`import-tree`]: https://github.com/vic/import-tree
