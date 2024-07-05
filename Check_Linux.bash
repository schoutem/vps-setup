#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
BLUE="\e[34m"
ENDCOLOR="\e[0m"



#Check Linux Dist

DISTREL="Ubuntu"
DISTVERSION="24"

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
#End Check Linux Dist
