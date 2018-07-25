#!/bin/bash
# 	PROBOTIX LinuxCNC Error File Capture and Copy To Thumb Drive
#
# 	Copyright 2018 PROBOTIX
# 	Originally by Len Shelton
#		Updated by Kaden Lewis
# 	Version 1.0 release Apr 12 2016
#
#	This script will capture the LinuxCNC error files, tar gzip them, and copy them to the thumb drive.
#	The LinuxCNC error files are temporary files located in the /tmp directory, and they get erased when
#	error window is closed. So you have to run this script while the error window is still up. Run this
#	script from the thumb drive.
#
VERSION=1.1
DATETIME=$(date +%Y%m%d%H%M%S)

f_prompt() {
	# usage: f_prompt question description
	clear
	printf '%s\n' "PROBOTIX LinuxCNC Error File Capture & Copy Version: $VERSION"
	printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
	printf '%s\n' "$1"
	if [ -n "$2" ]
	then
		printf "$2\n"
	fi
}

f_pause() {
	echo
	# pause for user
	read -rsp $'Press any key to continue...\n' -n 1 key
}

f_prompt "This script will capture the LinuxCNC error files, tar gzip them, and copy them to the thumb drive." "* The error files are located in \/tmp and are erased when the error window is closed.\n* Must be ran while the error window is still open.\n* Must be ran from the thumb drive."
f_pause

#push password into sudo so that it doesnt prompt for it later
sudo -S <<< "probotix" clear

sudo tar -cvzf linuxcnc.errors.$DATETIME.tar.gz /tmp/linuxcnc.* /home/probotix/linuxcnc

f_prompt "Error log copied to thumb drive. You may now close this window and remove the drive."
f_pause
