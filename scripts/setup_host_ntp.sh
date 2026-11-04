#!/usr/bin/env bash
# Run on the Ubuntu host connected to VMX at 172.22.11.1/24.
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo: sudo bash ~/vmx_ws/scripts/setup_host_ntp.sh" >&2
  exit 1
fi
if ! ip -4 addr show dev enp46s0 | grep -q 'inet 172\.22\.11\.1/24'; then
  echo "enp46s0 must have 172.22.11.1/24 before configuring VMX NTP" >&2
  exit 1
fi
profile=$(nmcli -g GENERAL.CONNECTION device show enp46s0)
if [[ -z $profile || $profile == -- ]]; then
  echo 'enp46s0 has no active NetworkManager profile' >&2
  exit 1
fi
if ! nmcli -g ipv4.addresses connection show "$profile" | grep -Fxq '172.22.11.1/24'; then
  nmcli connection modify "$profile" +ipv4.addresses 172.22.11.1/24
  nmcli device reapply enp46s0
fi

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y chrony

install -d -m 0755 /etc/chrony/conf.d
cat > /etc/chrony/conf.d/vmx.conf <<'CONF'
# Serve only the VMX over the direct Ethernet link. Do not advertise an
# unsynchronised local clock: chrony must have a valid upstream time source.
allow 172.22.11.2/32
CONF
if ! grep -Eq '^[[:space:]]*(confdir|include)[[:space:]]+/etc/chrony/conf.d' /etc/chrony/chrony.conf; then
  printf '\nconfdir /etc/chrony/conf.d\n' >> /etc/chrony/chrony.conf
fi

systemctl enable --now chrony.service
systemctl restart chrony.service
if systemctl is-active --quiet systemd-timesyncd.service; then
  systemctl disable --now systemd-timesyncd.service
fi
chronyc burst 4/4

if command -v ufw >/dev/null && ufw status | grep -q '^Status: active'; then
  ufw allow in on enp46s0 from 172.22.11.2 to 172.22.11.1 port 123 proto udp
fi

echo 'Chrony status:'
chronyc tracking
chronyc sources -v
echo 'Chrony may need more upstream samples before VMX accepts its root distance (<5 s).'
echo 'UDP/123 listeners:'
ss -lunp | grep ':123' || true
echo 'VMX NTP source: 172.22.11.1 (host must remain powered and connected).'
