# Homelab

Two connected infrastructure projects built on retired desktop hardware: a UniFi home network running self-hosted services, and a three-node Proxmox VE high-availability cluster on its own segmented lab subnet.

| Project | What it covers | Stack |
|---|---|---|
| [Home Network & Self-Hosted Server Lab](home-network-self-hosted-lab/) | ISP bridge mode, UniFi gateway and Wi-Fi, Pi-hole DNS, Dockerized services, Tailscale remote access, dashboards and monitoring | UniFi, Ubuntu Server, Docker, Portainer, Pi-hole, Jellyfin, Homepage, Grafana, InfluxDB, Tailscale |
| [Proxmox Cluster & Segmented Lab Network](proxmox-cluster-segmented-lab/) | Linux-routed lab subnet (NAT, DNS redirection, boot persistence), 3-node Proxmox cluster, TrueNAS NFS shared storage, HA failover, backups with restore drills | Proxmox VE, Corosync, HA Manager, LXC/KVM, TrueNAS, ZFS, NFS, iptables, systemd |

## Topology

```
                         Internet
                            │
                   Xfinity modem (bridge mode)
                            │
                ┌───────────┴───────────┐
                │  UniFi Express        │  192.168.1.1
                │  gateway / controller │  static route: 192.168.50.0/24 → pve1
                └───────────┬───────────┘
                            │
             USW-Lite-16-PoE (garage switch)
              │           │              │
         U6-LR / U7 Pro   chigoserver     household devices
         (Wi-Fi APs)      192.168.1.50
                          Pi-hole · Jellyfin · Portainer
                          Homepage · Grafana · InfluxDB · Tailscale
                            ┆
                            ┆ Wi-Fi uplink
                            ┆
     ┌──────────────────────┴───────────────────────────┐
     │ pve1  192.168.50.11   lab gateway                 │
     │       wlan uplink → NAT (MASQUERADE) → lab LAN    │
     │       all lab DNS (port 53) DNAT → Pi-hole        │
     └──────────────────────┬───────────────────────────┘
                            │
               UniFi Flex Mini (lab switch) — 192.168.50.0/24
              │            │             │              │
        pve2 .12      pve3 .13      TrueNAS .20     LXC guests
                                    NFS shared      (Jellyfin .30)
                                    storage
```

## Highlights

- **Segmentation without a second router.** A Proxmox node doubles as the lab gateway, using IP forwarding, iptables NAT, and DNS redirection, all rebuilt on every boot by a systemd unit.
- **Real HA, tested the hard way.** Failover was checked by pulling power on a live node and watching the guest come back up on another node.
- **Backups that are proven.** Nightly vzdump jobs with retention, a second backup server, and actual restores instead of just checking that the files exist.
- **Documented failures.** Every hard bug is written up in a troubleshooting log: symptom, root cause, fix, and lesson. See [the cluster troubleshooting log](proxmox-cluster-segmented-lab/docs/troubleshooting.md) and [the network troubleshooting log](home-network-self-hosted-lab/docs/troubleshooting.md).

## Repo layout

```
.
├── home-network-self-hosted-lab/
│   ├── README.md
│   ├── configs/docker/        # reference compose file for the service host
│   └── docs/                  # network design, services, troubleshooting
└── proxmox-cluster-segmented-lab/
    ├── README.md
    ├── scripts/               # lab gateway script, health checks
    ├── systemd/               # unit that restores the gateway at boot
    └── docs/                  # cluster, storage/HA/backups, troubleshooting, roadmap
```

> All addresses are private RFC 1918 ranges. Passwords, Wi-Fi keys, API tokens, and Tailscale auth keys are removed and shown as placeholders.
