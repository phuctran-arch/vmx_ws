cmake_minimum_required(VERSION 3.8)
project(vmx_cpp_imu_client)

if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(studica_control REQUIRED)

add_executable(read_imu src/read_imu.cpp)
target_compile_features(read_imu PUBLIC cxx_std_17)
ament_target_dependencies(read_imu rclcpp studica_control)
install(TARGETS read_imu DESTINATION lib/${PROJECT_NAME})

ament_package()
