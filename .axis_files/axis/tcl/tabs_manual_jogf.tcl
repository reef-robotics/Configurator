

#jogf frame
frame $_tabs_manual.jogf


#jog subframe
frame $_tabs_manual.jogf.jog
#	-background red

#zerohome subframe
frame $_tabs_manual.jogf.zerohome \




#CREATE JOG MINUS BUTTON
button $_tabs_manual.jogf.jog.jogminus \
	-command {if {![is_continuous]} {jog_minus 1}} \
	-padx 0 \
	-pady 0 \
	-width 2 \
	-text -
bind $_tabs_manual.jogf.jog.jogminus <Button-1> {
    if {[is_continuous]} { jog_minus }
}
bind $_tabs_manual.jogf.jog.jogminus <ButtonRelease-1> {
    if {[is_continuous]} { jog_stop }
}



#CREATE JOG PLUS BUTTON
button $_tabs_manual.jogf.jog.jogplus \
	-command {if {![is_continuous]} {jog_plus 1}} \
	-padx 0 \
	-pady 0 \
	-width 2 \
	-text +

bind $_tabs_manual.jogf.jog.jogplus <Button-1> {
    if {[is_continuous]} { jog_plus }
}
bind $_tabs_manual.jogf.jog.jogplus <ButtonRelease-1> {
    if {[is_continuous]} { jog_stop }
}



#CREATE JOG MODE LABEL
#label $_tabs_manual.jogf.jog.joglable -text [_ "Jog Mode:"]



#CREATE JOG INCREMENTS DROPDOWN
combobox $_tabs_manual.jogf.jog.jogincr \
	-editable 0 \
	-textvariable jogincrement \
	-value [_ Continuous] \
	-width 10
$_tabs_manual.jogf.jog.jogincr list insert end [_ Continuous] 0.1000 0.0100 0.0010 0.0001



#CREATE OVERRIDE LIMITS CHECKBOX
checkbutton $_tabs_manual.jogf.jog.override \
	-command toggle_override_limits \
	-variable override_limits
setup_widget_accel $_tabs_manual.jogf.jog.override [_ "Override Limits"]



#CREATE HOME AXIS BUTTON - NOT DISPLAYED
button $_tabs_manual.jogf.zerohome.home \
	-command home_axis \
	-padx 2m \
	-pady 0
setup_widget_accel $_tabs_manual.jogf.zerohome.home [_ "Home Axis"]



#CREATE SET AXIS ORIGIN BUTTON
button $_tabs_manual.jogf.zerohome.zero \
	-command touch_off \
	-padx 2m \
	-pady 0
setup_widget_accel $_tabs_manual.jogf.zerohome.zero [_ "Set Selected Axis Origin"]



#OLD OVERRIDE LIMITS CHECKBOX CODE
#checkbutton $_tabs_manual.jogf.override \
#	-command toggle_override_limits \
#	-variable override_limits
#setup_widget_accel $_tabs_manual.jogf.override [_ "Override Limits"]



#CREATE SET X/Y ORIGIN BUTTON
button $_tabs_manual.jogf.zerohome.xyzero \
	-command xy_origin \
	-padx 2m \
	-pady 0
setup_widget_accel $_tabs_manual.jogf.zerohome.xyzero [_ "Zero X/Y Origin"]



#CREATE SET Z ORIGIN BUTTON
button $_tabs_manual.jogf.zerohome.zzero \
	-command z_origin \
	-padx 2m \
	-pady 0
setup_widget_accel $_tabs_manual.jogf.zerohome.zzero [_ "Zero Z Origin"]



#TEST BUTTON -
#button $_tabs_manual.jogf.zerohome.testbutton \
#	-command test_button \
#	-padx 2m \
#	-pady 0
#setup_widget_accel $_tabs_manual.jogf.zerohome.testbutton [_ "TEST BUTTON"]



#CREATE SOME BLANK SPACE
label $_tabs_manual.jogf.zerohome.space \
	-anchor w \
	-borderwidth 2 \
	-text " " \
	-width 30





#START GRIDDING THINGS INTO PLACE


grid $_tabs_manual.jogf.jog \
	-column 0 \
	-row 0 \
	-columnspan 3 \
	-sticky w




#BEGIN jogf.jog frame

#ROW1
# Grid widget $_tabs_manual.jogf.jog.jogminus
grid $_tabs_manual.jogf.jog.jogminus \
	-column 0 \
	-row 0 \
	-padx 2 \
	-pady 2 \
	-sticky nsw

# Grid widget $_tabs_manual.jogf.jog.jogplus
grid $_tabs_manual.jogf.jog.jogplus \
	-column 1 \
	-row 0 \
	-padx 2 \
	-pady 2 \
	-sticky nsw

# Grid widget $_tabs_manual.jogf.jog.jogincr
grid $_tabs_manual.jogf.jog.jogincr \
	-column 2 \
	-row 0 \
	-pady 2 \
	-sticky nsw

#ROW2
# Grid widget $_tabs_manual.jogf.jog.override
grid $_tabs_manual.jogf.jog.override \
	-column 0 \
	-row 1 \
	-columnspan 3 \
	-pady 2 \
	-sticky w

#END OF jogf.jog frame




#BEGIN jogf.zerohome frame

grid $_tabs_manual.jogf.zerohome \
	-column 0 \
	-row 1 \
	-columnspan 3 \
	-sticky w

#blank labels create space
grid $_tabs_manual.jogf.zerohome.space \

# Grid widget $_tabs_manual.jogf.zerohome.home
grid $_tabs_manual.jogf.zerohome.home \
	-column 0 \
	-row 1 \
	-ipadx 2 \
	-pady 2 \
	-sticky w

# Grid widget $_tabs_manual.jogf.zerohome.zero
grid $_tabs_manual.jogf.zerohome.zero \
	-column 0 \
	-row 2 \
	-ipadx 2 \
	-pady 2 \
	-sticky w

# Grid widget $_tabs_manual.jogf.zerohome.xyzero
grid $_tabs_manual.jogf.zerohome.xyzero \
	-column 0 \
	-row 3 \
	-ipadx 2 \
	-pady 2 \
	-sticky w

# Grid widget $_tabs_manual.jogf.zerohome.zzero
grid $_tabs_manual.jogf.zerohome.zzero \
	-column 1 \
	-row 3 \
	-ipadx 2 \
	-pady 2 \
	-sticky w

# Grid widget $_tabs_manual.jogf.zerohome.testbutton
#grid $_tabs_manual.jogf.zerohome.testbutton \
#	-column 0 \
#	-row 5 \
#	-ipadx 2 \
#	-pady 2 \
#	-sticky w





# Grid widget $_tabs_manual.jogf.override
#grid $_tabs_manual.jogf.override \
#	-column 0 \
#	-row 3 \
#	-columnspan 3 \
#	-pady 2 \
#	-sticky w
