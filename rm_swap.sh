#!/bin/bash
# Function remove swap
function confirm() {
    while true; do
        read -p "Do you want to remove Swapfile? (YES/NO/CANCEL or y/n/c)" yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            [Cc]* ) exit;;
            * ) echo "Please answer YES, NO, or CANCEL.";;
        esac
    done
}

if confirm; then
    echo "Remove swapfile...."
	sleep 1
	sed -i '/swapfile/d' /etc/fstab
	echo "3" > /proc/sys/vm/drop_caches
	swapoff -a
	rm -f /swapfile
else
    echo "Aborting the remove Swapfile.."
fi
