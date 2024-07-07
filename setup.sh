#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
BLUE="\e[34m"
ENDCOLOR="\e[0m"

# Function to display the progress bar
progress_bar() {
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

#Check Linux Dist
check_root() {
echo "Check root..."
sleep 2
if [ "$(id -u)" != "0" ]; then
  echo
	echo -e "${RED}You must be root to execute the script. Exiting....${ENDCOLOR}"
	exit 1
 else
 echo
 	echo -e "${GREEN}Yes you are root....${ENDCOLOR}"
  echo
fi
}
#End Check Linux Dist

#Check Linux Dist
check_os() {

DISTREL="Ubuntu"
DISTVERSION="22"

source /etc/lsb-release

if [ -z $DISTRIB_RELEASE ] || [ -z $DISTRIB_ID ]; then
    echo "DISTRIB_RELEASE and DISTRIB_ID are not set"
else
    if [ $DISTRIB_ID == "$DISTREL" ]; then
        IFS='.' read -r -a distro_vers <<< $DISTRIB_RELEASE
        major_ver=${distro_vers[0]}
        echo "Distro major version $major_ver"
        if [ -z $major_ver ]; then
            echo "Major release version parsing failed"
        else
            if [ $(($major_ver)) -ge $DISTVERSION ]; then
               echo -e "${GREEN}Ubuntu major version is greater than $DISTVERSION, ok!${ENDCOLOR}";
                # do your operation here
            else
                echo -e "${RED}Ubuntu major version is lesser than $DISTVERSION, ok!${ENDCOLOR}";
                exit
            fi
        fi
    else
        echo -e "${RED}It is not a Ubuntu Linux but a $DISTREL linux${ENDCOLOR}";
        exit
    fi
fi
}
#End Check Linux Dist

##################################################################################################

echo -e "
__      _______   _____    _____      _               
\ \    / /  __ \ / ____|  / ____|    | |              
 \ \  / /| |__) | (___   | (___   ___| |_ _   _ _ __  
  \ \/ / |  ___/ \___ \   \___ \ / _ \ __| | | | '_ \ 
   \  /  | |     ____) |  ____) |  __/ |_| |_| | |_) |
    \/   |_|    |_____/  |_____/ \___|\__|\__,_| .__/ 
                                               | |    
                                               |_|    
" 

check_root
sleep 2
echo
echo "This script works best on Ubuntu OS"
echo "check..."
echo

progress_bar 5

check_os

##################################################################################################            


#Function nench test
function nenchtest() {
    while true; do
        echo
        read -p "Do you want test your system with VPS benchmark script? (YES/NO/CANCEL or y/n/c)" yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            [Cc]* ) exit;;
            * ) echo "Please answer YES, NO, or CANCEL.";;
        esac
    done
}

if nenchtest; then
    echo -e "${GREEN}Start testing system....${ENDCOLOR}"
    echo
	progress_bar 5
	(curl -s wget.racing/nench.sh | bash; curl -s wget.racing/nench.sh | bash) 2>&1 | tee nench.log
    echo
 read -p "Press enter to continue"
else
   echo
   echo -e "${RED}Aborting test...${ENDCOLOR}"
   read -p "Press enter to continue"
fi

#Swapfile

#Check swap excist
grep -q "swapfile" /etc/fstab

# if not then create it
if [ $? -ne 0 ]; then
  echo
        echo -e "${GREEN}No swapfile found, ok${ENDCOLOR}" ;
	echo
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
#read -p pm

#Choose TimeZone
PS3="Choose your timezone (NL or Custom select): "
echo 
select tz in "NL" "Select custom timezone"; do
  echo
  echo "Choosen manager ${tz}"
  echo
  break
done
#read -p tz

#Choose Pool NTP server
PS3="Choose your NTP server your nearest geo location (NL or Custom select): "
echo 
select ntp in "NL" "Select custom NTP"; do
  echo
  echo "Choosen manager ${ntp}"
  echo
  break
done
#read -p ntp

echo "Your settings are: port $selport, packetmanager $pm, Timezone $tz, NTP server $ntp"
echo
read -p "Press enter to continue"

sleep 2
echo
echo "Ok here we go...."

#Start set and install

##############################################################################################

# update and upgrade
echo "Update and upgrade your system..."
progress_bar 5
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
sudo $pm install mc curl apt-transport-https nano software-properties-common -y

#Set Nano settings
sleep 1
echo
echo "Set Nano config..."
echo

sed -i 's/[# ]*set tabsize 8/set tabsize 4/g' /etc/nanorc
sed -i -e '/^\(#\|\) set constantshow/s/^.*$/set constantshow/' /etc/nanorc
sed -i -e '/^\(#\|\) set linenumbers/s/^.*$/set linenumbers/' /etc/nanorc
sed -i -e '/^\(#\|\) set mouse/s/^.*$/set mouse/' /etc/nanorc

sleep 1
echo
echo "Set Nano config done..."
echo
#End set Nano settings

