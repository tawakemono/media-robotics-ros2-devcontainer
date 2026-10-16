FROM ros:humble-ros-base-jammy

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ros-humble-desktop \
    ros-humble-demo-nodes-cpp ros-humble-demo-nodes-py \
    ros-humble-rqt-graph ros-humble-rqt-image-view \
    ros-humble-raspimouse-msgs ros-humble-joy \
    python3-colcon-common-extensions python3-rosdep python3-pip \
    python3-venv python3-setuptools \
    git build-essential sudo curl ca-certificates \
    xvfb x11vnc novnc websockify fluxbox x11-utils libgl1-mesa-dri \
    procps util-linux iproute2 \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --shell /bin/bash student \
    && echo 'student ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/student \
    && chmod 0440 /etc/sudoers.d/student \
    && mkdir -p /home/student/ros2_ws \
    && chown student:student /home/student/ros2_ws \
    && printf '\nsource /opt/ros/humble/setup.bash\nif [ -f /home/student/ros2_ws/install/setup.bash ]; then\n  source /home/student/ros2_ws/install/setup.bash\nfi\n' >> /home/student/.bashrc

ENV ROS_DOMAIN_ID=0 \
    ROS_LOCALHOST_ONLY=1 \
    RMW_IMPLEMENTATION=rmw_fastrtps_cpp \
    DISPLAY=:99 \
    QT_X11_NO_MITSHM=1 \
    LIBGL_ALWAYS_SOFTWARE=1
USER student
WORKDIR /home/student/ros2_ws
CMD ["sleep", "infinity"]
