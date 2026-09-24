# SOC lab

What `sarten` is being built into: somewhere to generate attacks, detect them,
and learn what the detection actually looked like. This file is the plan and the
running assessment — it records what exists, what the hardware can carry, and
what to add next, so the work can be picked up cold.

## What exists now

| Piece | State |
| --- | --- |
| Wazuh 4.14.7 | manager, indexer, dashboard on Docker; `https://sarten` |
| Syslog pipeline | `wazuh-syslog` aspect on `p1` and `sarten`; both reporting |
| Incus | storage pool `vm` on the mirrored 500 GB pair, `incusbr0` + `labbr0`, no instances yet |
| Suricata | `suricata` aspect watching `labbr0`, `eve.json` read by the manager |
| VM import | `sarten-import-vm` turns a VulnHub-style image into a `labbr0` instance |
| Segmentation | `sarten-firewall` isolates `labbr0`; `sarten-fwtest` proves it |
| Transport | tailnet; nothing exposed on the LAN |

Verified working, host side: failed SSH logins on `sarten` and failed `sudo` on
`p1` both reach the manager and fire rules 2501 and 2504.

Verified working, network side: a scan between two `labbr0` instances fires a
Suricata HTTP rule, and the manager decodes it into a Wazuh alert (rule 86601,
`data.alert.signature` carried through). That is the whole path — attacker →
`labbr0` → Suricata `eve.json` → manager — end to end.

See [docs/WAZUH.md](WAZUH.md) for the SIEM, and [LAYOUT.md](LAYOUT.md) for the
disks, pools and the firewall the lab sits behind.

## What the hardware can carry

Incus has the **`qemu` driver alongside `lxc`**, `/dev/kvm` is present, and the
CPUs expose `vmx`/`ept`/`vpid`. Full VMs work, not just containers — that is what
makes a real lab possible here.

| | |
| --- | --- |
| CPU | 2× Xeon E5-2407, 8 cores total |
| Threads per core | 1 — no hyperthreading |
| Clock | 2.2 GHz, Sandy Bridge (2012) |
| AVX2 | absent (only `avx`) |
| RAM | 94 GB |
| Pool | `tank`, 1.81 T, ~1.75 T free |

**Cores are the budget, not memory.** Eight slow cores, and the Wazuh indexer is
a 1 GB-heap JVM that stays busy on its own. Plan on 2–4 concurrent VMs. Memory
will never be the limit.

No AVX2 means some modern guest software will not run. Windows 11 wants TPM 2.0
and Secure Boot — possible with vTPM and OVMF, but painful on this vintage. Use
**Windows Server 2019/2022 and Windows 10**, which install cleanly.

## The gap that matters: no Windows

Analyst work is overwhelmingly Windows — Security event logs, Sysmon,
Kerberoasting, DCSync, lateral movement, LOLBins. A Linux-only lab covers maybe a
third of the job, and not the third that comes up in interviews.

The highest-value single addition is a small AD lab: **Windows Server as a DC, one
Windows 10 client, Sysmon, and the Wazuh agent**. Wazuh's Windows agent is a real
MSI and works properly — unlike the NixOS hosts, which get log forwarding only,
a Windows guest gets full FIM, SCA, syscollector and active response.

## Where the attacker sits

