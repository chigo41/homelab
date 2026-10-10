# Troubleshooting Log: Cluster & Lab Network

Each entry lists the symptom, what was checked, the root cause, and the fix.

---

### Bootstrapping a gateway that had no internet itself

- **Symptom:** pve1 was supposed to give the lab subnet internet access but had none itself, so it couldn't download anything, including Wi-Fi tools.
- **Investigation:** Checked that the wireless firmware and driver had already loaded (`dmesg`, `ip link`), so nothing needed downloading. Brought the interface up and connected with `wpa_supplicant`.
- **Root cause (second problem):** Even with Wi-Fi connected, the **default route preferred the wired bridge**, which had no path out.
- **Fix:** Pointed the default route at the Wi-Fi interface (`ip route replace default via 192.168.1.1 dev <wlan>`).
- **Lesson:** "Connected" and "routed" are separate questions. Check `ip route` as well as `ip addr`.

---

### Gateway config disappeared on reboot

- **Symptom:** The NAT and DNS rules worked until the first reboot, then the whole lab lost internet.
- **Root cause:** Every command had been run by hand, so the config existed only in memory.
- **Fix:** Moved everything into `lab-gateway.sh` with idempotent rules, run by a `oneshot` systemd unit. Tested with a full reboot before moving on.
- **Lesson:** A setup isn't done until it survives a reboot.

---

### TrueNAS network settings that didn't apply

- **Symptom:** The console showed the static IP, gateway, and DNS as saved, but the box wasn't reachable at that address.
- **Root cause:** The console menus **stage** changes, and they only take effect once committed.
- **Fix:** Applied and committed the settings through the TrueNAS middleware API, then checked the running state.
- **Lesson:** Compare running state with saved state, not just what the UI shows.

---

### NFS export rejected a node

- **Symptom:** One node couldn't mount the shared storage, while the others could.
- **Root cause:** The NFS export's allowed-network list didn't match the subnet the request really came from.
- **Fix:** Corrected the export's allowed network to the lab subnet.

---

### Tailscale `--accept-routes` broke NFS and crash-looped Jellyfin

- **Symptom:** Jellyfin (LXC 100 on NFS storage) crash-looped about every 8 seconds. Logs showed SQLite errors opening its database.
- **Investigation:** SQLite error → database files on NFS → NFS access from pve2 failing → `ip route` / `ip rule` on pve2.
- **Root cause:** `--accept-routes` had been turned on for pve2's Tailscale the night before. pve2 then sent traffic for the LAN subnets **through the tunnel**, so NFS requests arrived from a Tailscale address that the export doesn't trust. NFS locking broke, and SQLite failed with it.
- **Fix (two parts):**
  1. `tailscale set --accept-routes=false` on pve2 to restore normal LAN routing.
  2. Restored CT 100 from the nightly backup onto **local storage**, removing the NFS/SQLite dependency. Checked that GPU passthrough was correct (`renderD128` only, no stale `card1`).
- **Trade-off:** Jellyfin is no longer covered by HA. That was chosen on purpose for stability.
- **Lesson:** A change on one layer (VPN routing) can show up as a failure several layers up (a database error). Follow the chain down one layer at a time.
