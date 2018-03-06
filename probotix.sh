#!/bin/bash
# 	PROBOTIX LinuxCNC Configurator
# 	zip file created Thu Jan  4 13:41:19 CST 2018
#
# 	Copyright 2018 PROBOTIX
# 	Originally written by Len Shelton
# 	Modified by Kaden Lewis
#
_VERSION="2.2.1"

###################################################################################################
# 	some variables
#
INSTALLDIR=$(pwd)
DATETIME=$(date +'%Y-%m-%d %T')
REBOOT=0
CONFIG_FILE="/home/probotix/LINUXCNC_CONFIG"
LOG_FILE="/home/probotix/LINUXCNC_LOG"
DUMP_DIR="../.CONFIGS"

###################################################################################################
# 	some functions
#
f_prompt() {
	# if second parameter not set then clear screen
	if [ -z $2 ]
	then
		clear
	fi

	printf '%s\n' "PROBOTIX LinuxCNC Configurator Version: $VERSION"
	printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
	printf '%s\n' "$1"
}

f_exit () {
	f_prompt "Configuration Complete"
	if [ $REBOOT == 1 ]
	then
		echo "Please reboot the PC to apply changes."
	else
		echo "No need to reboot. Restart LinuxCNC to apply changes."
	fi
	echo
	echo "This window will close in 10 seconds"

	sleep 10
	exit
}

###################################################################################################
# 	push password into sudo so that it doesnt prompt for it later
#
sudo -S <<< "probotix" clear

###################################################################################################
# 	set the terminal defaults so that we have classic green on black colors
#
gconftool-2 --set /apps/gnome-terminal/profiles/Default/use_theme_colors --type bool "false"
gconftool-2 --set /apps/gnome-terminal/profiles/Default/use_theme_background --type bool "false"
gconftool-2 --set /apps/gnome-terminal/profiles/Default/foreground_color --type string "#0000FFFF0000"
gconftool-2 --set /apps/gnome-terminal/profiles/Default/background_color --type string "#000000000000"

###################################################################################################
# 	check for some errors
#
if [ "$(whoami)" != "probotix" ]
then
	echo "Not running as user probotix! Call PROBOTIX 844.472.9262"
	sleep 10
	exit
fi

if [ -d "/home/probotix" ]
then
	clear
else
	echo "Probotix directory not found! Call PROBOTIX 844.472.9262"
	sleep 10
	exit
fi

if [ -d "/home/probotix/emc2" ]
then
	echo "EMC2 directory found! Call PROBOTIX 844.472.9262"
	sleep 10
	exit
fi

# if log exists
if [ -e $LOG_FILE ]
then
	# read previous log version
	source <(grep VERSION $LOG_FILE)
	# backup old log file then make new one
	cp -f $LOG_FILE "$LOG_FILE.old"
	rm -f $LOG_FILE
	echo "$LOG_FILE $VERSION found!" >> $LOG_FILE
fi

if [ -e $CONFIG_FILE ]
then
	# read previous config version
	source <(grep VERSION $CONFIG_FILE)
	# backup old config file then make new one
	cp -f $CONFIG_FILE "$CONFIG_FILE.old"
	rm -f $CONFIG_FILE
	echo "$CONFIG_FILE $VERSION found!" >> $LOG_FILE
fi

if [ -L /usr/bin/axis ]
then
	echo "/usr/bin/axis is symlink" >> $LOG_FILE
	tar -P -czf /home/probotix/.backup.$DATETIME.tar.gz /home/probotix/linuxcnc/
	echo "Configuration Backup Created!"  >> $LOG_FILE
else
	# make a backup of the original axis files
	tar -P -czf /home/probotix/.backup.axis.tar.gz /usr/bin/axis /usr/share/axis /home/probotix/linuxcnc/ /usr/lib/tcltk/linuxcnc/
	echo "NEW Configuration Backup Created!" >> $LOG_FILE
fi

# set version to this script
VERSION=$_VERSION
echo "this config run version $VERSION at $DATETIME" >> $LOG_FILE

###################################################################################################
# 	Step 0: installation type (new or upgrade)
#
echo "prompt for install type" >> $LOG_FILE
f_prompt "New install or upgrade existing?:"
select x in "New Install" "Upgrade Existing";
do
	case $x in
		"New Install" )
			INSTALL_TYPE="NEW"
			break;;
		"Upgrade Existing" )
			INSTALL_TYPE="UPGRADE"
			break;;
	esac
done

echo "INSTALL_TYPE=$INSTALL_TYPE" >> $LOG_FILE

###################################################################################################
# 	set num lock
#
if [ -e "/usr/bin/numlockx" ]
then
	echo "numlockx already installed" >> $LOG_FILE
	numlockx
else
	cd .numlockx
	sudo ./configure
	sudo make
	sudo make install
	echo "installing numlockx" >> $LOG_FILE
	numlockx
	cd ..
fi

###################################################################################################
# 	install php so that future versions will be able to use php scripting
#
if $(command -v php >/dev/null)
then
# echo $( command -v php )
	echo "php already installed" >> $LOG_FILE
else
	echo "no php"
	cd .php/
	sudo dpkg -i php5-common_5.3.2-1ubuntu4.30_i386.deb
	sudo dpkg -i php5-cli_5.3.2-1ubuntu4.30_i386.deb
	echo "installing php" >> $LOG_FILE
	cd ..
fi

###################################################################################################
# 	install samba
#		sudo apt-get install samba
#
if [ -e "/etc/samba/smb.conf" ]
then
	echo "samba already installed" >> $LOG_FILE
else
	cd .samba/
	sudo dpkg -i *.deb
	echo "installing samba" >> $LOG_FILE
	cd ..
