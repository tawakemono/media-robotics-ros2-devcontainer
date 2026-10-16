"""rqt_image_viewを確認するためのダミー画像。実機を使用しない。"""
import rclpy
from rclpy.node import Node
from sensor_msgs.msg import Image

rclpy.init()
node = Node('test_image_publisher')
publisher = node.create_publisher(Image, '/test_image', 10)


def publish():
    image = Image()
    image.header.stamp = node.get_clock().now().to_msg()
    image.height = 120
    image.width = 160
    image.encoding = 'rgb8'
    image.step = image.width * 3
    image.data = bytes([40, 180, 90]) * image.width * image.height
    publisher.publish(image)


timer = node.create_timer(0.2, publish)
try:
    rclpy.spin(node)
except KeyboardInterrupt:
    pass
finally:
    node.destroy_node()
    if rclpy.ok():
        rclpy.shutdown()
