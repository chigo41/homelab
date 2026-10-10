# Storage, High Availability & Backups

## Shared storage

- **TrueNAS** on a Lenovo ThinkCentre (`192.168.50.20`) with a ZFS pool on a dedicated data SSD.
- A dataset is exported over **NFS**, limited to the lab subnet, and added in Proxmox as storage `cluster-nfs` (`/mnt/pve/cluster-nfs`) on all three nodes.
- Guest disks on `cluster-nfs` can live-migrate between nodes and are eligible for HA.

**Lesson:** TrueNAS console network settings are *staged* until they are committed. The address looked set but wasn't active. It was applied through the middleware API, and running state was compared with saved state.

## High availability

- HA groups set which nodes a guest may run on, with priorities.
- With the CRM watchdog armed, a node that drops out is fenced, and its HA guests restart on a surviving node.
- **Failover test:** cut power to a node running an HA guest. The cluster stayed quorate, fenced the node, and restarted the guest on another node automatically.

```text
quorum OK
master pve2 (active)
fencing armed (CRM watchdog active)
lrm pve1 (idle, watchdog standby)
lrm pve2 (active, watchdog active)
lrm pve3 (idle, watchdog standby)
```

### Trade-off: SQLite workloads on NFS

Jellyfin keeps its library in SQLite, which relies on file locking. NFS locking turned out to be fragile under routing changes (see troubleshooting). Jellyfin was moved to **local storage** and taken out of HA on purpose: a stable service without failover is better than an HA service that crash-loops.

## Backups

- Nightly `vzdump` jobs (~02:00) write to `cluster-nfs/dump`, in `zstd` compression, with a retention policy.
- A **second backup server** keeps an extra copy (including `chigoserver` data in `/srv/backups/chigoserver/`).
- **Restore drill** (done for real during an outage):

```bash
pct restore 100 /mnt/pve/cluster-nfs/dump/vzdump-lxc-100-<date>.tar.zst --storage local-lvm
pct config 100 | grep dev      # check device passthrough is still right
pct start 100
pct exec 100 -- systemctl status jellyfin --no-pager
```

The `mknod ... Operation not permitted` warnings from unprivileged containers are harmless. The line `merging backed-up and given configuration` means the restore finished.
