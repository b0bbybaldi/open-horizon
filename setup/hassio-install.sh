#!/bin/bash
if [[ $(whoami) != "root" ]]; then
  echo "Run as root"
  exit 1
fi
wget -qO - https://raw.githubusercontent.com/home-assistant/hassio-build/master/install/hassio_install > ./hassio_install.sh
chmod 755 ./hassio_install.sh

ARCH=$(uname -m)

# ARM Machine types
#    intel-nuc
#    odroid-c2
#    odroid-xu
#    orangepi-prime
#    qemuarm
#    qemuarm-64
#    qemux86
#    qemux86-64
#    raspberrypi
#    raspberrypi2
#    raspberrypi3
#    raspberrypi3-64
#    tinker

# Generate hardware options
case $ARCH in
    "i386" | "i686" | "x86_64")
        ARGS=""
    ;;
    "arm")
        ARGS="-m raspberrypi"
    ;;
    "armv6l")
        ARGS="-m raspberrypi2"
    ;;
    "armv7l")
        ARGS="-m raspberrypi3"
    ;;
    "aarch64")
        ARGS="-m aarch64"
    ;;
    *)
        echo "[Error] $ARCH unsupported by this script"
        exit 1
    ;;
esac

echo "[Info] installing pre-requisites"

# install pre-requisites
apt install -y \
    apparmor-utils \
    apt-transport-https \
    avahi-daemon \
    ca-certificates \
    curl \
    dbus \
    jq \
    network-manager \
    socat \
    software-properties-common 

echo "[Info] installing HASSIO with ${ARGS}"

./hassio_install.sh ${ARGS}

echo "[Info] copying YAML"

curl -sL "https://raw.githubusercontent.com/dcmartin/hassio-addons/master/horizon/homeassistant/configuration.yaml" -o /config/configuration.yaml
curl -sL "https://raw.githubusercontent.com/dcmartin/hassio-addons/master/horizon/homeassistant/automations.yaml" -o /config/automations.yaml
curl -sL "https://raw.githubusercontent.com/dcmartin/hassio-addons/master/horizon/homeassistant/groups.yaml" -o /config/groups.yaml
curl -sL "https://raw.githubusercontent.com/dcmartin/hassio-addons/master/horizon/homeassistant/ui-lovelace.yaml" -o /config/ui-lovelace.yaml

