import rclpy
from rclpy.node import Node
from std_msgs.msg import String


class Subscriber(Node):
    def __init__(self):
        super().__init__('hello_subscriber')
        self.subscription = self.create_subscription(String, 'chatter', self.receive, 10)

    def receive(self, message):
        self.get_logger().info(f'Received: {message.data}')


def main(args=None):
    rclpy.init(args=args)
    node = Subscriber()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        if rclpy.ok():
            rclpy.shutdown()
