#!/bin/bash
# 	PROBOTIX LinuxCNC Configurator
#
# 	Copyright 2018 PROBOTIX
# 	Originally by Len Shelton
# 	Updated by Kaden Lewis
#
_VERSION="2.4.1"

###################################################################################################
# 	some variables
#
INSTALLDIR=$(pwd)
DATETIME=$(date +'%Y-%m-%d-%T')
REBOOT=0
CONFIG_FILE="/home/probotix/LINUXCNC_CONFIG"
LOG_FILE="/home/probotix/LINUXCNC_LOG"
DUMP_DIR="../.CONFIGS"

###################################################################################################
# 	some functions
#
f_prompt() {
	# usage: f_prompt question description
	clear
	printf '%s\n' "PROBOTIX LinuxCNC Configurator Version: $VERSION"
	printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
	printf '%s\n' "$1"
	if [ -n "$2" ]
	then
		printf "$2\n"
	fi
}

f_log() {
	case $2 in
		"show" )
			echo "$1"
			# fall thru
			;&
		"log" | "" )
			echo "$1" >> $LOG_FILE
			;;
		"config" )
			echo "$1" >> $CONFIG_FILE
			;;
		"both" )
			echo "$1" >> $LOG_FILE
			echo "$1" >> $CONFIG_FILE
			;;
	esac
}

f_pause() {
	echo
	# pause for user
	read -rsp $'Press any key to continue...\n' -n 1 key
}

f_exit () {
	f_prompt "Configuration Complete"
	if [ $REBOOT -eq 1 ]
	then
		echo "System will next reboot to apply changes."
		f_pause
		sudo shutdown -r now
	else
		echo "No need to reboot. Restart LinuxCNC to apply changes."
		f_pause
	fi
	exit
}

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
if [ "$(whoami)" = "probotix" ]
then
	# push password into sudo so that it doesnt prompt for it later
	sudo -S <<< "probotix" clear
else
	echo "Not running as user probotix! Call PROBOTIX 844.472.9262"
	echo "This configurator is only intended for Probotix systems."
	f_pause
	exit
fi

if [ -d "/home/probotix" ]
then
	clear
else
	echo "Probotix directory not found! Call PROBOTIX 844.472.9262"
	echo "This configurator is only intended for Probotix systems."
	f_pause
	exit
fi

if [ -d "/home/probotix/emc2" ]
then
	f_log "EMC2 directory found!" "show"
	f_prompt "Do you wish to contine?" "* This will delete your existing EMC2 folder."
	select x in "Yes" "No";
	do
		case $x in
			"Yes" )
				tar -P -czf /home/probotix/.backup.emc2.tar.gz /home/probotix/emc2/
				f_log "EMC2 Backup Created!"
				rm -Rf /home/probotix/emc2
				break;;
			"No" )
				echo "Call PROBOTIX 844.472.9262"
				echo "You appear to be running an old version of LinuxCNC."
				f_pause
				exit
				break;;
		esac
	done
fi

# if log exists
if [ -e $LOG_FILE ]
then
	# read previous log version
	source <(grep VERSION $LOG_FILE)
	# backup old log file then make new one
	cp -f $LOG_FILE "$LOG_FILE.old"
	rm -f $LOG_FILE
	f_log "$LOG_FILE $VERSION found!"
fi

if [ -e $CONFIG_FILE ]
then
	# read previous config version
	source <(grep VERSION $CONFIG_FILE)
	# backup old config file then make new one
	cp -f $CONFIG_FILE "$CONFIG_FILE.old"
	rm -f $CONFIG_FILE
	f_log "$CONFIG_FILE $VERSION found!"
fi

if [ -L /usr/bin/axis ]
then
	f_log "/usr/bin/axis is symlink"
	tar -P -czf /home/probotix/.backup.$DATETIME.tar.gz /home/probotix/linuxcnc/
	f_log "Configuration Backup Created!"
else
	# make a backup of the original axis files
	tar -P -czf /home/probotix/.backup.axis.tar.gz /usr/bin/axis /usr/share/axis /home/probotix/linuxcnc/ /usr/lib/tcltk/linuxcnc/
	f_log "NEW Configuration Backup Created!"
fi

# set version to this script
VERSION=$_VERSION
f_log "this config run version $VERSION at $DATETIME"

