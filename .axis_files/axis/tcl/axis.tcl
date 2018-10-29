#    This is a component of AXIS, a front-end for LinuxCNC
#    Copyright 2004, 2005, 2006, 2007, 2008, 2009
#    Jeff Epler <jepler@unpythonic.net> and Chris Radek <chris@timeguy.com>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#	Modified for PROBOTIX
#

lappend auto_path $::linuxcnc::TCL_LIB_DIR

### ADDED BY PROBOTIX
source /home/probotix/linuxcnc/configs/PROBOTIX/axis/tcl/menu.tcl
source /home/probotix/linuxcnc/configs/PROBOTIX/axis/tcl/toolbar.tcl
### END BY PROBOTIX

## MAIN FRAME
panedwindow .pane \
	-borderwidth 5 \
	-handlesize 5 \
	-orient v \
	-sashpad 0 \
	-showhandle 0

set pane_top [frame .pane.top]
set pane_bottom [frame .pane.bottom]
.pane add $pane_top -sticky nsew
.pane add $pane_bottom -sticky nsew
catch {
	.pane paneconfigure $pane_top -stretch always
	.pane paneconfigure $pane_bottom -stretch never
}

NoteBook ${pane_top}.tabs \
	-borderwidth 2 \
	-arcradius 3
proc show_all_tabs w {
	upvar 0 NoteBook::$w data
	set a [winfo reqwidth $w]
	set b [expr $data(wpage) + 3]
	if {$a < $b} { $w configure -width $b }
}
after 1 after idle show_all_tabs ${pane_top}.tabs
proc set_pane_minsize {} {
	global pane_bottom pane_top
	.pane paneconfigure $pane_top -minsize [winfo reqheight $pane_top]
	.pane paneconfigure $pane_bottom -minsize [winfo reqheight $pane_bottom]
}
after 1 after idle set_pane_minsize

set _tabs_manual [${pane_top}.tabs insert end manual -text [_ "Manual Control \[F3\]"] -raisecmd {focus .; ensure_manual}]
set _tabs_mdi [${pane_top}.tabs insert end mdi -text [_ "MDI \[F5\]"]]
$_tabs_manual configure -borderwidth 2
$_tabs_mdi configure -borderwidth 2

${pane_top}.tabs itemconfigure mdi -raisecmd "[list focus ${_tabs_mdi}.command]; ensure_mdi"
#${pane_top}.tabs raise manual
after idle {
	${pane_top}.tabs raise manual
	${pane_top}.right raise preview
	after idle ${pane_top}.tabs compute_size
#	after idle ${pane_top}.right compute_size
}

### ADDED BY PROBOTIX
source /home/probotix/linuxcnc/configs/PROBOTIX/axis/tcl/tabs_manual_axes.tcl
source /home/probotix/linuxcnc/configs/PROBOTIX/axis/tcl/tabs_manual_jog.tcl
source /home/probotix/linuxcnc/configs/PROBOTIX/axis/tcl/tabs_manual_spindle.tcl
source /home/probotix/linuxcnc/configs/PROBOTIX/axis/tcl/tabs_manual_coolant.tcl
### END BY PROBOTIX

grid rowconfigure $_tabs_manual 99 -weight 1
grid columnconfigure $_tabs_manual 99 -weight 1

# Grid widget $_tabs_manual.axis
grid $_tabs_manual.axis \
	-column 0 \
	-row 0 \
	-pady 1 \
	-sticky nw

# Grid widget $_tabs_manual.axes
grid $_tabs_manual.axes \
	-column 1 \
	-row 0 \
	-padx 0 \
	-sticky w

# Grid widget $_tabs_manual.joglabel
#grid $_tabs_manual.joglabel \
#	-column 0 \
#	-row 2 \
#	-pady 1 \
#	-sticky nw

# Grid widget $_tabs_manual.jogf
grid $_tabs_manual.jogf \
	-column 1 \
	-row 1 \
	-padx 4 \
	-sticky w

# Grid widget $_tabs_manual.spindlel
grid $_tabs_manual.spindlel \
	-column 0 \
	-row 5 \
	-pady 2 \
	-sticky nw

# Grid widget $_tabs_manual.spindlef
grid $_tabs_manual.spindlef \
	-column 1 \
	-row 5 \
	-padx 4 \
	-sticky w

# Grid widget $_tabs_manual.coolantl
grid $_tabs_manual.coolantl \
	-column 0 \
	-row 6 \
	-sticky w

# Grid widget $_tabs_manual.coolantf
grid $_tabs_manual.coolantf \
	-column 1 \
	-row 6 \
	-padx 4 \
	-sticky w

### ADDED BY PROBOTIX
source /home/probotix/linuxcnc/configs/PROBOTIX/axis/tcl/mdi.tcl
### END BY PROBOTIX

NoteBook ${pane_top}.right \
	-borderwidth 2 \
	-arcradius 3
after 1 after idle show_all_tabs ${pane_top}.right

