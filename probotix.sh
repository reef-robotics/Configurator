#!/bin/bash
CONFIG_NAME="PROBOTIX Galaxy Series LinuxCNC Configurator"
#
#	Copyright 2018 PROBOTIX
#	Originally by Len Shelton
#	Updated by Kaden Lewis
#
_VERSION="3.1.1"

###################################################################################################
# 	some variables
#
INSTALLDIR=$(pwd)
DATETIME=$(date +'%Y-%m-%d-%T')
REBOOT=0
DEBUG=0
CONFIG_FILE="/home/probotix/LINUXCNC_CONFIG"
LOG_FILE="/home/probotix/LINUXCNC_LOG"
DUMP_DIR="../.CONFIGS"

###################################################################################################
# 	some functions
#
f_prompt() {
	# usage: f_prompt question description
	if [ $DEBUG -eq 0 ]; then
		clear
	fi
	printf '%s\n' "$CONFIG_NAME v$_VERSION"
	printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
	printf '%s\n' "$1"
	if [ -n "$2" ]; then
		printf "$2\n"
	fi
}

f_log() {
	case $2 in
		"show" | "" )
			echo "$1"
			;& # fall thru
		"log" | "both" )
			echo "[$DATETIME] $1" >> $LOG_FILE
			;;& # continue matching
		"config" | "both" )
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
	if [ $REBOOT -eq 1 ]; then
		echo "System will next reboot to apply changes."
		sleep 3
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
if [ -e "./debug" ]; then
	DEBUG=1
fi

