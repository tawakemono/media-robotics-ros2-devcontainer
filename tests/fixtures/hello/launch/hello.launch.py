from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node


def generate_launch_description():
    namespace = LaunchConfiguration('namespace')
    return LaunchDescription([
        DeclareLaunchArgument('namespace', default_value='hello'),
        Node(package='hello', executable='publisher', namespace=namespace, output='screen'),
        Node(package='hello', executable='subscriber', namespace=namespace, output='screen'),
    ])