set _tabs_preview [${pane_top}.right insert end preview -text [_ "Preview"]]
set _tabs_numbers [${pane_top}.right insert end numbers -text [_ "DRO"]]
$_tabs_preview configure -borderwidth 1
$_tabs_numbers configure -borderwidth 1

text ${_tabs_numbers}.text -width 1 -height 1 -wrap none \
	-background [systembuttonface] \
	-borderwidth 0 \
	-undo 0 \
	-relief flat
pack ${_tabs_numbers}.text -fill both -expand 1
bindtags ${_tabs_numbers}.text [list ${_tabs_numbers}.text . all]


### BEGIN BOTTOM INFO BAR
frame .info

label .info.task_state \
	-anchor w \
	-borderwidth 2 \
	-relief sunken \
	-textvariable task_state_string \
	-width 14
setup_widget_accel .info.task_state {}

label .info.tool \
	-anchor w \
	-borderwidth 2 \
	-relief sunken \
	-textvariable tool \
	-width 30

#label .info.offset \
#	-anchor w \
#	-borderwidth 2 \
#	-relief sunken \
#	-textvariable offset \
#	-width 25

label .info.position \
	-anchor w \
	-borderwidth 2 \
	-relief sunken \
	-textvariable position \
	-width 25

label .info.g5x_coordinate_system \
	-anchor w \
	-borderwidth 2 \
	-relief sunken \
	-textvariable current_g5x \
	-width 25

label .info.commanded_spindle_speed \
	-anchor w \
	-borderwidth 2 \
	-relief sunken \
	-textvariable current_spindle_speed \
	-width 25

### END BOTTOM INFO BAR


# Pack widget .info.task_state
pack .info.task_state \
	-side left

# Pack widget .info.tool
pack .info.tool \
	-side left

# Pack widget .info.position
pack .info.position \
	-side left

# Pack widget .info.g5x_coordinate_system
pack .info.g5x_coordinate_system \
	-side left

# Pack widget .info.commanded_spindle_speed
pack .info.commanded_spindle_speed \
	-side left \
	-fill x \
	-expand 1



frame ${pane_bottom}.t \
	-borderwidth 2 \
	-relief sunken \
	-highlightthickness 1

text ${pane_bottom}.t.text \
	-borderwidth 0 \
	-background black \
	-foreground green \
	-exportselection 0 \
	-height 9 \
	-highlightthickness 0 \
	-relief flat \
	-takefocus 0 \
	-yscrollcommand [list ${pane_bottom}.t.sb set]
${pane_bottom}.t.text insert end {}
bind ${pane_bottom}.t.text <Configure> { goto_sensible_line }

scrollbar ${pane_bottom}.t.sb \
	-borderwidth 0 \
	-command [list ${pane_bottom}.t.text yview] \
	-highlightthickness 0

# Pack widget ${pane_bottom}.t.text
pack ${pane_bottom}.t.text \
	-expand 1 \
	-fill both \
	-side left

# Pack widget ${pane_bottom}.t.sb
pack ${pane_bottom}.t.sb \
	-fill y \
	-side right

frame ${pane_top}.ajogspeed
label ${pane_top}.ajogspeed.l0 -text [_ "Rotary Jog Speed:"]
label ${pane_top}.ajogspeed.l1
scale ${pane_top}.ajogspeed.s -bigincrement 0 -from .06 -to 1 -resolution .020 -showvalue 0 -variable ajog_slider_val -command update_ajog_slider_vel -orient h -takefocus 0
label ${pane_top}.ajogspeed.l -textv jog_aspeed -width 6 -anchor e
pack ${pane_top}.ajogspeed.l0 -side left
pack ${pane_top}.ajogspeed.s -side right
pack ${pane_top}.ajogspeed.l1 -side right
pack ${pane_top}.ajogspeed.l -side right
bind . <less> [regsub %W [bind Scale <Left>] ${pane_top}.ajogspeed.s]
bind . <greater> [regsub %W [bind Scale <Right>] ${pane_top}.ajogspeed.s]


frame ${pane_top}.jogspeed
label ${pane_top}.jogspeed.l0 -text [_ "Linear Jog Speed:"]
label ${pane_top}.jogspeed.l1
scale ${pane_top}.jogspeed.s -bigincrement 0 -from .06 -to 1 -resolution .020 -showvalue 0 -variable jog_slider_val -command update_jog_slider_vel -orient h -takefocus 0
label ${pane_top}.jogspeed.l -textv jog_speed -width 4 -anchor e
pack ${pane_top}.jogspeed.l0 -side left
pack ${pane_top}.jogspeed.s -side right
pack ${pane_top}.jogspeed.l1 -side right
pack ${pane_top}.jogspeed.l -side right
bind . , [regsub %W [bind Scale <Left>] ${pane_top}.jogspeed.s]
bind . . [regsub %W [bind Scale <Right>] ${pane_top}.jogspeed.s]

