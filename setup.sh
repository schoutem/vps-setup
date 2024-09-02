#!/usr/bin/env bash
# setup.sh
# Copyright 2024 schoutem. All rights reserved.

function header_info {
clear
cat <<"EOF"
__      _______   _____    _____      _               
\ \    / /  __ \ / ____|  / ____|    | |              
 \ \  / /| |__) | (___   | (___   ___| |_ _   _ _ __  
  \ \/ / |  ___/ \___ \   \___ \ / _ \ __| | | | '_ \ 
   \  /  | |     ____) |  ____) |  __/ |_| |_| | |_) |
    \/   |_|    |_____/  |_____/ \___|\__|\__,_| .__/ 
                                               | |    
                                               |_|    
EOF
}

echo -e "\n Loading..."

YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
BGN=$(echo "\033[4;92m")
GN=$(echo "\033[1;92m")
DGN=$(echo "\033[32m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD=" "
CM="${GREEN}>>${CL}"
CROSS="${RED}X${CL}"

set -e

#Function to display the progress bar
function pb {
# Usage:
# pb <length> <percentage> <title>
#
# Run a simple "echo" command any time to leave the progress bar

declare -i length=$1
declare -i percent=$2
title=$3
declare -i pop=length*percent/100
declare -i empty=length-pop
printf "$title ["
for (( i=0; i<=pop; i++ ))
do
    printf "#"
done
for (( i=0; i<empty; i++ ))
do
    printf " "
done
printf "]"
echo -n " $percent%"
printf "\r"
}

# Function to display the progress bar
function moment () {
  local duration=${1}
    
  already_done() { for ((done=0; done<$1; done++)); do printf "#"; done }
  remaining() { for ((remain=$1; remain<$duration; remain++)); do printf " "; done }
  percentage() { printf "| %s%%" $(( (($1)*100)/($duration)*100/100 )); }
  clean_line() { printf "\r"; }
 
  for (( current_duration=1; current_duration<=$duration; current_duration++ )); do
    already_done $current_duration
    remaining $current_duration
    percentage $current_duration
    clean_line
    sleep 1
  done
 
  clean_line
}

msg_ok() {
  printf "\e[?25h"
  local msg="$1"
  echo
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
  echo
}

# This function displays a error message with a red color.
msg_error() {
  printf "\e[?25h"
  local msg="$1"
  echo
  echo -e "${BFR} ${CROSS} ${RD}${msg}${CL}"
  echo
}

# This function displays an informational message with a yellow color.
msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}${CL}"
}

# This function displays continue
function cont {
echo
read -p " Press enter to continue..."
echo
}

#checkroot
function check_root() {
echo "Check root..."
sleep 2
if [[ "$(id -u)" -ne 0 || $(ps -o comm= -p $PPID) == "sudo" ]]; then
  msg_error "You must be root to execute the script. Exiting...."
	exit 1
 else
 echo
msg_ok "Yes you are root...."
  echo
fi
}
# End checkroot


function check_os()
{
hostnamectl
}

function nenchtest() {

echo -e  "${BFR} ${CM} ${GN}Start testing system....${CL}"
    echo
		(curl -s wget.racing/nench.sh | bash; curl -s wget.racing/nench.sh | bash) 2>&1 | tee nench.log
   sleep 2
   echo
   cont
}


function checkapp () {

 msg_ok "Installing required apps..."
  
apt-get install whiptail mc curl apt-transport-https nano software-properties-common systemd-timesyncd -y

msg_info "Update and upgrading your system..."

apt-get update && apt-get upgrade -y

apt clean && apt autoremove -y
   
   msg_ok "Done..."
}


function swapset () {
# does the swap file already exist?
grep -q "swapfile" /etc/fstab

# if not then create it
if [ $? -ne 0 ]; then
	echo 'swapfile not found. Adding swapfile.'
	fallocate -l ${swapsize}M /swapfile
	chmod 600 /swapfile
	mkswap /swapfile
	swapon /swapfile
	echo '/swapfile none swap defaults 0 0' >> /etc/fstab
else
	echo 'swapfile found. No changes made.'
fi

# output results to terminal
swapon --show
cat /proc/swaps
cat /proc/meminfo | grep Swap

msg_ok "Swapsize set done..."

}
#end swap

function nanoset () {
sed -i 's/[# ]*set tabsize 8/set tabsize 4/g' /etc/nanorc
sed -i -e '/^\(#\|\) set constantshow/s/^.*$/set constantshow/' /etc/nanorc
sed -i -e '/^\(#\|\) set linenumbers/s/^.*$/set linenumbers/' /etc/nanorc
sed -i -e '/^\(#\|\) set mouse/s/^.*$/set mouse/' /etc/nanorc
msg_ok "Nano set done..."
sleep 1
}

function timeset () {
#NTP server set
dpkg-reconfigure tzdata
timedatectl set-ntp true
timedatectl
msg_ok "NTP set done..."
}

function setssh () {

sed -i 's/[#]*PermitRootLogin yes/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)Port 22/s/^.*$/Port '$selport'/' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)PasswordAuthentication/s/^.*$/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)MaxAuthTries/s/^.*$/MaxAuthTries 2/' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)KbdInteractiveAuthentication/s/^.*$/KbdInteractiveAuthentication no/' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)ChallengeResponseAuthentication/s/^.*$/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)X11Forwarding/s/^.*$/X11Forwarding no/' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)AuthorizedKeysFile/s/^.*$/AuthorizedKeysFile .ssh\/authorized_keys/' /etc/ssh/sshd_config

