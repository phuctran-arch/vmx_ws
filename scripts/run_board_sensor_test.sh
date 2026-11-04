#!/usr/bin/env bash
# Run on VMX. Temporarily switch from the existing UDP HAL daemon to the
# Studica ROS 2 driver, read only battery/IMU, and restore the UDP daemon.
set -eo pipefail
source /opt/ros/humble/setup.bash
source /home/vmx/studica_ws/install/setup.bash
set -u

export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
export ROS_DOMAIN_ID=0
export ROS_LOCALHOST_ONLY=0
export CYCLONEDDS_URI=file:///home/vmx/studica_ws/config/cyclonedds_board.xml

service=vmx-udp-lowlevel.service
driver=/home/vmx/studica_ws/install/studica_control/lib/studica_control/manual_composition
params=/home/vmx/studica_ws/config/params_method2.yaml
log=/tmp/studica_method2_driver.log

sudo -v
was_active=0
if systemctl is-active --quiet "$service"; then
  was_active=1
fi
driver_pid=
restore() {
  if [[ -n "$driver_pid" ]] && kill -0 "$driver_pid" 2>/dev/null; then
    kill -INT "$driver_pid" 2>/dev/null || true
    wait "$driver_pid" 2>/dev/null || true
  fi
  if [[ "$was_active" -eq 1 ]]; then
    sleep 2
    sudo -n systemctl start "$service"
    systemctl is-active "$service"
  fi
}
trap restore EXIT
trap 'exit 1' HUP INT TERM

if [[ "$was_active" -eq 1 ]]; then
  sudo -n systemctl stop "$service"
fi

timeout --signal=INT --kill-after=3s 30s sudo -n /usr/bin/env \
  RMW_IMPLEMENTATION="$RMW_IMPLEMENTATION" \
  ROS_DOMAIN_ID="$ROS_DOMAIN_ID" \
  ROS_LOCALHOST_ONLY="$ROS_LOCALHOST_ONLY" \
  CYCLONEDDS_URI="$CYCLONEDDS_URI" \
  LD_LIBRARY_PATH="/opt/ros/humble/lib:/opt/ros/humble/lib/aarch64-linux-gnu:/home/vmx/studica_ws/install/studica_control/lib:/home/vmx/studica_ws/drivers:/usr/local/lib/vmxpi" \
  "$driver" --ros-args --params-file "$params" > "$log" 2>&1 &
driver_pid=$!

sleep 5
echo "ROS topics:"
timeout 8 ros2 topic list --no-daemon
echo "IMU service (C++ read-only):"
timeout 12 ros2 run vmx_cpp_imu_client read_imu
echo "Battery sample:"
timeout 10 ros2 topic echo /battery_state --once
echo "IMU sample:"
timeout 10 ros2 topic echo /imu --once
echo "Driver log:"
tail -20 "$log"
