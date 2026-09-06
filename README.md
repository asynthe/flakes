<h1 align="center">flakes</h1>

<p align="center">
  NixOS for every machine I run, except the laptop.<br>
  <a href="https://github.com/mightyiam/dendritic">Dendritic</a> ·
  <a href="https://github.com/serokell/deploy-rs">deploy-rs</a> ·
  <a href="https://github.com/Mic92/sops-nix">sops-nix</a>
</p>

```
flakes
│
└── sarten ── HP ProLiant ML350e Gen8 v2 · 2× Xeon E5-2407 · 94 GB · ZFS mirror
    │
    ├── media ─────── jellyfin      :8096   the library, on tank/media
    │                 radarr        :7878   movies
    │                 sonarr        :8989   series + anime
    │                 lidarr        :8686   music
    │                 prowlarr      :9696   indexers
    │                 bazarr        :6767   subtitles
    │                 qbittorrent   :8080   downloads
    │
    ├── monitoring ── grafana       :3000   dashboards
    │                 prometheus    :9090   metrics, 90d retention
    │                 homepage      :8082   what runs here and where
    │                 node-exporter :9100   host + smartctl metrics
    │                 smartd                nightly short test, weekly long
    │
    ├── security ──── wazuh          :443   SIEM, single-node compose stack
    │                 wazuh-syslog           p1 ships its journal here
    │
    ├── infra ─────── incus         :8443   containers + VMs, isolated lab bridge
    │                 docker                for the wazuh stack
    │                 tailscale             how everything is actually reached
    │
    └── ai ────────── hermes                Hermes Agent, dashboard on the tailnet
```

None of those services is reachable from the LAN. They bind wide and the
firewall drops them on `eno1` — only ssh and tailscale's own port are open, so
the tailnet is the way in.

## Deploy

```bash
nix develop          # deploy-rs, sops, age, ssh-to-age
deploy .#sarten
```

Builds on the workstation, pushes the closure, activates, and rolls back on its
own if the machine stops answering.

## Add a machine

```nix
# nix/hosts/<name>/default.nix
imports = with config.flake.modules.nixos; [ profile-server <name>-hardware boot-uefi ];

networking.hostName = "<name>";
system.stateVersion = "26.05";
sys.deploy.hostname = "<ip or tailnet name>";
```

That is the whole registration — the flake finds it by its `host-` prefix and it
becomes a deploy-rs node too. Users come from [`auth.nix`](auth.nix).

## Docs

| | |
|---|---|
| [DOCS.md](docs/DOCS.md)     | how the repo works: aspects, accounts, secrets, deploying |
| [SARTEN.md](docs/SARTEN.md) | the ProLiant: install, disks, networking, recovery |
| [MEDIA.md](docs/MEDIA.md)   | the media stack and the by-director library |
| [WAZUH.md](docs/WAZUH.md)   | the SIEM, and what a rebuild cannot reproduce |
| [LAB.md](docs/LAB.md)       | the SOC lab this box is being built into |
| [HERMES.md](docs/HERMES.md) | the agent |

<p align="center"><sub>the laptop lives in <a href="https://github.com/asynthe/dots">dots</a></sub></p>
