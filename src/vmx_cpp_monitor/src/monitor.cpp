#include <chrono>
#include <cmath>
#include <iomanip>
#include <memory>
#include <optional>
#include <sstream>
#include <stdexcept>
#include <string>

#include "rclcpp/rclcpp.hpp"
#include "sensor_msgs/msg/battery_state.hpp"
#include "sensor_msgs/msg/imu.hpp"

class VmxMonitor : public rclcpp::Node {
 public:
  VmxMonitor() : Node("vmx_cpp_monitor") {
    const auto battery_topic = declare_parameter<std::string>("battery_topic", "/battery_state");
    const auto imu_topic = declare_parameter<std::string>("imu_topic", "/imu");
    expect_imu_ = declare_parameter<bool>("expect_imu", false);
    timeout_sec_ = declare_parameter<double>("timeout_sec", 5.0);
    if (timeout_sec_ <= 0.0) {
      throw std::invalid_argument("timeout_sec must be positive");
    }

    battery_sub_ = create_subscription<sensor_msgs::msg::BatteryState>(
        battery_topic, 10,
        [this](sensor_msgs::msg::BatteryState::ConstSharedPtr msg) {
          battery_ = msg;
          battery_seen_ = std::chrono::steady_clock::now();
        });
    imu_sub_ = create_subscription<sensor_msgs::msg::Imu>(
        imu_topic, 10,
        [this](sensor_msgs::msg::Imu::ConstSharedPtr msg) {
          imu_ = msg;
          imu_seen_ = std::chrono::steady_clock::now();
        });
    timer_ = create_wall_timer(std::chrono::seconds(2), [this]() { report(); });
    RCLCPP_INFO(get_logger(), "Listening for VMX battery on %s%s", battery_topic.c_str(),
                expect_imu_ ? " and IMU" : "");
  }

 private:
  using TimePoint = std::chrono::steady_clock::time_point;

  bool fresh(const std::optional<TimePoint>& seen) const {
    if (!seen) return false;
    const auto age = std::chrono::duration<double>(std::chrono::steady_clock::now() - *seen).count();
    return age >= 0.0 && age < timeout_sec_;
  }

  void report() {
    if (!fresh(battery_seen_)) {
      RCLCPP_WARN(get_logger(), "No recent /battery_state from VMX; check driver and DDS/network");
      return;
    }

    std::ostringstream status;
    status << "VMX connected; battery ";
    if (std::isfinite(battery_->voltage)) {
      status << std::fixed << std::setprecision(2) << battery_->voltage << " V";
    } else {
      status << "unknown";
    }
    status << ", charge ";
    if (std::isfinite(battery_->percentage) && battery_->percentage >= 0.0f) {
      status << std::fixed << std::setprecision(0) << battery_->percentage * 100.0f << "%";
    } else {
      status << "unknown";
    }
    if (expect_imu_) {
      if (fresh(imu_seen_)) {
        status << "; IMU frame " << (imu_->header.frame_id.empty() ? "(unset)" : imu_->header.frame_id)
               << " received";
      } else {
        status << "; IMU missing (check imu.enabled in Studica params.yaml)";
      }
    }
    RCLCPP_INFO(get_logger(), "%s", status.str().c_str());
  }

  bool expect_imu_ = false;
  double timeout_sec_ = 5.0;
  std::optional<TimePoint> battery_seen_;
  std::optional<TimePoint> imu_seen_;
  sensor_msgs::msg::BatteryState::ConstSharedPtr battery_;
  sensor_msgs::msg::Imu::ConstSharedPtr imu_;
  rclcpp::Subscription<sensor_msgs::msg::BatteryState>::SharedPtr battery_sub_;
  rclcpp::Subscription<sensor_msgs::msg::Imu>::SharedPtr imu_sub_;
  rclcpp::TimerBase::SharedPtr timer_;
};

int main(int argc, char** argv) {
  rclcpp::init(argc, argv);
  try {
    rclcpp::spin(std::make_shared<VmxMonitor>());
  } catch (const std::exception& e) {
    RCLCPP_ERROR(rclcpp::get_logger("vmx_cpp_monitor"), "%s", e.what());
    rclcpp::shutdown();
    return 1;
  }
  rclcpp::shutdown();
  return 0;
}
