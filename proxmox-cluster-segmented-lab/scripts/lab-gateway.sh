#!/usr/bin/env bash
# lab-gateway.sh: turn pve1 into the gateway for the 192.168.50.0/24 lab subnet.
#
# pve1 joins the main network over Wi-Fi and shares that connection with the
# wired lab switch. systemd runs this script at boot (see ../systemd/lab-gateway.service).
#
# Sanitized: interface names, SSID, and keys are placeholders. Wi-Fi credentials
# live in /etc/wpa_supplicant/wpa_supplicant.conf on the host, never in this repo.

set -euo pipefail

WLAN_IF="${WLAN_IF:-wlp1s0}"          # Wi-Fi uplink to the main LAN (192.168.1.0/24)
LAB_IF="${LAB_IF:-vmbr0}"             # Bridge on the wired lab switch
LAB_NET="192.168.50.0/24"
MAIN_GW="192.168.1.1"                 # UniFi Express
PIHOLE="192.168.1.50"                 # Pi-hole on chigoserver
WPA_CONF="/etc/wpa_supplicant/wpa_supplicant.conf"

log() { echo "[lab-gateway] $*"; }

# 1. Bring up the Wi-Fi uplink
log "Bringing up $WLAN_IF"
ip link set "$WLAN_IF" up
if ! pgrep -f "wpa_supplicant.*$WLAN_IF" >/dev/null; then
  wpa_supplicant -B -i "$WLAN_IF" -c "$WPA_CONF"
fi
dhclient -1 "$WLAN_IF" || true

# 2. Default route goes out Wi-Fi, never the lab bridge
#    (Problem found during the build: the default route kept preferring the wired
#     bridge, which has no path to the internet.)
ip route replace default via "$MAIN_GW" dev "$WLAN_IF"

# 3. Enable routing
sysctl -qw net.ipv4.ip_forward=1

# 4. NAT the lab subnet out of the uplink (delete-then-add keeps it idempotent)
iptables -t nat -D POSTROUTING -s "$LAB_NET" -o "$WLAN_IF" -j MASQUERADE 2>/dev/null || true
iptables -t nat -A POSTROUTING -s "$LAB_NET" -o "$WLAN_IF" -j MASQUERADE

# 5. Allow forwarding between lab and uplink
iptables -D FORWARD -i "$LAB_IF" -o "$WLAN_IF" -j ACCEPT 2>/dev/null || true
iptables -A FORWARD -i "$LAB_IF" -o "$WLAN_IF" -j ACCEPT
iptables -D FORWARD -i "$WLAN_IF" -o "$LAB_IF" -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true
iptables -A FORWARD -i "$WLAN_IF" -o "$LAB_IF" -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -D FORWARD -i "$WLAN_IF" -o "$LAB_IF" -d "$LAB_NET" -j ACCEPT 2>/dev/null || true
iptables -A FORWARD -i "$WLAN_IF" -o "$LAB_IF" -d "$LAB_NET" -j ACCEPT   # main LAN → lab (static route on UniFi)

# 6. Send all lab DNS to Pi-hole, so hosts with hard-coded resolvers are filtered too
for proto in udp tcp; do
  iptables -t nat -D PREROUTING -i "$LAB_IF" -p "$proto" --dport 53 -j DNAT --to-destination "$PIHOLE:53" 2>/dev/null || true
  iptables -t nat -A PREROUTING -i "$LAB_IF" -p "$proto" --dport 53 -j DNAT --to-destination "$PIHOLE:53"
done

log "Gateway up: $LAB_NET → $WLAN_IF via $MAIN_GW, DNS → $PIHOLE"
