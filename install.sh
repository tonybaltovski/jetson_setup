#!/bin/bash -eu

#set -x

echo "Starting ROS installion for Jetson"

# Get Ubuntu version
ubuntu_version=`lsb_release -sc`

echo ""
echo "Checking your Ubuntu version"
echo "Detected Ubuntu: $ubuntu_version"

case $ubuntu_version in
  "xenial" )
    ros_distro="kinetic"
  ;;
  "bionic" )
    ros_distro="melodic"
  ;;
  *)
    echo "ERROR: Unsupported Ubuntu version"
    exit 0
esac

echo "Ubuntu ${ubuntu_version} is supported, proceeding to install ROS ${ros_distro}"

echo ""
echo "Which computing platform are you installing?"
echo "[1] Nvidia Jetson Nano"
echo "[2] Nvidia Jetson Xavier NX"
echo "[3] Nvidia Jetson AGX Xavier"
echo "[4] Nvidia Jetson TX2"

read -p "Enter your selection (Default is 1):" answer
case "$answer" in
  1)
    compute_type="jetson-nano"
    ;;
  2)
    compute_type="jetson-xavier-nx"
    ;;
  3)
    compute_type="jetson-xavier-agx"
    ;;
  4)
    compute_type="jetson-tx2"
    ;;
  * )
    compute_type="jetson-nano"
    ;;
esac

echo "Selected ${compute_type}."
echo ""

echo "Which robot are you installing?"
echo "[1] Clearpath Husky"
echo "[2] Clearpath Jackal"

read -p "Enter your selection (Default is 1):" answer
case "$answer" in
  1)
    platform="husky"
    ;;
  2)
    platform="jackal"
    ;;
  * )
    platform="husky"
    ;;
esac

echo "Selected ${platform}."
echo ""
echo "Summary: Installing ROS ${ros_distro} on ${compute_type} in ${platform}"


echo ""
echo "Step 1: Configuring Ubuntu repositories."
echo ""

sudo add-apt-repository -y universe
sudo add-apt-repository -y restricted
sudo add-apt-repository -y multiverse
sudo apt-get install -qq -y nano bash-completion git apt-utils apt-transport-https

echo ""
echo "Done: Configuring Ubuntu repositories."
echo ""


echo "Step 2: Setup your apt sources"
echo ""

# Check if ROS sources are already installed
if [ -e /etc/apt/sources.list.d/ros-latest.list ]; then
  echo "Warn: ROS sources exist, skipping"
else
  sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
  sudo apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654
  # Check if sources were added
  if [ ! -e /etc/apt/sources.list.d/ros-latest.list ]; then
    echo "Error: Unable to add ROS sources, exiting}"
    exit 0
  fi
fi

# Check if CPR sources are already installed
if [ -e /etc/apt/sources.list.d/clearpath-latest.list ]; then
  echo "Warn: CPR sources exist, skipping"
else
  wget https://packages.clearpathrobotics.com/public.key -O - | sudo apt-key add -
  sudo sh -c 'echo "deb https://packages.clearpathrobotics.com/stable/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/clearpath-latest.list'
  # Check if sources were added
  if [ ! -e /etc/apt/sources.list.d/clearpath-latest.list ]; then
    echo "Error: Unable to add CPR sources, exiting}"
    exit 0
  fi
fi

echo "Done: Setup your apt sources"
echo ""

echo "Step 3: Updating packages"
echo ""
sudo apt -y -qq update
sudo apt -y -qq dist-upgrade
echo "Done: Updating packages"
echo ""

echo "Step 4: Installing ROS prerequisites"
echo ""
sudo apt install -qq -y python-rosdep python-rosinstall python-rosinstall-generator python-wstool build-essential
echo "Done: Installing ROS prerequisites"
echo ""

echo "Step 5: Installing ${platform} packages"
echo ""
sudo apt -qq -y ros-${ros_distro}-${platform}-robot
echo "Done: Installing ${platform} packages"
echo ""

echo "Step 6: Configuring Robot environment"
echo ""
sudo mkdir -p /etc/ros
sudo wget -O /etc/profile.d/clearpath-ros-environment.sh https://raw.githubusercontent.com/clearpathrobotics/jetson_setup/melodic/files/clearpath-ros-environment.sh
sudo wget -O /etc/ros/setup.bash https://raw.githubusercontent.com/clearpathrobotics/jetson_setup/melodic/files/setup.bash
echo "source /opt/ros/$(ros_distro)/setup.bash" >> $HOME/.bashrc
echo "Done: Configuring Robot environment"
echo ""

echo "Step 7: Configuring rosdep"
echo ""
sudo rosdep init
sudo wget https://raw.githubusercontent.com/clearpathrobotics/public-rosdistro/master/rosdep/50-clearpath.list -O /etc/ros/rosdep/sources.list.d/50-clearpath.list
rosdep update
echo "Done: Configuring rosdep"
echo ""

echo "Step 8: Configuring udev rules"
echo ""
sudo wget -O /etc/udev/rules.d/10-microstrain.rules https://raw.githubusercontent.com/clearpathrobotics/jetson_setup/melodic/files/10-microstrain.rules
sudo wget -O /etc/udev/rules.d/41-clearpath.rules https://raw.githubusercontent.com/clearpathrobotics/jetson_setup/melodic/files/41-clearpath.rules
sudo wget -O /etc/udev/rules.d/41-hokuyo.rules https://raw.githubusercontent.com/clearpathrobotics/jetson_setup/melodic/files/41-hokuyo.rules
sudo wget -O /etc/udev/rules.d/41-gamepad.rules https://raw.githubusercontent.com/clearpathrobotics/jetson_setup/melodic/files/41-gamepad.rules
sudo wget -O /etc/udev/rules.d/52-ftdi.rules https://raw.githubusercontent.com/clearpathrobotics/jetson_setup/melodic/files/52-ftdi.rules
sudo wget -O /etc/udev/rules.d/60-startech.rules https://raw.githubusercontent.com/clearpathrobotics/jetson_setup/melodic/files/60-startech.rules
echo "Done: Configuring udev rules"
echo ""

echo "Step 9: Configuring system configs"
echo ""
wget -O $HOME/.screenrc https://raw.githubusercontent.com/clearpathrobotics/jetson_setup/melodic/files/.screenrc
wget -O $HOME/.vimrc https://raw.githubusercontent.com/clearpathrobotics/jetson_setup/melodic/files/.vimrc
echo "Done: Configuring system configs"
echo ""

echo "Step 10: Configuring ${platform}"
echo ""
source /etc/ros/setup.bash
if [ "platform" == "jackal" ]; then
  sudo sh -c 'echo export JACKAL_WIRELESS_INTERFACE=wlan0 >> /etc/ros/setup.bash'
fi
rosrun ${platform}_bringup install
echo "Done: Configuring ${platform}"
echo ""

echo "Step 11: Configuring Bluetooth"
echo ""
sudo apt install -qq -y bluez bluez-tools
echo "Done: Configuring Bluetooth"
echo ""

echo "Step 12: Removing unused packages"
echo ""
sudo apt-get -y autoremove
echo "Done: Removing unused packages"
echo ""

echo "Step 13: Verifying install"
echo ""
if [ "$ros_distro" == `rosversion -d` ]; then
    echo "Done: Verifying install"
else
    echo "Warn: Verifying install might not be complete"
fi
echo ""

echo "Done: Installing ROS ${ros_distro} on ${compute_type} in ${platform}"
