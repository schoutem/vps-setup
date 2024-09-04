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
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}\n\n"
}

# This function displays a error message with a red color.
msg_error() {
  printf "\e[?25h"
  local msg="$1"
  echo
  echo -e "${BFR} ${CROSS} ${RD}${msg}${CL}\n\n"
}

# This function displays an informational message with a yellow color.
msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}${CL}\n\n"
}

# This function displays continue
function cont() {
echo
read -p " Press enter to continue..."
echo
}

function waiting() {
sleep 2 & PID=$! #simulate process

printf "\n["
# While process is running...
while kill -0 $PID 2> /dev/null; do 
    printf  "█"
    sleep 0.08
done
printf "]\n\n"
}

#checkroot
function check_root() {

echo "Check root..."
waiting
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

function check_os() {
. /etc/os-release
if [ "$ID" == "ubuntu" ]; then   
  echo "Ubuntu detected" 
  echo
  hostnamectl
else
  if [ "$ID" == "debian" ]; then   
    echo "debian Linux detected" 
    echo
    hostnamectl
    else   
       echo "Unknown OS unsupported detected"
       sleep 4
echo
echo "Cancel setup..."
clear
exit 1;
    fi
  fi
}

function sshceck() {
echo -e "${RD}"
echo "You must first set and Generating an SSH key!"
echo
read -p "Setup SHH key? (y)Yes/(n)No/(c)Cancel:- " keychoice
echo -e "${CL}\n\n"

case $keychoice in
[yY]* ) msg_ok "Ok, we will proceed" 

pubkey

;;
[nN]* ) msg_info "Cancel generating SSH key..." ;;
[cC]* ) msg_error "Installation cancelled";
waiting
echo
clear
exit;;
*) exit ;;
esac
}

function pubkey() {

DIR="$HOME/.ssh/"
if [ -d "$DIR" ]; then
  echo
  echo "Check dir ${DIR} excist, setup ssh key..."
  echo
else
  echo "Error: ${DIR} not found. Create .ssh folder...."
  
  mkdir -p $HOME/.ssh && sudo touch $HOME.ssh/authorized_keys
  chmod 700 $HOME/.ssh && sudo chmod 600 $HOME/.ssh/authorized_keys
  chown -R root:root $HOME/.ssh
 
fi
sleep 1
ssh-keygen -t rsa
sleep 1
echo -e "${BL}"
echo "Dowload your id_rsa file from folder .ssh to your desktop folder..."
echo -e "${CL}\n\n"
echo
read -p " Press enter to copy your key to .ssh/authorized_keys..."

cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

echo

echo "Done....."
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

msg_info "Update and upgrading your system..."
echo

apt-get update && apt-get upgrade -y

msg_info "clean your system..."
echo

apt clean && apt autoremove -y
echo   

#. /etc/os-release
#if [ "$ID" == "ubuntu" ]; then     
apt-get install curl openssl apt-transport-https nano software-properties-common systemd-timesyncd unattended-upgrades update-notifier-common -y
#else
#apt-get install curl apt-transport-https nano unattended-upgrades apt-listchanges systemd-timesyncd -y
#fi
msg_ok "Done..."
}

#swap set
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
 
waiting
echo
msg_ok "Test it Out with a Dry Run..."
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
msg_ok "Set UFW port 123 (NTP)..."
ufw allow 123/udp

ufw allow OpenSSH
sleep 1
sudo ufw allow 80
sleep 1
sudo ufw allow 443
sleep 1


msg_ok "Firewall set done ..."
sleep 1
}

function check() {
   msg_ok "Config SHH and port set $selport"; sleep 1;
   msg_ok "Swap set"; sleep 1;
   msg_ok "Timezone set"; sleep 1;
   msg_ok "Nano set"; sleep 1;
   msg_ok "Install unattended-upgrades set"; sleep 1;
   msg_ok "20 auto-upgrades set"; sleep 1;
   msg_ok "Update and upgrades"; sleep 1;
   msg_ok "Firewall set"; sleep 1;
}

#######################################################################################

header_info

check_root

checkapp

msg_ok "This script works best on Ubuntu/Debian OS"

check_os

sshceck

echo -e "${BL}"
read -p "Do you want test your system with VPS benchmark script? (https://github.com/n-st/nench)? (y)Yes/(n)No/(c)Cancel:- " nenchchoice
echo -e "${CL}\n\n"
case $nenchchoice in
[yY]* ) msg_ok "Ok, we will proceed" 
msg_info "starting test...."
waiting
nenchtest
;;
[nN]* ) msg_info "Cancel Benchmark test, start setup settings..." ;;
[cC]* ) msg_error "Installation cancelled";
waiting
echo
clear
exit;;
*) exit ;;
esac

selport="22"
echo -e "${BL}"
read -e -i "$selport" -p "Please enter your SSH port (example: 223 or 2355, enter for default 22) " input
echo -e "${CL}\n\n"
selport="${input:-$selport}"

msg_ok "-> Ok your selecting port is $selport"
waiting

if [[ $(swapon -s | grep -ci "/dev" ) -gt 0 ]] ;
then

echo
msg_ok "-> Ok Swapfile found, no changes"
echo

else 

echo
echo "Swapfile not found, create one?"
echo "Set the swap size using the following guidelines:"
echo
echo "Less than 2 Gb RAM -> swap size: 2 x the amount of RAM"
echo "More than 2 GB RAM -> but less than 32 GB, swap size: 4 GB + (RAM = 2 GB)"
echo "32 GB of RAM or more -> swap size: 1 x the amount of RAM"
echo

echo -e "${BL}"
read -p "Set Swap file? (y)Yes/(n)No/(c)Cancel:- " choice
echo -e "${CL}\n\n"

case $choice in
[yY]* ) msg_ok "Ok,starting...." 
setupSwapMain
kill -9 $SPIN_PID
;;
[nN]* ) msg_info "Canceling no changes, proceed setup.." ;;
[cC]* ) msg_error "Installation cancelled";
exit;;
*) exit ;;
esac

fi

waiting

nanoset

waiting

timeset

waiting

setssh
  
waiting

autoupdate

waiting

setfirewall

waiting

check

echo -e "${BL}"
read -p "VPS Setup setup ready, required reboot system? (y)Yes/(n)No/(c)Cancel:- " rebootchoice
echo -e "${CL}\n\n"

# giving choices there tasks using
case $rebootchoice in
[yY]* ) msg_ok "Ok, we will proceed" 
msg_info "Implement latest changes and reboot sytem...."
waiting
sshd -t
ufw enable
ufw status verbose
waiting
reboot
;;
[nN]* ) msg_info "Cancel..." ;;
[cC]* ) msg_error "Installation cancelled";
waiting
echo
clear
exit;;
*) exit ;;
esac
