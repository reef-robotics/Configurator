#!/bin/sh


DIR=$(pwd)
TITLE="PanelRestore"

Main () {
    CHOICE=$(zenity --list --title "$TITLE" --hide-column 1 --text "What do you want to do?" --column "" --column "" \
"0" "Save Panel Settings" \
"1" "Restore Panel Settings" \
"2" "Restore Default Panel Settings")
    if [ $CHOICE = 0 ]; then
        Panel_Save
    fi
    if [ $CHOICE = 1 ]; then
        Panel_Restore
    fi
    if [ $CHOICE = 2 ]; then
        Panel_Defaults
    fi  
}

Panel_Restore () {
    FILE=$(zenity --title "$TITLE: Open File" --file-selection --file-filter "*.xml" )
    if [ -n "$FILE" ]; then 
        gconftool-2 --load "$FILE"
        killall gnome-panel
    fi
    Main
}

Panel_Save () {
    FILE=$(zenity --title "$TITLE: Save File" --file-selection --save --confirm-overwrite --filename "Gnome_Panel.xml" --file-filter "*.xml" )
    if [ -n "$FILE" ]; then 
        EXT=$(echo "$FILE" | grep "xml")
        if [ "$EXT" = "" ]; then
            FILE="$FILE.xml"
        fi
        gconftool-2 --dump /apps/panel > $FILE
        zenity --info --title "$TITLE: File Saved" --text "File saved as: \n $FILE"
    fi
    Main
}

Panel_Defaults () {
    zenity --question --text="Are you sure you want to restore the default top and bottom panels?"
    gconftool-2 --recursive-unset /apps/panel
    rm -rf ~/.gconf/apps/panel
    pkill gnome-panel
    exit
}

Main

# END OF Script
