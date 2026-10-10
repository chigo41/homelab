#!/usr/bin/env bash
# cluster-health.sh: quick health check, run from any Proxmox node.

echo "== Quorum / HA =="
ha-manager status

echo; echo "== Cluster members =="
pvecm status | sed -n '/Membership information/,$p'

echo; echo "== Storage =="
pvesm status

echo; echo "== Latest backups on shared storage =="
ls -lh /mnt/pve/cluster-nfs/dump/ 2>/dev/null | tail -3

echo; echo "== Jellyfin (expect 302) =="
curl -s -o /dev/null -w "%{http_code}\n" http://192.168.50.30:8096