frame ${pane_top}.maxvel
label ${pane_top}.maxvel.l0 -text [_ "Max Velocity:"]
label ${pane_top}.maxvel.l1
scale ${pane_top}.maxvel.s -bigincrement 0 -from .06 -to 1 -resolution .020 -showvalue 0 -variable maxvel_slider_val -command update_maxvel_slider_vel -orient h -takefocus 0
label ${pane_top}.maxvel.l -textv maxvel_speed -width 6 -anchor e
pack ${pane_top}.maxvel.l0 -side left
pack ${pane_top}.maxvel.s -side right
pack ${pane_top}.maxvel.l1 -side right
pack ${pane_top}.maxvel.l -side right
bind . <semicolon> [regsub %W [bind Scale <Left>] ${pane_top}.maxvel.s]
bind . ' [regsub %W [bind Scale <Right>] ${pane_top}.maxvel.s]

frame ${pane_top}.spinoverride

label ${pane_top}.spinoverride.foentry \
	-textvariable spindlerate \
	-width 3 \
	-anchor e
setup_widget_accel ${pane_top}.spinoverride.foentry 0

scale ${pane_top}.spinoverride.foscale \
	-command set_spindlerate \
	-orient horizontal \
	-resolution 1.0 \
	-showvalue 0 \
	-takefocus 0 \
	-to 120.0 \
	-variable spindlerate

label ${pane_top}.spinoverride.l
setup_widget_accel ${pane_top}.spinoverride.l [_ "Spindle Override:"]
label ${pane_top}.spinoverride.m -width 1
setup_widget_accel ${pane_top}.spinoverride.m [_ "%"]

# Pack widget ${pane_top}.spinoverride.l
pack ${pane_top}.spinoverride.l \
	-side left

# Pack widget ${pane_top}.spinoverride.foscale
pack ${pane_top}.spinoverride.foscale \
	-side right

# Pack widget ${pane_top}.spinoverride.foentry
pack ${pane_top}.spinoverride.m \
	-side right

# Pack widget ${pane_top}.spinoverride.foentry
pack ${pane_top}.spinoverride.foentry \
	-side right



frame ${pane_top}.feedoverride

label ${pane_top}.feedoverride.foentry \
	-textvariable feedrate \
	-width 4 \
	-anchor e
setup_widget_accel ${pane_top}.feedoverride.foentry 0

scale ${pane_top}.feedoverride.foscale \
	-command set_feedrate \
	-orient horizontal \
	-resolution 1.0 \
	-showvalue 0 \
	-takefocus 0 \
	-to 120.0 \
	-variable feedrate

label ${pane_top}.feedoverride.l
setup_widget_accel ${pane_top}.feedoverride.l [_ "Feed Override:"]
label ${pane_top}.feedoverride.m -width 1
setup_widget_accel ${pane_top}.feedoverride.m [_ "%"]

# Pack widget ${pane_top}.feedoverride.l
pack ${pane_top}.feedoverride.l \
	-side left

# Pack widget ${pane_top}.feedoverride.foscale
pack ${pane_top}.feedoverride.foscale \
	-side right

# Pack widget ${pane_top}.feedoverride.foentry
pack ${pane_top}.feedoverride.m \
	-side right

# Pack widget ${pane_top}.feedoverride.foentry
pack ${pane_top}.feedoverride.foentry \
	-side right

toplevel .about
bind .about <Key-Return> { wm wi .about }
bind .about <Key-Escape> { wm wi .about }

text .about.message \
	-background [systembuttonface] \
	-borderwidth 0 \
	-relief flat \
	-width 40 \
	-height 11 \
	-wrap word \
	-cursor {}

.about.message tag configure link \
	-underline 1 -foreground blue
.about.message tag bind link <Leave> {
	.about.message configure -cursor {}
	.about.message tag configure link -foreground blue}
.about.message tag bind link <Enter> {
	.about.message configure -cursor hand2
	.about.message tag configure link -foreground red}
