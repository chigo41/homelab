# Home Network & Self-Hosted Server Lab

**Stack:** UniFi · Ubuntu Server · Docker · Portainer · Pi-hole · Jellyfin · Homepage · Grafana · InfluxDB · Tailscale/WireGuard

A home network rebuilt on an all-UniFi stack, replacing the ISP's all-in-one gateway. It also hosts a headless Ubuntu server that runs the household's DNS filtering, media streaming, dashboards, and remote access.

## Goals

- Remove double NAT and give one device full control of routing, DHCP, and Wi-Fi.
- Filter DNS for every device on the network, including a separate lab subnet.
- Run services in containers that are easy to rebuild, update, and monitor.
- Reach everything securely from outside the house without opening any ports.

## Hardware

| Device | Role | Address |
|---|---|---|
| Xfinity modem | Bridge mode (modem only) | — |
| UniFi Express | Gateway, UniFi controller, router | 192.168.1.1 |
| UniFi USW-Lite-16-PoE | Core switch, PoE for the APs | — |
| UniFi U7 Pro | Wi-Fi 7 access point | — |
| UniFi U6-LR | Wi-Fi 6 long-range access point | — |
| HP ProDesk Mini (`chigoserver`) | Ubuntu Server Docker host | 192.168.1.50 (DHCP reservation) |
| APC Back-UPS | Power protection | — |

## What was built

**Edge and Wi-Fi**
- Put the ISP gateway in bridge mode so the UniFi Express holds the public IP. This removed double NAT.
- Adopted the switch and both APs into one UniFi controller for a single view of clients, traffic, and devices.
- Added a static route on the UniFi Express (`192.168.50.0/24` → pve1's Wi-Fi address on the main LAN), so workstations can reach every host on the lab subnet.

**Service host (`chigoserver`)**
- Ubuntu Server, run headless over SSH with a reserved DHCP address.
- Services run as Docker containers managed through Portainer. See [`configs/docker/docker-compose.yml`](configs/docker/docker-compose.yml).

| Service | Purpose | Port |
|---|---|---|
| Pi-hole | Network-wide DNS filtering for both subnets | 53, web UI |
| Jellyfin | Media streaming (original instance, before moving to the cluster) | 8096 |
| Portainer | Container management | 9443 |
| Homepage | Single dashboard with live widgets for every node and service | 3000 |
| Grafana + InfluxDB | Metrics dashboards for the Proxmox cluster and hosts | 3001 |

**Remote access**
- Tailscale subnet router advertising both `192.168.1.0/24` and `192.168.50.0/24`, so the whole lab, including the Proxmox web UI, can be reached from a phone on cellular.
- A second subnet router on a cluster node keeps access working if `chigoserver` goes down.
- Nothing is port-forwarded to the internet.

**Backups**
- `chigoserver` config and data are backed up nightly to a separate backup server (`/srv/backups/chigoserver/`).

## Docs

- [Network design](docs/network-design.md): addressing, DNS flow, routing, remote access
- [Services](docs/services.md): what runs where and how to check it
- [Troubleshooting log](docs/troubleshooting.md): real problems and how they were fixed

## Skills shown

TCP/IP and subnetting · DHCP reservations · DNS and Pi-hole · static routing · UniFi administration · Linux server administration over SSH · Docker and Portainer · WireGuard/Tailscale VPN · monitoring with Grafana · systematic troubleshooting
