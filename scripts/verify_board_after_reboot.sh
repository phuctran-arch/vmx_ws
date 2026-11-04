#!/usr/bin/env bash
# Read-only checks to run from the host once VMX SSH is available.
set -euo pipefail

target="${1:-vmx@172.22.11.2}"
ssh -o StrictHostKeyChecking=yes -o ConnectTimeout=6 "$target" 'bash -s' <<'REMOTE'
set -euo pipefail
# NTP may settle after SSH and the UDP service are already reachable.
for attempt in $(seq 1 24); do
  if [[ $(timedatectl show -p NTPSynchronized --value) == yes ]]; then
    break
  fi
  sleep 5
done
echo "Boot: $(uptime -s)"
echo "VMX UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "UDP: $(systemctl is-active vmx-udp-lowlevel.service)"
echo "UDP enabled: $(systemctl is-enabled vmx-udp-lowlevel.service)"
echo "ROS 2: $(systemctl is-active studica-ros2.service || true)"
echo "ROS 2 enabled: $(systemctl is-enabled studica-ros2.service || true)"
echo "NTP: $(timedatectl show -p NTPSynchronized --value)"
timedatectl timesync-status | grep -E 'Server:|Root distance:|Offset:|Packet count:'

systemctl is-active --quiet vmx-udp-lowlevel.service
[[ $(systemctl is-enabled vmx-udp-lowlevel.service) == enabled ]]
! systemctl is-active --quiet studica-ros2.service
[[ $(systemctl is-enabled studica-ros2.service) == disabled ]]
! pgrep -x manual_composition >/dev/null
[[ $(timedatectl show -p NTPSynchronized --value) == yes ]]
REMOTE