.about.message tag bind link <ButtonPress-1><ButtonRelease-1> {launch_website}
.about.message insert end [subst [_ "PROBOTIX Interface version \$pbx_version\n\nLinuxCNC/AXIS version \$version\n\nCopyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012 Jeff Epler and Chris Radek.\n\nThis is free software, and you are welcome to redistribute it under certain conditions.  See the file COPYING, included with LinuxCNC.\n\nVisit the LinuxCNC web site: "]] {} {http://www.linuxcnc.org/} link
.about.message configure -state disabled

button .about.ok \
	-command {wm wi .about} \
	-default active \
	-padx 0 \
	-pady 0 \
	-width 10
setup_widget_accel .about.ok [_ OK]

label .about.image \
	-borderwidth 0 \
	-image [load_image banner]
setup_widget_accel .about.image {}

# Pack widget .about.image
pack .about.image

# Pack widget .about.message
pack .about.message \
	-expand 1 \
	-fill both

# Pack widget .about.ok
pack .about.ok

# Configure widget .about
wm title .about [_ "About AXIS"]
wm iconname .about {}
wm resiz .about 0 0
wm minsize .about 1 1
wm protocol .about WM_DELETE_WINDOW {wm wi .about}

toplevel .keys
bind .keys <Key-Return> { wm withdraw .keys }
bind .keys <Key-Escape> { wm withdraw .keys }

frame .keys.text \

button .keys.ok \
	-command {wm wi .keys} \
	-default active \
	-padx 0 \
	-pady 0 \
	-width 10
setup_widget_accel .keys.ok [_ OK]

# Pack widget .keys.text
pack .keys.text \
	-expand 1 \
	-fill y

# Pack widget .keys.ok
pack .keys.ok

# Configure widget .keys
wm title .keys [_ "AXIS Quick Reference"]
wm iconname .keys {}
wm resiz .keys 0 0
wm minsize .keys 1 1
wm protocol .keys WM_DELETE_WINDOW {wm wi .keys}

# Grid widget ${pane_top}.feedoverride
grid ${pane_top}.feedoverride \
	-column 0 \
	-row 2 \
	-sticky new

# Grid widget ${pane_top}.spinoverride
grid ${pane_top}.spinoverride \
	-column 0 \
	-row 3 \
	-sticky new

grid ${pane_top}.jogspeed \
	-column 0 \
	-row 4 \
	-sticky new

grid ${pane_top}.ajogspeed \
	-column 0 \
	-row 5 \
	-sticky new

grid ${pane_top}.maxvel \
	-column 0 \
	-row 6 \
	-sticky new

# Grid widget .info
grid .info \
	-column 0 \
	-row 6 \
	-columnspan 2 \
	-sticky ew

# Grid widget ${pane_top}.right
grid ${pane_top}.right \
	-column 1 \
	-row 1 \
	-columnspan 2 \
	-padx 2 \
	-pady 2 \
	-rowspan 99 \
	-sticky nesw

grid ${pane_top}.tabs \
	-column 0 \
	-row 1 \
	-sticky nesw \
	-padx 2 \
	-pady 2
grid rowconfigure ${pane_top} 1 -weight 1
grid columnconfigure ${pane_top} 1 -weight 1
grid ${pane_bottom}.t \
	-column 1 \
	-row 1 \
	-sticky nesw
grid rowconfigure ${pane_bottom} 1 -weight 1
grid columnconfigure ${pane_bottom} 1 -weight 1

grid .pane -column 0 -row 1 -sticky nsew -rowspan 2

# Grid widget .toolbar
grid .toolbar \
	-column 0 \
	-row 0 \
	-columnspan 3 \
	-sticky nesw
grid columnconfigure . 0 -weight 1
grid rowconfigure . 1 -weight 1


set TASK_MODE_MANUAL 1
set TASK_MODE_AUTO 2
set TASK_MODE_MDI 3

set STATE_ESTOP 1
set STATE_ESTOP_RESET 2
set STATE_OFF 3
set STATE_ON 4

set INTERP_IDLE 1
set INTERP_READING 2
set INTERP_PAUSED 3
set INTERP_WAITING 4

set TRAJ_MODE_FREE 1
set KINEMATICS_IDENTITY 1

set manual [concat [winfo children $_tabs_manual.axes] \
	$_tabs_manual.jogf.zerohome.home \
	$_tabs_manual.jogf.jog.jogminus \
	$_tabs_manual.jogf.jog.jogplus \
	$_tabs_manual.spindlef.cw \
	$_tabs_manual.spindlef.ccw \
	$_tabs_manual.spindlef.stop \
	$_tabs_manual.spindlef.brake \
	$_tabs_manual.flood \
	$_tabs_manual.mist \
	$_tabs_mdi.command \
	$_tabs_mdi.go \
	$_tabs_mdi.history \
	$_tabs_manual.jogf.zerohome.xyzero \
	$_tabs_manual.jogf.zerohome.zzero \
	$_tabs_manual.jogf.jog.jogincr \
	]

proc disable_group {ws} { foreach w $ws { $w configure -state disabled } }
proc enable_group {ws} { foreach w $ws { $w configure -state normal } }

proc state {e args} {
	set e [uplevel \#0 [list expr $e]]
	if {$e} { set newstate normal } else {set newstate disabled}
	foreach w $args {
		if {[llength $w] > 1} {
			set m [lindex $w 0]
			for {set i 1} {$i < [llength $w]} {incr i} {
				set idx [extract_text [_ [lindex $w $i]]]
				set oldstate [$m entrycget $idx -state]
				if {$oldstate != $newstate} {
					$m entryconfigure $idx -state $newstate
				}
			}
		} else {
			set oldstate [$w cget -state]
			if {$oldstate != $newstate} {
				$w configure -state $newstate
			}
		}
	}
}
proc relief {e args} {
	set e [uplevel \#0 [list expr $e]]
	if {$e} { set newstate sunken } else {set newstate link }
	foreach w $args { $w configure -relief $newstate }
}

proc update_title {args} {
	set basetitle [subst [_ "AXIS \$::version on \$::machine"]]
	if {$::taskfile == ""} {
		set nofile [_ "(no file)"]
		wm ti . "$basetitle $nofile"
		wm iconname . "AXIS"
	} else {
		wm ti . "[lindex [file split $::taskfile] end] - $basetitle"
		wm iconname . "[lindex [file split $::taskfile] end]"
	}
}

proc update_state {args} {
	switch $::task_state \
		$::STATE_ESTOP { set ::task_state_string [_ "ESTOP"] } \
		$::STATE_ESTOP_RESET { set ::task_state_string [_ "OFF"] } \
		$::STATE_ON { set ::task_state_string [_ "ON"] } \

	relief {$task_state == $STATE_ESTOP} .toolbar.machine_estop
	state  {$task_state != $STATE_ESTOP} \
		.toolbar.machine_power {.menu.machine "Toggle _Machine Power"}
	relief {$task_state == $STATE_ON}    .toolbar.machine_power

	state  {$interp_state == $INTERP_IDLE && $taskfile != ""} \
		.toolbar.reload {.menu.file "_Reload"}
	state  {$taskfile != ""} \
		{.menu.file "_Save gcode as..."}
	state  {$interp_state == $INTERP_IDLE && $taskfile != "" && $::has_editor} \
		{.menu.file "_Edit..."}
	state  {$taskfile != ""} {.menu.file "_Properties..."}
	state  {$interp_state == $INTERP_IDLE} .toolbar.file_open \
		{.menu.file "_Open..." "_Quit" "Recent _Files"} \
		{.menu.machine "Skip lines with '_/'"} .toolbar.program_blockdelete
	state  {$task_state == $STATE_ON && $interp_state == $INTERP_IDLE } \
		.toolbar.program_run {.menu.machine "_Run program"} \
		{.menu.file "Reload tool ta_ble"}
	state  {$interp_state == $INTERP_IDLE} \
		{.menu.file "Edit _tool table..."}

	state  {$task_state == $STATE_ON && $interp_state == $INTERP_IDLE} \
		{.menu.machine "Homin_g" "_Unhoming" "_Zero coordinate system"}

	relief {$interp_state != $INTERP_IDLE} .toolbar.program_run
	state  {$task_state == $STATE_ON && $taskfile != ""} \
		.toolbar.program_step {.menu.machine "S_tep"}
	state  {$task_state == $STATE_ON && \
		($interp_state == $INTERP_READING || $interp_state == $INTERP_WAITING) } \
		{.menu.machine "_Pause"}
	state  {$task_state == $STATE_ON && $interp_state == $INTERP_PAUSED } \
		{.menu.machine "Re_sume"}
	state  {$task_state == $STATE_ON && $interp_state != $INTERP_IDLE} \
		.toolbar.program_pause
	relief {$interp_pause != 0} \
		.toolbar.program_pause
	relief {$block_delete != 0} \
		.toolbar.program_blockdelete
	relief {$optional_stop != 0} \
		.toolbar.program_optpause
	state  {$task_state == $STATE_ON && $interp_state != $INTERP_IDLE} \
		.toolbar.program_stop {.menu.machine "Stop"}
	relief {$interp_state == $INTERP_IDLE} \
		.toolbar.program_stop
	state  {$::has_ladder} {.menu.file "_Ladder Editor..."}

	state {$task_state == $STATE_ON \
		&& $interp_state == $INTERP_IDLE && $highlight_line != -1} \
		{.menu.machine "Ru_n from selected line"}

	state {$::task_state == $::STATE_ON && $::interp_state == $::INTERP_IDLE\
		&& $spindledir != 0} \
		$::_tabs_manual.spindlef.spindleminus \
		$::_tabs_manual.spindlef.spindleplus

	if {$::motion_mode == $::TRAJ_MODE_FREE && $::kinematics_type != $::KINEMATICS_IDENTITY} {
		set ::position [concat [_ "Position:"] Joint]
	} else {
		set coord_str [lindex [list [_ Machine] [_ Relative]] $::coord_type]
		set display_str [lindex [list [_ Actual] [_ Commanded]] $::display_type]

		set ::position [concat [_ "Position:"] $coord_str $display_str]
	}

	if {$::task_state == $::STATE_ON && $::interp_state == $::INTERP_IDLE} {
		if {$::last_interp_state != $::INTERP_IDLE || $::last_task_state != $::task_state} {
			set_mode_from_tab
		}
		enable_group $::manual
	} else {
		disable_group $::manual
	}

	if {$::task_state == $::STATE_ON && $::interp_state == $::INTERP_IDLE &&
		($::motion_mode == $::TRAJ_MODE_FREE
			|| $::kinematics_type == $::KINEMATICS_IDENTITY)} {
		$::_tabs_manual.jogf.jog.jogincr configure -state normal
	} else {
		$::_tabs_manual.jogf.jog.jogincr configure -state disabled
	}

	if {$::task_state == $::STATE_ON && $::interp_state == $::INTERP_IDLE &&
		($::motion_mode != $::TRAJ_MODE_FREE
			|| $::kinematics_type == $::KINEMATICS_IDENTITY)} {
		$::_tabs_manual.jogf.zerohome.zero configure -state normal
	} else {
		$::_tabs_manual.jogf.zerohome.zero configure -state disabled
	}

	set ::last_interp_state $::interp_state
	set ::last_task_state $::task_state

### EDITED BY PROBOTIX
	if {$::on_any_limit} {
		#$::_tabs_manual.jogf.override configure -state normal
		$::_tabs_manual.jogf.jog.override configure -state normal
	} else {
		#$::_tabs_manual.jogf.override configure -state disabled
		$::_tabs_manual.jogf.jog.override configure -state disabled
	}
}
### END BY PROBOTIX

proc set_mode_from_tab {} {
	set page [${::pane_top}.tabs raise]
	switch $page {
		mdi { ensure_mdi }
		default { ensure_manual }
	}
}

proc joint_mode_switch {args} {
	if {$::motion_mode == $::TRAJ_MODE_FREE && $::kinematics_type != $::KINEMATICS_IDENTITY} {
		grid forget $::_tabs_manual.axes
		grid $::_tabs_manual.joints -column 1 -row 0 -padx 0 -pady 0 -sticky w
		setup_widget_accel $::_tabs_manual.axis [_ Joint:]
	} else {
		grid forget $::_tabs_manual.joints
		grid $::_tabs_manual.axes -column 1 -row 0 -padx 0 -pady 0 -sticky w
		setup_widget_accel $::_tabs_manual.axis [_ Axis:]
	}
}

proc queue_update_state {args} {
	after cancel update_state
	after idle update_state
}

set rotate_mode 0
set taskfile ""
set machine ""
set task_state -1
set has_editor 1
set has_ladder 0
set last_task_state 0
set task_mode -1
set task_paused 0
set optional_stop 0
set block_delete 0
set interp_pause 0
set last_interp_state 0
set interp_state 0
set running_line -1
set highlight_line -1
set coord_type 1
set display_type 0
set spindledir {}
set motion_mode 0
set kinematics_type -1
set metric 0
set max_speed 1
trace variable taskfile w update_title
trace variable machine w update_title
trace variable taskfile w queue_update_state
trace variable task_state w queue_update_state
trace variable task_mode w queue_update_state
trace variable task_paused w queue_update_state
trace variable optional_stop w queue_update_state
trace variable block_delete w queue_update_state
trace variable interp_pause w queue_update_state
trace variable interp_state w queue_update_state
trace variable running_line w queue_update_state
trace variable highlight_line w queue_update_state
trace variable spindledir w queue_update_state
trace variable coord_type w queue_update_state
trace variable display_type w queue_update_state
trace variable motion_mode w queue_update_state
trace variable kinematics_type w queue_update_state
trace variable on_any_limit w queue_update_state
trace variable motion_mode w joint_mode_switch

set editor_deleted 0

bind . <Control-Tab> {
	set page [${pane_top}.tabs raise]
	switch $page {
		mdi { ${pane_top}.tabs raise manual }
		default { ${pane_top}.tabs raise mdi }
	}
	break
}

# any key that causes an entry or spinbox action should not continue to perform
# a binding on "."
foreach c {Entry Spinbox} {
	foreach b [bind $c] {
		switch -glob $b {
			<*-Key-*> {
				bind $c $b {+if {[%W cget -state] == "normal"} break}
			}
		}
	}

	foreach b { Left Right
		Up Down Prior Next Home
		Left Right Up Down
		Prior Next Home
		End } {
		bind $c <KeyPress-$b> {+if {[%W cget -state] == "normal"} break}
		bind $c <KeyRelease-$b> {+if {[%W cget -state] == "normal"} break}
	}
	bind $c <Control-KeyPress-Home> {+if {[%W cget -state] == "normal"} break}
	bind $c <Control-KeyRelease-Home> {+if {[%W cget -state] == "normal"} break}
	bind $c <Control-KeyPress-KP_Home> {+if {[%W cget -state] == "normal"} break}
	bind $c <Control-KeyRelease-KP_Home> {+if {[%W cget -state] == "normal"} break}
	set bb [bind $c <KeyPress>]
	foreach k { Left Right Up Down Prior Next Home End } {
		set b [bind $c <$k>]
		if {$b == {}} { set b $bb }
		bind $c <KeyPress-KP_$k> "if {%A == \"\"} { $b } { $bb; break }"
		bind $c <KeyRelease-KP_$k> {+if {[%W cget -state] == "normal"} break}
	}

	foreach k {0 1 2 3 4 5 6 7 8 9} {
		bind $c <KeyPress-KP_$k> "$bb; break"
		bind $c <KeyRelease-KP_$k> {+if {[%W cget -state] == "normal"} break}
	}

	bind $c <Key> {+if {[%W cget -state] == "normal" && [string length %A]} break}
}

proc is_continuous {} {
	expr {"[$::_tabs_manual.jogf.jog.jogincr get]" == [_ "Continuous"]}
}

proc show_all text {
	$text yview moveto 0.0
	update
	set fy [lindex [$text yview] 1]
	set ch [$text cget -height]
	$text configure -height [expr {ceil($ch/$fy)}]
}

proc delete_all text {
	set nl [lindex [split [$text index end] .] 0]
	while {$nl >= 1500} {
		$text delete 1.0 1000.end
		incr nl -1000
	}

	$text delete 1.0 end
}

proc size_combobox_to_entries c {
	set fo [$c cget -font]
	set wi [font measure $fo 0]
	set sz 4
	foreach i [$c list get 0 end] {
		set li [expr ([font measure $fo $i] + $wi - 1)/$wi]
		if {$li > $sz} { set sz $li }
	}
	$c configure -width $sz
}

proc size_label_to_strings {w args} {
	set fo [$w cget -font]
	set wi [font measure $fo 0]
	set sz 4
	foreach i args {
		set li [expr ([font measure $fo $i] + $wi - 1)/$wi]
		if {$li > $sz} { set sz $li }
	}
	$w configure -width $sz
}

proc size_menubutton_to_entries {w} {
	set m $w.menu
	set fo [$w cget -font]
	set wi [font measure $fo 0]
	set sz 4
	for {set i 0} {$i <= [$m index end]} {incr i} {
		set type [$m type $i]
		if {$type == "separator" || $type == "tearoff"} continue
		set text [$m entrycget $i -label]
		set li [expr ([font measure $fo $text] + $wi - 1)/$wi]
		if {$li > $sz} { set sz $li }
	}
	$w configure -width $sz
}

size_combobox_to_entries $_tabs_manual.jogf.jog.jogincr
size_label_to_strings $_tabs_manual.axis [_ Joint:] [_ Axis:]

proc setval {vel max_speed} {
	if {$vel == 0} { return 0 }
	if {$vel >= 60*$max_speed} { set vel [expr 60*$max_speed] }
	set x [expr {-1/(log($vel/60./$max_speed)-1)}]
	expr {round($x * 200.) / 200.}
}

proc val2vel {val max_speed} {
	if {$val == 0} { return 0 }
	if {$val == 1} { format "%32.5f" [expr {$max_speed * 60.}]
	} else { format "%32.5f" [expr {60 * $max_speed * exp(-1/$val + 1)}] }
}

proc places {s1 s2} {
	if {$s1 > 1 && int($s1) != int($s2)} {
		return [expr {[string first . $s1]-1}]
	}
	set l1 [string length $s1]
	set l2 [string length $s2]
	for {set i 15} {$i < $l1 && $i < $l2} {incr i} {
		set c1 [string index $s1 $i]
		set c2 [string index $s2 $i]
		if {$c1 != "0" && $c1 != "." && $c1 != $c2} { return $i }
	}
	return [string length $s1]
}

proc val2vel_show {val maxvel} {
	set this_vel [val2vel $val $maxvel]
	set next_places 0
	set last_places 0
	if {$val > .005} {
		set next_vel [val2vel [expr {$val - .005}] $maxvel]
		set next_places [places $this_vel $next_vel]
	}
	if {$val < .995} {
		set prev_vel [val2vel [expr {$val + .005}] $maxvel]
		set prev_places [places $this_vel $prev_vel]
	}
	if {$next_places > $last_places} {
		string trim [string range $this_vel 0 $next_places]
	} {
		string trim [string range $this_vel 0 $last_places]
	}
}

proc set_slider_min {minval} {
	global pane_top
	global max_speed
	${pane_top}.jogspeed.s configure -from [setval $minval $max_speed]
}

proc set_aslider_min {minval} {
	global pane_top
	global max_aspeed
	${pane_top}.ajogspeed.s configure -from [setval $minval $max_aspeed]
}

proc update_jog_slider_vel {newval} {
	global jog_speed max_speed
	set max_speed_units [to_internal_linear_unit $max_speed]
	if {$max_speed_units == {None}} return
	if {$::metric} { set max_speed_units [expr {25.4 * $max_speed_units}] }
	set speed [val2vel_show $newval $max_speed_units];
	set jog_speed $speed
}

proc update_maxvel_slider_vel {newval} {
	global maxvel_speed max_maxvel
	set max_speed_units [to_internal_linear_unit $max_maxvel]
	if {$max_speed_units == {None}} return
	if {$::metric} { set max_speed_units [expr {25.4 * $max_speed_units}] }
	set speed [val2vel_show $newval $max_speed_units];
	set maxvel_speed $speed
	set_maxvel $speed
}

proc update_maxvel_slider {} {
	global maxvel_speed max_maxvel maxvel_slider_val
	set max_speed_units [to_internal_linear_unit $max_maxvel]
	if {$max_speed_units == {None}} return
	if {$::metric} { set max_speed_units [expr {25.4 * $max_speed_units}] }
	set maxvel_slider_val [setval $maxvel_speed $max_speed_units]
}

proc update_units {args} {
	if {$::metric} {
		${::pane_top}.jogspeed.l1 configure -text mm/min
		${::pane_top}.maxvel.l1 configure -text mm/min
	} else {
		${::pane_top}.jogspeed.l1 configure -text in/min
		${::pane_top}.maxvel.l1 configure -text in/min
	}
	update_jog_slider_vel $::jog_slider_val
	update_maxvel_slider_vel $::maxvel_slider_val
}

proc update_ajog_slider_vel {newval} {
	global jog_aspeed max_aspeed
	set jog_aspeed [val2vel_show $newval $max_aspeed];
}

proc update_recent {args} {
	.menu.file.recent delete 0 end
	set i 1
	foreach f $args {
		if {$i < 10} { set und 0 } \
		elseif {$i == 10} { set und 1 } \
		else { set und -1 }
		.menu.file.recent add command -underline $und \
			-label "$i: [file tail $f]" \
			-command [list open_file_name $f]
		incr i
	}
}


bind . <Configure> {
	if {"%W" == "."} {
		set msz [wm minsize %W]
		set nmsz [list [winfo reqwidth %W] [expr [winfo reqheight %W]+4]]
		if {$msz != $nmsz} { eval wm minsize %W $nmsz }
	}
}

bind . <Alt-v> [bind all <Alt-Key>]
bind . <Alt-v> {+break}

bind . <Key-Return> {focus .}

wm withdraw .about
wm withdraw .keys

DynamicHelp::add $_tabs_manual.spindlef.ccw -text [_ "Turn spindle counterclockwise \[F10\]"]
DynamicHelp::add $_tabs_manual.spindlef.cw -text [_ "Turn spindle clockwise \[F9\]"]
DynamicHelp::add $_tabs_manual.spindlef.stop -text [_ "Stop spindle \[F9/F10\]"]
DynamicHelp::add $_tabs_manual.spindlef.spindleplus -text [_ "Turn spindle Faster \[F12\]"]
DynamicHelp::add $_tabs_manual.spindlef.spindleminus -text [_ "Turn spindle Slower \[F11\]"]
DynamicHelp::add $_tabs_manual.spindlef.brake -text [_ "Turn spindle brake on \[Shift-B\] or off \[B\]"]
DynamicHelp::add $_tabs_manual.flood -text [_ "Turn Outlet on or off \[F8\]"] ### ADDED BY PROBOTIX
DynamicHelp::add $_tabs_manual.mist -text [_ "Turn AUX on or off \[F7\]"] ### ADDED BY PROBOTIX
DynamicHelp::add $_tabs_manual.jogf.zerohome.home -text [_ "Send active axis home \[Home\]"]
DynamicHelp::add $_tabs_manual.jogf.zerohome.zero -text [_ "Set G54 offset for active axis \[End\]"]
DynamicHelp::add $_tabs_manual.axes.axisx -text [_ "Activate axis \[X\]"]
DynamicHelp::add $_tabs_manual.axes.axisy -text [_ "Activate axis \[Y\]"]
DynamicHelp::add $_tabs_manual.axes.axisz -text [_ "Activate axis \[Z\]"]
DynamicHelp::add $_tabs_manual.axes.axisa -text [_ "Activate axis \[A\]"]
DynamicHelp::add $_tabs_manual.axes.axisb -text [_ "Activate axis \[4\]"]
DynamicHelp::add $_tabs_manual.axes.axisc -text [_ "Activate axis \[5\]"]
DynamicHelp::add $_tabs_manual.jogf.jog.jogminus -text [_ "Jog selected axis"]
DynamicHelp::add $_tabs_manual.jogf.jog.jogplus -text [_ "Jog selected axis"]
DynamicHelp::add $_tabs_manual.jogf.jog.jogincr -text [_ "Select jog increment"]
DynamicHelp::add $_tabs_manual.jogf.jog.override -text [_ "Temporarily allow jogging outside machine limits \[L\]"]

# On at least some versions of Tk (tk8.4 on ubuntu 6.06), this hides files
# beginning with "." from the open dialog.  Who knows what it does on other
# versions.
catch {
	auto_load ::tk::dialog::file::
	namespace eval ::tk::dialog::file {}
	set ::tk::dialog::file::showHiddenBtn 1
	set ::tk::dialog::file::showHiddenVar 0
}

# Show what alphabetic letters are left for a specific menu
proc show_menu_available {m} {
	for {set i 0} {$i < [$m index end]} {incr i} {
		set t [$m type $i]
		if {$t == "separator" || $t == "tearoff"} {continue}
		set u [$m entrycget $i -underline]
		if {$u == -1} {continue}
		set l [$m entrycget $i -label]
		set c [string tolower [string range $l $u $u]]
		if {[info exists used($c)]} { puts "Duplicate: $c" }
		set used($c) {}
	}

	foreach i {a b c d e f g h i j k l m n o p q r s t u v w x y z} {
		if {![info exists used($i)]} { puts "Available: $i" }
	}
}

# vim:ts=8:sts=4:et:sw=4:
