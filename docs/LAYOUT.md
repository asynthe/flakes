# Layout

What `sarten` is made of: disks, pools, datasets, networks and the firewall
between them. [SARTEN.md](SARTEN.md) is how the host is operated; this file is
the shape underneath it. Anything that describes the machine goes here first,
and the config follows.

The rule every change is held to: **a fresh install from this repo, plus the
short list in [State outside the flake](#state-outside-the-flake), is the whole
machine.** Every item that is not on that list should come back from `deploy`.

Checked on the box on 2026-09-15.

## Hardware

| | |
| --- | --- |
| Chassis | HP ProLiant ML350e Gen8 v2, legacy BIOS only (no UEFI on Gen8) |
| CPU | 2× Xeon E5-2407, 8 cores, no hyperthreading, no AVX2 |
| RAM | 94 GB |
| Storage controller | onboard AHCI, no Smart Array |
| NICs | `eno1` `eno2` onboard, `enp9s0f0/1` `enp10s0f0/1` on a quad-port card; only `eno1` is cabled |

## Disks

| disk (by-id) | size | holds |
| --- | --- | --- |
| `ata-ST2000NM0018-2F3130_ZDS154KD` | 2 TB | `root` ext4 400G at `/`, `swap` 9G, pool `scratch` 1.4T. GRUB is installed here and the BIOS boots it |
| `ata-ST2000VX012-2LY102_ZFM3Y07C` | 2 TB | pool `tank`, whole disk, single vdev |
| `ata-MB0500GCEHE_WMAYP6540495` | 500 GB | pool `vm`, mirrored with the next disk |
| `ata-MB0500GCEHE_WMAYP6572250` | 500 GB | pool `vm` |

Why the 500 GB pair is `vm`, the Incus pool:

- **Instances get their own spindles.** VM disk I/O is small and random; `tank`
  streams media and carries the Wazuh indexer. Separating them keeps one from
  stalling the other.
- **It is the only redundant storage the box has.** Both disks have over 82,000
  power-on hours. As a mirror that age is survivable; alone it is not.
- **~460 GB is enough.** The CPUs cap the box at two to four concurrent VMs.

## Pools and datasets

All three pools: `ashift=12`, `compression=zstd`, `atime=off`, `xattr=sa`,
`acltype=posixacl`, `mountpoint=none`. Every mounted dataset is
`mountpoint=legacy` and mounts `nofail`, declared in
`nix/hosts/sarten/filesystems.nix`; all three pools are in
`boot.zfs.extraPools`.

| dataset | mounted at | recordsize | holds |
| --- | --- | --- | --- |
| `tank/media` | `/srv/media` | 1M | Jellyfin's library |
| `tank/archive` | `/srv/archive` | 1M | the mirror pushed up from the laptop |
| `tank/wazuh` | `/srv/wazuh` | 128K | the Wazuh compose checkout and certs |
| `tank/docker` | `/var/lib/docker` | 128K | Docker's images and named volumes, including all of Wazuh's data |
| `vm/incus` | (Incus) | 128K | Incus storage pool `vm`; both profiles' root disks |
| `scratch/data` | `/srv/scratch` | 1M | install images and other re-downloadable files |

`docker.service` has `RequiresMountsFor=/var/lib/docker`. If `tank` is missing,
boot carries on and Docker does not start. Without that, Docker would initialise
a fresh `/var/lib/docker` on root and bring the stack up with no data.

## Network

- `eno1` static `192.168.1.135/24`, gateway `192.168.1.1`.
- `tailscale0` is a trusted interface; the tailnet is how services are reached.
- `net.ipv4.ip_forward = 1`, and `br_netfilter` is loaded (Docker loads it), so
  bridged frames pass through the `forward` hook too.

| bridge | owner | address | NAT | used by |
| --- | --- | --- | --- | --- |
| `incusbr0` | Incus | `10.162.79.1/24`, DHCP | yes | profile `default` |
| `labbr0` | Incus | `10.66.66.1/24`, DHCP | no | profile `lab` |
| `br-*` | Docker | `172.18.0.0/16` | yes | the Wazuh stack; the name changes when Compose recreates the network |

Both Incus bridge addresses are pinned in the preseed. `ipv4.address = "auto"`
picks a new subnet whenever the preseed is applied, which is on every deploy.

### Who may reach what

| from | may reach | must not reach |
| --- | --- | --- |
| LAN (`eno1`) | sshd, homepage `:80`, docs `:8081` | anything Docker publishes (443, 514, 1514, 1515, 9200, 55000), Incus `:8443`, instances |
| tailnet | everything on the host | |
| `incusbr0` instance | DHCP/DNS on the bridge, the internet, Wazuh 1514/1515, other `incusbr0` instances | every other host port, the LAN, the tailnet, `labbr0` |
| `labbr0` instance | DHCP/DNS on the bridge, Wazuh 1514/1515, other `labbr0` instances | every other host port, the internet, the LAN, the tailnet, `incusbr0` |

### How it is enforced

`nix/hosts/sarten/firewall.nix`, the `sarten-firewall` aspect. Four tables share
the netfilter hooks: `nixos-fw`, Docker's `ip filter`/`ip nat`, Incus's
`inet incus`, and this aspect's `inet sarten-guard`.

- **`sarten-guard` only drops.** Its chains hook at `priority filter - 10`, ahead
  of the others. In nftables a drop in any base chain is final, while an accept
  only means "not dropped here", so the guard can close things without taking
  over what the other tables do.
- **Docker's published ports** are DNAT'd in `prerouting` and then *forwarded*,
  so `nixos-fw`'s `input` chain never sees them, and `filterForward` would not
  help either: its `forward-allow` chain accepts `ct status dnat` before any
  extra rule. The guard drops `iifname eno1 ct status dnat` instead.
- **Incus bridges, input:** DHCP and DNS accepted, everything else dropped, so
  the ports opened globally for the LAN (sshd, nginx) do not leak onto the
  bridges. `nixos-fw` also needs 53 and 67 opened per bridge: its `input` chain
  drops by default, and Incus's own accepts cannot override that.
- **Incus bridges, forward:** same-bridge traffic accepted; to the Docker bridge
  only 1514/1515; `labbr0` to anywhere else dropped; `incusbr0` to `labbr0`, the
  tailnet and `192.168.1.0/24` dropped, which leaves it the internet.
- **Rule reloads are scoped.** The NixOS nftables service deletes and recreates
  only its own tables, so a deploy does not wipe Docker's or Incus's rules.

### Testing it

```bash
ssh asynthe@sarten sarten-fwtest
```

Launches throwaway Alpine containers on both bridges, probes every instance row
above from inside them, and deletes them on exit. Each "must not reach" probe is
repeated from the host, where the guard does not apply: if the host cannot reach
the target either, the result proves nothing and prints `INCONCLUSIVE`, not
`PASS`. Exit status is non-zero on any `FAIL`. Run it after any change to the
firewall, the preseed, or the Wazuh ports.

It cannot test the LAN row, which needs a machine on `192.168.1.0/24`:

```bash
nc -zv 192.168.1.135 443     # must fail
nc -zv 192.168.1.135 9200    # must fail
nc -zv 192.168.1.135 22      # must succeed
```

## Services

| service | state | notes |
| --- | --- | --- |
| Wazuh manager, indexer, dashboard | `tank/wazuh` + `tank/docker` | compose stack, see [WAZUH.md](WAZUH.md) |
| Wazuh agents | inside each instance | enrol to the bridge gateway on 1514/1515 |
| Incus | `vm` | `default` profile on `incusbr0`, `lab` profile on `labbr0` |
| media stack, archive, monitoring | `tank`, `/var/lib` | see the README tree |
| hermes | `/var/lib/hermes` | gateway only; the dashboard is off until it has an auth provider, see [HERMES.md](HERMES.md) |

Instances are not declared in Nix. What is declared is everything they stand on:
the pool, the bridges, the profiles and the firewall around them. An instance is
built on `incusbr0`, snapshotted, then moved to `labbr0` when it should be cut
off. Rebuilding one is redoing that from the base image.

## Open

1. **Root and `tank` have no redundancy.** Each is a single disk. Only `vm` is
   mirrored.
2. **The LAN row is untested** from the LAN itself; see [Testing it](#testing-it).
3. **The pre-move copy of `/var/lib/docker`** (~15.6G) is still on root, hidden
   under the `tank/docker` mount. To remove it:
   ```bash
   sudo mkdir /mnt/rootfs && sudo mount --bind / /mnt/rootfs
   findmnt -no FSTYPE --target /mnt/rootfs/var/lib/docker   # must print ext4
   sudo find /mnt/rootfs/var/lib/docker -mindepth 1 -maxdepth 1 -exec rm -rf {} +
   sudo umount /mnt/rootfs && sudo rmdir /mnt/rootfs
   ```
4. **Partitioning is not declarative.** It was done by hand. See [Later](#later-4-4-tb).

## State outside the flake

What a fresh install does not bring back. Each item is either restored or
redone by hand.

| state | lives at | comes back by |
| --- | --- | --- |
| age identity | `/var/lib/sops/age-keys.txt` | copied in before the first switch, see [SARTEN.md](SARTEN.md) |
| tailnet membership | `/var/lib/tailscale` | `sudo tailscale up` once |
| Wazuh checkout and certs | `tank/wazuh` | *Steps taken* in [WAZUH.md](WAZUH.md), certs regenerated |
| Wazuh indexed data | `tank/docker` | not restored; starts empty |
| Incus instances and snapshots | `vm` | rebuilt from base images, see [Services](#services) |
| Jellyfin, the arrs, qBittorrent | `/var/lib/<service>` | set up again per [MEDIA.md](MEDIA.md) |
| Grafana and Prometheus history | `/var/lib/grafana`, `/var/lib/prometheus2` | starts empty |
| media and archive | `tank/media`, `tank/archive` | re-acquired or pushed again from the laptop |

## Later: 4× 4 TB

When those disks arrive, the box is reinstalled rather than migrated. The design,
so it is not re-derived then:

- GPT on every disk (4 TB is past MBR's limit): a 1 MiB BIOS boot partition,
  64 GiB for root on md RAID1 across all four with GRUB on each, the rest for
  ZFS. Any disk boots and any disk is replaced the same way. md metadata 1.2, so
  member partitions carry no filesystem label that could collide.
- `tank` as two mirror vdevs, about 7 TiB. It takes over `vm`'s role; a separate
  instance pool stops being worth its bays.
- `zramSwap` instead of a swap partition.
- Declared in `nix/hosts/sarten/disko.nix` (disko is already a flake input) and
  installed with `nixos-anywhere` from `p1`. The only step at the box is booting
  the installer.
- The firewall, the preseed and `sarten-fwtest` carry over unchanged; run the
  test before anything else goes on the box.
- Afterwards, [State outside the flake](#state-outside-the-flake) is the checklist.