#Create swapfile
echo "Create swapfile"
create_swap "$swap_size"
progress_bar 5
echo "Done..."
echo
# output results to terminal
cat /proc/swaps
cat /proc/meminfo | grep Swap
#End create swapfile

#Set swapiness
function swness() {

# if not then create it
if [ $? -ne 0 ]; then
        echo
        echo -e "${GREEN}Swapiness settings are $var (not set to default), ok${ENDCOLOR}" ;
	      echo 
        sleep 1
        echo -e "${GREEN}No changes necessary${ENDCOLOR}" ;
        echo
else

echo "Choose an option:"
echo "1. Set Swapiness to 10"
echo "2. Set custom size (10-40)"
echo "3. Exit"
 
read -p "Enter your choice (1/2/3): " choice

case $choice in
  1)
    # Double the system memory
    swap_size=10
    ;;
  2)
    read -p "Enter custom size in (10-40): " swap_size
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

        echo
        echo -e "${BLUE}Chance Swapiness to $swap_size...${ENDCOLOR}" ;
        echo
        sed -i -e '$a\'$'\n''vm.swappiness = '$swap_size'' /etc/sysctl.conf
        echo   
        sudo sysctl -p    
        sleep 2
        echo -e "${GREEN}Swapiness settings are set to $swap_size....${ENDCOLOR}" ;
        echo

fi

}
#END Set swapiness

#check Swapiness excist
if [ $(grep -ic "60" /proc/sys/vm/swappiness) -eq 1 ]; then
    echo -e "${RED}We have found custom swap.${ENDCOLOR}"
    rmswness
elif [ $(grep -ic "vm.swappiness" /etc/sysctl.conf) -eq 1 ]; then
    echo -e "${RED}We have found custom swap in /etc/sysctl.conf.${ENDCOLOR}"
    rmswness
else
    echo -e "${GREEN}We haven't found custom swapiness.${ENDCOLOR}"
    swness
fi
#END check Swapiness excist

# set time

sudo apt-get install ntp -y
sleep 1
sudo ufw allow 123/udp
sleep 1
echo ""
echo "create conf file..."
progress_bar 5
touch /etc/ntp.conf
sleep 1

#NTP server set
if [[ $ntp == NL ]]
then
  echo
  echo "Set pool NL in ntp.conf..."
  progress_bar 5
  cat > /etc/ntp.conf << EOF
server 0.nl.pool.ntp.org
server 1.nl.pool.ntp.org
server 2.nl.pool.ntp.org
server 3.nl.pool.ntp.org
EOF
  echo
  echo "Done.."
else
  echo
  echo "Setting default NTP (pool.ntp.org)..."
  progress_bar 5
  cat > /etc/ntp.conf << EOF
server 0.pool.ntp.org
server 1.pool.ntp.org
server 2.pool.ntp.org
server 3.pool.ntp.org
EOF
  echo
  echo "Done.."
fi

echo "restart NTP"
progress_bar 5
sudo systemctl restart ntp
sleep 1
echo "Status.."
echo
sudo systemctl status ntp
sleep 1
echo
echo "Check Sync..."
progress_bar 5
ntpq -p 


#Timezone set
if [[ $tz == NL ]]
then
  echo
  echo "Set NL timezone..."
  sleep 1
  timedatectl set-timezone "Europe/Amsterdam"
  echo
  echo "Done.."
else
  echo
  echo "Starting reconfigure tzdata"
  sleep 
  sudo dpkg-reconfigure tzdata
  echo
  echo "Done.."
fi

sleep 1
echo ""
echo "Check..."
sudo systemctl restart ntp
sleep 1
echo ""
echo "Status NTP Check..."
sudo systemctl status ntpd
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
progress_bar 5
sudo sshd -t

sudo systemctl restart ssh
echo
echo "Ready installing, SHH port is set to $selport and choosen packetmanager is $pm"
progress_bar 5

echo
echo "Setting auto updates..."
echo
progress_bar 5

#auto updates
sudo apt install unattended-upgrades -y && sudo apt install update-notifier-common -y

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

sleep 1
echo
echo -e "${BLUE}Now we are going reconfigue unattended service, next step click Enter for Yes.${ENDCOLOR}"
echo
sleep 1
read -p "Press enter to begin reconfigure..."
sudo dpkg-reconfigure -plow unattended-upgrades

sleep 1
echo
echo "service unattended restart..."
progress_bar 5
sudo systemctl restart unattended-upgrades.service
sleep 1

#status Unatended
echo
echo "Status test...."
progress_bar 5
systemctl status unattended-upgrades

sleep 1
echo
echo "Test it Out with a Dry Run..."
echo
progress_bar 5
sudo unattended-upgrades --dry-run --debug

echo
echo "Ready install unattended-upgrades.."
echo
#End auto updates

#Function reboot
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
    echo -e "${GREEN}Reboot system....${ENDCOLOR}"
    echo
	progress_bar 5
	sudo reboot
else
   echo -e "${RED}Aborting the reboot...${ENDCOLOR}"
fi
