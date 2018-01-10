#!/bin/bash
# 	PROBOTIX LinuxCNC Configurator
# 	zip file created Tue Dec 26 10:35:38 CST 2017
#
# 	Copyright 2016 PROBOTIX
# 	Written by Len Shelton
# 	Version 1.0 release  Mar 29 2016
#
# 	Rev1.1	Bug fixes
# 	Rev1.2	Bug Fixes
# 	Rev1.3
# 		Added PyVCP buttons
# 		Hard Coded G28 & G30 buttons to G53 coordinates
# 		Hard Coded ATLaS location to G53 coordinates
# 		Fixed o102 bug
# 		Consolidated o100 & o101
# 	Rev1.4
# 		Added php installer
# 		Added lspci dump to text file
# 		Misc bug fixes
# 		Fix o100: check for already tool loaded and measured
# 		Added router mount chooser to fix ATLaS Y offset
#
# 	Rev1.5
# 		Added grab_errors.sh script to copy startup errors to thumb drive
# 		Added custom show_errors.tcl to display location of debug files
#
# 	Rev1.6
# 		Set G28 and G30 locations in emc.var
# 		Added key binding "q" to pause/resume toggle
#
# 	Rev1.7
# 		Changed Z min to 10 to check possible G43 problems
# 		Added o130 helical interpolation subroutine
#
# 	Rev1.8
# 		Create log file
# 		Started separating prompts from other stuff so that we can implement defaults and load prior config
# 		Turned off g-zip stdout output
# 		Added MPG pendant support on PARPORT2
# 		Increased max velocity on rotary axis to 2 revs/second
# 		Discovered 8192cu.ko module installation procedure
# 		Fixed panel.xml case issue
#
# 	Rev1.8.1
# 		Added YEAR variable to desktop shortcut name
# 		Prompt for which PARPORT to use for pendant and remove unused PARPORT2 if necessary
# 		Remove second e-stop code if not in use
# 		Remove references to a-axis if no rotary present
# 		General code cleanup and unified formatting
# 	Rev1.8.2
# 		Added HAL code for a-axis rotation jogging
#
# 	Todo:
# 		Fix missing NGC startup file causes o100 to not be found
# 		Fix RS274_STARTUP_CODE to clear tool and offset
# 		Clear preview history after homing
# 		Make insmod edimax permanent
# 		Probe from shorter height
# 		Z-axis min limit fix
# 		Add key bindings for rotary jog
# 		Add support for older gamepads
# 		Check for error on script keyboard input
# 		Finish ngc2 filter
# 		Rotate g-code functions
# 		Update sample g-code programs
# 		Update table grid and threaded insert programs
# 		Increase debounce time for limits only
# 		Put axis files back in original directories
#
#
_VERSION="1.8.2"
###################################################################################################
# 	some variables
#
INSTALLDIR=$(pwd)
DATETIME=$(date +'%Y-%m-%d %T')
REBOOT=0
CONFIG_FILE="/home/probotix/LINUXCNC_CONFIG"
LOG_FILE="/home/probotix/LINUXCNC_LOG"
#rm -f $LOG_FILE

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
if ( whoami != probotix )
then
	echo "Not running as user probotix! Call PROBOTIX 309-691-2643"
	sleep 10
	exit
fi

if [ -d "/home/probotix" ]
then
	clear
else
	echo "Probotix directory not found! Call PROBOTIX 309-691-2643"
	sleep 10
	exit
fi

if [ -d "/home/probotix/emc2" ]
then
	echo "EMC2 directory found! Call PROBOTIX 309-691-2643"
	sleep 10
	exit
fi

if [ -e $CONFIG_FILE ]
then
	# config exists
	# load config variables
	source <(grep VERSION $CONFIG_FILE)
	echo "$CONFIG_FILE $VERSION found!" >> $LOG_FILE
	# just remove it for now and create a new config file
	rm -f $CONFIG_FILE
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

