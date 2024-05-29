#!/bin/sh

# Check root

if [ "$(id -u)" != "0" ]; then
	echo "You must be root to execute the script. Exiting."
	exit 1
fi

# update and upgrade
echo "Check system...."
sleep 1
case $(uname -m) in
x86_64)
	ARCH=amd64
	;;
amd64)
	ARCH=amd64
	;;
aarch64)
	ARCH=arm64
	;;
*)
	echo "This script does not support \"$(uname -m)\" CPU architecture. Exiting."
	exit 1
	;;
esac

if [ "$(uname -s)" != "Linux" ]; then
	echo "This script does not support \"$(uname -s)\" Operating System. Exiting."
	exit 1
fi

sleep 1
echo ""
echo "Ok here we go...."

# update and upgrade
echo "Update and upgrade"
sleep 1
sudo apt-get update -y ; sudo apt-get upgrade -y ; sudo apt autoremove -y

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
sed -i -e '/^\(#\|\)Port 22/s/^.*$/Port 2367/' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)PasswordAuthentication/s/^.*$/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)MaxAuthTries/s/^.*$/MaxAuthTries 2/' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)KbdInteractiveAuthentication/s/^.*$/KbdInteractiveAuthentication no/' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)ChallengeResponseAuthentication/s/^.*$/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)X11Forwarding/s/^.*$/X11Forwarding no/' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)AuthorizedKeysFile/s/^.*$/AuthorizedKeysFile .ssh\/authorized_keys/' /etc/ssh/sshd_config
sleep 1
echo ""
echo "restart SSH"
sleep 1
sudo sshd -t

sudo systemctl restart ssh
echo ""
echo "Ready installing SSH"
sleep 1
