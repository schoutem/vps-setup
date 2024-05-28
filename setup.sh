#!/bin/sh

set -e

echo "Install and set VPS script."

# update and upgrade
echo "Update and upgrade"
sleep 1
sudo apt-get update -y ; sudo apt-get upgrade -y ; sudo apt autoremove -y

# install software
echo "install packages"
sleep 1
sudo apt install nala -y
sleep 1
sudo nala install mc curl apt-transport-https ntp nano software-properties-common -y

# set time
sleep 1
echo "Tijd naar Nederlands zetten"
timedatectl set-timezone "Europe/Amsterdam"
sleep 1
echo "Check..."
systemctl status ntpd
sleep 3
