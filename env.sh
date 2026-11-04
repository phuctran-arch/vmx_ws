#!/usr/bin/env bash
# Source this file on the computer that observes the VMX board.
if [[ ! -f /opt/ros/humble/setup.bash ]]; then
  echo "ROS 2 Humble is required at /opt/ros/humble" >&2
  return 1
fi
source /opt/ros/humble/setup.bash
_vmx_ws_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_vmx_vendor_prefix="${_vmx_ws_dir}/vendor/opt/ros/humble"
if [[ ! -d /opt/ros/humble/share/rmw_cyclonedds_cpp && -f "${_vmx_vendor_prefix}/lib/librmw_cyclonedds_cpp.so" ]]; then
  export AMENT_PREFIX_PATH="${_vmx_vendor_prefix}:${AMENT_PREFIX_PATH:-}"
  export LD_LIBRARY_PATH="${_vmx_vendor_prefix}/lib:${_vmx_vendor_prefix}/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}"
fi
if [[ -f "${_vmx_ws_dir}/install/setup.bash" ]]; then
  source "${_vmx_ws_dir}/install/setup.bash"
fi
export ROS_DOMAIN_ID="${VMX_ROS_DOMAIN_ID:-0}"
export ROS_LOCALHOST_ONLY=0
export CYCLONEDDS_URI="file://${_vmx_ws_dir}/config/cyclonedds_host.xml"
if [[ -d /opt/ros/humble/share/rmw_cyclonedds_cpp || -f "${_vmx_vendor_prefix}/lib/librmw_cyclonedds_cpp.so" ]]; then
  export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
else
  echo "Install ros-humble-rmw-cyclonedds-cpp for communication with Studica's driver." >&2
  return 1
fi
unset _vmx_ws_dir _vmx_vendor_prefix
