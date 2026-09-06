# `sarten`

HP ProLiant ML350e Gen8 v2, headless, on the LAN and the tailnet. Two Xeon
E5-2407, 94 GB of RAM, two 500 GB SATA disks on the onboard AHCI controller —
despite the ProLiant badge there is no Smart Array in this one, so `hpsa` and
`smartpqi` are not needed and are not loaded.

**It was adopted, not installed.** The box was already running a stock NixOS
26.05 from the graphical installer when it joined this flake, so there is no
disko step and no `nixos-anywhere` run: `sda` keeps the layout the installer
gave it, and the flake was pointed at the machine as it stood. That is the one
real difference from `p1`, and it has a consequence worth stating plainly —
**this host's partitioning is not declarative.** Rebuilding it from bare metal
means redoing the manual steps in [Rebuilding from scratch](#rebuilding-from-scratch),
not just running one command.

The host is three files, and only `default.nix` is meant to be edited often:

| file | what it holds |
| --- | --- |
| `nix/hosts/sarten/default.nix` | the aspect list, the per-host `sys.*` values, the static network |
| `nix/hosts/sarten/filesystems.nix` | the `sarten-filesystems` aspect — `fileSystems`, swap, GRUB's target disk |
| `nix/hosts/sarten/hardware.nix` | the `sarten-hardware` aspect — initrd modules, microcode |

## Disk layout

Legacy BIOS, no encryption. `sda` is as the installer left it and carries the
whole operating system; the data lives on a ZFS mirror that the root disk stays
out of.

| device | label | contents |
| --- | --- | --- |
| `sda1` | `root` | ext4, mounted at `/` — `/boot` is a directory inside it, not a partition |
| `sda2` | `swap` | swap partition |

Everything is addressed by label, and GRUB's target disk by `by-id`, because
`/dev/sd*` is probe order: drives of the same model can swap between reboots.

### `tank`

A hand-made two-disk mirror over the 2 TB pair, imported through
`boot.zfs.extraPools`. Three datasets: `tank/media` at `/srv/media` is
Jellyfin's library, `tank/wazuh` at `/srv/wazuh` holds the compose checkout,
its certs and its container volumes, and `tank/incus` is created by Incus
itself, which is why `filesystems.nix` never mentions it.

Both mounted datasets are `mountpoint=legacy` so systemd owns the mount rather
than ZFS, and both mount `nofail` — a data disk that fails to appear must not
hold up boot on a machine with no console attached.

`boot.zfs.forceImportRoot` is **off**. Root is ext4, so ZFS is never in the boot
path here, and forcing an import past another machine's claim on the pool has no
upside and one very bad failure mode. `networking.hostId` is set from
`/etc/machine-id`; ZFS refuses to import a pool without one, so removing that
line leaves the datasets unmounted and Jellyfin staring at an empty directory.

A weekly scrub is enabled. It is the only thing that walks the blocks nothing
reads, which is exactly where rot hides.

Three deliberate differences from `p1`:

**No LUKS.** The box is headless. An encrypted root turns every unattended
reboot — a power cut, a kernel update — into a machine sitting at a passphrase
prompt nobody is in the room to answer. The alternative, an SSH server in the
initrd, is a second boot-time network stack to keep working. Neither is worth it
for a media and agent host on a home LAN.

**No impermanence.** The rollback is only as good as what `/persist` captures,
and debugging a missing persist entry on a remote box means losing the state
that would have told you what went wrong. This repo has no impermanence in it at
all — the aspects here were rewritten without it, so unlike in `dots` there is
nothing for the host to switch off.

**GRUB, not systemd-boot.** The `boot` aspect is systemd-boot, which is UEFI
only. `sarten` imports `boot-bios` instead — never both. `boot-bios` turns GRUB
on but names no target disk; with no disko module here, `filesystems.nix` is
what sets `boot.loader.grub.devices`. An empty list installs no bootloader at
all, so that line is load-bearing.

## Networking

Static, on `eno1`, at `192.168.1.135/24` via `192.168.1.1`. The box has six
ethernet ports and one cable.

The `net-base` aspect in this repo is server-shaped and drives no wireless
backend at all, so the address is simply declared by hand in `default.nix`.
Scripted networking brings it up through `network-addresses-eno1.service`; no
DHCP client is involved. The equivalent aspect in `dots` is laptop-shaped and
drives `iwd`, which on a box with no wireless hardware is a guaranteed lockout —
that is one of the reasons these machines no longer share a repo.

If the address ever has to change, change it *and* reboot with a console
available. There is no second way in over the LAN.

## Access

Accounts come from `auth.nix` at the repo root, not from this host's file: two
admins, `asynthe` (keys `p1` and `s24`) and `kazu`, both in `wheel` and both nix
daemon trusted-users. A non-empty key list is what turns password auth off, so
those keys are the only way in. Root login is off.

The installer's original `sarten` *account* -- same word as the host name, unrelated thing -- did **not** survive the first switch,
and `users.mutableUsers = true` is not the escape hatch it looks like: it allows
users created by hand with `useradd` to persist, but `sarten` was declared in
the old `/etc/nixos/configuration.nix`, so NixOS considered it a managed user
and `update-users-groups.pl` removed it the moment it stopped being declared.
Only `/home/sarten` is left behind. Anything that has to outlive a switch has to
be in this flake.

The fallback is therefore whatever else is in the key list. Until `kazu`'s RSA
key is filled in that is one key, `s24`, so the margin is thin: if both it and
`p1`'s key go, the only way back in is the physical console.

The same rule applies to `meow`. It was the account on this box until
2026-09-05 and it is not in `auth.nix`, so the switch that introduces `asynthe`
removes it — `/home/meow` is left behind, owned by a uid nothing claims. Move
it before that switch, not after.

One nixpkgs trap worth knowing, which this account happens to sidestep. Under
`users.mutableUsers = true` an *existing* `/etc/shadow` entry is carried over
verbatim — `update-users-groups.pl` only writes `!` for a password when
`mutableUsers` is false, or when the entry is new. Declaring no password does not
clear one, and neither does `hashedPassword = "!"`; the script carries a standing
FIXME about exactly that. `user` gets a fresh entry, so it is locked properly. An
account *adopted* from a previous install would keep whatever password it had and
needs `sudo passwd -l <name>` once.

`root` is the mirror image of that. `sys.sops.rootPassword = true` points it at
the same hash as the first admin, so `su` works and nothing new is granted —
that account is in `wheel` and already sudos to root. It reuses that secret
rather than a `users/root` key so there is one less name that has to exist in
`secrets.yaml`; sops-nix validates those names at build time and refuses to
build a system naming one that is absent. But root's shadow entry predates this flake, so the same trap applies:
the declaration is inert here until `sudo passwd root` is run once. A host
installed fresh gets it without that step.

## The secret that has to arrive first

`sops` decrypts `secrets/secrets.yaml` with a private age identity, and the
`user-password` secret is `neededForUsers` — **activation fails outright if the
identity is missing**, which fails the whole switch. `p1` keeps the identity in
`/persist`; `sarten` has no `/persist`, so `sys.sops.ageKeyFile` points at
`/var/lib/sops/age-keys.txt` instead.

Both hosts use the same age identity, so nothing needs re-encrypting. It is
already staged on the box. To redo it:

```bash
ssh root@192.168.1.135 'install -d -m 0755 /var/lib/sops'
scp ~/.config/sops/age/keys.txt root@192.168.1.135:/var/lib/sops/age-keys.txt
ssh root@192.168.1.135 'chmod 0600 /var/lib/sops/age-keys.txt'
```

That is a plaintext private key sitting on the server; it is the price of
`neededForUsers`, and it is why the file is root-owned and `0600`.

## Rebuilding

From a checkout on `p1` — builds locally, pushes the closure, the ProLiant
compiles nothing:

```bash
deploy .#sarten
```

`autoRollback` reverts a failed activation and `magicRollback` reverts if `p1`
cannot reach the box afterwards, which is the net under a bad firewall or
network change. The `deploy` aspect gives `meow` passwordless sudo on this
machine, because deploy-rs cannot answer a password prompt — it hangs on one.

`nixos-rebuild` still works if you want it:

```bash
nixos-rebuild switch --flake .#sarten --target-host meow@192.168.1.135 \
    --sudo --ask-sudo-password
```

Or on the box itself:

```bash
ssh meow@192.168.1.135
nh os switch -H sarten /home/meow/flakes
```

Once it is on the tailnet, `sarten` works in place of the IP.

## After the first switch

Join the tailnet by hand — it is the one step that needs an interactive login:

```bash
ssh meow@192.168.1.135
sudo tailscale up
```

Jellyfin serves `/srv/media` on `:8096` with `sys.jellyfin.openFirewall = false`,
so it is reachable over tailscale and not from the LAN — see [MEDIA.md](MEDIA.md).
Hermes binds its dashboard to the name `sarten` and waits for it to resolve,
which is why `sys.hermes.waitForHost` is set — see [HERMES.md](HERMES.md).
Neither is reachable until `tailscale up` has been run.

## Rebuilding from scratch

The manual steps, in order, if the disks are ever replaced. `sda` is assumed to
already carry a NixOS install with SSH reachable.

```bash
# 1. the media disk -- DESTROYS /dev/sdb
wipefs -a /dev/sdb
printf 'label: gpt\n,,L\n' | sfdisk /dev/sdb
mkfs.ext4 -m 0 -L media /dev/sdb1

# 2. labels the flake expects on the root disk
e2label /dev/sda1 root
swaplabel -L swap /dev/sda2

# 3. the age identity (see above), then switch
```

`mkfs.ext4 -m 0` skips the usual 5% reserve. That default exists to keep root
able to write on a full filesystem; on a disk that holds only a media library it
is 23 GB thrown away.
