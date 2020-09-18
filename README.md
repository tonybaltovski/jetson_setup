# jetson_setup
Simple script that makes all Clearpath specific changes to a vanilla Jetson to make it operate like our robot standard images.  Makes it work as a standard computer for Husky or Jackal.

## Supported Jetsons
* TX2 (Kinetic)
* Nano (Melodic)
* Xavier AGX (Melodic)
* Xavier NX (Melodic)

## Usage
```wget -c https://raw.githubusercontent.com/clearpathrobotics/jetson_setup/melodic/install.sh && chmod +x ./install.sh && ./install.sh```

## What it Does
* Add ROS sources and key
* Add Clearpath sources and key
* Installs apt-transport-https
* Installs ROS Husky/Jackal robot packages
* Sets up /etc/ros/setup.bash environment (standard with CP robots)
* Adds standard vim and screen config files
* Adds udev rules for microstrain, clearpath, hukuyo, ftdi, and startech
* Adds setup script for Husky and Jackal
* Unblocks bluetooth
