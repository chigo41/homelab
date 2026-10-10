# Roadmap

- [ ] **Replace the Wi-Fi uplink.** Swap pve1's wireless bridge for a wired uplink, ideally a VLAN trunk from the UniFi gateway. The UniFi Express would then route between `192.168.1.0/24` and `192.168.50.0/24`, and pve1 would go back to being a plain cluster node.
- [ ] **Consolidate hardware.** Move `chigoserver` and an access point next to the cluster, and add a second Flex Mini if more ports are needed.
- [ ] **Bring Jellyfin back under HA safely.** Options: keep the database on local storage with replication (`pvesr`) and put only the media on NFS, or move to storage with reliable locking.
- [ ] **Alerting.** Add Grafana alerts for node down, quorum lost, pool health, and backup job failure.
- [ ] **Infrastructure as code.** Manage guests and config with Ansible/Terraform so the lab can be rebuilt from this repo.
- [ ] **Rack and cable management.**
