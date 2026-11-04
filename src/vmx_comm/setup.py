from setuptools import find_packages, setup


setup(
    name="vmx_comm",
    version="0.1.0",
    packages=find_packages(exclude=["test"]),
    data_files=[
        ("share/ament_index/resource_index/packages", ["resource/vmx_comm"]),
        ("share/vmx_comm", ["package.xml"]),
    ],
    install_requires=["setuptools"],
    zip_safe=True,
    maintainer="VMX workspace maintainer",
    maintainer_email="maintainer@example.com",
    description="Read-only ROS 2 monitor for a Studica VMX board.",
    license="Apache-2.0",
    entry_points={"console_scripts": ["monitor = vmx_comm.monitor:main"]},
)
