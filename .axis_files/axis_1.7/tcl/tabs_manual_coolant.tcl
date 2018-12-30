
label $_tabs_manual.coolantl
setup_widget_accel $_tabs_manual.coolantl [_ "Relay:"]

frame $_tabs_manual.coolantf

checkbutton $_tabs_manual.mist \
	-command mist \
	-variable mist
setup_widget_accel $_tabs_manual.mist [_ "5VDC AUX (M7)"]

checkbutton $_tabs_manual.flood \
	-command flood \
	-variable flood
setup_widget_accel $_tabs_manual.flood [_ "120VAC Outlet (M8)"]

#CREATE SOME BLANK SPACE
vspace $_tabs_manual.space1 -height 12




#START GRIDDING THINGS INTO PLACE

# Grid widget $_tabs_manual.coolantl
#grid $_tabs_manual.coolant \
#	-column 0 \
#	-row 5 \
#	-sticky w


#START PACKING THINGS INTO PLACE

# Grid widget $_tabs_manual.mist
pack $_tabs_manual.mist \
	-in $_tabs_manual.coolantf \
        -side top \
        -pady 2 \
	-padx 4 \

# Grid widget $_tabs_manual.flood
pack $_tabs_manual.flood \
	-in $_tabs_manual.coolantf \
        -side top \
        -pady 2 \
	-padx 4 \

# BLANK SPACE
grid $_tabs_manual.space1

