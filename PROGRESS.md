# Tiến độ giáo trình Studica C++ / ROS 2 trên VMX

Cập nhật: 06/11/2026. Workspace máy tính: `~/vmx_ws`; workspace VMX: `~/studica_ws` (`vmx@172.22.11.2`). Chỉ đánh dấu hoàn thành khi đã build hoặc kiểm tra trên board thật. Mỗi đầu việc dưới đây có trọng số bằng nhau; tỷ lệ hoàn thành = số đầu việc đã kiểm chứng / 7. Chẩn đoán HDMI mới được ghi riêng bên dưới, không tính vào bảy giai đoạn cũ.

## Các giai đoạn và bằng chứng

| # | Đầu việc | Trạng thái | Bằng chứng / điều kiện hoàn thành |
|---|---|---|---|
| 1 | Kiểm tra Ethernet, SSH, ROS 2 Humble, HAL và công cụ C++ trên VMX | Hoàn thành | Đã truy cập VMX qua SSH, xác nhận HAL và công cụ build; phép thử phần cứng nhận dạng board VMX. |
| 2 | Build `studica_control` C++ với thư viện Studica riêng trên VMX | Hoàn thành | `colcon build` thành công; `ldd` xác nhận link tới thư viện mới trong `~/studica_ws/drivers`, giữ thư viện hệ thống của dịch vụ UDP. |
| 3 | Thiết lập ROS 2 giữa VMX và máy tính qua CycloneDDS | Hoàn thành | VMX phát `std_msgs/String` và máy tính nhận `hello_vmx` qua Ethernet. |
| 4 | Node C++ `rclcpp` nhận pin và IMU thật | Hoàn thành | Node đã build, thử với dữ liệu ROS 2 giả lập và nhận `/battery_state`, `/imu` từ VMX; dịch vụ UDP cũ được khôi phục sau phép thử. |
| 5 | Client C++ đọc dịch vụ IMU Studica theo yêu cầu | Hoàn thành | `colcon build --packages-select vmx_cpp_imu_client` thành công trên VMX; dịch vụ trả `pitch: 1.630000, yaw: 0.050000, roll: -0.580000`; dịch vụ UDP được khôi phục. |
| 6 | Đồng bộ và kiểm chứng đồng hồ VMX | Hoàn thành | ASUS chạy Chrony, VMX lấy giờ từ `172.22.11.1` với `NTPSynchronized=yes`; sau reboot, offset `-524 µs`, root distance `31,134 ms`, 2 gói NTP. |
| 7 | Quy trình chạy ổn định, lặp lại và kiểm tra tổng thể | Hoàn thành | ROS 2 chạy hơn 1 phút, host C++ nhận pin/IMU, board C++ đọc dịch vụ IMU; hai chu trình start/stop khôi phục UDP. Sau khi cài giới hạn 45 giây cho `snapd.apparmor.service`, một lần reboot phần mềm đưa SSH trở lại sau khoảng 25 giây. Script kiểm tra sau reboot thoát mã 0: UDP active/enabled, ROS 2 inactive/disabled, không còn `manual_composition`, NTP đồng bộ với `172.22.11.1`, offset `-524 µs`. |

**Mức độ hoàn thành đã kiểm chứng: 7/7 đầu việc = 100%.**

## Công việc đã hoàn thành

