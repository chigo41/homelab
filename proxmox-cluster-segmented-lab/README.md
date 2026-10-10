# Proxmox Cluster & Segmented Lab Network

**Stack:** Proxmox VE · Corosync · HA Manager · LXC/KVM · TrueNAS · ZFS · NFS · iptables · systemd · Tailscale

A three-node Proxmox VE high-availability cluster (`chigo`) built from retired HP ProDesk Minis. It runs on its own isolated `192.168.50.0/24` subnet, uses TrueNAS for NFS shared storage, and has automated backups. A Proxmox node also works as the subnet's Linux gateway.

## Goals

- Practice production building blocks on real hardware: clustering, quorum, shared storage, HA failover, backups, and network segmentation.
- Keep lab traffic away from household devices.
- Make everything survive a reboot or power loss without manual steps.

## Hardware

| Device | Role | Address |
|---|---|---|
| HP ProDesk Mini (`pve1`) | Proxmox node + lab gateway (Wi-Fi uplink) | 192.168.50.11 |
| HP ProDesk Mini (`pve2`) | Proxmox node | 192.168.50.12 |
| HP ProDesk Mini (`pve3`) | Proxmox node | 192.168.50.13 |
| Lenovo ThinkCentre | TrueNAS, ZFS pool, NFS export | 192.168.50.20 |
| UniFi Flex Mini | Lab switch | — |
| Separate backup server | Second copy of backups | — |

## Architecture

### Segmented lab network

`pve1` connects to the main network over Wi-Fi and routes for the whole lab subnet:

- `net.ipv4.ip_forward=1`
- `iptables -t nat -A POSTROUTING -s 192.168.50.0/24 -o <wlan> -j MASQUERADE`: NAT for the lab
- `PREROUTING` DNAT on port 53: all lab DNS is sent to Pi-hole on the main network
- A static route on the UniFi Express points `192.168.50.0/24` at pve1, so the main LAN can reach the lab

The setup lives in [`scripts/lab-gateway.sh`](scripts/lab-gateway.sh) and is run at boot by [`systemd/lab-gateway.service`](systemd/lab-gateway.service). Wi-Fi association, addressing, routing, and firewall rules rebuild themselves after every reboot.

### Cluster

- **Three nodes on purpose.** Quorum needs a majority, and an odd node count prevents split-brain during a network partition.
- Corosync links are bound to the **wired** lab subnet, keeping cluster heartbeat off the Wi-Fi uplink.
- Nodes were moved from the enterprise repos to the no-subscription community repos. Kernels were upgraded **one node at a time** so quorum held the whole way.

### Storage, HA, and backups

- TrueNAS ZFS pool exported over NFS and mounted cluster-wide as `cluster-nfs`, which enables live migration.
- HA groups restart guests on a surviving node. **Tested by pulling power on a live node.**
- Nightly `vzdump` backups to `cluster-nfs` with a retention policy, plus a second backup server.
- Restore drills: guests were actually restored from backup and started, not just checked for files.

Details: [docs/storage-ha-backups.md](docs/storage-ha-backups.md)

### Monitoring

- Proxmox metric server → InfluxDB → Grafana dashboards.
- Homepage tiles for every node, TrueNAS, and the backup server.

## Docs

- [Cluster build and maintenance](docs/cluster.md)
- [Storage, HA, and backups](docs/storage-ha-backups.md)
- [Troubleshooting log](docs/troubleshooting.md)
- [Roadmap](docs/roadmap.md)

## Status

| Phase | Status |
|---|---|
| Lab subnet: gateway, NAT, DNS redirection, boot persistence | ✅ Complete |
| Inter-subnet static routing | ✅ Complete |
| 3-node cluster formed and quorate | ✅ Complete |
| Repo migration and rolling kernel upgrades | ✅ Complete |
| TrueNAS installed, ZFS pool, NFS export | ✅ Complete |
| Shared storage attached to the cluster | ✅ Complete |
| HA groups and power-pull failover test | ✅ Complete |
| Nightly backups, retention, restore drill | ✅ Complete |
| Second backup server | ✅ Complete |
| Grafana + InfluxDB metrics | ✅ Complete |
| Jellyfin on the cluster (LXC, GPU passthrough) | ✅ Running on local storage, not covered by HA (see troubleshooting) |
| Replace the Wi-Fi uplink with a wired / VLAN trunk | 🗓 Planned |

## Skills shown

Proxmox VE clustering and HA · quorum design · LXC/KVM · ZFS and NFS · Linux routing, NAT, and iptables · systemd unit authoring · shell scripting · rolling upgrades · backup and restore testing · structured troubleshooting
