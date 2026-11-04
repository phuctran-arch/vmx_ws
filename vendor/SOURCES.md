# CycloneDDS libraries for the host

The `vendor/opt/ros/humble` tree was extracted from seven amd64 Debian packages without installing them into the host OS. Package URLs, versions, sizes, and MD5 checksums from `apt-get --print-uris` are recorded in [apt_uris.txt](apt_uris.txt); every downloaded package matched its checksum before extraction.

Packages: `ros-humble-rmw-cyclonedds-cpp`, `ros-humble-cyclonedds`, `ros-humble-iceoryx-binding-c`, `ros-humble-iceoryx-hoofs`, `ros-humble-iceoryx-posh`, `libacl1-dev`, and `libattr1-dev`.

The package sources are the [official ROS 2 apt repository](http://packages.ros.org/ros2/ubuntu/) and [Ubuntu archive](http://vn.archive.ubuntu.com/ubuntu/). `env.sh` adds only this vendor prefix to the ROS runtime library and ament search paths. If CycloneDDS is later installed system-wide, `env.sh` uses the system package instead.
