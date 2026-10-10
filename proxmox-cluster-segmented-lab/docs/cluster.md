# Cluster Build & Maintenance

## Forming the cluster

```bash
# on pve1, using the wired lab address for the Corosync link
pvecm create chigo --link0 192.168.50.11

# on pve2 and pve3
pvecm add 192.168.50.11 --link0 192.168.50.12   # .13 on pve3

pvecm status   # expect: Quorate: Yes, 3 nodes
```

Binding `link0` to the wired subnet keeps Corosync heartbeats off pve1's Wi-Fi uplink. Wi-Fi latency spikes would otherwise cause false node failures.

## Why three nodes

Quorum needs **more than half** of the votes. With two nodes, losing either one loses quorum, and a network split leaves both halves unsure who is in charge (split-brain). With three nodes, any two still make a majority, so one node can fail or be partitioned and the cluster stays writable.

## Repositories

Switched every node from `enterprise.proxmox.com` (needs a subscription; `apt update` fails with 401) to the `pve-no-subscription` repo, and disabled the enterprise Ceph repo too.

## Rolling upgrades

Upgraded one node at a time so the cluster never dropped below quorum:

1. Migrate or stop the guests on the node.
2. `apt update && apt full-upgrade`
3. Reboot, then confirm it rejoins: `pvecm status` shows Quorate, 3 nodes.
4. Move on to the next node.

## Guests

| ID | Type | Service | Node | Storage | HA |
|---|---|---|---|---|---|
| 100 | LXC | Jellyfin (`/dev/dri/renderD128` passed through for hardware transcoding) | pve2 | local-lvm | No (see troubleshooting) |
