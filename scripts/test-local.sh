#!/usr/bin/env bash
set -Eeuo pipefail
# shellcheck source=scripts/test-common.sh
source "$(dirname "$0")/test-common.sh"
echo '[1/6] 環境・Python'
cat /etc/os-release
# shellcheck source=/dev/null
source /etc/os-release
[[ $ID == ubuntu && $VERSION_ID == 22.04 ]]
[[ $ROS_DISTRO == humble ]]
[[ $(uname -m) == x86_64 || $(uname -m) == aarch64 ]]
uname -m
python3 --version
python3 -c 'import sys; assert sys.version_info[:2] == (3, 10); import rclpy; from PyQt5 import QtWidgets, QtSvg; print("rclpy / Qt OK")'
timeout 10 ros2 --help
echo '[2/6] メッセージ型'
for type in std_msgs/msg/String geometry_msgs/msg/Twist sensor_msgs/msg/Joy raspimouse_msgs/msg/LightSensors; do
    timeout 10 ros2 interface show "$type"
done
echo '[3/6] C++ talker → Python listener'
start_node demo-listener ros2 run demo_nodes_py listener --ros-args -r "__ns:=$namespace"
start_node demo-talker ros2 run demo_nodes_cpp talker --ros-args -r "__ns:=$namespace"
wait_message demo-listener 'I heard: [Hello World:'
echo '[4/6] 一時ワークスペースでcolcon build'
mkdir -p "$work/ws/src"
cp -a "$repo/tests/fixtures/hello" "$work/ws/src/"
cd "$work/ws"
timeout --kill-after=5 120 colcon build --event-handlers console_direct+ >"$work/build.log" 2>&1
set +u
# shellcheck source=/dev/null
source install/setup.bash
set -u
echo '[5/6] console_scripts / ros2 run / Publisher・Subscriber'
start_node hello-listener ros2 run hello subscriber --ros-args -r "__ns:=${namespace}_run"
start_node hello-talker ros2 run hello publisher --ros-args -r "__ns:=${namespace}_run"
wait_message hello-listener 'Received: Hello ROS 2'
echo '[6/6] Python Launch / ros2 launch'
timeout 10 ros2 launch hello hello.launch.py --show-args
start_node hello-launch ros2 launch hello hello.launch.py "namespace:=${namespace}_launch"
wait_message hello-launch 'Received: Hello ROS 2'
echo 'PASS: test-local'