fi

###################################################################################################
# 	if a bin folder is found in the $HOME folder, then it is added to the $PATH
# 		this is where we will want to put any php scripts that we access from the GUI
#
if [ -d "/home/probotix/bin" ]
then
	cp -f .g-code-filter.php /home/probotix/bin/g-code-filter.php
else
	mkdir -p /home/probotix/bin
	cp -f .g-code-filter.php /home/probotix/bin/g-code-filter.php
	# this one will require a reboot
	REBOOT=1
fi

###################################################################################################
# 	misc setup stuff
#
# set the default editor for .ngc files
sudo cp -f .freedesktop.org.xml /usr/share/mime/packages/freedesktop.org.xml
sudo update-mime-database /usr/share/mime
echo "set default editor for .ngc files" >> $LOG_FILE

if [ $INSTALL_TYPE == "NEW" ]
then
	# remove the desktop icons
	rm -Rf /home/probotix/Desktop/*.desktop
	rm -f /home/probotix/Desktop/nc_files
	echo "remove desktop icons" >> $LOG_FILE

	# delete and recreate the linuxcnc directory
	rm -Rf /home/probotix/linuxcnc
	mkdir -p /home/probotix/linuxcnc/configs/PROBOTIX/axis
	mkdir -p /home/probotix/linuxcnc/nc_files
	echo "remove and recreate LinuxCNC dir" >> $LOG_FILE
fi
cp -R .nc_files/* /home/probotix/linuxcnc/nc_files
sudo cp -f .probotix_splash.gif /usr/share/linuxcnc/probotix_splash.gif
echo "copy nc_files and splash" >> $LOG_FILE

# copy custom stepconf
sudo cp -f .stepconf /usr/bin/stepconf
#/usr/share/applications/linuxcnc-stepconf.desktop
#/usr/share/linuxcnc/stepconf.glade
echo "copy custom stepconf" >> $LOG_FILE

# create symlink to axis program
sudo rm -f /usr/bin/axis
sudo rm -Rf /usr/share/axis
cp -Rud .axis_files/axis/* /home/probotix/linuxcnc/configs/PROBOTIX/axis/
sudo ln -s /home/probotix/linuxcnc/configs/PROBOTIX/axis/axis /usr/bin/axis
sudo ln -s /home/probotix/linuxcnc/configs/PROBOTIX/axis /usr/share/axis
echo "create symlink to axis" >> $LOG_FILE

# install fixed tooledit
sudo cp -f .tooledit /usr/bin/tooledit
echo "copy fixed tooledit" >> $LOG_FILE

# install customized files
sudo cp -f .show_errors.tcl /usr/lib/tcltk/linuxcnc/show_errors.tcl
echo "copy customized files" >> $LOG_FILE

# set desktop background
SCREEN_WIDTH=$(xrandr --current | grep '*' | uniq | awk '{print $1}' | cut -d 'x' -f1)
cp -f .$SCREEN_WIDTH*probotix_background.png /home/probotix/Pictures/.background.png
gconftool-2 -t string -s /desktop/gnome/background/picture_filename /home/probotix/Pictures/.background.png
echo "set desktop background" >> $LOG_FILE

# turn off the screen-saver and idle login
gconftool-2 --type bool --set /apps/gnome-screensaver/lock_enabled 0
gconftool-2 --type bool --set /apps/gnome-screensaver/idle_activation_enabled 0
echo "disable screen-saver/idle login" >> $LOG_FILE

# turn on line numbers in gedit
gconftool-2 --type bool --set /apps/gedit-2/preferences/editor/line_numbers/display_line_numbers true
echo "gedit line numbers" >> $LOG_FILE

# remove the update manager so that folks can't break linuxcnc with a software update
sudo apt-get -qq -y remove update-manager
echo "remove update-manager" >> $LOG_FILE

if [ $INSTALL_TYPE == "UPGRADE" ]
then
	# no need to create temp files or prompt for other info, simply close
	echo "Upgrade of Installation Complete" >> $LOG_FILE
	f_exit
fi

# create the config file
echo "DATE=$DATETIME" >> $CONFIG_FILE
echo "VERSION=$VERSION" >> $CONFIG_FILE
echo "SCREEN_WIDTH=$SCREEN_WIDTH" >> $CONFIG_FILE

# create some temporary files from our skeleton files
cp .PROBOTIX.ini .TEMP.ini
cp .PROBOTIX.hal .TEMP.hal
cp .PYVCP.xml .TEMP.xml
cp .POSTGUI.hal .TEMPpostgui.hal
cp .102.ngc .TEMP102.ngc
cp .100.ngc .TEMP100.ngc
cp .emc.var .TEMPemc.var
cp .icon.desktop .TEMP.desktop
echo "create temporary files" >> $LOG_FILE

###################################################################################################
# 	this section tries to identify the add-on parallel port address
#
LSPCI=$(lspci -v | grep NetMos)
if [ -z "$LSPCI" ]
then
	echo "SECOND PARALLEL PORT NOT FOUND"
	echo "SECOND PARALLEL PORT NOT FOUND" >> $LOG_FILE
	sleep 3
fi

# capture output of lscpi and copy it to file on the thumb drive so customer can email it if necessary
rm -rf ./LSPCI.txt
lspci -v > ./LSPCI.txt

# get substring
SUB=${LSPCI:0:7}
ADDR=$(dmesg | grep $SUB)
A=${ADDR#*0x}
B=${A:0:4}
# hopefully this will be the variable for the second parallel port
IDENT="0x"$B
LEN=${#IDENT}

if [ $LEN -eq 6 ]
then
	IDENTB=$IDENT
else
	IDENTB="0xd050"
fi
echo "indentified $IDENTB" >> $LOG_FILE

###################################################################################################
# 	Step 1: order number
# 		we will use the order number to create a local database of config files
# 		we can also encode a license mechanism here
#
echo "prompt for order number" >> $LOG_FILE
f_prompt "Enter Order Number:"
read ORDER_NO
echo "ORDER_NO=$ORDER_NO" >> $LOG_FILE
echo "ORDER_NO=$ORDER_NO" >> $CONFIG_FILE

case $ORDER_NO in
	666 )
		clear
		echo "FACTORY INSTALL"
		sleep 1
		echo "FACTORY INSTALL" >> $LOG_FILE
		break;;
	* )
		clear
		echo "CUSTOMER INSTALL"
		break;;
esac

###################################################################################################
# 	Step 2: machine
#
echo "prompt for machine" >> $LOG_FILE
f_prompt "Choose your machine:"
select x in "V90mk2" "Comet" "Asteroid" "Meteor" "Nebula/MeteorXL" "Custom" "StepConf Only";
do
	case $x in
		"V90mk2" )
			MACHINE="V90MK2"
			X_MAX_LIMIT=20.25
			Y_MAX_LIMIT=12.4
			break;;
		"Comet" )
			MACHINE="COMET"
			X_MAX_LIMIT=26.125
			Y_MAX_LIMIT=25.1152
			break;;
		"Asteroid" )
			MACHINE="ASTEROID"
			X_MAX_LIMIT=37.25
			Y_MAX_LIMIT=25.1152
			break;;
		"Meteor" )
			MACHINE="METEOR"
			X_MAX_LIMIT=26.125
			Y_MAX_LIMIT=52.2
			break;;
		"Nebula/MeteorXL" )
			MACHINE="NEBULA"
			X_MAX_LIMIT=37.25
			Y_MAX_LIMIT=52.2
			break;;
		"Custom" )
			MACHINE="CUSTOM"
			echo "prompt for custom x travel" >> $LOG_FILE
			f_prompt "Enter X-Axis Max Travel $UNIT_DESC_BIG"
			read CUSTOM_X_MAX_LIMIT
			echo "read CUSTOM_X_MAX_LIMIT=$CUSTOM_X_MAX_LIMIT" >> $LOG_FILE
			echo "prompt for custom y travel" >> $LOG_FILE
			f_prompt "Enter Y-Axis Max Travel $UNIT_DESC_BIG"
			read CUSTOM_Y_MAX_LIMIT
			echo "read CUSTOM_Y_MAX_LIMIT=$CUSTOM_Y_MAX_LIMIT" >> $LOG_FILE
			# use input values instead of calculated
			echo "use input values" >> $LOG_FILE
			X_MAX_LIMIT=$CUSTOM_X_MAX_LIMIT
			Y_MAX_LIMIT=$CUSTOM_Y_MAX_LIMIT
			break;;
	esac
done

echo "MACHINE=$MACHINE" >> $LOG_FILE
echo "MACHINE=$MACHINE" >> $CONFIG_FILE

###################################################################################################
# 	Step 3a: up-rights (short or tall)
#
echo "prompt for up-right" >> $LOG_FILE
f_prompt "Choose your up-right:"
select x in "Tall" "Short";
do
	case $x in
		"Short" )
			UPRIGHT="SHORT"
			break;;
		"Tall" )
			UPRIGHT="TALL"
			Y_MAX_LIMIT=$(expr "scale=4; $Y_MAX_LIMIT-1" | bc -l)
			# need Y offset for ATLaS if using TALL uprights
			#$Y_OFFSET=
			break;;
	esac
done

echo "UPRIGHT=$UPRIGHT" >> $LOG_FILE
echo "UPRIGHT=$UPRIGHT" >> $CONFIG_FILE
echo "Y_MAX_LIMIT=$Y_MAX_LIMIT" >> $LOG_FILE

###################################################################################################
# 	Step 3b: z bearings (2 or 4)
#			number of bearings and their placement determins Z-axis travel
#
echo "prompt for z bearings" >> $LOG_FILE
f_prompt "Number of Z bearings:"
select x in "Four" "Two";
do
	case $x in
		"Two" )
			ZBEARINGS="2"
			# needs to be at least 5.7 to avoid crimping cable
			ZMINLIM=5.7
			break;;
		"Four" )
			ZBEARINGS="4"
			ZMINLIM=4.7
			break;;
	esac
done

echo "ZBEARINGS=$ZBEARINGS" >> $LOG_FILE
echo "ZBEARINGS=$ZBEARINGS" >> $CONFIG_FILE

###################################################################################################
# 	Step 4: units (inch or mm)
#
echo "prompt for units" >> $LOG_FILE
f_prompt "Choose your units:"
select x in "Inch" "Metric";
do
	case $x in
		"Inch" )
			UNITS="inch"
			I=1
			UNIT_DESC="(X.XXX in inches)"
			UNIT_DESC_BIG="(XX.XXX in inches)"
			REPLACE_RSC="G17 G20 G40 G49 G54 G90 G64 P0.001 T0"
			REPLACE_INC=".1in .05in .01in .005in .001in"
			GUNITS="G20"
			break;;
		"Metric" )
			UNITS="mm"
			I=25.4
			UNIT_DESC="(XX.XX in mm)"
			UNIT_DESC_BIG="(XXXX.XX in mm)"
			REPLACE_RSC="G17 G21 G40 G49 G54 G90 G64 P0.03 T0"
			REPLACE_INC="10mm 5mm 1mm 0.1mm 0.01mm"
			GUNITS="G21"
			break;;
	esac
done
echo "UNITS=$UNITS" >> $LOG_FILE
echo "UNITS=$UNITS" >> $CONFIG_FILE

if [ $MACHINE != "CUSTOM" ]
then
	# use calculated values to adjust for metric
	echo "use calculated values" >> $LOG_FILE
	X_MAX_LIMIT=$(expr "scale=4; $X_MAX_LIMIT*$I" | bc -l)
	Y_MAX_LIMIT=$(expr "scale=4; $Y_MAX_LIMIT*$I" | bc -l)
fi

echo "set X_MAX_LIMIT=$X_MAX_LIMIT" >> $LOG_FILE
echo "set Y_MAX_LIMIT=$Y_MAX_LIMIT" >> $LOG_FILE
echo "X_MAX_LIMIT=$X_MAX_LIMIT" >> $CONFIG_FILE
echo "Y_MAX_LIMIT=$Y_MAX_LIMIT" >> $CONFIG_FILE

# X_PARK is center of X travel
X_PARK=$(expr "scale=2; $X_MAX_LIMIT/2" | bc -l)
echo "X_PARK=$X_PARK" >> $LOG_FILE
# Y_PARK is .1in from max Y
Y_PARK=$(expr "scale=2; $Y_MAX_LIMIT-(0.1*$I)" | bc -l)
echo "Y_PARK=$Y_PARK" >> $LOG_FILE

Z_MIN_LIMIT=$(expr "scale=2; $ZMINLIM*$I" | bc -l)
echo "Z_MIN_LIMIT=$Z_MIN_LIMIT" >> $LOG_FILE

###################################################################################################
# 	set G28 and G30 locations in emc.var
#
echo "set G28 and G30 locations in emc.var" >> $LOG_FILE
sed -i -e 's/REPLACE_X_PARK/'"$X_PARK"'/' .TEMPemc.var
sed -i -e 's/REPLACE_Y_PARK/'"$Y_PARK"'/' .TEMPemc.var

###################################################################################################
# 	Step 5a: spindle (router or vfd)
#
SPID="FALSE"

echo "prompt for spindle" >> $LOG_FILE
f_prompt "Choose your spindle:"
select x in "Router" "VFD Spindle";
do
	case $x in
		"Router" )
			echo "prompt for superpid" >> $LOG_FILE
			f_prompt "Do you have a SuperPID?:"
			select y in "No" "Yes";
			do
				case $y in
					"Yes" )
						SPID="TRUE"
						echo "SPID=$SPID" >> $CONFIG_FILE
						# remove router code
						echo "removing router controls from hal file" >> $LOG_FILE
						sed -i '/ROUTER/,+7d' .TEMP.hal
						break;;
					"No" )
						sed -i '/PWM/,+5d' .TEMP.hal
						break;;
				esac
			done
			SPINDLE="ROUTER"
			# remove spindle speed
			echo "removing spindle from hal files" >> $LOG_FILE
			sed -i '/SPINDLE/,+16d' .TEMP.hal
			sed -i '/SPINDLE_SPEED/,+13d' .TEMP.xml
			sed -i '/VFD/,+3d' .TEMPpostgui.hal
			break;;
		"VFD Spindle" )
			SPINDLE="VFD"
			ROUTER_MOUNT="LONG"
			# remove router code
			echo "removing router controls from hal file" >> $LOG_FILE
			sed -i '/ROUTER/,+7d' .TEMP.hal
			break;;
	esac
done

if [ $SPID == "FALSE" ]
then
	# remove superpid code
	echo "removing superpid from hal files" >> $LOG_FILE
	sed -i '/SUPERPID/,+10d' .TEMP.hal
fi

echo "SPINDLE=$SPINDLE" >> $LOG_FILE
echo "SPINDLE=$SPINDLE" >> $CONFIG_FILE
echo "SPID=$SPID" >> $LOG_FILE

###################################################################################################
# 	Step 5b: router mount (long or short)
#			need to ask this to determine ATLaS Y position
#			short mounts are -0.165 shorter from Y center
#
ATLAS_X=-0.075
#ATLAS_Y=3.5533

if [ $SPINDLE == "ROUTER" ]
then
	echo "prompt for router mount" >> $LOG_FILE
	f_prompt "Choose Your Router Mount:"
	select x in "One-Piece Long Center" "Two-Piece Short Center" "Two-Piece Long Center";
	do
		case $x in
			"One-Piece Long Center" )
				ROUTER_MOUNT="LONG"
				ATLAS_Y=3.5533
				break;;
			"Two-Piece Short Center" )
				ROUTER_MOUNT="SHORT"
				ATLAS_Y=3.3883
				break;;
			"Two-Piece Long Center" )
				ROUTER_MOUNT="LONG"
				ATLAS_Y=3.5533
				break;;
		esac
	done
	echo "$x" >> $LOG_FILE
fi

echo "ROUTER_MOUNT=$ROUTER_MOUNT" >> $LOG_FILE
echo "ROUTER_MOUNT=$ROUTER_MOUNT" >> $CONFIG_FILE

###################################################################################################
# 	ATLaS settings
#
ATLAS_X=$(expr "scale=4; $ATLAS_X*$I" | bc -l)
#ATLAS_Y=$(expr "scale=4; $ATLAS_Y+$Y_OFFSET" | bc -l)
ATLAS_Y=$(expr "scale=4; $ATLAS_Y*$I" | bc -l)
echo "ATLAS_X=$ATLAS_X" >> $LOG_FILE
echo "ATLAS_Y=$ATLAS_Y" >> $LOG_FILE

# hardcode ATLaS offset in 100.ngc
echo "hard code ATLaS offset in 100.ngc" >> $LOG_FILE
sed -i -e 's/REPLACE_ATLAS_X/'"$ATLAS_X"'/' .TEMP100.ngc
sed -i -e 's/REPLACE_ATLAS_Y/'"$ATLAS_Y"'/' .TEMP100.ngc

# set G59.3 offset to center of ATLaS
echo "set G59.3 offset to center of ATLaS" >> $LOG_FILE
sed -i -e 's/REPLACE_ATLAS_X/'"$ATLAS_X"'/' .TEMPemc.var
sed -i -e 's/REPLACE_ATLAS_Y/'"$ATLAS_Y"'/' .TEMPemc.var

###################################################################################################
# 	Step 6: ACME screw (roton or helix)
#
echo "prompt for acme" >> $LOG_FILE
f_prompt "Choose your ACME screw:"
select x in "Helix" "Roton";
do
	case $x in
		"Roton" )
			ACME="ROTON"
			ZTPI=5
			Z_MAXVEL=0.4
			# 24IPM Z-Axis
			break;;
		"Helix" )
			ACME="HELIX"
			ZTPI=2
			Z_MAXVEL=2
			# 120IPM Z-Axis
			break;;
	esac
done
echo "ACME=$ACME" >> $LOG_FILE
echo "ACME=$ACME" >> $CONFIG_FILE

echo "replace z max velocity in ini file" >> $LOG_FILE
sed -i -e 's/REPLACE_ZVELOCITY/'"Z_MAXVEL"'/' .TEMP.ini

###################################################################################################
# 	Step 7: drivers (unipolar or bipolar)
#
echo "prompt for drivers" >> $LOG_FILE
f_prompt "Choose your drivers:"
select x in "MondoStep" "ProboStep";
do
	case $x in
		"ProboStep" )
			DRIVERS="PROBOSTEP"
			XYSCALE=$(expr "scale=4; 2*200*2/$I" | bc -l)
			ZSCALE=$(expr "scale=4; 2*200*$ZTPI/$I" | bc -l)
			break;;
		"MondoStep" )
			DRIVERS="MONDOSTEP"
			XYSCALE=$(expr "scale=4; 4*200*2/$I" | bc -l)
			ZSCALE=$(expr "scale=4; 4*200*$ZTPI/$I" | bc -l)
			break;;
	esac
done
echo "DRIVERS=$DRIVERS" >> $LOG_FILE
echo "DRIVERS=$DRIVERS" >> $CONFIG_FILE

echo "XYSCALE=$XYSCALE" >> $LOG_FILE
echo "ZSCALE=$ZSCALE" >> $LOG_FILE

###################################################################################################
# 	Step 8: jogger (gamepad or mpg pendant)
#
echo "prompt for gamepad" >> $LOG_FILE
f_prompt "Do you use the Gamepad or MPG pendant?"
select x in "None" "Gamepad" "MPG Pendant";
do
	case $x in
		"Gamepad" )
			PENDANT="GAMEPAD"
			# remove mpg pendant from hal file
			echo "remove mpg from hal file" >> $LOG_FILE
			sed -i '/MPG_PENDANT/,+62d' .TEMP.hal
			# remove unused second estop section from hal file
			sed -i '/ESTOP_2/,+9d' .TEMP.hal
			break;;
		"MPG Pendant" )
			PENDANT="MPG"
			# remove gamepad from hal file
			echo "remove gamepad from hal files" >> $LOG_FILE
			sed -i '/GAMEPAD/,+1d' .TEMP.hal
			sed -i '/GAMEPAD/,+31d' .TEMPpostgui.hal
			# remove code for single estop usage
			sed -i '/ESTOP_1/,+1d' .TEMP.hal
			break;;
		"None" )
			PENDANT="NONE"
			# remove mpg pendant from hal file
			echo "remove mpg from hal file" >> $LOG_FILE
			sed -i '/MPG_PENDANT/,+62d' .TEMP.hal
			# remove gamepad from hal file
			echo "remove gamepad from hal files" >> $LOG_FILE
			sed -i '/GAMEPAD/,+1d' .TEMP.hal
			sed -i '/GAMEPAD/,+31d' .TEMPpostgui.hal
			# remove unused second estop section from hal file
			sed -i '/ESTOP_2/,+9d' .TEMP.hal
			break;;
	esac
done
echo "PENDANT=$PENDANT" >> $LOG_FILE
echo "PENDANT=$PENDANT" >> $CONFIG_FILE

###################################################################################################
# 	Step 9: confirm parallel port addresses, or enter custom
#
PARPORT0="0x378"
PARPORT1=$IDENTB
echo "prompt confirm parport addr" >> $LOG_FILE
f_prompt "PARPORT.0 $PARPORT0, PARPORT.1 $PARPORT1 Okay?"
select x in "Yes" "No";
do
	case $x in
		"Yes" )
			break;;
		"No" )
			echo
			echo "Enter PARPORT0:"
			read PARPORT0
			echo "Enter PARPORT1:"
			read PARPORT1
			break;;
	esac
done
echo "$x" >> $LOG_FILE

###################################################################################################
# 	Step 10: sensors (atlas or zpuck)
#
ZPUCK="NONE"

echo "prompt for options" >> $LOG_FILE
f_prompt "Do you use the ATLaS Tool Length Sensor or the Z-Puck?"
select x in "None" "ATLaS only" "Z-Puck only" "Both" "Swap Parallel Ports";
do
	case $x in
		"ATLaS only" )
			SENSOR="ATLAS"
			sed -i -e 's/REPLACE_GUNITS/'"$GUNITS"'/' \
				-e 's/REPLACE_ZMIN/'"$Z_MIN_LIMIT"'/' \
				-e 's/REPLACE_MULTIPLIER/'"$I"'/' \
				-e 's/REPLACE_X_PARK/'"$X_PARK"'/' .TEMP100.ngc
			# remove zpuck control
			sed -i '/ZPUCK/,+5d' .TEMP.xml
			sed -i '/HALUI_ZPUCK/,+1d' .TEMPpostgui.hal
			break;;
		"Z-Puck only" )
			SENSOR="Z-Puck"
			ZPUCK_DIST=$(expr "scale=2; 5*$I" | bc -l)
			ZPUCK_FEED=$(expr "scale=2; 10*$I" | bc -l)
			f_prompt "Enter Height of Z-Puck $UNIT_DESC"
			read ZPUCK
			sed -i -e 's/REPLACE_GUNITS/'"$GUNITS"'/' \
				-e 's/REPLACE_ZP_DIST/'"$ZPUCK_DIST"'/' \
				-e 's/REPLACE_ZP_FEED/'"$ZPUCK_FEED"'/' \
				-e 's/REPLACE_ZP_HEIGHT/'"$ZPUCK"'/' .TEMP102.ngc
			echo "ZPUCK=$ZPUCK" >> $LOG_FILE
			echo "ZPUCK=$ZPUCK" >> $CONFIG_FILE
			# remove atlas
			sed -i '/ATLAS/,+5d' .TEMP.xml
			sed -i '/HALUI_FIRST_TOOL/,+1d' .TEMPpostgui.hal
			break;;
		"Both" )
			SENSOR="BOTH"
			ZPUCK_DIST=$(expr "scale=2; 5*$I" | bc -l)
			ZPUCK_FEED=$(expr "scale=2; 10*$I" | bc -l)
			f_prompt "Enter Height of Z-Puck $UNIT_DESC"
			read ZPUCK
			sed -i -e 's/REPLACE_GUNITS/'"$GUNITS"'/' \
				-e 's/REPLACE_ZP_DIST/'"$ZPUCK_DIST"'/' \
				-e 's/REPLACE_ZP_FEED/'"$ZPUCK_FEED"'/' \
				-e 's/REPLACE_ZP_HEIGHT/'"$ZPUCK"'/' .TEMP102.ngc
			echo "ZPUCK=$ZPUCK" >> $LOG_FILE
			echo "ZPUCK=$ZPUCK" >> $CONFIG_FILE
			sed -i -e 's/REPLACE_GUNITS/'"$GUNITS"'/' \
				-e 's/REPLACE_ZMIN/'"$Z_MIN_LIMIT"'/' \
				-e 's/REPLACE_MULTIPLIER/'"$I"'/' \
				-e 's/REPLACE_X_PARK/'"$X_PARK"'/' .TEMP100.ngc
			break;;
		"Swap Parallel Ports" )
			PARPORT0=$IDENTB
			PARPORT1="0x378"
			# fall-thru
			;&
		"None" )
			SENSOR="NONE"
			# remove probe indicator
			sed -i '/PROBE/,+15d' .TEMP.xml
			sed -i '/PROBE_LED/,+1d' .TEMPpostgui.hal
			# remove zpuck control
			sed -i '/ZPUCK/,+5d' .TEMP.xml
			sed -i '/HALUI_ZPUCK/,+1d' .TEMPpostgui.hal
			# remove atlas
			sed -i '/ATLAS/,+5d' .TEMP.xml
			sed -i '/HALUI_FIRST_TOOL/,+1d' .TEMPpostgui.hal
			break;;
	esac
done
echo "SENSOR=$SENSOR" >> $LOG_FILE
echo "SENSOR=$SENSOR" >> $CONFIG_FILE

# save parports to hal file
echo "set parport addr in hal file" >> $LOG_FILE
sed -i -e 's/PARPORT0/'"$PARPORT0"'/' \
	-e 's/PARPORT1/'"$PARPORT1 in"'/' .TEMP.hal

echo "PARPORT0=$PARPORT0" >> $LOG_FILE
echo "PARPORT0=$PARPORT0" >> $CONFIG_FILE
echo "PARPORT1=$PARPORT1" >> $LOG_FILE
echo "PARPORT1=$PARPORT1" >> $CONFIG_FILE

###################################################################################################
# 	Step 11: rotary?
#
echo "prompt for rotary axis" >> $LOG_FILE
f_prompt "Do you have the rotary axis?"
select xa in "No" "Yes";
do
	case $xa in
		"Yes" )
			COORDINATES="X Y Z A"
			COORDINATES_="X\ Y\ Z\ A"
			AXES=4
			break;;
		"No" )
			COORDINATES="X Y Z"
			COORDINATES_="X\ Y\ Z"
			AXES=3
			# remove a-axis from ini file
			sed -i '/AXIS_3/,+10d' .TEMP.ini
			# remove a-axis from hal file
			sed -i '/A-AXIS/,+13d' .TEMP.hal
			# remove remaining a-axis references from hal file
			sed -i '/axis.3/d' .TEMP.hal
			break;;
	esac
done
echo "COORDINATES=$COORDINATES" >> $CONFIG_FILE

###################################################################################################
# 	Step 12: driver swap
#
XSTEP="02"
XDIR="03"
Y1STEP="04"
Y1DIR="05"
Y2STEP="08"
Y2DIR="09"
ZSTEP="06"
ZDIR="07"
ASTEP="17"
ADIR="01"

echo "prompt for driver swap" >> $LOG_FILE
f_prompt "Do you want to swap a motor to the A-axis output?"
select x in "No" "X" "Y1" "Y2" "Z";
do
	case $x in
		"X" )
			XSTEP="17"
			XDIR="01"
			COORDINATES="X Y Z"
			COORDINATES_="X\ Y\ Z"
			AXES=3
			# continue matching
			;;&
		"Y1" )
			Y1STEP="17"
			Y1DIR="01"
			COORDINATES="X Y Z"
			COORDINATES_="X\ Y\ Z"
			AXES=3
			;;&
		"Y2" )
			Y2STEP="17"
			Y2DIR="01"
			COORDINATES="X Y Z"
			COORDINATES_="X\ Y\ Z"
			AXES=3
			;;&
		"Z" )
			ZSTEP="17"
			ZDIR="01"
			COORDINATES="X Y Z"
			COORDINATES_="X\ Y\ Z"
			AXES=3
			;;&
		"X" | "Y1" | "Y2" | "Z" )
			# remove a-axis from ini file
			sed -i '/AXIS_3/,+10d' .TEMP.ini
			# remove a-axis from hal file
			sed -i '/A-AXIS/,+13d' .TEMP.hal
			break;;
		"No" )
			break;;
	esac
done
echo "SWAP_TO_A=$x" >> $CONFIG_FILE

# markers for any swapped axis are already removed, sed will ignore those axes
sed -i -e "s/XSTEP/$XSTEP/" \
	-e "s/XDIR/$XDIR/" \
	-e "s/Y1STEP/$Y1STEP/" \
	-e "s/Y1DIR/$Y1DIR/" \
	-e "s/Y2STEP/$Y2STEP/" \
	-e "s/Y2DIR/$Y2DIR/" \
	-e "s/ZSTEP/$ZSTEP/" \
	-e "s/ZDIR/$ZDIR/" \
	-e "s/ASTEP/$ASTEP/" \
	-e "s/ADIR/$ADIR/" .TEMP.hal
echo "set axis pins in hal file" >> $LOG_FILE

###################################################################################################
# 	Step 13: soft limits only
#
echo "prompt for soft limits" >> $LOG_FILE
f_prompt "Do you want to use soft limits only?"
select x in "No" "Yes";
do
	case $x in
		"Yes" )
			sed -i '/LIMITS/,+5d' .TEMP.hal
			break;;
		"No" )
			break;;
	esac
done
echo "SOFT_ONLY=$x" >> $CONFIG_FILE


# metricify some additional axis vars
# floating point math is hoaky in bash, must us bc (bash calculator)
# a-axis is in degrees, so no metrification necessary
XY_MAXVEL=$(expr 3.34*$I | bc -l)
Z_MAXVEL=$(expr $Z_MAXVEL*$I | bc -l)
XY_MAXACCEL=$(expr 6*$I | bc -l)
Z_MAXACCEL=$(expr 10*$I | bc -l)
XY_STEPGEN_MAXACCEL=$(expr 15*$I | bc -l)
Z_STEPGEN_MAXACCEL=$(expr 15*$I | bc -l)
XY_MIN_LIMIT=$(expr 0.1*$I | bc -l)

Z_MAX_LIMIT=$(expr 0.1*$I | bc -l)
XY_HOME_OFFSET=$(expr 0.2*$I | bc -l)
Z_HOME_OFFSET=$(expr 0.2*$I | bc -l)
XY_SEARCH_VEL=$(expr 0.5*$I | bc -l)
Z_SEARCH_VEL=$(expr 0.5*$I | bc -l)
XY_LATCH_VEL=$(expr 0.2*$I | bc -l)
Z_LATCH_VEL=$(expr 0.2*$I | bc -l)
DEFAULT_VELOCITY=$(expr 3.34*$I | bc -l)
MAX_LINEAR_VELOCITY=$(expr 3.34*$I | bc -l)
echo "metricify axis vars" >> $LOG_FILE

# folder should only exist during factory install
if [ -d "$DUMP_DIR" ]
then
	clear
	echo "PROBOTIX LinuxCNC Configurator Version: $VERSION" >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "ORDER_NO    =" $ORDER_NO >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "MACHINE     =" $MACHINE >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "UPRIGHT     =" $UPRIGHT >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "ZBEARINGS   =" $ZBEARINGS >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "UNITS       =" $UNITS >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "ACME        =" $ACME >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "DRIVERS     =" $DRIVERS >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "SPINDLE     =" $SPINDLE >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "SPID        =" $SPID >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "PENDANT     =" $PENDANT >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "SENSOR      =" $SENSOR >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "AXES        =" $AXES >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "COORDINATES =" $COORDINATES >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "ZPUCK       =" $ZPUCK >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "ZTPI        =" $ZTPI >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "PARPORT0    =" $PARPORT0 >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "PARPORT1    =" $PARPORT1 >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "XYSCALE     =" $XYSCALE >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "ZSCALE      =" $ZSCALE >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "XY_MAXVEL   =" $XY_MAXVEL >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "Z_MAXVEL    =" $Z_MAXVEL >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "XY_MAXACCEL =" $XY_MAXACCEL >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "Z_MAXACCEL  =" $Z_MAXACCEL >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "XY_SMAX_ACC =" $XY_STEPGEN_MAXACCEL >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "Z_SMAX_ACC  =" $Z_STEPGEN_MAXACCEL >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "XY_MIN_LIMIT=" $XY_MIN_LIMIT >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "Z_MIN_LIMIT =" $Z_MIN_LIMIT >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "X_MAX_LIMIT =" $X_MAX_LIMIT >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "Y_MAX_LIMIT =" $Y_MAX_LIMIT >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "Z_MAX_LIMIT =" $Z_MAX_LIMIT >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "XY_HM_OFFSET=" $XY_HOME_OFFSET >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "Z_HM_OFFSET =" $Z_HOME_OFFSET >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "XY_SEARCH_VL=" $XY_SEARCH_VEL >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "Z_SEARCH_VEL=" $Z_SEARCH_VEL >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "XY_LATCH_VEL=" $XY_LATCH_VEL >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "Z_LATCH_VEL =" $Z_LATCH_VEL >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "DEF_VELOCITY=" $DEFAULT_VELOCITY >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "MAX_LIN_VEL =" $MAX_LINEAR_VELOCITY >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "config dump" >> $LOG_FILE
fi

# was 0.08
FERROR=$(expr 0.08*$I | bc -l)
# was 0.05
MIN_FERROR=$(expr 0.05*$I | bc -l)

# replace vars in ini file - single + double quote to expand vars and escape spaces
sed -i -e 's/REPLACE_MACHINE/'"$MACHINE"'/' \
	-e 's/REPLACE_DEFAULT_VELOCITY/'"$DEFAULT_VELOCITY"'/' \
	-e 's/REPLACE_MAX_LINEAR_VELOCITY/'"$MAX_LINEAR_VELOCITY"'/' \
	-e 's/REPLACE_FERROR/'"$FERROR"'/' \
	-e 's/REPLACE_MIN_FERROR/'"$MIN_FERROR"'/' \
	-e 's/REPLACE_AXES/'"$AXES"'/' \
	-e 's/REPLACE_COORDINATES/'"$COORDINATES_"'/' \
	-e 's/REPLACE_UNITS/'"$UNITS"'/' \
	-e 's/REPLACE_XY_SCALE/'"$XYSCALE"'/' \
	-e 's/REPLACE_Z_SCALE/'"$ZSCALE"'/' \
	-e 's/REPLACE_XY_MAXVEL/'"$XY_MAXVEL"'/' \
	-e 's/REPLACE_Z_MAXVEL/'"$Z_MAXVEL"'/' \
	-e 's/REPLACE_XY_MAXACCEL/'"$XY_MAXACCEL"'/' \
	-e 's/REPLACE_Z_MAXACCEL/'"$Z_MAXACCEL"'/' \
	-e 's/REPLACE_XY_STEPGEN_MAXACCEL/'"$XY_STEPGEN_MAXACCEL"'/' \
	-e 's/REPLACE_Z_STEPGEN_MAXACCEL/'"$XY_STEPGEN_MAXACCEL"'/' \
	-e 's/REPLACE_XY_MIN_LIMIT/'"$XY_MIN_LIMIT"'/' \
	-e 's/REPLACE_Z_MIN_LIMIT/'"$Z_MIN_LIMIT"'/' \
	-e 's/REPLACE_X_MAX_LIMIT/'"$X_MAX_LIMIT"'/' \
	-e 's/REPLACE_Y_MAX_LIMIT/'"$Y_MAX_LIMIT"'/' \
	-e 's/REPLACE_Z_MAX_LIMIT/'"$Z_MAX_LIMIT"'/' \
	-e 's/REPLACE_XY_HOME_OFFSET/'"$XY_HOME_OFFSET"'/' \
	-e 's/REPLACE_Z_HOME_OFFSET/'"$Z_HOME_OFFSET"'/' \
	-e 's/REPLACE_XY_SEARCH_VEL/'"$XY_SEARCH_VEL"'/' \
	-e 's/REPLACE_Z_SEARCH_VEL/'"$Z_SEARCH_VEL"'/' \
	-e 's/REPLACE_XY_LATCH_VEL/'"$XY_LATCH_VEL"'/' \
	-e 's/REPLACE_Z_LATCH_VEL/'"$Z_LATCH_VEL"'/' \
	-e 's/REPLACE_RSC/'"$REPLACE_RSC"'/' \
	-e 's/REPLACE_INC/'"$REPLACE_INC"'/' \
	-e 's/REPLACE_X_PARK/'"$X_PARK"'/' \
	-e 's/REPLACE_Y_PARK/'"$Y_PARK"'/' .TEMP.ini
echo "replace vars in ini file" >> $LOG_FILE

###################################################################################################
#		Save the TEMP files
#
# create link to LinuxCNC on desktop
sed -i -e 's/REPLACE_MACHINE/'"$MACHINE"'/' .TEMP.desktop
cp .TEMP.desktop /home/probotix/Desktop/$MACHINE.desktop
echo "save LinuxCNC desktop link" >> $LOG_FILE

# create link to nc_files on desktop
ln -sf /home/probotix/linuxcnc/nc_files/ /home/probotix/Desktop/nc_files
echo "create nc_files desktop link" >> $LOG_FILE

# move the temp files to LinuxCNC dir
cp .TEMP.ini /home/probotix/linuxcnc/configs/PROBOTIX/probotix.ini
cp .TEMP.hal /home/probotix/linuxcnc/configs/PROBOTIX/probotix.hal
cp .TEMPpostgui.hal /home/probotix/linuxcnc/configs/PROBOTIX/postgui.hal
cp .TEMP.xml /home/probotix/linuxcnc/configs/PROBOTIX/pyvcp.xml
cp .tool.tbl /home/probotix/linuxcnc/configs/PROBOTIX/tool.tbl
cp .emc.nml  /home/probotix/linuxcnc/configs/PROBOTIX/emc.nml
cp .TEMPemc.var  /home/probotix/linuxcnc/configs/PROBOTIX/emc.var
cp .TEMP102.ngc /home/probotix/linuxcnc/nc_files/subs/102.ngc
cp .TEMP100.ngc /home/probotix/linuxcnc/nc_files/subs/100.ngc
echo "save temp files to LinuxCNC dir" >> $LOG_FILE

# remove remaining temp files
rm -f .TEMP*
echo "remove temp files" >> $LOG_FILE

###################################################################################################
#		End
#
f_exit