if [[ "$INSTALLDIR/" != /media/* ]]; then
	echo "You appear to have copied the Configurator to the Linux PC."
	echo "Delete this and re-run from the removeable drive instead."
	echo
	echo "No changes made to system. Configurator will now close."
	f_pause
	exit
fi

if [ "$(whoami)" = "probotix" ]; then
	# push password into sudo so that it doesnt prompt for it later
	sudo -S <<< "probotix" clear
else
	f_log "Not running as user probotix!"
	echo "This configurator is only intended for PROBOTIX systems."
	echo "Call PROBOTIX 844.472.9262 for more help."
	f_pause
	exit
fi

if [ ! -d "/home/probotix" ]; then
	f_log "Probotix directory not found!"
	echo "This configurator is only intended for PROBOTIX systems."
	echo "Call PROBOTIX 844.472.9262 for more help."
	f_pause
	exit
fi

if [ -d "/home/probotix/emc2" ]; then
	f_log "EMC2 directory found!"
	echo "You appear to be running an old version of LinuxCNC."
	echo "Call PROBOTIX 844.472.9262 for more help."
	f_pause
	exit
fi

# if log exists
if [ -e $LOG_FILE ]; then
	# read previous log version
	source <(grep VERSION $LOG_FILE)
	# backup old log file then make new one
	cp -f $LOG_FILE "$LOG_FILE.old"
	rm -f $LOG_FILE
	f_log "$LOG_FILE $VERSION found!"
fi

if [ -e $CONFIG_FILE ]; then
	f_prompt "Change Settings or Start Over?"
	select x in "Change Settings" "Start Over"; do
		case $x in
			"Start Over" )
				# read previous config version
				source <(grep VERSION $CONFIG_FILE)
				break;;
			"Change Settings" )
				INSTALL_TYPE="MODIFY"
				# case insensitive matching for compatibility with older configs
				shopt -s nocasematch
				# read previous config
				source $CONFIG_FILE
				while [ -z "$SETTINGS" ]; do
					f_prompt "What would you like to change?" "* Order# = $ORDER_NO\n* Machine = $MACHINE\n* Spindle/Mount = $SPINDLE/$MOUNT\n* Controller Drivers = $DRIVERS\n* Gamepad/Pendant = $PENDANT\n* Sensors = $SENSOR\n* 4th Axis Rotary = $ROTARY\n* Laser = $LASER\n* Units = $UNITS\n* Swap Motor A = $SWAP_TO_A\n* Ignore Limit Switches = $SOFT_ONLY\n* Parallel Ports: $PARPORT0, $PARPORT1"
					select y in "Exit" "Machine" "Spindle/Mount" "Controller" "Gamepad/Pendant" "Sensors" "4th Axis Rotary" "Laser" "Units" "Advanced Settings" ; do
						SETTINGS=$y
						break
					done # select

					case $SETTINGS in
						"Exit" )
							f_prompt "No changes made to system. Configurator will now close."
							f_pause
							exit
							;;
						"Machine" )
							unset -v SERIES
							unset -v MACHINE
							unset -v UPRIGHT
							unset -v ZBEARINGS
							unset -v ACME
							;;
						"Spindle/Mount" )
							unset -v SPINDLE
							unset -v SPID
							unset -v MOUNT
							;;
						"Controller" )
							unset -v DRIVERS
							;;
						"Gamepad/Pendant" )
							unset -v PENDANT
							;;
						"Sensors" )
							unset -v SENSOR
							unset -v ZPUCK
							;;
						"4th Axis Rotary" )
							unset -v ROTARY
							;;
						"Laser" )
							unset -v LASER
							;;
						"Units" )
							unset -v UNITS
							;;
						"Advanced Settings" )
							SETTINGS="ADVANCED"
							f_prompt "These options are intended for troubleshooting purposes and not for beginners." "* Only use if you know what you are doing!\n2) Swap Motor A = $SWAP_TO_A\n3) Ignore Limit Switches = $SOFT_ONLY\n4) Parallel Ports: $PARPORT0, $PARPORT1"
							select z in "Go Back" "Swap Motor A" "Disable Hardware Limits" "Parallel Ports" ; do
								case $z in
									"Go Back" )
										unset -v SETTINGS
										break;;
									"Swap Motor A" )
										unset -v SWAP_TO_A
										break;;
									"Disable Hardware Limits" )
										unset -v SOFT_ONLY
										break;;
									"Parallel Ports" )
										unset -v SWAP_PARPORTS
										#unset -v PARPORT0
										#unset -v PARPORT1
										break;;
								esac
							done # select
							;; # "Advanced Settings"
					esac

					if [ -n "$SETTINGS" ]; then
						f_prompt "Do you wish to change another setting?"
						select z in "No" "Yes" ; do
							case $z in
								"No" )
									# keep SETTINGS=$y
									break;;
								"Yes" )
									unset -v SETTINGS
									break;;
							esac
						done # select
					fi
				done # while [ -z $SETTINGS ]
				break;;
		esac
	done # select
	# backup old config file
	cp -f $CONFIG_FILE "$CONFIG_FILE.old"
	rm -f $CONFIG_FILE
	f_log "$CONFIG_FILE $VERSION found!"
fi

if [ -L /usr/bin/axis ] || [ -L /usr/bin/probotix-axis ]; then
	f_log "PROBOTIX Axis Interface detected"
	f_log "Backing up ~/linuxcnc folder..."
	tar -P -czf /home/probotix/.backup.$DATETIME.tar.gz /home/probotix/linuxcnc/
	f_log "LinuxCNC Backup Created!"
else
	# make a backup of the original axis files
	f_log "Backing up original Axis files..."
	tar -P -czf /home/probotix/.backup.axis.tar.gz /usr/bin/axis /usr/share/axis /home/probotix/linuxcnc/ /usr/lib/tcltk/linuxcnc/
	f_log "Original Axis Backup Created!"
fi

# set version to this script
VERSION=$_VERSION
f_log "$CONFIG_NAME v$VERSION"

###################################################################################################
# 	Step 0: installation type
#
if [ -z $INSTALL_TYPE ]; then
	f_log "prompt for install type"
	f_prompt "Configure machine or update software?:"
	select x in "Configure Machine" "Update Software"; do
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
fi

if [ "$INSTALL_TYPE" != "MODIFY" ]; then
	###################################################################################################
	#	Apply Settings
	#
	# set desktop background
	f_log "set desktop background"
	SCREEN_WIDTH=$(xrandr --current | grep '*' | uniq | awk '{print $1}' | cut -d 'x' -f1)
	cp -f .desktop_background.png /home/probotix/Pictures/.background.png
	gconftool-2 -t string -s /desktop/gnome/background/picture_filename /home/probotix/Pictures/.background.png

	# set the default editor for .ngc files
	f_log "set default editor for .ngc files"
	sudo cp -f .freedesktop.org.xml /usr/share/mime/packages/freedesktop.org.xml
	sudo update-mime-database /usr/share/mime

	# turn off the screen-saver and idle login
	f_log "disable screen-saver/idle login"
	gconftool-2 --type bool --set /apps/gnome-screensaver/lock_enabled 0
	gconftool-2 --type bool --set /apps/gnome-screensaver/idle_activation_enabled 0

	# gedit settings
	f_log "gedit settings"
	gconftool-2 --type bool --set /apps/gedit-2/preferences/editor/line_numbers/display_line_numbers true
	gconftool-2 --type bool --set /apps/gedit-2/preferences/editor/auto_indent/auto_indent 1
	gconftool-2 --type int --set /apps/gedit-2/preferences/editor/tabs/tabs_size 4

	# remove the update manager so that folks can't break linuxcnc with a software update
	f_log "remove update-manager"
	sudo apt-get -qq -y remove update-manager

	###################################################################################################
	#	Install Software
	#
	f_log "installing software"
	# set num lock
	if [ -e "/usr/bin/numlockx" ]; then
		f_log "numlockx already installed"
		numlockx
	else
		cd .numlockx
		sudo ./configure
		sudo make
		f_log "installing numlockx"
		sudo make install
		numlockx
		cd ..
	fi

	# install php so that future versions will be able to use php scripting
	if $(command -v php >/dev/null); then
		# echo $( command -v php )
		f_log "php already installed"
	else
		cd .php/
		f_log "installing php"
		sudo dpkg -i php5-common_5.3.2-1ubuntu4.30_i386.deb
		sudo dpkg -i php5-cli_5.3.2-1ubuntu4.30_i386.deb
		cd ..
	fi

	# install samba
	# sudo apt-get install samba
	if [ -e "/etc/samba/smb.conf" ]; then
		f_log "samba already installed"
	else
		cd .samba/
		f_log "installing samba"
		sudo dpkg -i *.deb
		cd ..
	fi

	# if a bin folder is found in the $HOME folder, then it is added to the $PATH
	# this is where we will want to put any php scripts that we access from the GUI
	if [ -d "/home/probotix/bin" ]; then
		cp -fR .bin/* /home/probotix/bin
	else
		mkdir -p /home/probotix/bin
		cp -fR .bin/* /home/probotix/bin
		# this one will require a reboot
		REBOOT=1
	fi
fi # [ "$INSTALL_TYPE" != "MODIFY" ]

if [ "$INSTALL_TYPE" = "SOFTWARE" ]; then
	# no need to create temp files or prompt for other info, simply close
	f_log "Installation of Software Complete"
	f_exit
fi

###################################################################################################
# 	this section tries to identify the add-on parallel port address
#
LSPCI=$(lspci -v | grep -i "parallel")
if [ -z "$LSPCI" ]; then
	f_log "SECOND PARALLEL PORT NOT FOUND"
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

if [ $LEN -eq 6 ]; then
	IDENTB=$IDENT
else
	IDENTB="0xd050"
fi
f_log "identified PARAPORT1 at $IDENTB"

###################################################################################################
# 	misc setup stuff
#
if [ "$INSTALL_TYPE" = "NEW" ]; then
	# set some defaults
	f_log "set some defaults"
	SWAP_TO_A="NO"
	SOFT_ONLY="NO"
	SWAP_PARPORTS="NO"
	PARPORT0="0x378"
	PARPORT1=$IDENTB
fi

# create the config file
f_log "create config file"
echo "DATE=$DATETIME" >> $CONFIG_FILE
echo "VERSION=$VERSION" >> $CONFIG_FILE

# create some temporary files from our skeleton files
f_log "create temporary files"
cp .PROBOTIX.ini .TEMP.ini
cp .PROBOTIX.hal .TEMP.hal
cp .PYVCP.xml .TEMP.xml
cp .POSTGUI.hal .TEMPpostgui.hal
cp .102.ngc .TEMP102.ngc
cp .100.ngc .TEMP100.ngc
cp .emc.var .TEMPemc.var
cp .icon.desktop .TEMP.desktop

###################################################################################################
# 	Step 1: order number
# 		we will use the order number to create a local database of config files
# 		we can also encode a license mechanism here
#
if [ -z $ORDER_NO ]; then
	f_log "prompt for order number"
	until [[ $ORDER_NO =~ ^[0-9]+$ ]]; do
		f_prompt "Enter Order Number:" "* If you do not know your order number, enter 00000"
		read ORDER_NO
	done
fi

case $ORDER_NO in
	666 )
		f_log "FACTORY INSTALL"
		;;
	* )
		f_log "CUSTOMER INSTALL"
		;;
esac

f_log "ORDER_NO=$ORDER_NO" "both"

###################################################################################################
# 	Series & Machine Selection
#
GX=("GX2525" "GX2550" "GX3725" "GX3750" "GX5050" "CUSTOM")
GALAXY=("V90MK2" "COMET" "METEOR" "ASTEROID" "NEBULA" "CUSTOM")
FIREBALL=("V90MK2" "COMET" "METEOR" "ASTEROID" "METEORXL" "CUSTOM")

# Series selection removed
SERIES="GALAXY"

case $SERIES in
	"GX" )
		SERIESARR=( "${GX[@]}" )
		UPRIGHT="TALL"
		ZBEARINGS=4
		ACME="HELIX"
		DRIVERS="MONDOSTEP"
		MOUNT="LONG"
		;;
	"GALAXY" )
		SERIESARR=( "${GALAXY[@]}" )
		;;
	"FIREBALL" )
	 	SERIESARR=( "${FIREBALL[@]}" )
	 	UPRIGHT="SHORT"
	 	ZBEARINGS=2
		;;
esac

f_log "SERIES=$SERIES" "both"

if [ -z $MACHINE ]; then
	f_prompt "Choose your machine:"
	select x in "${SERIESARR[@]}"; do
		MACHINE=$x
		break
	done
fi

case $MACHINE in
	"V90MK2" )
		X_MAX_LIMIT=20.25
		Y_MAX_LIMIT=12.4
		UPRIGHT="SHORT"
		ZBEARINGS=2
		;;
	"GX2525" | "COMET" )
		X_MAX_LIMIT=26.125
		Y_MAX_LIMIT=25.1152
		;;
	"GX2550" | "METEOR" )
		X_MAX_LIMIT=26.125
		Y_MAX_LIMIT=52.2
		;;
	"GX3725" | "ASTEROID" )
		X_MAX_LIMIT=37.25
		Y_MAX_LIMIT=25.1152
		;;
	"GX3750" | "NEBULA" | "METEORXL" )
		X_MAX_LIMIT=37.25
		Y_MAX_LIMIT=52.2
		;;
	"GX5050" )
		X_MAX_LIMIT=53.6
		Y_MAX_LIMIT=51
		UPRIGHT="TALL"
		ZBEARINGS=4
		;;
	"CUSTOM" )
		f_log "prompt for custom x travel"
		until [[ $CUSTOM_X_MAX_LIMIT =~ ^[0-9]+\.?[0-9]*$ ]]; do
			f_prompt "Enter X-Axis Max Travel $UNIT_DESC_BIG"
			read CUSTOM_X_MAX_LIMIT
		done
		f_log "CUSTOM_X_MAX_LIMIT=$CUSTOM_X_MAX_LIMIT"
		f_log "prompt for custom y travel"
		until [[ $CUSTOM_Y_MAX_LIMIT =~ ^[0-9]+\.?[0-9]*$ ]]; do
			f_prompt "Enter Y-Axis Max Travel $UNIT_DESC_BIG"
			read CUSTOM_Y_MAX_LIMIT
		done
		f_log "CUSTOM_Y_MAX_LIMIT=$CUSTOM_Y_MAX_LIMIT"
		# use input values instead of calculated
		f_log "use input values"
		X_MAX_LIMIT=$CUSTOM_X_MAX_LIMIT
		Y_MAX_LIMIT=$CUSTOM_Y_MAX_LIMIT
		;;
esac

f_log "MACHINE=$MACHINE" "both"

if [ "$MACHINE" != "GX3750" ]; then
	# only GX3750 has laser option
	LASER="NO"
fi

###################################################################################################
# 	Step 3a: up-rights (short or tall)
#
if [ -z $UPRIGHT ]; then
	f_log "prompt for up-right"
	f_prompt "Choose your up-right:" "* Tall up-rights have a triangle cut out (all machines 2018+).\n* Short up-rights are solid with no holes."
	select x in "Tall" "Short"; do
		case $x in
			"Short" )
				UPRIGHT="SHORT"
				ZBEARINGS=2
				break;;
			"Tall" )
				UPRIGHT="TALL"
				break;;
		esac
	done
fi

if [ "$SERIES" = "GX" ] || [ "$UPRIGHT" = "TALL" ] && [ "$MACHINE" != "GX5050" ]; then
	f_log "adjust Y_MAX_LIMIT for tall uprights"
	Y_MAX_LIMIT=$(expr "scale=4; $Y_MAX_LIMIT-1" | bc -l)
fi

f_log "UPRIGHT=$UPRIGHT" "both"

###################################################################################################
# 	Step 3b: z bearings (2 or 4)
#		number of bearings and their placement determins Z-axis travel
#
if [ -z $ZBEARINGS ]; then
	f_log "prompt for z bearings"
	f_prompt "Number of Z bearings:" "* Tall up-rights typically have four Z bearings (all machines 2018+).\n* Older machines with short up-rights typically have two Z bearings."
	select x in "Four" "Two"; do
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
if [ -z $UNITS ]; then
	f_log "prompt for units"
	f_prompt "Choose your units:"
	select x in "Inch" "Metric"; do
		case $x in
			"Inch" )
				UNITS="inch"
				break;;
			"Metric" )
				UNITS="mm"
				break;;
		esac
	done
fi

case $UNITS in
	"inch" )
		I=1
		UNIT_DESC="(X.XXX in inches)"
		UNIT_DESC_BIG="(XX.XXX in inches)"
		REPLACE_RSC="G54 G17 G20 G40 G49 G90 G64 P0.001 T0"
		REPLACE_INC="0.1in 0.05in 0.01in 0.005in 0.001in"
		GUNITS="G20"
		;;
	"mm" )
		I=25.4
		UNIT_DESC="(XX.XX in mm)"
		UNIT_DESC_BIG="(XXXX.XX in mm)"
		REPLACE_RSC="G54 G17 G21 G40 G49 G90 G64 P0.03 T0"
		REPLACE_INC="10mm 5mm 1mm 0.1mm 0.01mm"
		GUNITS="G21"
		;;
esac

f_log "UNITS=$UNITS" "both"

if [ "$MACHINE" != "CUSTOM" ]; then
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
if [ -z $SPINDLE ]; then
	f_log "prompt for spindle"
	f_prompt "Choose your spindle:"
	select x in "Router" "VFD Spindle"; do
		case $x in
			"Router" )
				SPINDLE="ROUTER"
				break;;
			"VFD Spindle" )
				SPINDLE="VFD"
				break;;
		esac
	done
fi

case $SPINDLE in
	"ROUTER" )
		# remove spindle speed
		f_log "removing spindle from hal files"
		sed -i '/SPINDLE/,+11d' .TEMP.hal
		sed -i '/SPINDLE_SPEED/,+10d' .TEMP.xml
		;;
	"VFD" )
		MOUNT="LONG"
		SPID="NO"
		# remove router code
		f_log "removing router controls from hal file"
		sed -i '/ROUTER/,+6d' .TEMP.hal
		;;
esac

if [ -z $SPID ]; then
	f_log "prompt for superpid"
	f_prompt "Do you have a SuperPID?:" "* Label can be found on back of Unity controller.\n* If unsure, say NO"
	select y in "No" "Yes"; do
		case $y in
			"Yes" )
				SPID="YES"
				break;;
			"No" )
				SPID="NO"
				break;;
		esac
	done
fi

case $SPID in
	"YES" | "True" )
		# remove router code
		f_log "removing router controls from hal file"
		sed -i '/ROUTER/,+6d' .TEMP.hal
		;;
	"NO" | "False" )
		# remove superpid code
		f_log "removing superpid from hal files"
		sed -i '/SUPERPID/,+10d' .TEMP.hal
		sed -i '/ROUTER_SPEED/,+10d' .TEMP.xml
		;;
esac

if [ "$SPINDLE" = "ROUTER" ] && [ "$SPID" = "NO" ]; then
	f_log "remove vfd code"
	sed -i '/VFD/,+3d' .TEMPpostgui.hal
fi

f_log "SPINDLE=$SPINDLE" "both"
f_log "SPID=$SPID" "both"

###################################################################################################
# 	Step 6: ACME screw (roton or helix)
#
if [ -z $ACME ]; then
	f_log "prompt for acme"
	f_prompt "Choose your ACME screw:" "* Helix: blue drive nuts on lead-screws (all machines 2016+)\n* Roton: black drive nuts on lead-screws"
	select x in "Helix" "Roton"; do
		case $x in
			"Roton" )
				ACME="ROTON"
				break;;
			"Helix" )
				ACME="HELIX"
				break;;
		esac
	done
fi

case $ACME in
	"ROTON" )
		ZTPI=5
		Z_MAXVEL=0.4
		# 24IPM Z-Axis
		;;
	"HELIX" )
		ZTPI=2
		Z_MAXVEL=2
		# 120IPM Z-Axis
		;;
esac

f_log "ACME=$ACME" "both"

f_log "replace z max velocity in ini file"
sed -i -e 's/REPLACE_ZVELOCITY/'"Z_MAXVEL"'/' .TEMP.ini

###################################################################################################
# 	Step 7: drivers (unipolar or bipolar)
#
if [ -z $DRIVERS ]; then
	f_log "prompt for drivers"
	f_prompt "Choose your drivers:" "* MondoStep: bi-polar, black cabinet or Unity controller (2016+ machines).\n* Probostep: uni-polar, beige control cabinet."
	select x in "MondoStep" "ProboStep"; do
		case $x in
			"ProboStep" )
				DRIVERS="PROBOSTEP"
				break;;
			"MondoStep" )
				DRIVERS="MONDOSTEP"
				break;;
		esac
	done
fi

case $DRIVERS in
	"PROBOSTEP" )
		XYSCALE=$(expr "scale=4; 2*200*2/$I" | bc -l)
		ZSCALE=$(expr "scale=4; 2*200*$ZTPI/$I" | bc -l)
		;;
	"MONDOSTEP" )
		XYSCALE=$(expr "scale=4; 4*200*2/$I" | bc -l)
		ZSCALE=$(expr "scale=4; 4*200*$ZTPI/$I" | bc -l)
		;;
esac

f_log "DRIVERS=$DRIVERS" "both"
f_log "XYSCALE=$XYSCALE"
f_log "ZSCALE=$ZSCALE"

###################################################################################################
# 	Step 8: jogger (gamepad or mpg pendant)
#
if [ -z $PENDANT ]; then
	f_log "prompt for gamepad"
	f_prompt "Do you use the Gamepad or MPG pendant?"
	select x in "None" "Gamepad" "MPG Pendant"; do
		case $x in
			"Gamepad" )
				PENDANT="GAMEPAD"
				break;;
			"MPG Pendant" )
				PENDANT="MPG"
				break;;
			"None" )
				PENDANT="NONE"
				break;;
		esac
	done
fi

case $PENDANT in
	"GAMEPAD" )
		# remove mpg pendant from hal file
		f_log "remove mpg from hal file"
		sed -i '/MPG_PENDANT/,+62d' .TEMP.hal
		# remove unused second estop section from hal file
		sed -i '/ESTOP_2/,+9d' .TEMP.hal
		;;
	"MPG" )
		# remove gamepad from hal file
		f_log "remove gamepad from hal files"
		sed -i '/GAMEPAD/,+1d' .TEMP.hal
		sed -i '/GAMEPAD/,+31d' .TEMPpostgui.hal
		# remove code for single estop usage
		sed -i '/ESTOP_1/,+1d' .TEMP.hal
		;;
	"NONE" )
		# remove mpg pendant from hal file
		f_log "remove mpg from hal file"
		sed -i '/MPG_PENDANT/,+62d' .TEMP.hal
		# remove gamepad from hal file
		f_log "remove gamepad from hal files"
		sed -i '/GAMEPAD/,+1d' .TEMP.hal
		sed -i '/GAMEPAD/,+31d' .TEMPpostgui.hal
		# remove unused second estop section from hal file
		sed -i '/ESTOP_2/,+9d' .TEMP.hal
		;;
esac

f_log "PENDANT=$PENDANT" "both"

###################################################################################################
# 	Step 9: sensors (atlas or zpuck)
#
if [ -z $SENSOR ]; then
	f_log "prompt for options"
	f_prompt "Do you use the ATLaS Tool Length Sensor or the Z-Puck?" "* ATLaS: a silver button in the front left corner of the spoilboard.\n* Z-Puck: black disc with silver top connected to alligator clip."
	select x in "None" "ATLaS only" "Z-Puck only" "Both"; do
		case $x in
			"ATLaS only" )
				SENSOR="ATLAS"
				break;;
			"Z-Puck only" )
				SENSOR="ZPUCK"
				break;;
			"Both" )
				SENSOR="BOTH"
				break;;
			"None" )
				SENSOR="NONE"
				break;;
		esac
	done
fi

f_log "SENSOR=$SENSOR" "both"

case $SENSOR in
	"ATLAS" )
		f_log "remove Z-Puck code"
		sed -i '/ZPUCK/,+5d' .TEMP.xml
		sed -i '/HALUI_ZPUCK/,+1d' .TEMPpostgui.hal
		;;
	"ZPUCK" )
		f_log "remove ATLaS code"
		sed -i '/ATLAS/,+5d' .TEMP.xml
		sed -i '/HALUI_FIRST_TOOL/,+1d' .TEMPpostgui.hal
		sed -i '/probe-atlas/d' .TEMP.hal
		;;& # continue matching
	"BOTH" | "ZPUCK" )
		if [ -z $ZPUCK ] || [ "$ZPUCK" = "NONE" ]; then
			f_log "prompt for Z-Puck height"
			until [[ $ZPUCK =~ ^[0-9]+\.?[0-9]*$ ]]; do
				f_prompt "Enter height of Z-Puck $UNIT_DESC"
				read ZPUCK
			done
		fi
		f_log "ZPUCK=$ZPUCK" "both"
		;;
	"NONE" )
		f_log "remove sensors from side panel"
		sed -i '/SENSORS/,+32d' .TEMP.xml
		f_log "remove probe indicator code"
		#sed -i '/PROBE/,+14d' .TEMP.xml
		sed -i '/PROBE_LED/,+1d' .TEMPpostgui.hal
		sed -i '/PROBE/,+9d' .TEMP.hal
		f_log "remove Z-Puck code"
		#sed -i '/ZPUCK/,+5d' .TEMP.xml
		sed -i '/HALUI_ZPUCK/,+1d' .TEMPpostgui.hal
		f_log "remove ATLaS code"
		#sed -i '/ATLAS/,+5d' .TEMP.xml
		sed -i '/HALUI_FIRST_TOOL/,+1d' .TEMPpostgui.hal
		;;
esac

if [ -z $ZPUCK ]; then
	ZPUCK="NONE"
fi

f_log "save ATLaS settings"
sed -i -e 's/REPLACE_GUNITS/'"$GUNITS"'/' \
	-e 's/REPLACE_ZMIN/'"$Z_MIN_LIMIT"'/' \
	-e 's/REPLACE_MULTIPLIER/'"$I"'/' \
	-e 's/REPLACE_X_PARK/'"$X_PARK"'/' .TEMP100.ngc

f_log "save Z-Puck settings"
sed -i -e 's/REPLACE_GUNITS/'"$GUNITS"'/' \
	-e 's/REPLACE_ZMIN/'"$Z_MIN_LIMIT"'/' \
	-e 's/REPLACE_MULTIPLIER/'"$I"'/' \
	-e 's/REPLACE_ZP_HEIGHT/'"$ZPUCK"'/' .TEMP102.ngc

###################################################################################################
# 	Laser
#
if [ -z $LASER ]; then
	f_log "prompt for laser"
	f_prompt "Do you have the PROBOTIX Laser by J-Tech?"
	select x in "No" "Yes"; do
		case $x in
			"No" )
				LASER="NO"
				break;;
			"Yes" )
				LASER="YES"
				break;;
		esac
	done
fi

f_log "LASER=$LASER" "both"

case $LASER in
	"NO" )
		f_log "remove Laser code"
		sed -i '/LASER/,+9d' .TEMP.hal
		sed -i '/LASER/,+2d' .TEMPpostgui.hal
		sed -i '/LASER/,+15d' .TEMP.xml
		if [ "$SPINDLE" = "ROUTER" ] && [ "$SPID" = "NO" ]; then
			f_log "remove pwm code"
			sed -i '/PWM/,+5d' .TEMP.hal
		fi
		;;
	"YES" )
		# nothing
		;;
esac

###################################################################################################
# 	Step 5b: router mount (long or short)
#		need to ask this to determine ATLaS Y position
#		short mounts are -0.165 shorter from Y center
#
if [ -z $MOUNT ]; then
	f_log "prompt for router mount"
	f_prompt "Choose Your Router Mount:" "* This only matters if you use the ATLaS.\n* One-piece mounts are made of a single piece of metal (all machines 2018+).\n* Two-piece mounts are L shaped and made from two joined pieces of metal."
	select x in "One-Piece Mount" "Two-Piece with 3/4in Back Plate" "Two-Piece with 1/2in Back Plate"; do
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
		if [ "$UPRIGHT" = "TALL" ]; then
			f_log "adjust ATLAS_Y for tall uprights"
			ATLAS_Y=3.0755
		fi
		;;
	"SHORT" )
		ATLAS_Y=3.3883
		;;
esac

f_log "MOUNT=$MOUNT" "both"

###################################################################################################
# 	ATLaS settings
#
f_log "ATLAS_X=$ATLAS_X"
ATLAS_X=$(expr "scale=4; $ATLAS_X*$I" | bc -l)
f_log "ATLAS_Y=$ATLAS_Y"
ATLAS_Y=$(expr "scale=4; $ATLAS_Y*$I" | bc -l)

# hardcode ATLaS offset in 100.ngc
f_log "hard code ATLaS offset in 100.ngc"
sed -i -e 's/REPLACE_ATLAS_X/'"$ATLAS_X"'/' .TEMP100.ngc
sed -i -e 's/REPLACE_ATLAS_Y/'"$ATLAS_Y"'/' .TEMP100.ngc

# set G59.3 offset to center of ATLaS
f_log "set G59.3 offset to center of ATLaS"
sed -i -e 's/REPLACE_ATLAS_X/'"$ATLAS_X"'/' .TEMPemc.var
sed -i -e 's/REPLACE_ATLAS_Y/'"$ATLAS_Y"'/' .TEMPemc.var

###################################################################################################
# 	Step 11: rotary?
#
if [ -z $ROTARY ]; then
	f_log "prompt for rotary axis"
	f_prompt "Do you have the 4th/rotary/A-axis?" "* If unsure, say NO."
	select xa in "No" "Yes"; do
		case $xa in
			"Yes" )
				ROTARY="YES"
				break;;
			"No" )
				ROTARY="NO"
				break;;
		esac
	done
fi

case $ROTARY in
	"YES" | "True" )
		COORDINATES="X Y Z A"
		COORDINATES_="X\ Y\ Z\ A"
		AXES=4
		;;
	"NO" | "False" )
		COORDINATES="X Y Z"
		COORDINATES_="X\ Y\ Z"
		AXES=3
		# remove a-axis from files
		sed -i '/AXIS_3/,+10d' .TEMP.ini
		sed -i '/A-AXIS/,+13d' .TEMP.hal
		sed -i '/axis.3/d' .TEMP.hal
		;;
esac

f_log "ROTARY=$ROTARY" "both"

###################################################################################################
# 	Step 12: driver swap
#
if [ -z $SWAP_TO_A ]; then
	f_log "prompt for driver swap"
	f_prompt "Do you want to swap a motor to the A-axis output?" "* For use as a temporary work-around for a failed driver.\n* You will lose use of the rotary when configured like this.\n* If unsure, say NO."
	select x in "No" "X" "Y1" "Y2" "Z"; do
		case $x in
			"X" )
				SWAP_TO_A="X"
				break;;
			"Y1" )
				SWAP_TO_A="Y1"
				break;;
			"Y2" )
				SWAP_TO_A="Y2"
				break;;
			"Z" )
				SWAP_TO_A="Z"
				break;;
			"No" )
				SWAP_TO_A="NO"
				break;;
		esac
	done
fi

# default pins
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

case $SWAP_TO_A in
	"X" )
		XSTEP="17"
		XDIR="01"
		ASTEP="02"
		ADIR="03"
		;;& # continue matching
	"Y1" )
		Y1STEP="17"
		Y1DIR="01"
		ASTEP="04"
		ADIR="05"
		;;&
	"Y2" )
		Y2STEP="17"
		Y2DIR="01"
		ASTEP="08"
		ADIR="09"
		;;&
	"Z" )
		ZSTEP="17"
		ZDIR="01"
		ASTEP="06"
		ADIR="07"
		;;&
	"X" | "Y1" | "Y2" | "Z" )
		COORDINATES="X Y Z"
		COORDINATES_="X\ Y\ Z"
		AXES=3
		# remove a-axis from files
		sed -i '/AXIS_3/,+10d' .TEMP.ini
		sed -i '/A-AXIS/,+13d' .TEMP.hal
		sed -i '/axis.3/d' .TEMP.hal
		;;
esac

f_log "SWAP_TO_A=$SWAP_TO_A" "both"

# markers for any swapped axis are already removed, sed will ignore those axes
f_log "set axis pins in hal file"
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
# 	Step 13: soft limits only
#
if [ -z $SOFT_ONLY ]; then
	f_log "prompt for soft limits"
	f_prompt "Do you want to ignore the hardware limit switches?" "* For use when having intermittent limit switch issues from faulty switches or electrical noise.\n* Switches will still be used for Homing.\n* If unsure, say NO."
	select x in "No" "Yes"; do
		case $x in
			"Yes" )
				SOFT_ONLY="YES"
				break;;
			"No" )
				SOFT_ONLY="NO"
				break;;
		esac
	done
fi

case $SOFT_ONLY in
	"YES" | "True" )
		sed -i '/LIMITS/,+5d' .TEMP.hal
		;;
	"NO" | "False" )
		# nothing
		;;
esac

f_log "SOFT_ONLY=$SOFT_ONLY" "both"

###################################################################################################
# 	Step 10a: confirm parallel port addresses, or enter custom
#
if [ -z $PARPORT0 ] || [ -z $PARPORT1 ]; then
	PARPORT0="0x378"
	PARPORT1=$IDENTB
	f_log "prompt confirm parport addr"
	f_prompt "Are the detected parallel port addresses correct?" "* PARPORT0 = $PARPORT0\n* PARPORT1 = $PARPORT1\n* If unsure, say YES."
	select x in "Yes" "No"; do
		case $x in
			"Yes" )
				f_log "correct parports"
				break;;
			"No" )
				f_log "incorrect parports, prompting for correction"
				echo
				echo "Please enter the correct parallel port addresses."
				echo "PARPORT0:"
				read PARPORT0
				echo "PARPORT1:"
				read PARPORT1
				break;;
		esac
	done
fi

###################################################################################################
# 	Step 10b: swap parallel ports
#
if [ -z $SWAP_PARPORTS ]; then
	f_log "prompt swap parallel ports"
	f_prompt "Do you want to swap the parallel ports?" "* Used to troubleshoot issues with machine control.\n* PARPORT0 = $PARPORT0\n* PARPORT1 = $PARPORT1\n* If unsure, say NO."
	select x in "No" "Yes"; do
		case $x in
			"No" )
				SWAP_PARPORTS="NO"
				break;;
			"Yes" )
				SWAP_PARPORTS="YES"
				break;;
		esac
	done
fi

case $SWAP_PARPORTS in
	"NO" | "False" )
		;;
	"YES" | "True" )
		PARPORT0=$IDENTB
		PARPORT1="0x378"
		f_prompt "New parallel port address:" "* PARPORT0 = $PARPORT0\n* PARPORT1 = $PARPORT1"
		f_pause
		;;
esac

f_log "SWAP_PARPORTS=$SWAP_PARPORTS" "both"

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
f_log "metricify axis vars"
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


# folder should only exist during factory install
if [ -d "$DUMP_DIR" ]; then
	f_log "config dump"
	echo "$CONFIG_NAME v$_VERSION" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "ORDER_NO=$ORDER_NO" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "SERIES=$SERIES" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "MACHINE=$MACHINE" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "UPRIGHT=$UPRIGHT" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "ZBEARINGS=$ZBEARINGS" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "UNITS=$UNITS" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "ACME=$ACME" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "DRIVERS=$DRIVERS" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "SPINDLE=$SPINDLE" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "MOUNT=$MOUNT" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "SPID=$SPID" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "PENDANT=$PENDANT" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "SENSOR=$SENSOR" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "ZPUCK=$ZPUCK" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "LASER=$LASER" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "ROTARY=$ROTARY" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "PARPORT0=$PARPORT0" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "PARPORT1=$PARPORT1" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "AXES=$AXES" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "COORDINATES=$COORDINATES" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "ZTPI=$ZTPI" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "XYSCALE=$XYSCALE" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "ZSCALE=$ZSCALE" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "XY_MAXVEL=$XY_MAXVEL" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "Z_MAXVEL=$Z_MAXVEL" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "XY_MAXACCEL=$XY_MAXACCEL" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "Z_MAXACCEL=$Z_MAXACCEL" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "XY_SMAX_ACC=$XY_STEPGEN_MAXACCEL" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "Z_SMAX_ACC=$Z_STEPGEN_MAXACCEL" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "XY_MIN_LIMIT=$XY_MIN_LIMIT" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "Z_MIN_LIMIT=$Z_MIN_LIMIT" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "X_MAX_LIMIT=$X_MAX_LIMIT" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "Y_MAX_LIMIT=$Y_MAX_LIMIT" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "Z_MAX_LIMIT=$Z_MAX_LIMIT" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "XY_HM_OFFSET=$XY_HOME_OFFSET" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "Z_HM_OFFSET=$Z_HOME_OFFSET" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "XY_SEARCH_VL=$XY_SEARCH_VEL" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "Z_SEARCH_VEL=$Z_SEARCH_VEL" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "XY_LATCH_VEL=$XY_LATCH_VEL" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "Z_LATCH_VEL=$Z_LATCH_VEL" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "DEF_VELOCITY=$DEFAULT_VELOCITY" >> $DUMP_DIR/$ORDER_NO.CONFIG
	echo "MAX_LIN_VEL=$MAX_LINEAR_VELOCITY" >> $DUMP_DIR/$ORDER_NO.CONFIG
	lspci -v > $DUMP_DIR/$ORDER_NO.LSPCI
fi

# was 0.08
FERROR=$(expr 0.08*$I | bc -l)
# was 0.05
MIN_FERROR=$(expr 0.05*$I | bc -l)

# replace vars in ini file - single + double quote to expand vars and escape spaces
f_log "replace vars in ini file"
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
#	Install Configuration
#
if [ "$INSTALL_TYPE" = "NEW" ]; then
	# remove the desktop icons
	f_log "remove desktop icons"
	rm -f /home/probotix/Desktop/probotix.desktop
	rm -Rf /home/probotix/Desktop/nc_files

	# delete and recreate the linuxcnc/PROBOTIX directory
	f_log "remove and recreate PROBOTIX config dir"
	rm -Rf /home/probotix/linuxcnc/configs/PROBOTIX
	mkdir -p /home/probotix/linuxcnc/configs/PROBOTIX/axis
	mkdir -p /home/probotix/linuxcnc/nc_files
fi

f_log "installing PROBOTIX Axis Interface"
case $SERIES in
	"GX" )
		cp -Rfd .axis_files/axis/* /home/probotix/linuxcnc/configs/PROBOTIX/axis/
		# install new GX ToolEditor
		#sudo cp -Rfd .tooledit /usr/bin/pbx-tooledit
		# remove duplicate touch-off buttons
		sed -i '/SET_ORIGIN/,+15d' .TEMP.xml
		sed -i '/HALUI_TOUCH/,+2d' .TEMPpostgui.hal
		;;
	"GALAXY" | "FIREBALL" )
		cp -Rfd .axis_files/axis_1.7/* /home/probotix/linuxcnc/configs/PROBOTIX/axis/
		;;
esac
# create symlink to axis program
sudo ln -sTf /home/probotix/linuxcnc/configs/PROBOTIX/axis/axis /usr/bin/probotix-axis
sudo ln -sTf /home/probotix/linuxcnc/configs/PROBOTIX/axis /usr/share/probotix-axis
# axis imports /usr/share/pyshared/nf.py
# which has hard-coded references to default axis file locations
cp -Rfd .axis_files/nf_pbx.py /home/probotix/linuxcnc/configs/PROBOTIX/axis/nf_pbx.py
sudo ln -sTf /home/probotix/linuxcnc/configs/PROBOTIX/axis/nf_pbx.py /usr/share/pyshared/nf_pbx.py

# install customized files
f_log "copy customized show_errors"
sudo cp -f .show_errors.tcl /usr/lib/tcltk/linuxcnc/show_errors.tcl

f_log "copy tool.tbl, emc.nml, splash, and nc_files"
cp -f .tool.tbl /home/probotix/linuxcnc/configs/PROBOTIX/tool.tbl
cp -f .emc.nml  /home/probotix/linuxcnc/configs/PROBOTIX/emc.nml
cp -f .probotix_splash.gif /home/probotix/linuxcnc/configs/PROBOTIX/probotix_splash.gif
cp -R .nc_files/* /home/probotix/linuxcnc/nc_files

# move the temp files to LinuxCNC dir
f_log "save temp files to LinuxCNC dir"
cp .TEMP.ini /home/probotix/linuxcnc/configs/PROBOTIX/probotix.ini
cp .TEMP.hal /home/probotix/linuxcnc/configs/PROBOTIX/probotix.hal
cp .TEMPpostgui.hal /home/probotix/linuxcnc/configs/PROBOTIX/postgui.hal
cp .TEMP.xml /home/probotix/linuxcnc/configs/PROBOTIX/pyvcp.xml
cp .TEMPemc.var  /home/probotix/linuxcnc/configs/PROBOTIX/emc.var
cp .TEMP100.ngc /home/probotix/linuxcnc/nc_files/subs/100.ngc
cp .TEMP102.ngc /home/probotix/linuxcnc/nc_files/subs/102.ngc

# create link to LinuxCNC on desktop
f_log "save LinuxCNC desktop link"
sed -i -e 's/REPLACE_MACHINE/'"$MACHINE"'/' .TEMP.desktop
cp .TEMP.desktop /home/probotix/Desktop/probotix.desktop

# wait for LinuxCNC icon to be created
sleep 1

if [ ! -L "/home/probotix/Desktop/nc_files" ]; then
	# create link to nc_files on desktop
	f_log "create nc_files desktop link"
	ln -sf /home/probotix/linuxcnc/nc_files/ /home/probotix/Desktop/nc_files
fi

# remove remaining temp files
f_log "remove temp files"
rm -f .TEMP*

###################################################################################################
#	End
#
f_exit
