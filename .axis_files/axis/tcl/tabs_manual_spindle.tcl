
#spindle_speed

#----------------------------- BEGIN SPINDLE

vspace $_tabs_manual.space1 \
	-height 12


label $_tabs_manual.spindlel
setup_widget_accel $_tabs_manual.spindlel [_ "Spindle:"]

frame $_tabs_manual.spindlef
frame $_tabs_manual.spindlef.row1
frame $_tabs_manual.spindlef.row2

#label $_tabs_manual.spindlespl
#setup_widget_accel $_tabs_manual.spindlespl [_ "Speed:"]

radiobutton $_tabs_manual.spindlef.ccw \
	-borderwidth 2 \
	-command spindle \
	-image [load_image spindle_ccw] \
	-indicatoron 0 \
	-selectcolor [systembuttonface] \
	-value -1 \
	-variable spindledir
setup_widget_accel $_tabs_manual.spindlef.ccw {}

radiobutton $_tabs_manual.spindlef.stop \
	-borderwidth 2 \
	-command spindle \
	-indicatoron 0 \
	-selectcolor [systembuttonface] \
	-value 0 \
	-variable spindledir
setup_widget_accel $_tabs_manual.spindlef.stop [_ "Stop"]

radiobutton $_tabs_manual.spindlef.cw \
	-borderwidth 2 \
	-command spindle \
	-indicatoron 0 \
	-selectcolor [systembuttonface] \
	-value 1 \
	-variable spindledir
setup_widget_accel $_tabs_manual.spindlef.cw [_ "Start"]

#setup_widget_accel $_tabs_manual.spindlef.cw {}
#	-image [load_image spindle_cw] \

button $_tabs_manual.spindlef.spindleminus \
	-padx 0 \
	-pady 0 \
	-width 7
bind $_tabs_manual.spindlef.spindleminus <Button-1> {
	if {[%W cget -state] == "disabled"} { continue }
	spindle_decrease
}
bind $_tabs_manual.spindlef.spindleminus <ButtonRelease-1> {
	if {[%W cget -state] == "disabled"} { continue }
	spindle_constant
}
setup_widget_accel $_tabs_manual.spindlef.spindleminus [_ "Speed -"]

button $_tabs_manual.spindlef.spindleplus \
	-padx 0 \
	-pady 0 \
	-width 7
bind $_tabs_manual.spindlef.spindleplus <Button-1> {
	if {[%W cget -state] == "disabled"} { continue }
	spindle_increase
}
bind $_tabs_manual.spindlef.spindleplus <ButtonRelease-1> {
	if {[%W cget -state] == "disabled"} { continue }
	spindle_constant
}
setup_widget_accel $_tabs_manual.spindlef.spindleplus [_ "Speed +"]

checkbutton $_tabs_manual.spindlef.brake \
	-command brake \
	-variable brake
setup_widget_accel $_tabs_manual.spindlef.brake [_ "Brake"]

# Grid widget $_tabs_manual.spindlef.brake
grid $_tabs_manual.spindlef.brake \
	-column 0 \
	-row 3 \
	-pady 2 \
	-sticky w

grid $_tabs_manual.spindlef.row1 -row 1 -column 0 -sticky nw
grid $_tabs_manual.spindlef.row2 -row 2 -column 0 -sticky nw

# Grid widget $_tabs_manual.spindlef.ccw
pack $_tabs_manual.spindlef.ccw  \
        -in $_tabs_manual.spindlef.row1 \
        -side left \
        -pady 2

# Grid widget $_tabs_manual.spindlef.stop
pack $_tabs_manual.spindlef.stop \
        -in $_tabs_manual.spindlef.row1 \
        -side left \
        -pady 2 \
        -ipadx 14

# Grid widget $_tabs_manual.spindlef.cw
pack $_tabs_manual.spindlef.cw \
        -in $_tabs_manual.spindlef.row1 \
        -side left \
        -pady 2 \
        -ipadx 14

# Grid widget $_tabs_manual.spindlef.spindleminus
pack $_tabs_manual.spindlef.spindleminus \
        -in $_tabs_manual.spindlef.row2 \
        -side left \
        -pady 2

# Grid widget $_tabs_manual.spindlef.spindleplus
pack $_tabs_manual.spindlef.spindleplus \
        -in $_tabs_manual.spindlef.row2 \
        -side left \
        -pady 2

#------------------------------------ END SPINDLE
