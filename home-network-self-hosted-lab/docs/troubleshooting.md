# Troubleshooting Log: Network & Services

Each entry lists the symptom, what was checked, the root cause, and the fix.

---

### Services unreachable over the VPN

- **Symptom:** The Tailscale tunnel was up and the host answered ping, but the web UIs would not load remotely.
- **Investigation:** Checked the tunnel status, then looked at the actual container port bindings with `docker ps` instead of assuming the default ports.
- **Root cause:** The containers were published on non-default host ports. The tunnel was fine; the browser was trying the wrong port.
- **Fix:** Used the correct published ports and recorded them in the Homepage tiles and the service table.
- **Lesson:** Check what is actually listening before blaming the network.

---

### DNS hijacked by a VPN client

- **Symptom:** Some name lookups skipped Pi-hole filtering, or failed outright, after Tailscale was installed.
- **Root cause:** The VPN client changed the host's resolver settings and replaced Pi-hole with its own DNS.
- **Fix:** Fixed the resolver configuration so Pi-hole stayed authoritative for LAN clients, then checked with test queries.
- **Lesson:** Anything that installs a network client can quietly change DNS. Verify `resolv.conf` / `resolvectl` after installing one.

---

### `--accept-routes` broke NFS and crash-looped Jellyfin

See the full write-up in the [cluster troubleshooting log](../../proxmox-cluster-segmented-lab/docs/troubleshooting.md#tailscale---accept-routes-broke-nfs-and-crash-looped-jellyfin). In short: a cluster node began routing LAN traffic through Tailscale, the NFS export rejected the tunnel address, and Jellyfin's SQLite database failed under it.