msg_ok "SSH config set done ..."
}

function autoupdate () {

apt install unattended-upgrades update-notifier-common -y

#50auto-upgrades
sed -i 's/\/\/	 "${distro_id}:${distro_codename}";/	 "${distro_id}:${distro_codename}";/g' /etc/apt/apt.conf.d/50unattended-upgrades
sed -i 's/\/\/	 "${distro_id}:${distro_codename}-security";/	 "${distro_id}:${distro_codename}-security";/g' /etc/apt/apt.conf.d/50unattended-upgrades

sed -i 's/\/\/Unattended-Upgrade::AutoFixInterruptedDpkg "true";/Unattended-Upgrade::AutoFixInterruptedDpkg "true";/g' /etc/apt/apt.conf.d/50unattended-upgrades
sed -i 's/\/\/Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";/Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";/g' /etc/apt/apt.conf.d/50unattended-upgrades
sed -i 's/\/\/Unattended-Upgrade::Remove-New-Unused-Dependencies "true";/Unattended-Upgrade::Remove-New-Unused-Dependencies "true";/g' /etc/apt/apt.conf.d/50unattended-upgrades
sed -i 's/\/\/Unattended-Upgrade::Remove-Unused-Dependencies "false";/Unattended-Upgrade::Remove-Unused-Dependencies "true";/g' /etc/apt/apt.conf.d/50unattended-upgrades
sed -i 's/\/\/Unattended-Upgrade::Remove-New-Unused-Dependencies "true";/Unattended-Upgrade::Remove-New-Unused-Dependencies "true";/g' /etc/apt/apt.conf.d/50unattended-upgrades
sed -i 's/\/\/Unattended-Upgrade::Automatic-Reboot "false";/Unattended-Upgrade::Automatic-Reboot "true";/g' /etc/apt/apt.conf.d/50unattended-upgrades
sed -i 's/\/\/Unattended-Upgrade::Automatic-Reboot-Time "02:00";/Unattended-Upgrade::Automatic-Reboot-Time "03:00";/g' /etc/apt/apt.conf.d/50unattended-upgrades

#20auto-upgrades
sed -i -e '$a\'$'\n''APT::Periodic::AutocleanInterval "7";' /etc/apt/apt.conf.d/20auto-upgrades
sed -i 's/\/\/APT::Periodic::Update-Package-Lists "0";/APT::Periodic::Update-Package-Lists "1";/g' /etc/apt/apt.conf.d/20auto-upgrades
sed -i 's/\/\/APT::Periodic::Unattended-Upgrade "0";/APT::Periodic::Unattended-Upgrade "1";/g' /etc/apt/apt.conf.d/20auto-upgrades

read -p "Press enter to begin reconfigure..."
 dpkg-reconfigure -plow unattended-upgrades
 
sleep 1
echo
echo "Test it Out with a Dry Run..."
echo

unattended-upgrades --dry-run --debug

msg_ok "Auto update set done ..."
}

function setfirewall () {

apt install ufw -y

ufw disable
sleep 1

ufw default deny incoming
sleep 1
ufw default allow outgoing
sleep 1
ufw default deny outgoing

sleep 1

if [ -z "$selport" ];
then
ufw allow ssh
else
ufw allow $selport
fi

echo ""
echo "Set UFW port 123 (NTP)..."
ufw allow 123/udp

ufw allow OpenSSH
sleep 1
sudo ufw allow 80
sleep 1
sudo ufw allow 443
sleep 1
ufw enable
ufw status verbose

msg_ok "Firewall set done ..."
sleep 1
}

#######################################################################################

header_info
sleep 1
check_root
sleep 1

checkapp

msg_ok "This script works best on Ubuntu/Debian OS"

check_os

if whiptail --title "Benchmark test" --yesno "Do you want test your system with VPS benchmark script? (https://github.com/n-st/nench)" 10 100; then

nenchtest

else
echo "Cancel Benchmark test, start setup settings....."

sleep 2
fi

selport=$(whiptail --inputbox "Please enter your SSH port (example: 223 or 2355)" 10 100 3>&1 1>&2 2>&3)

swapsize=$(whiptail --title "Swapfile set" --menu "Choose an option" 18 100 10 \
  "512" "set to 512 MB size." \
  "1024" "set to 1024 MB size." \
  "2048" "set to 2048 MB size." \
  "4096" "set to 4096 MB size." \
  "6144" "set to 6144 MB size." 3>&1 1>&2 2>&3)

if [ -z "$swapsize" ]; then
  echo "No option was chosen (user hit Cancel)"
  echo
else
echo   "Swapsize $swapsize set"
fi

if whiptail --yesno "Your settings: SSH port: $selport, Swapsize: $swapsize \n\nCancel setup, select No." 10 100; then
msg_info "Start setup....."
moment 6
else
echo "Cancel setup....."
moment 6
  clear
  exit
fi

swapset

sleep 1

nanoset

sleep 1

timeset

sleep 1

setssh

sleep 1

autoupdate

sleep 1

setfirewall

if whiptail --title "Reboot" --yesno "VPS Setup setup ready, required reboot system?" 10 100; then

msg_ok "Roboot system ..."
moment 6
sshd -t
sleep 1
reboot
else
cont
fi
