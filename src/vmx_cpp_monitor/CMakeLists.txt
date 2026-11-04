cmake_minimum_required(VERSION 3.8)
project(vmx_cpp_monitor)

if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(sensor_msgs REQUIRED)

add_executable(monitor src/monitor.cpp)
target_compile_features(monitor PUBLIC cxx_std_17)
ament_target_dependencies(monitor rclcpp sensor_msgs)
install(TARGETS monitor DESTINATION lib/${PROJECT_NAME})

ament_package()
