"""Observe VMX power and optional IMU data without sending actuator commands."""

import math

import rclpy
from rclpy.node import Node
from sensor_msgs.msg import BatteryState, Imu


class VMXMonitor(Node):
    def __init__(self):
        super().__init__("vmx_monitor")
        self.declare_parameter("battery_topic", "/battery_state")
        self.declare_parameter("imu_topic", "/imu")
        self.declare_parameter("expect_imu", False)
        self.declare_parameter("timeout_sec", 5.0)

        battery_topic = self.get_parameter("battery_topic").value
        imu_topic = self.get_parameter("imu_topic").value
        self.expect_imu = self.get_parameter("expect_imu").value
        self.timeout_sec = float(self.get_parameter("timeout_sec").value)
        if self.timeout_sec <= 0:
            raise ValueError("timeout_sec must be positive")

        self.last_battery = None
        self.last_imu = None
        self.battery = None
        self.imu = None
        self.create_subscription(BatteryState, battery_topic, self.on_battery, 10)
        self.create_subscription(Imu, imu_topic, self.on_imu, 10)
        self.create_timer(2.0, self.report)
        self.get_logger().info(
            f"Listening for VMX battery on {battery_topic}"
            + (f" and IMU on {imu_topic}" if self.expect_imu else "")
        )

    def on_battery(self, message):
        self.last_battery = self.get_clock().now()
        self.battery = message

    def on_imu(self, message):
        self.last_imu = self.get_clock().now()
        self.imu = message

    def is_fresh(self, last_seen):
        if last_seen is None:
            return False
        age = (self.get_clock().now() - last_seen).nanoseconds / 1e9
        return 0 <= age < self.timeout_sec

    def report(self):
        if not self.is_fresh(self.last_battery):
            self.get_logger().warn("No recent VMX /battery_state; check board driver, DDS and network")
            return

        battery = self.battery
        voltage = f"{battery.voltage:.2f} V" if math.isfinite(battery.voltage) else "unknown"
        percent = (
            f"{battery.percentage * 100:.0f}%"
            if math.isfinite(battery.percentage) and battery.percentage >= 0
            else "unknown"
        )
        status = f"VMX connected; battery {voltage}, charge {percent}"
        if self.expect_imu:
            if self.is_fresh(self.last_imu):
                status += f"; IMU frame {self.imu.header.frame_id or '(unset)'} received"
            else:
                status += "; IMU missing (enable imu in Studica params.yaml)"
        self.get_logger().info(status)


def main(args=None):
    rclpy.init(args=args)
    node = None
    try:
        node = VMXMonitor()
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        if node is not None:
            node.destroy_node()
        rclpy.shutdown()


if __name__ == "__main__":
    main()