- Đánh giá VMX: Ethernet/SSH, Ubuntu 22.04, ROS 2 Humble, VMX HAL, G++ và CMake.
- Build mã ROS 2 Studica chính thức và các driver C++ riêng trên VMX; giữ dịch vụ `vmx-udp-lowlevel.service` hiện có.
- Thiết lập CycloneDDS giữa máy tính và VMX; kiểm chứng trao đổi topic hai máy.
- Build và thử node C++ nhận topic. Khi chạy trên board thật, `/battery_state` khoảng 12,07 V và `/imu` có frame `imu_link`; dịch vụ UDP hoạt động lại sau phép thử.
- Build client C++ dịch vụ IMU trên VMX và đọc góc thật bằng yêu cầu chỉ đọc. Phép thử ngày 04/11/2026 trả về pitch 1,63°, yaw 0,05°, roll -0,58°; pin 12,06 V. Sau đó `vmx-udp-lowlevel.service` ở trạng thái `active/running`, còn `manual_composition` đã dừng.
- Đồng hồ VMX đã được đưa từ 15/10/2026 về gần giờ ASUS ngày 04/11/2026 bằng một lần chỉnh thủ công; dịch vụ UDP được khởi động lại. Đã cài NTP drop-in ưu tiên `172.22.11.1` và giữ `ubuntu.local` làm nguồn thay thế.
- Đã cài `studica-ros2.service` ở trạng thái disabled; kiểm chứng nó từ chối khởi động khi NTP chưa đồng bộ và không dừng dịch vụ UDP.
- ASUS đã cài và bật Chrony, cho phép VMX `172.22.11.2` truy vấn UDP/123; profile `vmx-lowlevel-lan` lưu `172.22.11.1/24`. VMX báo `NTPSynchronized=yes` từ `172.22.11.1`, offset sau reboot `-524 µs`.
- `studica-ros2.service` chạy liên tục khoảng 1 phút 19 giây. Node C++ trên ASUS nhận pin 11,71–11,81 V và IMU `imu_link`; client C++ trên VMX trả pitch -1,46°, yaw -0,07°, roll -1,49°. Đã dừng và thử lại start/stop; kết quả cuối `Result=success`, UDP `active`, `manual_composition` đã dừng.
- Sau lần reboot đầu bị kẹt trước khi SSH chạy, người dùng cấp nguồn lại và SSH hoạt động. Nhật ký của boot lỗi kết thúc khi `snapd.apparmor.service` vừa bắt đầu; dịch vụ này nằm trước `sysinit.target` và trước SSH trong chuỗi khởi động. Đã cài drop-in giới hạn `TimeoutStartSec=45s`, kiểm tra `systemctl restart snapd.apparmor.service` trả `Result=success`.
- Một lần reboot phần mềm tiếp theo đưa SSH trở lại sau khoảng 25 giây. Ban đầu NTP chưa đồng bộ; khoảng một phút sau, timesyncd nhận `172.22.11.1`. `scripts/verify_board_after_reboot.sh` chạy lại thành công: UDP `active/enabled`, ROS 2 `inactive/disabled`, NTP `yes`, offset `-524 µs`, root distance `31,134 ms`.
- Đã khởi tạo Git cho workspace và đẩy 31 file nguồn/tài liệu lên repository riêng tư `phuctran-arch/vmx_ws`, nhánh `main`. Đã đối chiếu SHA commit đầu tiên `7b07692` giữa máy và GitHub. Các thư mục build, log và thư viện nhị phân `vendor/opt/` không nằm trong commit.
- Ngày 06/11/2026 đã kiểm chứng SSH qua Wi‑Fi `TTN_5G`: laptop `192.168.50.77`, VMX `192.168.50.220` qua `wlan0`, `vmx.local` phân giải đúng IP. Route đi qua `wlp45s0`, ping 3/3, TCP/22 mở, SSH đăng nhập thành công và host key khớp bản đã biết từ Ethernet. Chưa kiểm chứng ROS 2 qua Wi‑Fi.

## File đã tạo hoặc chỉnh sửa

- `README.md` (bổ sung lệnh SSH qua Wi‑Fi), `env.sh`, `config/params_method2.yaml`, `config/cyclonedds_host.xml`, `config/cyclonedds_board.xml`.
- `src/vmx_cpp_monitor/`, `src/vmx_comm/`, `scripts/check_board.sh`, `scripts/run_board_sensor_test.sh`.
- `board_src/vmx_cpp_imu_client/CMakeLists.txt`, `package.xml`, `src/read_imu.cpp`; script thử cảm biến đã bổ sung bước gọi client C++.
- `scripts/setup_host_ntp.sh`, `scripts/run_studica_ros2_mode.sh`, `scripts/verify_board_after_reboot.sh` (chờ NTP tối đa hai phút), `config/zz-vmx-local-timesyncd.conf`, `config/studica-ros2.service`, `config/snapd-apparmor-timeout.conf`.
- `patches/studica_private_driver.patch`, `vendor/SOURCES.md`, `vendor/apt_uris.txt`; thư viện CycloneDDS đã giải nén dưới `vendor/`.
- Trên VMX: `~/studica_ws/src/studica_control/CMakeLists.txt` được vá để dùng driver riêng; `~/studica_ws/src/vmx_cpp_imu_client/` đã build; `~/studica_ws/config/cyclonedds_board.xml` và `~/studica_ws/scripts/run_board_sensor_test.sh`.
- Trên ASUS: `/etc/chrony/conf.d/vmx.conf`; profile NetworkManager `vmx-lowlevel-lan` thêm địa chỉ cố định.
- Trên VMX: `/etc/systemd/timesyncd.conf.d/zz-vmx-local.conf`, `/etc/systemd/system/studica-ros2.service`, `/etc/systemd/system/snapd.apparmor.service.d/timeout.conf`, `/usr/local/sbin/run_studica_ros2_mode.sh` (root-owned), `~/studica_ws/scripts/run_studica_ros2_mode.sh` (bản nguồn), `~/studica_ws/config/snapd-apparmor-timeout.conf`.
- File này: `PROGRESS.md`.

