#!/bin/bash

sleep 1
echo ""
echo "Ok here we go...."

# update and upgrade
echo "Update and upgrade"
sleep 1
sudo apt update -y
sudo apt upgrade -y

# install software
echo ""
echo "install packages"
sleep 1
sudo apt install nala -y
sleep 1
sudo nala install mc curl apt-transport-https ntp nano software-properties-common -y
