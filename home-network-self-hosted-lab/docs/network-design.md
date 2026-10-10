# Network Design

## Address plan

| Network | Purpose | Gateway | DHCP |
|---|---|---|---|
| 192.168.1.0/24 | Main / household network, service host | 192.168.1.1 (UniFi Express) | UniFi Express |
| 192.168.50.0/24 | Lab network (Proxmox cluster, storage) | 192.168.50.11 (pve1) | Static addresses |
| 100.64.0.0/10 | Tailscale overlay | — | Tailscale |

### Reserved and static addresses

| Host | Address |
|---|---|
| UniFi Express | 192.168.1.1 |
| chigoserver | 192.168.1.50 |
| pve1 / pve2 / pve3 | 192.168.50.11 / .12 / .13 |
| TrueNAS | 192.168.50.20 |
| Jellyfin LXC (CT 100) | 192.168.50.30 |

## Why ISP bridge mode

The Xfinity gateway's own router plus a UniFi router caused **double NAT**: two layers of address translation, two DHCP servers, and two places to troubleshoot. In bridge mode the Xfinity box is only a modem. The UniFi Express gets the public IP and is the one router for the house.

## DNS flow

```
client ──► Pi-hole (192.168.1.50:53) ──► upstream resolver
                ▲
lab host ──► pve1 :53 ──(iptables DNAT)──┘
```

- Main-network clients get Pi-hole as their DNS server from UniFi DHCP. A secondary resolver is set so the network still works if Pi-hole is down.
- Lab hosts send DNS to their gateway (pve1). pve1 sends **all** port-53 traffic to Pi-hole with a DNAT rule, so even hosts with hard-coded DNS get filtered. There is one resolver to look after instead of two.

## Routing between subnets

- Lab → main / internet: pve1 NATs lab traffic out of its Wi-Fi uplink (`MASQUERADE`).
- Main → lab: a static route on the UniFi Express sends `192.168.50.0/24` to pve1. This makes lab hosts reachable by IP from any workstation.

## Remote access

- Tailscale on `chigoserver` advertises both subnets as routes.
- Tailscale on a Proxmox node provides a second route, so remote access survives one entry point going down.
- **Lesson learned:** `--accept-routes` should stay **off** on hosts that already sit on those LANs. When it was on, the node sent LAN traffic through the tunnel and broke NFS. See the troubleshooting log.