# reset version just in case previous config loaded
VERSION=$_VERSION
echo "DATE="$DATETIME >> $CONFIG_FILE
echo "VERSION=$VERSION" >> $CONFIG_FILE
echo "this config run version $VERSION at "$DATETIME >> $LOG_FILE

###################################################################################################
#	set num lock
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
	cd ..
	echo "installing numlockx" >> $LOG_FILE
	numlockx
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
	sleep 3
	cd ..
fi

###################################################################################################
# 	if a bin folder is found in the $HOME folder, then it is added to the $PATH
# 	this is where we will want to put and php scripts that we access from the GUI
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
# 	this section tries to identify the add-on parallel port address
#
LSPCI=$(lspci -v | grep NetMos)

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
#	misc setup stuff
#
# set the default editor for .ngc files
sudo cp -f .freedesktop.org.xml /usr/share/mime/packages/freedesktop.org.xml
sudo update-mime-database /usr/share/mime
echo "setting default editor for .ngc files" >> $LOG_FILE

# remove the desktop icon
rm -Rf /home/probotix/Desktop/*.desktop

# delete and recreate the linuxcnc directory
rm -Rf /home/probotix/linuxcnc
mkdir -p /home/probotix/linuxcnc
mkdir -p /home/probotix/linuxcnc/configs
mkdir -p /home/probotix/linuxcnc/configs/PROBOTIX
mkdir -p /home/probotix/linuxcnc/configs/PROBOTIX/axis
mkdir -p /home/probotix/linuxcnc/nc_files
cp -R .nc_files/* /home/probotix/linuxcnc/nc_files
sudo cp .probotix_splash.gif /usr/share/linuxcnc/probotix_splash.gif

# create symlink to axis program
sudo rm -f /usr/bin/axis
sudo rm -Rf /usr/share/axis
cp -Rud .axis_files/axis/* /home/probotix/linuxcnc/configs/PROBOTIX/axis/
sudo ln -s /home/probotix/linuxcnc/configs/PROBOTIX/axis/axis /usr/bin/axis
sudo ln -s /home/probotix/linuxcnc/configs/PROBOTIX/axis /usr/share/axis

# install customized files
sudo cp .show_errors.tcl /usr/lib/tcltk/linuxcnc/show_errors.tcl

# create link to nc_files on desktop
rm -f /home/probotix/Desktop/nc_files
ln -sf /home/probotix/linuxcnc/nc_files/ /home/probotix/Desktop/nc_files

# set desktop background
SCREEN_WIDTH=$(xrandr --current | grep '*' | uniq | awk '{print $1}' | cut -d 'x' -f1)
cp -f .$SCREEN_WIDTH*probotix_background.png /home/probotix/Pictures/.background.png
gconftool-2 -t string -s /desktop/gnome/background/picture_filename /home/probotix/Pictures/.background.png
echo "set desktop background" >> $LOG_FILE
echo "SCREEN_WIDTH=$SCREEN_WIDTH" >> $CONFIG_FILE

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

# create some temporary files from our skeleton files
echo "creating temporary files" >> $LOG_FILE
cp .PROBOTIX.ini .TEMP.ini
cp .PROBOTIX.hal .TEMP.hal
cp .PYVCP.xml .TEMP.xml
cp .POSTGUI.hal .TEMPpostgui.hal
cp .102.ngc .TEMP102.ngc
cp .100.ngc .TEMP100.ngc
cp .emc.var .TEMPemc.var

###################################################################################################
# 	Step 1: prompt for the order number
#	 	we will use the order number to create a local database of config files
#		we can also encode a license mechanism here
#
echo "prompt for order number" >> $LOG_FILE
clear
echo "PROBOTIX LinuxCNC Configurator Version: $VERSION"
echo "Enter Order Number:"
read ORDER_NO
echo "ORDER_NO=$ORDER_NO" >> $LOG_FILE
echo "ORDER_NO=$ORDER_NO" >> $CONFIG_FILE

if [ $ORDER_NO -eq 666 ]
then
	clear
	echo "FACTORY INSTALL"
	sleep 1
	echo "FACTORY INSTALL" >> $LOG_FILE
fi

###################################################################################################
#	Step 2: which machine
#
clear
echo "prompt for machine" >> $LOG_FILE
echo "PROBOTIX LinuxCNC Configurator Version: $VERSION"
echo "Choose your machine:"
select x in "V90mk2" "Comet" "Asteroid" "Meteor" "Nebula/MeteorXL" "Custom";
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
			clear
			echo "prompt for custom x travel" >> $LOG_FILE
			echo "PROBOTIX LinuxCNC Configurator Version: $VERSION"
			echo "Enter X-Axis Max Travel $UNIT_DESC_BIG"
			read CUSTOM_X_MAX_LIMIT
			echo "read CUSTOM_X_MAX_LIMIT=$CUSTOM_X_MAX_LIMIT" >> $LOG_FILE
			clear
			echo "prompt for custom y travel" >> $LOG_FILE
			echo "PROBOTIX LinuxCNC Configurator Version: $VERSION"
			echo "Enter Y-Axis Max Travel $UNIT_DESC_BIG"
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
#	Step 3: inch or mm
#
clear
echo "prompt for units" >> $LOG_FILE
echo "PROBOTIX LinuxCNC Configurator Version: $VERSION"
echo "Choose your units:"
select x in "Inch" "Metric";
do
	case $x in
		"Inch" )
			UNITS="inch";
			I=1
			UNIT_DESC="(X.XXX in inches)"
			UNIT_DESC_BIG="(XX.XXX in inches)"
			REPLACE_RSC="G17 G20 G40 G49 G54 G90 G64 P0.001 T0"
			REPLACE_INC=".1in .05in .01in .005in .001in"
			GUNITS="G20"
			break;;
		"Metric" )
			UNITS="mm";
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

# set Z minimum limit to 5.7 - temporarily disabled
#ZMINLIM="5.7"
ZMINLIM="10"
Z_MIN_LIMIT=$(expr "scale=2; $ZMINLIM*$I" | bc -l)
echo "Z_MIN_LIMIT=$Z_MIN_LIMIT" >> $LOG_FILE

###################################################################################################
#	set G28 and G30 locations in emc.var
#
echo "set G28 and G30 locations in emc.var" >> $LOG_FILE
sed -i -e 's/REPLACE_X_PARK/'"$X_PARK"'/' .TEMPemc.var
sed -i -e 's/REPLACE_Y_PARK/'"$Y_PARK"'/' .TEMPemc.var

###################################################################################################
#	Step 4a: which spindle
#
clear
echo "prompt for spindle" >> $LOG_FILE
echo "PROBOTIX LinuxCNC Configurator Version: $VERSION"
echo "Choose your spindle:"
select x in "Router" "VFD Spindle";
do
	case $x in
		"Router" )
			SPINDLE="ROUTER"
			# remove spindle speed
			echo "removing spindle from hal files" >> $LOG_FILE
			sed -i '/PWM/,+5d' .TEMP.hal
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
echo "SPINDLE=$SPINDLE" >> $LOG_FILE
echo "SPINDLE=$SPINDLE" >> $CONFIG_FILE

###################################################################################################
#	Step 4b: which router mount
#		need to ask this to determine ATLaS Y position
#		short mounts are -0.165 shorter from Y center
#
ATLAS_X="-0.075"
ATLAS_Y="3.5533"

if [ $SPINDLE = "ROUTER" ]
then
	clear
	echo "prompt for router mount" >> $LOG_FILE
	echo "PROBOTIX LinuxCNC Configurator Version: $VERSION"
	echo "Choose Your Router Mount"
	select x in "One Piece" "Two-Piece Short Center" "Two-Piece Long Center";
	do
		case $x in
			"One Piece" )
				ROUTER_MOUNT="LONG"
				ATLAS_Y="3.5533"
				break;;
			"Two-Piece Short Center" )
				ROUTER_MOUNT="SHORT"
				ATLAS_Y="3.3883"
				break;;
			"Two-Piece Long Center" )
				ROUTER_MOUNT="LONG"
				ATLAS_Y="3.5533"
				break;;
		esac
	done
	echo "$x" >> $LOG_FILE
fi

echo "ROUTER_MOUNT=$ROUTER_MOUNT" >> $LOG_FILE
echo "ROUTER_MOUNT=$ROUTER_MOUNT" >> $CONFIG_FILE

ATLAS_X=$(expr "scale=4; $ATLAS_X*$I" | bc -l)
ATLAS_Y=$(expr "scale=4; $ATLAS_Y*$I" | bc -l)
echo "ATLAS_X=$ATLAS_X" >> $LOG_FILE
echo "ATLAS_Y=$ATLAS_Y" >> $LOG_FILE

###################################################################################################
#	ATLaS settings
#
# hardcode ATLaS offset in 100.ngc
echo "hard code ATLaS offset in 100.ngc" >> $LOG_FILE
sed -i -e 's/REPLACE_ATLAS_X/'"$ATLAS_X"'/' .TEMP100.ngc
sed -i -e 's/REPLACE_ATLAS_Y/'"$ATLAS_Y"'/' .TEMP100.ngc
sed -i -e 's/REPLACE_ATLAS_Y/'"$ATLAS_Y"'/' .nc_files/utilities/table_extents.ngc

# set G59.3 offset to center of ATLaS
echo "set G59.3 offset to center of ATLaS" >> $LOG_FILE
sed -i -e 's/REPLACE_ATLAS_X/'"$ATLAS_X"'/' .TEMPemc.var
sed -i -e 's/REPLACE_ATLAS_Y/'"$ATLAS_Y"'/' .TEMPemc.var

###################################################################################################
#	Step 5: which ACME screw
#
clear
echo "prompt for acme" >> $LOG_FILE
echo "PROBOTIX LinuxCNC Configurator Version: $VERSION"
echo "Choose your ACME screw:"
select x in "Roton" "Helix";
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
#	Step 6: which drivers (unipolar or bipolar)
#
clear
echo "prompt for drivers" >> $LOG_FILE
echo "PROBOTIX LinuxCNC Configurator Version: $VERSION"
echo "Choose your drivers:"
select x in "ProboStep" "MondoStep";
do
	case $x in
		"ProboStep" )
			DRIVERS="PROBOSTEP";
			XYSCALE=$(expr "scale=4; 2*200*2/$I" | bc -l)
			ZSCALE=$(expr "scale=4; 2*200*$ZTPI/$I" | bc -l)
			break;;
		"MondoStep" )
			DRIVERS="MONDOSTEP";
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
#	Step 7: gamepad or mpg pendant?
#
clear
echo "prompt for gamepad" >> $LOG_FILE
echo "PROBOTIX LinuxCNC Configurator Version: $VERSION"
echo "Do you use the GamePad or MPG pendant?"
select x in "GamePad" "MPG Pendant" "None";
do
	case $x in
		"GamePad" )
			PENDANT="GAMEPAD"
			# remove mpg pendant from hal file
			echo "remove mpg from hal file" >> $LOG_FILE
			sed -i '/MPG_PENDANT/,+59d' .TEMP.hal
			break;;
		"MPG Pendant" )
			PENDANT="MPG"
			# remove gamepad from hal file
			echo "remove gamepad from hal files" >> $LOG_FILE
			sed -i '/GAMEPAD/,+1d' .TEMP.hal
			sed -i '/GAMEPAD/,+31d' .TEMPpostgui.hal
			break;;
		"None" )
			PENDANT="NONE"
			# remove mpg pendant from hal file
			echo "remove mpg from hal file" >> $LOG_FILE
			sed -i '/MPG_PENDANT/,+59d' .TEMP.hal
			# remove gamepad from hal file
			echo "remove gamepad from hal files" >> $LOG_FILE
			sed -i '/GAMEPAD/,+1d' .TEMP.hal
			sed -i '/GAMEPAD/,+31d' .TEMPpostgui.hal
			break;;
	esac
done
echo "PENDANT=$PENDANT" >> $LOG_FILE
echo "PENDANT=$PENDANT" >> $CONFIG_FILE

###################################################################################################
#	Step 8: confirm parallel port addresses, or enter custom
#
PARPORT0="0x378"
PARPORT1=$IDENTB
#PARPORT2="0xd030"
clear
echo "prompt confirm parport addr" >> $LOG_FILE
echo "PROBOTIX LinuxCNC Configurator Version: $VERSION"
echo "PARPORT.0 $PARPORT0, PARPORT.1 $PARPORT1 Okay?"
select x in "Yes" "No";
do
	case $x in
		"Yes" )
			break;;
		"No" )
			clear
			echo "PROBOTIX LinuxCNC Configurator Version: $VERSION"
			echo "Enter PARPORT0:"
			read PARPORT0
			clear
			echo "PROBOTIX LinuxCNC Configurator Version: $VERSION"
			echo "Enter PARPORT1:"
			read PARPORT1
			break;;
	esac
done
echo "$x" >> $LOG_FILE

if [ $PENDANT = "MPG" ]
then
	echo "PROBOTIX LinuxCNC Configurator Version: $VERSION"
	echo "Choose PARPORT for pendant use:"
	select x in "PARPORT.1" "PARPORT.2";
	do
		case $x in
			"PARPORT.1" )
				# cfg="PARPORT0 PARPORT1PARPORT2"
				# set parport1 as input-only by changing value of PARPORT2
				PARPORT2=" in"
				# comment-out reset-time for parport1 as now input-only
				sed -i '/parport.1.reset-time/s/^/#/' .TEMP.hal
				# remove parport2 section from hal file
				sed -i '/PARPORT2x/,+3d' .TEMP.hal
				# replace all instances of parport.2 with parport.1
				sed -i -e 's/parport.2/parport.1/g' .TEMP.hal
				break;;
			"PARPORT.2" )
				echo "Enter PARPORT2:"
				read PARPORT2
				PARPORT2=" $PARPORT2 in"
				break;;
		esac
	done
	# remove code for single estop usage
	sed -i '/ESTOP_1/,+1d' .TEMP.hal
else
	PARPORT2="NONE"
	# remove parport2 section from hal file
	sed -i '/PARPORT2x/,+3d' .TEMP.hal
	# remove parport2 var in hal file
	sed -i 's/PARPORT2//' .TEMP.hal
	# remove unused second estop section from hal file
	sed -i '/ESTOP_2/,+9d' .TEMP.hal
fi

###################################################################################################
#	Step 9: option selection
#
ZPUCK="NONE"
clear
echo "prompt for options" >> $LOG_FILE
echo "PROBOTIX LinuxCNC Configurator Version: $VERSION"
echo "Do you use the ATLaS Tool Length Sensor or the Z-Puck?"
select x in "ATLaS only" "Z-Puck only" "Both" "None" "Swap Parallel Ports";
do
	case $x in
		"ATLaS only" )
			SENSOR="ATLAS";
			# remove zpuck control
			sed -i '/ZPUCK/,+5d' .TEMP.xml
			sed -i '/HALUI_ZPUCK/,+1d' .TEMPpostgui.hal
			sed -i -e 's/REPLACE_GUNITS/'"$GUNITS"'/' \
				-e 's/REPLACE_ZMIN/'"$Z_MIN_LIMIT"'/' \
				-e 's/REPLACE_MULTIPLIER/'"$I"'/' \
				-e 's/REPLACE_X_PARK/'"$X_PARK"'/' .TEMP100.ngc
			break;;
		"Z-Puck only" )
			SENSOR="Z-Puck";
			ZPUCK_DIST=$(expr "scale=2; 5*$I" | bc -l)
			ZPUCK_FEED=$(expr "scale=2; 10*$I" | bc -l)
			clear
			echo "PROBOTIX LinuxCNC Configurator Version: $VERSION"
			echo "Enter Height of Z-Puck $UNIT_DESC"
			read ZPUCK
			sed -i -e 's/REPLACE_ZP_HEIGHT/'"$ZPUCK"'/' \
				-e 's/REPLACE_ZP_DIST/'"$ZPUCK_DIST"'/' \
				-e 's/REPLACE_ZP_FEED/'"$ZPUCK_FEED"'/' \
				-e 's/REPLACE_GUNITS/'"$GUNITS"'/' .TEMP102.ngc
			# remove atlas
			sed -i '/ATLAS/,+5d' .TEMP.xml
			sed -i '/HALUI_FIRST_TOOL/,+1d' .TEMPpostgui.hal
			break;;
		"Both" )
			SENSOR="BOTH";
			ZPUCK_DIST=$(expr "scale=2; 5*$I" | bc -l)
			ZPUCK_FEED=$(expr "scale=2; 10*$I" | bc -l)
			clear
			echo "PROBOTIX LinuxCNC Configurator Version: $VERSION"
			echo "Enter Height of Z-Puck $UNIT_DESC"
			read ZPUCK
			sed -i -e 's/REPLACE_ZP_HEIGHT/'"$ZPUCK"'/' \
				-e 's/REPLACE_ZP_DIST/'"$ZPUCK_DIST"'/' \
				-e 's/REPLACE_ZP_FEED/'"$ZPUCK_FEED"'/' \
				-e 's/REPLACE_GUNITS/'"$GUNITS"'/' .TEMP102.ngc
			sed -i -e 's/REPLACE_GUNITS/'"$GUNITS"'/' \
				-e 's/REPLACE_ZMIN/'"$Z_MIN_LIMIT"'/' \
				-e 's/REPLACE_MULTIPLIER/'"$I"'/' \
				-e 's/REPLACE_X_PARK/'"$X_PARK"'/' .TEMP100.ngc
			break;;
		"Swap Parallel Ports" )
			SENSOR="NONE";
			PARPORT0=$IDENTB
			PARPORT1="0x378"
			# fall-thru
			;&
		"None" )
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
echo "$x" >> $LOG_FILE

echo "PARPORT0=$PARPORT0" >> $LOG_FILE
echo "PARPORT1=$PARPORT1" >> $LOG_FILE
echo "PARPORT2=$PARPORT2" >> $LOG_FILE
echo "PARPORT0=$PARPORT0" >> $CONFIG_FILE
echo "PARPORT1=$PARPORT1" >> $CONFIG_FILE
echo "PARPORT2=$PARPORT2" >> $CONFIG_FILE

echo "set parport addr in hal file" >> $LOG_FILE
sed -i -e 's/PARPORT0/'"$PARPORT0"'/' \
	-e 's/PARPORT1/'"$PARPORT1"'/' \
	-e 's/PARPORT2/'"$PARPORT2"'/' .TEMP.hal

###################################################################################################
#	Step 10: rotary?
#
clear
echo "PROBOTIX LinuxCNC Configurator Version: $VERSION"
echo "Do you have the rotary axis?"
select xa in "Yes" "No";
do
	case $xa in
		"Yes" )
			COORDINATES="X Y Z A";
			COORDINATES_="X\ Y\ Z\ A";
			AXES="4";
			break;;
		"No" )
			COORDINATES="X Y Z";
			COORDINATES_="X\ Y\ Z";
			AXES="3";
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
#	Step 11: driver swap
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
clear
echo "PROBOTIX LinuxCNC Configurator Version: $VERSION"
echo "Do you want to swap a motor to the A-axis output?"
select x in "X" "Y1" "Y2" "Z" "No";
do
	case $x in
		"X" )
			XSTEP="17"
			XDIR="01"
			COORDINATES="X Y Z";
			COORDINATES_="X\ Y\ Z";
			AXES="3";
			# continue matching
			;;&
		"Y1" )
			Y1STEP="17"
			Y1DIR="01"
			COORDINATES="X Y Z";
			COORDINATES_="X\ Y\ Z";
			AXES="3";
			;;&
		"Y2" )
			Y2STEP="17"
			Y2DIR="01"
			COORDINATES="X Y Z";
			COORDINATES_="X\ Y\ Z";
			AXES="3";
			;;&
		"Z" )
			ZSTEP="17"
			ZDIR="01"
			COORDINATES="X Y Z";
			COORDINATES_="X\ Y\ Z";
			AXES="3";
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

###################################################################################################
#	Step 12: soft limits only
#
clear
echo "PROBOTIX LinuxCNC Configurator Version: $VERSION"
echo "Do you want to use soft limits only?"
select x in "Yes" "No";
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

clear
echo "ORDER_NO    =" $ORDER_NO >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO
echo "MACHINE     =" $MACHINE >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO
echo "UNITS       =" $UNITS >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO
echo "ACME        =" $ACME >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO
echo "DRIVERS     =" $DRIVERS >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO
echo "SPINDLE     =" $SPINDLE >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO
echo "PENDANT     =" $PENDANT >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO
echo "SENSOR      =" $SENSOR >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO
echo "AXES        =" $AXES >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO
echo "COORDINATES =" $COORDINATES >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO
echo "ZPUCK       =" $ZPUCK >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO
echo "ZTPI        =" $ZTPI >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO
echo "PARPORT0    =" $PARPORT0 >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO
echo "PARPORT1    =" $PARPORT1 >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO
echo "XYSCALE     =" $XYSCALE >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO
echo "ZSCALE      =" $ZSCALE >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO
echo "XY_MAXVEL   =" $XY_MAXVEL >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO
echo "Z_MAXVEL    =" $Z_MAXVEL >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO
echo "XY_MAXACCEL =" $XY_MAXACCEL >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO
echo "Z_MAXACCEL  =" $Z_MAXACCEL >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO
echo "XY_SMAX_ACC =" $XY_STEPGEN_MAXACCEL >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO
echo "Z_SMAX_ACC  =" $Z_STEPGEN_MAXACCEL >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO
echo "XY_MIN_LIMIT=" $XY_MIN_LIMIT >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO
echo "Z_MIN_LIMIT =" $Z_MIN_LIMIT >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO
echo "X_MAX_LIMIT =" $X_MAX_LIMIT >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO
echo "Y_MAX_LIMIT =" $Y_MAX_LIMIT >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO
echo "Z_MAX_LIMIT =" $Z_MAX_LIMIT >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO
echo "XY_HM_OFFSET=" $XY_HOME_OFFSET >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO
echo "Z_HM_OFFSET =" $Z_HOME_OFFSET >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO
echo "XY_SEARCH_VL=" $XY_SEARCH_VEL >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO
echo "Z_SEARCH_VEL=" $Z_SEARCH_VEL >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO
echo "XY_LATCH_VEL=" $XY_LATCH_VEL >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO
echo "Z_LATCH_VEL =" $Z_LATCH_VEL >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO
echo "DEF_VELOCITY=" $DEFAULT_VELOCITY >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO
echo "MAX_LIN_VEL =" $MAX_LINEAR_VELOCITY >> .CONFIGS/CONFIG_DUMP-.$ORDER_NO

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

###################################################################################################
#	Save the TEMP files
#
# create icon
YEAR=$(date +%Y)
cp .icon.desktop .TEMP.desktop
sed -i -e 's/REPLACE_MACHINE/'"$MACHINE $YEAR"'/' .TEMP.desktop
cp .TEMP.desktop /home/probotix/Desktop/$MACHINE.desktop

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

# remove remaining temp files
rm -f .TEMP*

###################################################################################################
#	End
#
clear
echo "PROBOTIX LinuxCNC Configurator Version: $VERSION"
echo "Configuration Complete"
if [ $REBOOT = 1 ]
then
	echo "Please reboot the PC to apply changes."
else
	echo "No need to reboot. Restart LinuxCNC to apply changes."
fi
echo
echo "This window will close in 10 seconds"

sleep 10