###################################################################################################
# 	Step 0: installation type (new or upgrade)
#
f_log "prompt for install type"
f_prompt "Configure machine or update software?:"
select x in "Configure Machine" "Update Software";
do
	case $x in
		"Configure Machine" )
			INSTALL_TYPE="NEW"
			break;;
		"Update Software" )
			INSTALL_TYPE="SOFTWARE"
			break;;
	esac
done
f_log "$x"

###################################################################################################
# 	set num lock
#
if [ -e "/usr/bin/numlockx" ]
then
	f_log "numlockx already installed" "show"
	numlockx
else
	cd .numlockx
	sudo ./configure
	sudo make
	sudo make install
	f_log "installing numlockx" "show"
	numlockx
	cd ..
fi

###################################################################################################
# 	install php so that future versions will be able to use php scripting
#
if $(command -v php >/dev/null)
then
# echo $( command -v php )
	f_log "php already installed" "show"
else
	cd .php/
	sudo dpkg -i php5-common_5.3.2-1ubuntu4.30_i386.deb
	sudo dpkg -i php5-cli_5.3.2-1ubuntu4.30_i386.deb
	f_log "installing php" "show"
	cd ..
fi

###################################################################################################
# 	install samba
#	sudo apt-get install samba
#
if [ -e "/etc/samba/smb.conf" ]
then
	f_log "samba already installed" "show"
else
	cd .samba/
	sudo dpkg -i *.deb
	f_log "installing samba" "show"
	cd ..
fi

###################################################################################################
# 	if a bin folder is found in the $HOME folder, then it is added to the $PATH
# 	this is where we will want to put any php scripts that we access from the GUI
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
f_log "set default editor for .ngc files" "show"

