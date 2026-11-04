#include <chrono>
#include <iostream>
#include <memory>

#include "rclcpp/rclcpp.hpp"
#include "studica_control/srv/set_data.hpp"

int main(int argc, char ** argv)
{
  using namespace std::chrono_literals;
  using Service = studica_control::srv::SetData;

  rclcpp::init(argc, argv);
  auto node = std::make_shared<rclcpp::Node>("vmx_cpp_imu_client");
  auto client = node->create_client<Service>("/imu/get_imu_data");

  if (!client->wait_for_service(10s)) {
    RCLCPP_ERROR(node->get_logger(), "IMU service unavailable");
    rclcpp::shutdown();
    return 1;
  }

  auto request = std::make_shared<Service::Request>();
  // The Studica service resets yaw only for "zero_yaw". "read" requests
  // the current angles without issuing a calibration or motion command.
  request->params = "read";
  auto response = client->async_send_request(request);
  if (rclcpp::spin_until_future_complete(node, response, 5s) !=
      rclcpp::FutureReturnCode::SUCCESS) {
    RCLCPP_ERROR(node->get_logger(), "Timed out reading IMU service");
    rclcpp::shutdown();
    return 1;
  }

  const auto result = response.get();
  if (!result->success) {
    RCLCPP_ERROR(node->get_logger(), "%s", result->message.c_str());
    rclcpp::shutdown();
    return 1;
  }

  std::cout << result->message << std::endl;
  rclcpp::shutdown();
  return 0;
}
