#!/bin/bash

# ------------ config -----------------
# setup
doSetup=true

# ------------ end config -----------------


if $doSetup ; then

 # update and upgrade
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
	
	#install software
	
	apt-get -y install nala mc curl apt-transport-https ntp
	
	
	#set time
	sleep 3
	echo "Tijd naar Nederlands zetten";
	timedatectl set-timezone "Europe/Amsterdam"
	sleep 3
	echo "Check...";
	systemctl status ntpd  
	sleep 3
	timedatectl 
	sleep 3
	
	
	# nano + other apps for add-apt-repository cmd
    # http://stackoverflow.com/a/16032073 - page deleted :(
    apt-get -y install nano software-properties-common
	