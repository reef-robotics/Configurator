#!/bin/bash
# 	PROBOTIX LinuxCNC Error File Capture and Copy To Thumb Drive
#
# 	Copyright 2016 PROBOTIX
# 	Written by Len Shelton
# 	Version 1.0 release Apr 12 2016
#
#	This script will capture the LinuxCNC error files, tar gzip them, and copy them to the thumb drive.
#	The LinuxCNC error files are temporary files located in the /tmp directory, and they get erased when
#	error window is closed. So you have to run this script while the error window is still up. Run this
#	script from the thumb drive.
#
#
#
#

DATETIME=$(date +%m%d%Y%H%M%S)

#push password into sudo so that it doesnt prompt for it later
sudo -S <<< "probotix" clear

sudo tar -cvzf linuxcnc.errors.$DATETIME.tar.gz /tmp/linuxcnc.*
