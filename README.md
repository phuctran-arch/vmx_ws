# VMX ROS 2 workspace — phương pháp 2 (C++/rclcpp)

Workspace này ở `~/vmx_ws` trên máy tính. `vmx_cpp_monitor` nhận topic pin và IMU do driver [Studica `studica_control`](https://github.com/Studica-Robotics/ROS2) chạy trên VMX phát ra. Node chỉ đọc dữ liệu, không gửi lệnh động cơ. `vmx_comm` là bản monitor Python để tham khảo.

## Trạng thái đã kiểm tra ngày 04/11/2026

- VMX `vmx@172.22.11.2`: Ubuntu 22.04, ROS 2 Humble, VMX HAL, driver ROS 2 `studica_control` đã build trong `~/studica_ws`. Mã nguồn Studica ở commit `5e8591778e033e6df90a601a4df180551e7f45b2`.
- Driver ROS 2 dùng thư viện Studica mới trong `~/studica_ws/drivers`. [Bản vá CMake](patches/studica_private_driver.patch) giữ nguyên thư viện `/usr/local/lib/studica_drivers` mà dịch vụ UDP cũ đang dùng.
- CycloneDDS đã cài trên VMX. Trên máy tính, các thư viện CycloneDDS đã giải nén nằm riêng trong `vendor/opt/`; [nguồn gói](vendor/SOURCES.md). Các file nhị phân này không được đưa lên GitHub. Máy mới có thể cài `ros-humble-rmw-cyclonedds-cpp` bằng apt hoặc tải các gói được ghi trong `vendor/apt_uris.txt`; `env.sh` dùng bản cài hệ thống nếu có.
- Thông điệp ROS 2 mẫu đã truyền từ VMX về máy tính. Phép thử phần cứng nhận `/battery_state` (12,07 V; khoảng 63% theo ước lượng NiMH của Studica) và `/imu` (`imu_link`) trên board; node C++ trên máy tính cũng nhận cả hai.
- Client C++ chạy trên VMX đã đọc dịch vụ `/imu/get_imu_data`. Chrony trên ASUS cấp giờ qua Ethernet `172.22.11.1`. `studica-ros2.service` đã chạy hơn 1 phút, host C++ nhận pin/IMU, board C++ đọc góc IMU; sau lệnh stop, dịch vụ UDP `active`, driver ROS 2 đã dừng. Sau một lần reboot phần mềm thành công ngày 04/11/2026, SSH hoạt động, UDP tự chạy, ROS 2 vẫn tắt mặc định và VMX đồng bộ NTP với offset `-524 µs`. Xem [tiến độ kiểm chứng](PROGRESS.md).

## Điều khiển xe bằng UDP đang chạy trên VMX

Ngày 06/11/2026, `vmx-udp-lowlevel.service` đang `active`, nhận gói UDP ở `0.0.0.0:15000`, nhận diện Titan Quad CAN ID 42. Workspace này chưa cài `vmx_highlevel` trên laptop; cấu hình ROS 2 Studica chỉ bật pin và IMU, vì vậy gửi `/cmd_vel` trong workspace này sẽ không làm xe chạy. Script [vmx_drive_udp.py](scripts/vmx_drive_udp.py) gửi trực tiếp lệnh ngắn tới daemon hiện có, rồi gửi lệnh dừng trong 1,2 giây. Daemon có watchdog 0,30 giây.

**Kê cả bốn bánh khỏi mặt đất ở lần chạy đầu.** Từ kết quả encoder tiến/lùi trong biên bản cũ, script **suy luận** M0/M1 ở bên trái, M2/M3 ở bên phải và dấu lệnh ngược nhau; chưa xác nhận trực tiếp ánh xạ này trên xe hiện tại. Kiểm tra nguồn cấp trước khi thử vì Raspberry Pi từng báo sụt áp `0x50005`. Trên laptop nối cùng Wi-Fi `TTN_5G`:

```bash
cd ~/vmx_ws
python3 scripts/vmx_drive_udp.py forward   # tiến 0,7 giây
python3 scripts/vmx_drive_udp.py backward  # lùi 0,7 giây
python3 scripts/vmx_drive_udp.py left      # quay trái tại chỗ 0,7 giây
python3 scripts/vmx_drive_udp.py right     # quay phải tại chỗ 0,7 giây
python3 scripts/vmx_drive_udp.py stop      # dừng ngay
```

Mặc định VMX ở `192.168.50.220`, duty mỗi bánh `0.16`; nếu IP Wi-Fi đổi, thêm `--host IP_MOI`. Có thể đổi `--speed` trong `(0, 0.25]` và `--duration` trong `(0, 3.0]`. Đây là duty thô, không phải m/s. Lệnh `left`/`right` quay tại chỗ. Script đã kiểm tra cú pháp và cấu trúc gói 44 byte/FNV-1a; gói **dừng** qua Wi-Fi đã được VMX nhận và telemetry báo `motor_enabled=0`, cả bốn RPM bằng 0. **Chưa chạy lệnh có duty khác 0 trên xe trong phiên này**, nên chiều di chuyển thực tế vẫn phải xác nhận khi bánh được kê lên.

## Chạy lại phép thử cảm biến

Máy tính dùng Ethernet `enp46s0` với địa chỉ `172.22.11.1/24` đã lưu trong profile NetworkManager `vmx-lowlevel-lan`; VMX là `172.22.11.2`. Nếu mất kết nối sau khi đổi mạng, kiểm tra `nmcli device show enp46s0` và `ping 172.22.11.2`.

Ngày 06/11/2026, laptop và VMX cùng kết nối Wi‑Fi `TTN_5G`; VMX có IP DHCP `192.168.50.220` và tên `vmx.local`. SSH qua Wi‑Fi đã được kiểm chứng bằng lệnh sau trên laptop (dùng host key đã biết từ kết nối Ethernet):

```bash
ssh -o HostKeyAlias=172.22.11.2 vmx@vmx.local
```

IP Wi‑Fi có thể đổi theo DHCP; kiểm tra lại bằng `getent hosts vmx.local`. Cấu hình CycloneDDS trong workspace vẫn trỏ tới Ethernet, nên phép thử này chỉ xác nhận SSH qua Wi‑Fi, chưa xác nhận ROS 2 qua Wi‑Fi.

Terminal 1 trên máy tính:

```bash
cd ~/vmx_ws
source env.sh
ros2 run vmx_cpp_monitor monitor --ros-args -p expect_imu:=true
```

Terminal 2 trên máy tính:

```bash
ssh -tt vmx@172.22.11.2 'bash ~/studica_ws/scripts/run_board_sensor_test.sh'
```

Script trên VMX hỏi mật khẩu `sudo`, dừng dịch vụ UDP bằng chính `ExecStop` của service, chạy driver Studica tối đa 30 giây với [cấu hình chỉ bật pin và IMU](config/params_method2.yaml), gọi client C++ để đọc góc IMU, đọc một mẫu mỗi topic, rồi khôi phục dịch vụ UDP. Nó không bật Titan hoặc gửi lệnh chuyển động. Xem trạng thái board không làm thay đổi phần cứng bằng `~/vmx_ws/scripts/check_board.sh vmx@172.22.11.2`.

## Đồng bộ giờ VMX

Trên máy ASUS có cổng Ethernet `enp46s0` nối VMX. Script sau đã chạy thành công ngày 04/11/2026; dùng lại nếu cần cài đặt lại máy ASUS:

```bash
sudo bash ~/vmx_ws/scripts/setup_host_ntp.sh
```

Script cài Chrony, lưu `172.22.11.1/24` trong profile NetworkManager, chỉ cho VMX `172.22.11.2` truy vấn UDP/123, và mở đúng rule nếu UFW đang hoạt động. Máy ASUS phải bật và nối Ethernet khi VMX dùng nguồn này. Trên VMX, `/etc/systemd/timesyncd.conf.d/zz-vmx-local.conf` ưu tiên ASUS `172.22.11.1`, sau đó là AGX/Orin `ubuntu.local` nếu kết nối lại. Cấu hình AGX cũ không bị xóa. Kiểm tra sau khi chạy script:

```bash
ssh vmx@172.22.11.2 'timedatectl show -p NTPSynchronized; timedatectl timesync-status'
```

Chỉ dùng timestamp IMU cho sensor fusion khi `NTPSynchronized=yes`. Sau reboot gần nhất, VMX có offset `-524 µs` và root distance `31,134 ms`. Khi SSH vừa mở, NTP có thể vẫn báo `no`; lần kiểm tra này timesyncd đồng bộ sau khoảng một phút. Nếu chưa đồng bộ, kiểm tra `chronyc tracking` trên ASUS, kết nối Ethernet, và UDP/123. Sau khi cài mới Chrony, có thể mất vài phút để root distance giảm xuống mức VMX chấp nhận; không tăng ngưỡng 5 giây của timesyncd. Cách cấu hình Chrony theo [hướng dẫn Ubuntu](https://ubuntu.com/server/docs/how-to/networking/serve-ntp-with-chrony/).

## Vận hành ROS 2 lâu dài trên VMX

`studica-ros2.service` được cài trên VMX nhưng **không tự khởi động**. Nó chỉ chạy khi NTP đã đồng bộ, dừng dịch vụ UDP bằng `ExecStop` hiện có, chạy driver Studica với [cấu hình chỉ bật pin/IMU](config/params_method2.yaml), rồi khôi phục UDP khi ROS 2 dừng. Script thực thi được cài root-owned tại `/usr/local/sbin/run_studica_ros2_mode.sh`; bản nguồn ở `scripts/`. Chuyển chế độ trên VMX:

```bash
sudo systemctl start studica-ros2.service
systemctl status studica-ros2.service
source /opt/ros/humble/setup.bash
source ~/studica_ws/install/setup.bash
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp ROS_DOMAIN_ID=0 ROS_LOCALHOST_ONLY=0
export CYCLONEDDS_URI=file:///home/vmx/studica_ws/config/cyclonedds_board.xml
ros2 topic list
sudo systemctl stop studica-ros2.service
systemctl is-active vmx-udp-lowlevel.service
```

Theo dõi `journalctl -u studica-ros2.service -f`. Service từ chối khởi động nếu `NTPSynchronized=no`, giữ UDP hoạt động. Không bật cả hai driver VMX cùng lúc.

## Kiểm tra sau reboot và khôi phục SSH

Lần reboot phần mềm đầu ngày 04/11/2026, VMX trả lời ping `172.22.11.2` nhưng từ chối SSH cho tới khi được cấp nguồn lại. Nhật ký boot lỗi dừng lúc nạp profile của `snapd.apparmor.service`. Dịch vụ này chạy trước `sysinit.target`, nằm trên chuỗi phụ thuộc tới SSH và trước đó có thời gian chờ vô hạn. Đã cài [drop-in giới hạn 45 giây](config/snapd-apparmor-timeout.conf) tại `/etc/systemd/system/snapd.apparmor.service.d/timeout.conf`; sau đó một lần reboot phần mềm đưa SSH trở lại sau khoảng 25 giây. Đây là cách giới hạn ảnh hưởng của bước bị nghi kẹt; một lần thành công chưa chứng minh nguyên nhân gốc hoặc loại trừ lỗi gián đoạn. Nếu lặp lại, cần xem trạng thái trên console:

```bash
sudo systemctl status snapd.apparmor.service ssh --no-pager
sudo journalctl -b -u snapd.apparmor.service -u ssh --no-pager
```

Sau khi SSH trở lại, từ ASUS chạy [script kiểm tra chỉ đọc](scripts/verify_board_after_reboot.sh):

```bash
~/vmx_ws/scripts/verify_board_after_reboot.sh
```

Script chờ NTP tối đa hai phút, rồi chỉ thành công khi UDP đang chạy, ROS 2 không chạy và vẫn disabled, không còn `manual_composition`, và VMX đã NTP-synced.

## Build và cấu trúc

```bash
cd ~/vmx_ws
source /opt/ros/humble/setup.bash
colcon build --packages-select vmx_cpp_monitor vmx_comm
source env.sh
ros2 pkg executables vmx_cpp_monitor
```

- `src/vmx_cpp_monitor/`: node C++ `rclcpp`, nhận `sensor_msgs/BatteryState` và `sensor_msgs/Imu`.
- `src/vmx_comm/`: node Python `rclpy` cùng mục đích.
- `board_src/vmx_cpp_imu_client/`: client C++ chỉ đọc dịch vụ Studica IMU. Bản nguồn này được copy tới `~/studica_ws/src/vmx_cpp_imu_client` trên VMX và build ở đó bằng `colcon build --packages-select vmx_cpp_imu_client`, vì interface `studica_control` hiện chỉ được build trên VMX.
- `config/cyclonedds_host.xml`, `config/cyclonedds_board.xml`: giao diện và peer Ethernet cố định cho hai máy.
- `config/zz-vmx-local-timesyncd.conf`, `config/studica-ros2.service`, `config/snapd-apparmor-timeout.conf`: cấu hình NTP và service vận hành trên VMX.
- `scripts/`: kiểm tra board/sau reboot, cài Chrony cho ASUS và chạy phép thử cảm biến có khôi phục dịch vụ.
- `vendor/`: chỉ commit danh sách nguồn gói; cây thư viện CycloneDDS amd64 trong `vendor/opt/` là dữ liệu cục bộ được bỏ qua bởi Git. Có thể cài `ros-humble-rmw-cyclonedds-cpp` bằng apt trên máy khác.

Tham khảo [mạng Ethernet VMX](https://learn.studica.com/docs/ws/vmx/networking/) và [cấu hình CycloneDDS](https://cyclonedds.io/docs/cyclonedds/latest/config/runtime_config.html). Nếu IP hoặc ROS domain thay đổi, cập nhật cả hai file XML và `VMX_ROS_DOMAIN_ID` trước khi chạy.
