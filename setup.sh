#!/bin/bash

#Specify settings
echo "Which port do you want to use for SHH?"
read -r selport
echo "Entered port: $selport"

read -r "Please enter your packet manager (NALA or APT)? " pm

case "$pm" in
	"apt")
		echo "default packet manager"
	;;
	"nala")
		echo "a free, open source alternative front-end to APT"
	;;
	*)
	;;
esac

echo "Your settings are: port $selport and the chosen packetmanager $pm"

sleep 2
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

# set time
sleep 1
echo ""
echo "Tijd naar Nederlands zetten"
timedatectl set-timezone "Europe/Amsterdam"
sleep 1
echo ""
echo "Check..."
systemctl status ntpd
sleep 1

#set SSH
echo "Set SHH..."
sed -i 's/[#]*PermitRootLogin yes/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)Port 22/s/^.*$/Port '$selport'/' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)PasswordAuthentication/s/^.*$/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)MaxAuthTries/s/^.*$/MaxAuthTries 2/' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)KbdInteractiveAuthentication/s/^.*$/KbdInteractiveAuthentication no/' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)ChallengeResponseAuthentication/s/^.*$/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)X11Forwarding/s/^.*$/X11Forwarding no/' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)AuthorizedKeysFile/s/^.*$/AuthorizedKeysFile .ssh\/authorized_keys/' /etc/ssh/sshd_config
sleep 1
echo ""
echo "Restart SSH and set port to $selport"
sleep 1
sudo sshd -t

sudo systemctl restart ssh
echo ""
echo "Ready installing SSH"
sleep 1
