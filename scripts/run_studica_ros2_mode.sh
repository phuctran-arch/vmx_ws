#!/usr/bin/env bash
# Run as root on VMX. Switch from the existing UDP daemon to the sensor-only
# Studica ROS 2 driver, then restore the UDP daemon when ROS 2 stops.
set -Eeo pipefail

if [[ $EUID -ne 0 ]]; then
  echo 'This script must run as root through studica-ros2.service.' >&2
  exit 1
fi
if [[ $(timedatectl show -p NTPSynchronized --value) != yes ]]; then
  echo 'VMX clock is not NTP-synchronised; refusing ROS 2 sensor timestamps.' >&2
  exit 1
fi

source /opt/ros/humble/setup.bash
source /home/vmx/studica_ws/install/setup.bash
set -u

export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
export ROS_DOMAIN_ID=0
export ROS_LOCALHOST_ONLY=0
export CYCLONEDDS_URI=file:///home/vmx/studica_ws/config/cyclonedds_board.xml
export LD_LIBRARY_PATH="/opt/ros/humble/lib:/opt/ros/humble/lib/aarch64-linux-gnu:/home/vmx/studica_ws/install/studica_control/lib:/home/vmx/studica_ws/drivers:/usr/local/lib/vmxpi:${LD_LIBRARY_PATH:-}"

udp_service=vmx-udp-lowlevel.service
driver=/home/vmx/studica_ws/install/studica_control/lib/studica_control/manual_composition
params=/home/vmx/studica_ws/config/params_method2.yaml

was_active=0
if systemctl is-active --quiet "$udp_service"; then
  was_active=1
fi
driver_pid=
restore() {
  if [[ -n "$driver_pid" ]] && kill -0 "$driver_pid" 2>/dev/null; then
    kill -INT "$driver_pid" 2>/dev/null || true
    wait "$driver_pid" 2>/dev/null || true
  fi
  if [[ $was_active -eq 1 ]]; then
    sleep 2
    systemctl start "$udp_service"
    systemctl is-active --quiet "$udp_service"
  fi
}
trap restore EXIT
trap 'exit 0' TERM
trap 'exit 130' INT

if [[ $was_active -eq 1 ]]; then
  systemctl stop "$udp_service"
fi

"$driver" --ros-args --params-file "$params" &
driver_pid=$!
wait "$driver_pid"
