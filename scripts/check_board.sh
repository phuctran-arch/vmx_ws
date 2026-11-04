#!/usr/bin/env bash
set -euo pipefail

target="${1:-vmx@172.22.11.2}"
ssh -o StrictHostKeyChecking=yes -o ConnectTimeout=6 "$target" 'bash -s' <<'REMOTE'
echo "Host: $(hostname)"
echo "Architecture: $(uname -m)"
if [[ ! -f /opt/ros/humble/setup.bash ]]; then
  echo "ROS 2 Humble: missing"
  exit 1
fi
source /opt/ros/humble/setup.bash
if [[ -f "$HOME/studica_ws/install/setup.bash" ]]; then
  source "$HOME/studica_ws/install/setup.bash"
fi
set -u
echo "ROS_DISTRO: ${ROS_DISTRO:-unset}"
if command -v colcon >/dev/null; then
  echo "Colcon: $(command -v colcon)"
else
  echo "Colcon: missing"
fi
if ldconfig -p | awk '/libvmxpi_hal_cpp.so/ { found=1 } END { exit !found }'; then
  echo "VMX HAL C++: found"
else
  echo "VMX HAL C++: missing from ldconfig"
fi
if [[ -d /usr/local/include/studica_drivers ]]; then
  echo "Studica driver headers: found"
else
  echo "Studica driver headers: not in /usr/local/include/studica_drivers"
fi
if ros2 pkg prefix studica_control 2>/dev/null; then
  echo "studica_control: found"
else
  echo "studica_control: not visible in sourced ROS environment"
fi
if [[ -d /opt/ros/humble/share/rmw_cyclonedds_cpp ]]; then
  echo "CycloneDDS ROS RMW: found"
else
  echo "CycloneDDS ROS RMW: missing"
fi
echo "Visible ROS topics (up to 8 s):"
timeout 8 ros2 topic list -t || true
REMOTE