## Đang thực hiện

Không còn đầu việc bắt buộc của bảy giai đoạn. Có thể tiếp tục theo dõi vài chu kỳ reboot để đánh giá độ ổn định của phần cứng. Theo mã nguồn Studica, `params="zero_yaw"` sẽ đặt lại yaw; client đã kiểm chứng dùng `params="read"` để chỉ đọc pitch, yaw, roll.

Đang chẩn đoán tình trạng màn hình ngoài không hiện hình trên Raspberry Pi 4 của VMX. Ngày 06/11, Ethernet có carrier, ping 3/3 và SSH thành công. Kernel đã nạp `vc4-kms-v3d`, GDM chạy và phiên X11 hoạt động. Lúc đầu cả hai cổng HDMI đều `disconnected` và EDID 0 byte; sau đó `card1-HDMI-A-2` chuyển sang `connected`, EDID 256 byte, `enabled=enabled`. X11 nhận màn hình `LEN L1950wD`, đang xuất 1920×1080 @ 60 Hz và DPMS báo `Monitor is On`. Chưa có xác nhận trực tiếp màn hình ngoài đã hiện giao diện hay vẫn báo không có tín hiệu.

## Lỗi hoặc vấn đề chưa giải quyết

- Lần reboot đầu ngày 04/11/2026 đã kẹt: VMX trả lời ping và mở TCP/53 nhưng SSH bị từ chối cho đến khi cấp nguồn lại. Nhật ký dừng ngay sau khi bắt đầu `snapd.apparmor.service`; đây là dấu hiệu nghi ngờ, **chưa chứng minh** Snap là nguyên nhân duy nhất. Drop-in 45 giây giới hạn thời gian kẹt tại bước này; một lần reboot phần mềm sau đó thành công, nhưng chưa đủ để khẳng định lỗi gián đoạn sẽ không lặp lại. Nếu lỗi tái diễn, cần console để xem trạng thái tại chỗ.
- Nguồn NTP ASUS chỉ khả dụng khi máy và Ethernet được bật; cấu hình `ubuntu.local` của AGX/Orin còn đó nhưng chưa được kiểm chứng trong kết nối hiện tại.
- Nguồn Raspberry Pi đang sụt áp và giảm xung: `sudo vcgencmd get_throttled` chuyển từ `0x50000` sang `0x50005`, giữ `0x50005` ở ba lần đo cách nhau khoảng 5 giây. Nhật ký kernel có nhiều dòng `Voltage normalised`. Cần kiểm tra nguồn cấp cho VMX/Pi; chưa chứng minh sụt áp là nguyên nhân duy nhất của việc màn hình không hiện hình.

## Công việc tiếp theo

1. Sau các lần reboot hoặc cấp nguồn sau này, chạy `~/vmx_ws/scripts/verify_board_after_reboot.sh` trên ASUS. Script tự chờ NTP tối đa hai phút trước khi kết luận.
2. Nếu VMX lại trả lời ping nhưng SSH từ chối, dùng màn hình/bàn phím để xem `systemctl status snapd.apparmor.service ssh --no-pager` và `journalctl -b -u snapd.apparmor.service -u ssh --no-pager` trước khi cấp nguồn lại.
3. Kiểm tra sau reboot ASUS khi có thể: Chrony tự chạy và Ethernet vẫn có `172.22.11.1/24`.
4. Với các thay đổi sau này trong `~/vmx_ws`, tạo commit và chạy `git push origin main` để đồng bộ repository GitHub.
5. Với lỗi HDMI, xác nhận trực tiếp màn hình `LEN L1950wD` đã hiện hình chưa. Ưu tiên kiểm tra nguồn VMX/Pi vì `0x50005` báo sụt áp hiện tại; kiểm tra đầu cắm nguồn, bộ nguồn/ắc quy và dây cấp nguồn. Nếu màn hình vẫn không có hình dù X11 đã xuất 1080p, kiểm tra đúng input, cáp micro-HDMI và thử cổng HDMI0. Chỉ thay đổi mode hiển thị khi đã có kết quả kiểm tra vật lý.
