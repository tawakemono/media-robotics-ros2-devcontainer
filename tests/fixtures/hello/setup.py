from glob import glob

from setuptools import setup

setup(
    name='hello',
    version='0.0.1',
    packages=['hello'],
    data_files=[
        ('share/ament_index/resource_index/packages', ['resource/hello']),
        ('share/hello', ['package.xml']),
        ('share/hello/launch', glob('launch/*.launch.py')),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='ROS 2 Lab maintainers',
    maintainer_email='maintainers@example.invalid',
    description='実験用の最小Publisher・SubscriberとLaunch',
    license='Apache-2.0',
    entry_points={'console_scripts': [
        'publisher = hello.publisher:main',
        'subscriber = hello.subscriber:main',
    ]},
)
