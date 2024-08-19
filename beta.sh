#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/schoutem/vps-setup/main/build.func)
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



#######################################################################################

header_info
variables
color


check_root
sleep 1
echo
echo "This script works best on Ubuntu/Debian OS"
echo "check..."
echo

check_os
msg_ok "Completed Successfully!\n"
echo

read -p "Press enter to continue"

echo

    
echo

apt-get install whiptail -y

if whiptail --title "Benchmark test" --yesno "Do you want test your system with VPS benchmark script? (https://github.com/n-st/nench)" 10 100; then

nenchtest

else
     read -p "Press enter to continue"
fi

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
echo   "Swapsize $swapsize"
echo
swapset
echo
fi



read -p "Press enter to continue".


