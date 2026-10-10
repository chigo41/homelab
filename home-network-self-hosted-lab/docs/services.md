# Services

## Where things run

| Service | Host | URL |
|---|---|---|
| UniFi Network | UniFi Express | https://192.168.1.1 |
| Pi-hole | chigoserver (Docker) | http://192.168.1.50/admin |
| Portainer | chigoserver (Docker) | https://192.168.1.50:9443 |
| Homepage | chigoserver (Docker) | http://192.168.1.50:3000 |
| Grafana | chigoserver (Docker) | http://192.168.1.50:3001 |
| Jellyfin | Proxmox LXC 100 on pve2 | http://192.168.50.30:8096 |
| Proxmox VE | pve1 / pve2 / pve3 | https://192.168.50.11:8006 |
| TrueNAS | ThinkCentre | http://192.168.50.20 |

## Homepage dashboard

One page with live widgets for the Proxmox nodes (CPU, RAM, guest counts), TrueNAS pool health, UniFi, Pi-hole, Jellyfin, Portainer, Grafana, and the backup server. A red or unreachable tile is the first sign that something is down.

## Health checks

```bash
# Containers on the service host
ssh chigo41@192.168.1.50 'sudo docker ps --format "table {{.Names}}\t{{.Status}}"'

# Jellyfin responding (expect HTTP 302)
curl -I http://192.168.50.30:8096

# Last night's backups
ls -lh /srv/backups/chigoserver/ | tail -3
```

## Housekeeping done

- Removed an unused `minecraft-bedrock` container and its exposure.
- Applied pending kernel updates and rebooted, then checked that every container came back `Up`.
