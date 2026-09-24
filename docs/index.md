# flakes

NixOS for every machine I run, except the laptop — which lives in
[dots](https://github.com/asynthe/dots). Built on
[dendritic](https://github.com/mightyiam/dendritic),
[deploy-rs](https://github.com/serokell/deploy-rs) and
[sops-nix](https://github.com/Mic92/sops-nix).

```
flakes
│
└── sarten ── HP ProLiant ML350e Gen8 v2 · 2× Xeon E5-2407 · 94 GB · ZFS
    │
    ├── media ─────── jellyfin      :8096   the library, on tank/media
    │                 radarr        :7878   movies
    │                 sonarr        :8989   series + anime
    │                 lidarr        :8686   music
    │                 prowlarr      :9696   indexers
    │                 bazarr        :6767   subtitles
    │                 qbittorrent   :8080   downloads
    │
    ├── archive ───── /srv/archive          mirrored from the laptop, tank/archive
    │
    ├── monitoring ── grafana       :3000   dashboards
    │                 prometheus    :9090   metrics, 90d retention
    │                 homepage        :80   what runs here and where
    │                 docs          :8081   these pages
    │                 node-exporter :9100   host + smartctl metrics
    │                 smartd                nightly short test, weekly long
    │
    ├── security ──── wazuh          :443   SIEM, single-node compose stack
    │                 wazuh-syslog           p1 ships its journal here
    │
    ├── infra ─────── incus         :8443   containers + VMs on the vm mirror, isolated lab bridge
    │                 docker                for the wazuh stack
    │                 tailscale             how everything is actually reached
    │
    └── ai ────────── hermes                Hermes Agent gateway; dashboard off until it has auth
```

## Where to start

| | |
|---|---|
| [Reference](DOCS.md)        | how the repo works: aspects, accounts, secrets, deploying |
| [`sarten`](SARTEN.md)       | the ProLiant: install, disks, networking, recovery |
| [Layout](LAYOUT.md)         | current disks, pools and networks, and the target |
| [The media stack](MEDIA.md) | jellyfin, the arrs, and the by-director library |
| [The archive](ARCHIVE.md)   | what the laptop mirrors up, and how |
| [Wazuh](WAZUH.md)           | the SIEM, and what a rebuild cannot reproduce |
| [SOC lab](LAB.md)           | what this box is being built into |
| [`hermes` aspect](HERMES.md)| the agent |

## Deploy

```bash
nix develop          # deploy-rs, sops, age, ssh-to-age
deploy .#sarten
```

Builds on the workstation, pushes the closure, activates, and rolls back on its
own if the machine stops answering.

## These pages

`docs.nix` renders this directory with mdBook at build time and nginx serves the
result on `:8081`. There is no daemon reading the markdown — a change to a `.md`
file reaches the site on the next `deploy`, and nowhere else.