if [ "$INSTALL_TYPE" = "NEW" ]
then
	# remove the desktop icons
	rm -Rf /home/probotix/Desktop/*.desktop
	rm -f /home/probotix/Desktop/nc_files
	f_log "remove desktop icons" "show"

	# delete and recreate the linuxcnc directory
	rm -Rf /home/probotix/linuxcnc
	mkdir -p /home/probotix/linuxcnc/configs/PROBOTIX/axis
	mkdir -p /home/probotix/linuxcnc/nc_files
	f_log "remove and recreate LinuxCNC dir" "show"
fi
cp -R .nc_files/* /home/probotix/linuxcnc/nc_files
cp -f .probotix_splash.gif /home/probotix/linuxcnc/configs/PROBOTIX/probotix_splash.gif
f_log "copy nc_files and splash" "show"

# copy custom stepconf
#sudo cp -f .stepconf /usr/bin/stepconf
#/usr/share/applications/linuxcnc-stepconf.desktop
#/usr/share/linuxcnc/stepconf.glade
#f_log "copy custom stepconf" "show"

# create symlink to axis program
sudo rm -f /usr/bin/axis
sudo rm -Rf /usr/share/axis
cp -Rud .axis_files/axis/* /home/probotix/linuxcnc/configs/PROBOTIX/axis/
sudo ln -s /home/probotix/linuxcnc/configs/PROBOTIX/axis/axis /usr/bin/axis
sudo ln -s /home/probotix/linuxcnc/configs/PROBOTIX/axis /usr/share/axis
f_log "create symlink to axis" "show"

# install fixed tooledit
sudo cp -f .tooledit /usr/bin/tooledit
f_log "copy fixed tooledit" "show"

# install customized files
sudo cp -f .show_errors.tcl /usr/lib/tcltk/linuxcnc/show_errors.tcl
f_log "copy customized files" "show"

# set desktop background
SCREEN_WIDTH=$(xrandr --current | grep '*' | uniq | awk '{print $1}' | cut -d 'x' -f1)
#cp -f .$SCREEN_WIDTH*probotix_background.png /home/probotix/Pictures/.background.png
cp -f .desktop_background.png /home/probotix/Pictures/.background.png
gconftool-2 -t string -s /desktop/gnome/background/picture_filename /home/probotix/Pictures/.background.png
f_log "set desktop background" "show"

# turn off the screen-saver and idle login
gconftool-2 --type bool --set /apps/gnome-screensaver/lock_enabled 0
gconftool-2 --type bool --set /apps/gnome-screensaver/idle_activation_enabled 0
f_log "disable screen-saver/idle login" "show"

# turn on line numbers in gedit
gconftool-2 --type bool --set /apps/gedit-2/preferences/editor/line_numbers/display_line_numbers true
gconftool-2 --type bool --set /apps/gedit-2/preferences/editor/auto_indent/auto_indent 1
f_log "gedit line numbers and auto-indent" "show"

# remove the update manager so that folks can't break linuxcnc with a software update
sudo apt-get -qq -y remove update-manager
f_log "remove update-manager" "show"

if [ "$INSTALL_TYPE" = "SOFTWARE" ]
then
	# no need to create temp files or prompt for other info, simply close
	f_log "Installation of Software Complete" "show"
	f_exit
fi

# create the config file
echo "DATE=$DATETIME" >> $CONFIG_FILE
echo "VERSION=$VERSION" >> $CONFIG_FILE
echo "SCREEN_WIDTH=$SCREEN_WIDTH" >> $CONFIG_FILE
f_log "created config file"

# create some temporary files from our skeleton files
cp .PROBOTIX.ini .TEMP.ini
cp .PROBOTIX.hal .TEMP.hal
cp .PYVCP.xml .TEMP.xml
cp .POSTGUI.hal .TEMPpostgui.hal
cp .102.ngc .TEMP102.ngc
cp .100.ngc .TEMP100.ngc
cp .emc.var .TEMPemc.var
cp .icon.desktop .TEMP.desktop
f_log "create temporary files"

###################################################################################################
# 	this section tries to identify the add-on parallel port address
#
LSPCI=$(lspci -v | grep NetMos)
if [ -z "$LSPCI" ]
then
	f_log "SECOND PARALLEL PORT NOT FOUND" "show"
	sleep 3
fi

# capture output of lscpi and copy it to file on the thumb drive so customer can email it if necessary
rm -rf ./../LSPCI.txt
lspci -v > ./../LSPCI.txt

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
f_log "indentified $IDENTB"

###################################################################################################
# 	Step 1: order number
# 		we will use the order number to create a local database of config files
# 		we can also encode a license mechanism here
#
f_log "prompt for order number"
until [[ $ORDER_NO =~ ^[0-9]+$ ]]
do
	f_prompt "Enter Order Number:"
	read ORDER_NO
done

case $ORDER_NO in
	666 )
		f_log "FACTORY INSTALL" "show"
		sleep 1
		;;
	* )
		f_log "CUSTOMER INSTALL" "show"
		;;
esac

f_log "ORDER_NO=$ORDER_NO" "both"

###################################################################################################
# 	Step 2: machine
#
f_log "prompt for machine"
f_prompt "Choose your machine:"
select x in "V90mk2" "Comet" "Asteroid" "Meteor" "Nebula/MeteorXL" "Custom";
do
	case $x in
		"V90mk2" )
			MACHINE="V90MK2"
			X_MAX_LIMIT=20.25
			Y_MAX_LIMIT=12.4
			UPRIGHT="SHORT"
			ZBEARINGS="2"
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
			f_log "prompt for custom x travel"
			f_prompt "Enter X-Axis Max Travel $UNIT_DESC_BIG"
			read CUSTOM_X_MAX_LIMIT
			f_log "read CUSTOM_X_MAX_LIMIT=$CUSTOM_X_MAX_LIMIT"
			f_log "prompt for custom y travel"
			f_prompt "Enter Y-Axis Max Travel $UNIT_DESC_BIG"
			read CUSTOM_Y_MAX_LIMIT
			f_log "read CUSTOM_Y_MAX_LIMIT=$CUSTOM_Y_MAX_LIMIT"
			# use input values instead of calculated
			f_log "use input values"
			X_MAX_LIMIT=$CUSTOM_X_MAX_LIMIT
			Y_MAX_LIMIT=$CUSTOM_Y_MAX_LIMIT
			break;;
	esac
done

f_log "MACHINE=$MACHINE" "both"

###################################################################################################
# 	Step 3a: up-rights (short or tall)
#
if [ -z $UPRIGHT ]
then
	f_log "prompt for up-right"
	f_prompt "Choose your up-right:" "* Tall up-rights have a triangle cut out, the older Short ones do not.\n* All 2018+ machines have Tall up-rights."
	select x in "Tall" "Short";
	do
		case $x in
			"Short" )
				UPRIGHT="SHORT"
				break;;
			"Tall" )
				UPRIGHT="TALL"
				Y_MAX_LIMIT=$(expr "scale=4; $Y_MAX_LIMIT-1" | bc -l)
				# need new Y for ATLaS if using TALL uprights
				break;;
		esac
	done
fi

f_log "UPRIGHT=$UPRIGHT" "both"
f_log "Y_MAX_LIMIT=$Y_MAX_LIMIT"

###################################################################################################
# 	Step 3b: z bearings (2 or 4)
#		number of bearings and their placement determins Z-axis travel
#
if [ -z $ZBEARINGS ]
then
	f_log "prompt for z bearings"
	f_prompt "Number of Z bearings:" "* 2018+ machines have four Z bearings, older have two Z bearings."
	select x in "Four" "Two";
	do
		case $x in
			"Two" )
				ZBEARINGS=2
				break;;
			"Four" )
				ZBEARINGS=4
				break;;
		esac
	done
fi

case $ZBEARINGS in
	2 )
		# needs to be at least 5.7 to avoid crimping cable
		ZMINLIM=5.7
		;;
	4 )
		ZMINLIM=4.7
		;;
esac

f_log "ZBEARINGS=$ZBEARINGS" "both"

###################################################################################################
# 	Step 4: units (inch or mm)
#
f_log "prompt for units"
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
			REPLACE_INC="0.1in 0.05in 0.01in 0.005in 0.001in"
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
f_log "UNITS=$UNITS" "both"

if [ $MACHINE != "CUSTOM" ]
then
	# use calculated values to adjust for metric
	f_log "use calculated values"
	X_MAX_LIMIT=$(expr "scale=4; $X_MAX_LIMIT*$I" | bc -l)
	Y_MAX_LIMIT=$(expr "scale=4; $Y_MAX_LIMIT*$I" | bc -l)
fi

f_log "X_MAX_LIMIT=$X_MAX_LIMIT" "both"
f_log "Y_MAX_LIMIT=$Y_MAX_LIMIT" "both"

# X_PARK is center of X travel
X_PARK=$(expr "scale=2; $X_MAX_LIMIT/2" | bc -l)
f_log "X_PARK=$X_PARK"
# Y_PARK is .1in from max Y
Y_PARK=$(expr "scale=2; $Y_MAX_LIMIT-(0.1*$I)" | bc -l)
f_log "Y_PARK=$Y_PARK"

Z_MIN_LIMIT=$(expr "scale=2; $ZMINLIM*$I" | bc -l)
f_log "Z_MIN_LIMIT=$Z_MIN_LIMIT"

###################################################################################################
# 	set G28 and G30 locations in emc.var
#
f_log "set G28 and G30 locations in emc.var"
sed -i -e 's/REPLACE_X_PARK/'"$X_PARK"'/' .TEMPemc.var
sed -i -e 's/REPLACE_Y_PARK/'"$Y_PARK"'/' .TEMPemc.var

###################################################################################################
# 	Step 5a: spindle (router or vfd)
#
f_log "prompt for spindle"
f_prompt "Choose your spindle:"
select x in "Router" "VFD Spindle";
do
	case $x in
		"Router" )
			f_log "prompt for superpid"
			f_prompt "Do you have a SuperPID?:" "* Label can be found on Unity backpanel.\n* If you are unsure, say NO"
			select y in "No" "Yes";
			do
				case $y in
					"Yes" )
						SPID="YES"
						break;;
					"No" )
						SPID="NO"
						break;;
				esac
			done
			SPINDLE="ROUTER"
			# remove spindle speed
			f_log "removing spindle from hal files"
			sed -i '/SPINDLE/,+11d' .TEMP.hal
			sed -i '/SPINDLE_SPEED/,+13d' .TEMP.xml
			break;;
		"VFD Spindle" )
			SPINDLE="VFD"
			MOUNT="LONG"
			SPID="NO"
			# remove router code
			f_log "removing router controls from hal file"
			sed -i '/ROUTER/,+6d' .TEMP.hal
			break;;
	esac
done

case $SPID in
	"YES" )
		# remove router code
		f_log "removing router controls from hal file"
		sed -i '/ROUTER/,+6d' .TEMP.hal
		;;
	"NO" )
		# remove superpid code
		f_log "removing superpid from hal files"
		sed -i '/SUPERPID/,+10d' .TEMP.hal
		sed -i '/ROUTER_SPEED/,+13d' .TEMP.xml
		;;
esac

if [ "$SPINDLE" = "ROUTER" ] && [ "$SPID" = "NO" ]
then
	# remove superpid code
	sed -i '/PWM/,+5d' .TEMP.hal
	sed -i '/VFD/,+3d' .TEMPpostgui.hal
fi

f_log "SPINDLE=$SPINDLE" "both"
f_log "SPID=$SPID" "both"

###################################################################################################
# 	Step 6: ACME screw (roton or helix)
#
f_log "prompt for acme"
f_prompt "Choose your ACME screw:" "* Helix: blue drive nuts, Roton: black drive nuts\n* All 2016+ machines have Helix."
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
f_log "ACME=$ACME" "both"

f_log "replace z max velocity in ini file"
sed -i -e 's/REPLACE_ZVELOCITY/'"Z_MAXVEL"'/' .TEMP.ini

###################################################################################################
# 	Step 7: drivers (unipolar or bipolar)
#
f_log "prompt for drivers"
f_prompt "Choose your drivers:" "* MondoStep (newer, bi-polar, black cabinet or Unity controller).\n* Probostep (older, uni-polar, beige control cabinet)."
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
f_log "DRIVERS=$DRIVERS" "both"

f_log "XYSCALE=$XYSCALE"
f_log "ZSCALE=$ZSCALE"

###################################################################################################
# 	Step 8: jogger (gamepad or mpg pendant)
#
f_log "prompt for gamepad"
f_prompt "Do you use the Gamepad or MPG pendant?"
select x in "None" "Gamepad" "MPG Pendant";
do
	case $x in
		"Gamepad" )
			PENDANT="GAMEPAD"
			# remove mpg pendant from hal file
			f_log "remove mpg from hal file"
			sed -i '/MPG_PENDANT/,+62d' .TEMP.hal
			# remove unused second estop section from hal file
			sed -i '/ESTOP_2/,+9d' .TEMP.hal
			break;;
		"MPG Pendant" )
			PENDANT="MPG"
			# remove gamepad from hal file
			f_log "remove gamepad from hal files"
			sed -i '/GAMEPAD/,+1d' .TEMP.hal
			sed -i '/GAMEPAD/,+31d' .TEMPpostgui.hal
			# remove code for single estop usage
			sed -i '/ESTOP_1/,+1d' .TEMP.hal
			break;;
		"None" )
			PENDANT="NONE"
			# remove mpg pendant from hal file
			f_log "remove mpg from hal file"
			sed -i '/MPG_PENDANT/,+62d' .TEMP.hal
			# remove gamepad from hal file
			f_log "remove gamepad from hal files"
			sed -i '/GAMEPAD/,+1d' .TEMP.hal
			sed -i '/GAMEPAD/,+31d' .TEMPpostgui.hal
			# remove unused second estop section from hal file
			sed -i '/ESTOP_2/,+9d' .TEMP.hal
			break;;
	esac
done
f_log "PENDANT=$PENDANT" "both"

###################################################################################################
# 	Step 9: sensors (atlas or zpuck)
#
ZPUCK="NONE"

f_log "prompt for options"
f_prompt "Do you use the ATLaS Tool Length Sensor or the Z-Puck?"
select x in "None" "ATLaS only" "Z-Puck only" "Both";
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
			ZPUCK_DIST=$(expr "scale=2; $ZMINLIM*$I" | bc -l)
			ZPUCK_FEED=$(expr "scale=2; 10*$I" | bc -l)
			f_prompt "Enter Height of Z-Puck $UNIT_DESC"
			read ZPUCK
			sed -i -e 's/REPLACE_GUNITS/'"$GUNITS"'/' \
				-e 's/REPLACE_ZP_DIST/'"$ZPUCK_DIST"'/' \
				-e 's/REPLACE_ZP_FEED/'"$ZPUCK_FEED"'/' \
				-e 's/REPLACE_ZP_HEIGHT/'"$ZPUCK"'/' .TEMP102.ngc
			f_log "ZPUCK=$ZPUCK" "both"
			# remove atlas
			sed -i '/ATLAS/,+5d' .TEMP.xml
			sed -i '/HALUI_FIRST_TOOL/,+1d' .TEMPpostgui.hal
			sed -i '/tool_length_in/d' .TEMP.hal
			break;;
		"Both" )
			SENSOR="BOTH"
			ZPUCK_DIST=$(expr "scale=2; $ZMINLIM*$I" | bc -l)
			ZPUCK_FEED=$(expr "scale=2; 10*$I" | bc -l)
			f_prompt "Enter Height of Z-Puck $UNIT_DESC"
			read ZPUCK
			sed -i -e 's/REPLACE_GUNITS/'"$GUNITS"'/' \
				-e 's/REPLACE_ZP_DIST/'"$ZPUCK_DIST"'/' \
				-e 's/REPLACE_ZP_FEED/'"$ZPUCK_FEED"'/' \
				-e 's/REPLACE_ZP_HEIGHT/'"$ZPUCK"'/' .TEMP102.ngc
			f_log "ZPUCK=$ZPUCK" "both"
			sed -i -e 's/REPLACE_GUNITS/'"$GUNITS"'/' \
				-e 's/REPLACE_ZMIN/'"$Z_MIN_LIMIT"'/' \
				-e 's/REPLACE_MULTIPLIER/'"$I"'/' \
				-e 's/REPLACE_X_PARK/'"$X_PARK"'/' .TEMP100.ngc
			break;;
		"None" )
			SENSOR="NONE"
			# remove probe indicator
			sed -i '/PROBE/,+15d' .TEMP.xml
			sed -i '/PROBE_LED/,+1d' .TEMPpostgui.hal
			sed -i '/PROBE/,+9d' .TEMP.hal
			# remove zpuck control
			sed -i '/ZPUCK/,+5d' .TEMP.xml
			sed -i '/HALUI_ZPUCK/,+1d' .TEMPpostgui.hal
			# remove atlas
			sed -i '/ATLAS/,+5d' .TEMP.xml
			sed -i '/HALUI_FIRST_TOOL/,+1d' .TEMPpostgui.hal
			break;;
	esac
done
f_log "SENSOR=$SENSOR" "both"

###################################################################################################
# 	Step 5b: router mount (long or short)
#		need to ask this to determine ATLaS Y position
#		short mounts are -0.165 shorter from Y center
#
if [ -z $MOUNT ]
then
	f_log "prompt for router mount"
	f_prompt "Choose Your Router Mount:" "* This only matters if you use the ATLaS."
	select x in "One-Piece Mount" "Two-Piece with 3/4in Back Plate" "Two-Piece with 1/2in Back Plate";
	do
		case $x in
			"One-Piece Mount" | "Two-Piece with 3/4in Back Plate" )
				MOUNT="LONG"
				break;;
			"Two-Piece with 1/2in Back Plate" )
				MOUNT="SHORT"
				break;;
		esac
	done
	f_log "$x"
fi

ATLAS_X=-0.075

case $MOUNT in
	"LONG" )
		ATLAS_Y=3.5533
		;;
	"SHORT" )
		ATLAS_Y=3.3883
		;;
esac

f_log "MOUNT=$MOUNT" "both"

###################################################################################################
# 	ATLaS settings
#
ATLAS_X=$(expr "scale=4; $ATLAS_X*$I" | bc -l)
ATLAS_Y=$(expr "scale=4; $ATLAS_Y*$I" | bc -l)
f_log "ATLAS_X=$ATLAS_X"
f_log "ATLAS_Y=$ATLAS_Y"

# hardcode ATLaS offset in 100.ngc
sed -i -e 's/REPLACE_ATLAS_X/'"$ATLAS_X"'/' .TEMP100.ngc
sed -i -e 's/REPLACE_ATLAS_Y/'"$ATLAS_Y"'/' .TEMP100.ngc
f_log "hard code ATLaS offset in 100.ngc"

# set G59.3 offset to center of ATLaS
sed -i -e 's/REPLACE_ATLAS_X/'"$ATLAS_X"'/' .TEMPemc.var
sed -i -e 's/REPLACE_ATLAS_Y/'"$ATLAS_Y"'/' .TEMPemc.var
f_log "set G59.3 offset to center of ATLaS"

###################################################################################################
# 	Step 11: rotary?
#
f_log "prompt for rotary axis"
f_prompt "Do you have the 4th/rotary/A-axis?" "* If unsure, say NO."
select xa in "No" "Yes";
do
	case $xa in
		"Yes" )
			ROTARY="YES"
			COORDINATES="X Y Z A"
			COORDINATES_="X\ Y\ Z\ A"
			AXES=4
			break;;
		"No" )
			ROTARY="NO"
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
f_log "COORDINATES=$COORDINATES" "both"
f_log "ROTARY=$ROTARY" "both"

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

f_log "prompt for driver swap"
f_prompt "Do you want to swap a motor to the A-axis output?" "* For use as a temporary work-around for a failed driver.\n* You will lose use of the rotary when configured like this.\n* If unsure, say NO."
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
f_log "SWAP_TO_A=$x" "both"

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
f_log "set axis pins in hal file"

###################################################################################################
# 	Step 13: soft limits only
#
f_log "prompt for soft limits"
f_prompt "Do you want to use soft limits only?" "* For use when having intermittent limit switch issues from faulty switches or electrical noise.\n* If unsure, say NO."
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
f_log "SOFT_ONLY=$x" "both"

###################################################################################################
# 	Step 10a: confirm parallel port addresses, or enter custom
#
PARPORT0="0x378"
PARPORT1=$IDENTB
f_log "prompt confirm parport addr"
f_prompt "Are the detected parallel port addresses correct?" "* PARPORT0 = $PARPORT0\n* PARPORT1 = $PARPORT1\n* If unsure, say YES."
select x in "Yes" "No";
do
	case $x in
		"Yes" )
			break;;
		"No" )
			echo
			echo "Please enter the correct parallel port addresses."
			echo "PARPORT0:"
			read PARPORT0
			echo "PARPORT1:"
			read PARPORT1
			break;;
	esac
done
f_log "correct parports=$x"

###################################################################################################
# 	Step 10b: swap parallel ports
#
f_log "prompt swap parallel ports"
f_prompt "Do you want to swap the parallel ports?" "* Used to troubleshoot issues with machine control.\n* PARPORT0 = $PARPORT0\n* PARPORT1 = $PARPORT1\n* If unsure, say NO."
select x in "No" "Yes";
do
	case $x in
		"No" )
			SWAP_PARPORTS="NO"
			break;;
		"Yes" )
			SWAP_PARPORTS="YES"
			PARPORT0=$IDENTB
			PARPORT1="0x378"
			break;;
	esac
done
f_log "SWAP_PARPORTS=$SWAP_PARPORTS"

# save parports to hal file
f_log "set parport addr in hal file"
sed -i -e 's/PARPORT0/'"$PARPORT0"'/' \
	-e 's/PARPORT1/'"$PARPORT1"'/' .TEMP.hal

f_log "PARPORT0=$PARPORT0" "both"
f_log "PARPORT1=$PARPORT1" "both"

###################################################################################################
# 	Calculations
#
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
f_log "metricify axis vars"

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
	echo "MOUNT       =" $MOUNT >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "SPID        =" $SPID >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "PENDANT     =" $PENDANT >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "SENSOR      =" $SENSOR >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "ZPUCK       =" $ZPUCK >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "ROTARY      =" $ROTARY >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "PARPORT0    =" $PARPORT0 >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "PARPORT1    =" $PARPORT1 >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "AXES        =" $AXES >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "COORDINATES =" $COORDINATES >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
	echo "ZTPI        =" $ZTPI >> $DUMP_DIR/CONFIG_DUMP.$ORDER_NO
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
	f_log "config dump"
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
f_log "replace vars in ini file"

###################################################################################################
#	Save the TEMP files
#
# create link to LinuxCNC on desktop
sed -i -e 's/REPLACE_MACHINE/'"$MACHINE"'/' .TEMP.desktop
cp .TEMP.desktop /home/probotix/Desktop/$MACHINE.desktop
f_log "save LinuxCNC desktop link"

# wait for LinuxCNC icon to be created
sleep 1

# create link to nc_files on desktop
ln -sf /home/probotix/linuxcnc/nc_files/ /home/probotix/Desktop/nc_files
f_log "create nc_files desktop link"

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
f_log "save temp files to LinuxCNC dir"

# remove remaining temp files
rm -f .TEMP*
f_log "remove temp files"

###################################################################################################
#	End
#
f_exit
