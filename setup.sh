#!/bin/bash

set -e

if [ "$(id -u)" != "0" ]; then
	echo -e "\033[31m You must be root to execute the script. Exiting....\033[0m"
	exit 1
fi

 #Check swap excist
 if [[ $(swapon -s | grep -ci "/dev" ) -gt 0 ]] ;
 then echo -e "\033[32m No swapfile found, ok \033[0m" ;
 else echo -e "\033[31m Swapfile excis remove the swap file first...\033[0m" ;
 echo "Get script: wget https://raw.github.com/schoutem/vps-setup/master/rm_swap.sh";
 read -p "Press enter to continue"
 exit 1
 fi

#swapfile set
# Get total available memory in bytes
total_memory=$(grep MemTotal /proc/meminfo | awk '{print $2 * 1024}')
 
# Function to create and enable swap file
create_swap() {
  local size=$1
  local swapfile="/swapfile"
 
  # Create swap file with the specified size
  sudo fallocate -l "$size" "$swapfile"
 
  # Set permissions
  sudo chmod 600 "$swapfile"
 
  # Make it a swap file
  sudo mkswap "$swapfile"
 
  # Enable swap
  sudo swapon "$swapfile"
 
  # Add swap file to /etc/fstab for auto-mount
  echo "$swapfile none swap sw 0 0" | sudo tee -a /etc/fstab
 
  echo "Swap file created and enabled successfully."
}
 
echo "Choose an option:"
echo "1. Double the system memory"
echo "2. Set custom size (in GB)"
echo "3. Exit"
 
read -p "Enter your choice (1/2/3): " choice
 
case $choice in
  1)
    # Double the system memory
    swap_size=$((total_memory * 2))
    ;;
  2)
    read -p "Enter custom size in **GB**: " custom_size
    # Convert to bytes
    swap_size=$((custom_size * 1024 * 1024 * 1024))
    ;;
  3)
    echo "Exiting..."
    exit 0
    ;;
  *)
    echo "Invalid option, exiting..."
    exit 1
    ;;
esac
#End setting swapfile

#Specify settings
echo "Which port do you want to use for SHH?"
read -r selport
echo "Entered port: $selport"

PS3="Choose your packet manager (APT or NALA): "
echo 
select pm in "apt" "nala"; do
  echo
  echo "Choosen manager ${pm}"
  echo
  break
done
read -p pm

echo "Your settings are: port $selport and the chosen packetmanager $pm"

sleep 2
echo
echo "Ok here we go...."

# update and upgrade
echo "Update and upgrade"
sleep 1
sudo apt update -y
sudo apt upgrade -y

# install software
echo
echo "install packages"
sleep 1
if [ "$pm" = "nala" ] ; then
	echo "Installing nala...."
	sudo apt install nala -y
fi
sleep 1
sudo $pm install mc curl apt-transport-https ntp nano software-properties-common -y

#Create swapfile
echo "Create swapfile"
create_swap "$swap_size"
sleep 1
echo "Done..."

# set time
sleep 1
echo
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
echo
echo "Restart SSH..."
sleep 1
sudo sshd -t

sudo systemctl restart ssh
echo
echo "Ready installing, SHH port is set to $selport and choosen packetmanager is $pm"
sleep 1

# Function reboot
function confirm() {
    while true; do
        read -p "Do you want to reboot system? (YES/NO/CANCEL or y/n/c)" yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            [Cc]* ) exit;;
            * ) echo "Please answer YES, NO, or CANCEL.";;
        esac
    done
}

if confirm; then
    echo "Reboot system...."
	sleep 1
	sudo reboot
else
    echo "Aborting the reboot..."
fi