`labbr0` is sealed: [LAYOUT.md](LAYOUT.md#who-may-reach-what) blocks it from the
LAN, the tailnet, the internet and `incusbr0`, in both directions. So the
attacker cannot be `p1` reaching in — a vulnerable target reachable from the
laptop is a pivot onto the whole network. **The attacker is an instance inside
the lab**, on `labbr0` beside the target, and you drive it from `p1` over the
tailnet with `incus console <name>` or `incus exec <name> -- …`. Suricata watches
`labbr0`, so it sees the attacker↔target traffic from the middle.

## Working pattern: build wet, detonate dry

`ipv4.nat = false` and no uplink means a `labbr0` instance cannot download a
package, an agent or an OS update. So anything that needs the network is built
first on `incusbr0`, which is NAT'd:

1. build on `incusbr0` — install the OS, tools (nmap and friends on the attacker;
   Sysmon and the Wazuh agent on a Windows target), enrol the agent
2. `incus snapshot create <name> clean`
3. move it to `labbr0`: `incus profile assign <name> lab`, or relaunch `-p lab`
4. `incus restore <name> clean` afterwards

A VulnHub target is the exception: it ships its services pre-installed and needs
no build step, so it goes straight onto `labbr0`. Step 2 is what makes the lab
reusable rather than rebuilt every weekend; on ZFS those snapshots are near-free.

## Importing a VulnHub target

`sarten-import-vm NAME IMAGE [SIZE_GIB]` (from `nix/hosts/sarten/lab.nix`) takes
an `.ova`, `.zip`, or a bare disk image (`.vmdk .qcow2 .vdi .vhd .raw`), unpacks
it if need be, and writes the largest disk it finds into a new `lab` VM's zvol —
Incus keeps that volume with no device node, so the tool flips it on for the copy
and off after. VulnHub images are almost all legacy BIOS, so it sets
`security.csm=true`.

```bash
scp target.ova asynthe@sarten:/srv/scratch/
ssh asynthe@sarten
sarten-import-vm kioptrix /srv/scratch/target.ova
incus start kioptrix
incus console kioptrix           # watch it boot; --type=vga needs a remote client
incus list kioptrix              # its labbr0 address, once it DHCPs
incus snapshot create kioptrix clean
```

Then launch an attacker beside it, built wet and moved dry, and go.

## Suricata

The `suricata` aspect (`nix/nixos/services/suricata.nix`) runs Suricata on
`labbr0` in IDS mode and writes `eve.json` to `/var/log/suricata`, which the
Wazuh manager reads through a `:ro` bind mount and its own Suricata decoders.
`sys.suricata.homeNet` is `labbr0`'s subnet, so "inside" means the lab.

Two things worth knowing, both load-bearing rather than tuning:

- **`af-packet defrag` is off.** With the fanout DEFRAG flag on, capturing the
  bridge silently swallows the DHCP reply back to instances and they never get a
  lease. Off, DHCP works and Suricata still reassembles streams at the app layer.
- **modbus and dnp3 rules are disabled** in `disabledRules`. nixpkgs builds
  Suricata without those parsers, and a signature for a missing parser is a fatal
  config error, not a skipped rule — Suricata refuses to start at all. The
  pattern match survives the daily ruleset update; rule ids would not.

## Roadmap

Roughly in order of value.

1. **Windows AD pair** — Server as DC plus a Win10 client on `incusbr0`, Sysmon
   and the Wazuh agent on both. Biggest jump in realism available.
2. **A vulnerable Linux target on `labbr0`** — import one with
   `sarten-import-vm` and attack it from an attacker instance beside it. The
   detection path is already proven; this is the first real target through it.
3. **Atomic Red Team** — pre-labelled, MITRE-mapped attacks, so detections can be
   checked rather than guessed at.
4. **Custom rules and decoders** — the media services currently land as generic
   syslog: searchable, no alerts. Writing decoders for one of them is what makes
   the rule syntax stick.
5. **`docker-listener` wodle** — needs `/var/run/docker.sock` bound into the
   manager; gives container lifecycle events.

## Learning the tooling

- `wazuh-logtest` is the best single tool for understanding Wazuh. Paste a raw
  log line and watch it decode, then match, with the phase breakdown:
  ```
  docker exec -it single-node-wazuh.manager-1 /var/ossec/bin/wazuh-logtest
  ```
- `/var/ossec/logs/alerts/alerts.json` is what the dashboard renders. Reading it
  directly is faster than clicking during a rule-writing loop.
- Only events that match a rule are written. Non-matching events are dropped
  unless archives are enabled, which is why a plain test message appears nowhere.

## Known problems

**`hermes-agent` floods the journal.** It crash-loops on a missing
`hermes_state_holders` module, and `hermes-agent` plus `hermes-backend` are the
top two log producers on `sarten` by a wide margin. On first start the forwarder
lost 1,179,870 messages to rate-limiting. It is not just wasted CPU — it drowns
the signal the SIEM exists to find. Fix or disable it before tuning anything.

**Syslog is UDP and lossy.** Only 514/udp is published by the compose file, so
`p1` off the tailnet drops its logs silently rather than queueing. Moving to TCP
is one line in the compose ports, one in the manager's `<remote>` block, and one
in the `wazuh-syslog` aspect.

**Indexer retention is unbounded.** No index lifecycle policy, so it grows on
`tank` forever. Worth setting before there are months of data.

**`allowed-ips` is not the control.** Docker's userland proxy rewrites the source
address, so every event reaches the manager as `172.18.0.1` regardless of sender.
The NixOS firewall is what actually restricts this — 514/udp is not in
`allowedUDPPorts` and `tailscale0` is a trusted interface. Host attribution still
works, because Wazuh reads the hostname from the message rather than the packet.
