
#CREATE JOG MODE LABEL - NOT DISPLAYED
label $_tabs_manual.jogl -text [_ "Jog Mode:"]

frame $_tabs_manual.jogf
frame $_tabs_manual.jogf.jog
frame $_tabs_manual.jogf.zerohome
frame $_tabs_manual.jogf.zerohome.row1


#label $_tabs_manual.jogf.jog.jogl -text [_ "Jog Mode:"]

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

#CREATE JOG INCREMENTS DROPDOWN
combobox $_tabs_manual.jogf.jog.jogincr \
	-editable 0 \
	-textvariable jogincrement \
	-value [_ Continuous] \
	-width 10
$_tabs_manual.jogf.jog.jogincr list insert end [_ "Continuous"] 0.1000 0.0100 0.0010 0.0001

#CREATE OVERRIDE LIMITS CHECKBOX
checkbutton $_tabs_manual.jogf.jog.override \
	-command toggle_override_limits \
	-variable override_limits
setup_widget_accel $_tabs_manual.jogf.jog.override [_ "Override Limits"]

#CREATE SOME BLANK SPACE
vspace $_tabs_manual.jogf.jog.space1 -height 12




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

label $_tabs_manual.jogf.zerohome.zeroorigin -text [_ "Zero Origin:"]

#CREATE SET X/Y ORIGIN BUTTON
button $_tabs_manual.jogf.zerohome.xyzero \
	-command xy_origin \
	-padx 2m \
	-pady 0
setup_widget_accel $_tabs_manual.jogf.zerohome.xyzero [_ "X/Y"]

#CREATE SET Z ORIGIN BUTTON
button $_tabs_manual.jogf.zerohome.zzero \
	-command z_origin \
	-padx 2m \
	-pady 0
setup_widget_accel $_tabs_manual.jogf.zerohome.zzero [_ "Z"]

#TEST BUTTON - 
#button $_tabs_manual.jogf.zerohome.testbutton \
#	-command test_button \
#	-padx 2m \
#	-pady 0
#setup_widget_accel $_tabs_manual.jogf.zerohome.testbutton [_ "TEST BUTTON"]

#CREATE SOME BLANK SPACE
vspace $_tabs_manual.jogf.zerohome.space1 -height 12




#START GRIDDING THINGS INTO PLACE

grid $_tabs_manual.jogf.jog \
	-column 0 \
	-row 0 \
	-columnspan 3 \
	-sticky w

#BEGIN jogf.jog frame

#ROW1
#grid $_tabs_manual.jogf.jog.jogl \
#	-column 0 \
#	-columnspan 2 \
#	-row 0 \
#	-pady 2 \
#	-sticky nsw

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

# BLANK SPACE
#grid $_tabs_manual.jogf.jog.space1

#END OF jogf.jog frame




#BEGIN jogf.zerohome frame

grid $_tabs_manual.jogf.zerohome \
	-column 0 \
	-row 1 \
	-sticky nw

# Grid widget $_tabs_manual.jogf.zerohome.home
#grid $_tabs_manual.jogf.zerohome.home \
#	-column 0 \
#	-row 0 \
#	-ipadx 2 \
#	-pady 2 \
#	-sticky w

# Grid widget $_tabs_manual.jogf.zerohome.zero
grid $_tabs_manual.jogf.zerohome.zero \
	-column 0 \
	-row 0 \
	-columnspan 2 \
	-pady 2 \
	-sticky w

grid $_tabs_manual.jogf.zerohome.row1 -row 1 -column 0 -sticky nw

pack $_tabs_manual.jogf.zerohome.zeroorigin \
	-in $_tabs_manual.jogf.zerohome.row1 \
	-side left \
	-padx 2 \
	-pady 2

pack $_tabs_manual.jogf.zerohome.xyzero \
	-in $_tabs_manual.jogf.zerohome.row1 \
	-side left \
	-padx 2 \
	-pady 2

pack $_tabs_manual.jogf.zerohome.zzero \
	-in $_tabs_manual.jogf.zerohome.row1 \
	-side left \
	-padx 2 \
	-pady 2

# Grid widget $_tabs_manual.jogf.zerohome.testbutton
#grid $_tabs_manual.jogf.zerohome.testbutton \
#	-column 0 \
#	-row 3 \
#	-ipadx 2 \
#	-pady 2 \
#	-sticky w

# Grid widget $_tabs_manual.jogf.override
#grid $_tabs_manual.jogf.override \
#	-column 0 \
#	-row 4 \
#	-columnspan 3 \
#	-pady 2 \
#	-sticky w

# BLANK SPACE
grid $_tabs_manual.jogf.zerohome.space1

