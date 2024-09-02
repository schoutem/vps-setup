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
  
apt-get install whiptail curl apt-transport-https nano software-properties-common systemd-timesyncd -y

msg_info "Update and upgrading your system..."
echo

apt-get update && apt-get upgrade -y

msg_info "clean your system..."
echo

apt clean && apt autoremove -y
echo   
msg_ok "Done..."
}




#swap set

removeSwap() {
    msg_ok "Will remove swap and backup fstab."
    echo ""

    #get the date time to help the scripts
    backupTime=$(date +%y-%m-%d--%H-%M-%S)

    #get the swapfile name
    swapSpace=$(swapon -s | tail -1 |  awk '{print $1}' | cut -d '/' -f 2)
    #debug: echo $swapSpace

    #turn off swapping
    swapoff /$swapSpace

    #make backup of fstab
    cp /etc/fstab /etc/fstab.$backupTime
    
    #remove swap space entry from fstab
    sed -i "/swap/d" /etc/fstab

    #remove swapfile
    rm -f "/$swapSpace"

    echo ""
    echo "--> Done"
    echo ""
}

#spinner by: https://www.shellscript.sh/tips/spinner/
setupSwapSpinner() {
  spinner="/|\\-/|\\-"
  while :
  do
    for i in `seq 0 7`
    do
      echo -n "${spinner:$i:1}"
      echo -en "\010"
      sleep 1
    done
  done
}

#identifies available ram, calculate swap file size and configure
createSwap() {
    msg_ok "Will create a swap and setup fstab."
    echo ""

    #get available physical ram
    availMemMb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    #debug: echo $availMemMb
    
    #convert from kb to mb to gb
    gb=$(awk "BEGIN {print $availMemMb/1024/1204}")
    #debug: echo $gb
    
    #round the number to nearest gb
    gb=$(echo $gb | awk '{print ($0-int($0)<0.499)?int($0):int($0)+1}')
    #debug: echo $gb

    msg_ok "-> Available Physical RAM: $gb Gb"
    echo ""
    if [ $gb -eq 0 ]; then
        echo "Something went wrong! Memory cannot be 0!"
        exit 1;
    fi

    if [ $gb -le 2 ]; then
        echo "   Memory is less than or equal to 2 Gb"
        let swapSizeGb=$gb*2
        msg_ok "   -> Set swap size to $swapSizeGb Gb"
    fi
    if [ $gb -gt 2 -a $gb -lt 32 ]; then
        msg_ok "   Memory is more than 2 Gb and less than to 32 Gb."
        let swapSizeGb=4+$gb-2
        msg_ok "   -> Set swap size to $swapSizeGb Gb."
    fi
    if [ $gb -gt 32 ]; then
        msg_ok "   Memory is more than or equal to 32 Gb."
        let swapSizeGb=$gb
        msg_ok "   -> Set swap size to $swapSizeGb Gb."
    fi
    echo ""

    msg_ok "Creating the swap file! This may take a few minutes."
    echo ""

    #implement swap file

    #start the spinner:
    setupSwapSpinner &
    
    #make a note of its Process ID (PID):
    SPIN_PID=$!
    
    #kill the spinner on any signal, including our own exit.
    trap "kill -9 $SPIN_PID" `seq 0 15`

    #convert gb to mb to avoid error: dd-memory-exhausted-by-input-buffer-of-size-bytes
    let mb=$gb*1024

    #create swap file on root system and set file size to mb variable
    msg_ok "-> Create swap file."
    echo ""
    dd if=/dev/zero of=/swapfile bs=1M count=$mb

    #set read and write permissions
    msg_ok "-> Set swap file permissions."
    echo ""
    chmod 600 /swapfile

    #create swap area
    msg_ok "-> Create swap area."
    echo ""
    mkswap /swapfile

    #enable swap file for use
    echo "-> Turn on swap."
    echo ""
    swapon /swapfile

    echo ""

    #update the fstab
    if grep -q "swap" /etc/fstab; then
        echo "-> The fstab contains a swap entry."
        #do nothing
    else
        echo "-> The fstab does not contain a swap entry. Adding an entry."
        echo "/swapfile swap swap defaults 0 0" >> /etc/fstab    
    fi

    echo ""
    echo "--> Done"
    echo ""

}

#the main function that is run by the calling script.
function setupSwapMain() {
    #check if swap is on
    isSwapOn=$(swapon -s | tail -1)

    if [[ "$isSwapOn" == "" ]]; then
        msg_ok "No swap has been configured! Will create."
        echo ""

        createSwap
    else
        msg_ok "Swap has been configured. Will remove and then re-create the swap."
        echo ""
        
        removeSwap
        createSwap
    fi

    msg_ok "Setup swap complete! Check output to confirm everything is good."
}

# output results to terminal
swapon --show
cat /proc/swaps
cat /proc/meminfo | grep Swap

msg_ok "Swapsize set done..."


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

if whiptail --title "Swapset" --yesno "Set Swap file? \n\nSet the swap size using the following guidelines:\n
less than 2 Gb RAM = swap size: 2 x the amount of RAM\n
more than 2 GB RAM = but less than 32 GB, swap size: 4 GB + (RAM = 2 GB)\n
32 GB of RAM or more = swap size: 1 x the amount of RAM\n" 20 100; 

then

setupSwapMain
kill -9 $SPIN_PID
else
echo "Cancel Swapfiles set, start setup settings....."

sleep 2
fi

if whiptail --yesno "Your settings: SSH port: $selport, Swapsize: auto \n\nCancel setup, select No." 10 100; then
msg_info "Start setup....."
echo

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

msg_ok "Reboot system ..."

sshd -t
sleep 1
reboot
else
cont
fi


else
echo "Cancel setup....."

echo
  clear
  exit
fi

