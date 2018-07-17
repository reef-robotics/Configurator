#---------------------------- BEGIN TOOL BAR

frame .toolbar \
	-borderwidth 2 \
	-relief raised



vrule .toolbar.rule16

Button .toolbar.machine_estop \
	-helptext [_ "Toggle Emergency Stop \[F1\]"] \
	-image [load_image tool_estop] \
	-relief sunken \
	-takefocus 0
bind .toolbar.machine_estop <Button-1> { estop_clicked }
setup_widget_accel .toolbar.machine_estop {}

Button .toolbar.machine_power \
	-command onoff_clicked \
	-helptext [_ "Toggle Machine power \[F2\]"] \
	-image [load_image tool_power] \
	-relief link \
	-state disabled \
	-takefocus 0
setup_widget_accel .toolbar.machine_power {}

Button .toolbar.machine_home \
	-command home_all_axes \
	-helptext [_ "Home Machine \[CTRL-HOME\]"] \
	-image [load_image tool_home] \
	-relief link \
	-takefocus 0
setup_widget_accel .toolbar.machine_power {}

vrule .toolbar.rule0

Button .toolbar.file_open \
	-command { open_file } \
	-helptext [_ "Open File From Hard Drive \[O\]"] \
	-image [load_image tool_open_hd] \
	-relief link \
	-takefocus 0
setup_widget_accel .toolbar.file_open {}

Button .toolbar.file_open_usb \
	-command { open_file_usb } \
	-helptext [_ "Open File From USB \[O\]"] \
	-image [load_image tool_open_usb] \
	-relief link \
	-takefocus 0
setup_widget_accel .toolbar.file_open {}

Button .toolbar.reload \
	-command { reload_file } \
	-helptext [_ "Reopen current file \[Control-R\]"] \
	-image [load_image tool_reload] \
	-relief link \
	-takefocus 0
setup_widget_accel .toolbar.reload {}

vrule .toolbar.rule4

Button .toolbar.program_run \
	-command task_run \
	-helptext [_ "Begin executing current file \[R\]"] \
	-image [load_image tool_run] \
	-relief link \
	-takefocus 0
setup_widget_accel .toolbar.program_run {}

Button .toolbar.program_step \
	-command task_step \
	-helptext [_ "Execute next line \[T\]"] \
	-image [load_image tool_step] \
	-relief link \
	-takefocus 0
setup_widget_accel .toolbar.program_step {}

Button .toolbar.program_pause \
	-command task_pauseresume \
	-helptext [_ "Pause \[P\] / resume \[S\] execution"] \
	-image [load_image tool_pause] \
	-relief link \
	-takefocus 0
setup_widget_accel .toolbar.program_pause {}
       
Button .toolbar.program_stop \
	-command task_stop \
	-helptext [_ "Stop program execution \[ESC\]"] \
	-image [load_image tool_stop] \
	-relief link \
	-takefocus 0
setup_widget_accel .toolbar.program_stop {}

vrule .toolbar.rule8

Button .toolbar.program_blockdelete \
        -command { set block_delete [expr {!$block_delete}]; toggle_block_delete } \
        -helptext [_ "Toggle skip lines with '/' \[Alt-M /\]"] \
	-image [load_image tool_blockdelete] \
        -relief link \
        -takefocus 0

Button .toolbar.program_optpause \
        -command { set optional_stop [expr {!$optional_stop}]; toggle_optional_stop } \
        -helptext [_ "Toggle optional pause \[Alt-M 1\]"] \
	-image [load_image tool_optpause] \
        -relief link \
        -takefocus 0

vrule .toolbar.rule9
 
Button .toolbar.view_zoomin \
	-command zoomin \
	-helptext [_ "Zoom in"] \
	-image [load_image tool_zoomin] \
	-relief link \
	-takefocus 0
setup_widget_accel .toolbar.view_zoomin {}

Button .toolbar.view_zoomout \
	-command zoomout \
	-helptext [_ "Zoom out"] \
	-image [load_image tool_zoomout] \
	-relief link \
	-takefocus 0
setup_widget_accel .toolbar.view_zoomout {}

Button .toolbar.view_z \
	-command set_view_z \
	-helptext [_ "Top view"] \
	-image [load_image tool_axis_z] \
	-relief sunken \
	-takefocus 0
setup_widget_accel .toolbar.view_z {}

Button .toolbar.view_z2 \
	-command set_view_z2 \
	-helptext [_ "Rotated top view"] \
	-image [load_image tool_axis_z2] \
	-relief link \
	-takefocus 0
setup_widget_accel .toolbar.view_z2 {}

Button .toolbar.view_x \
	-command set_view_x \
	-helptext [_ "Side view"] \
	-image [load_image tool_axis_x] \
	-relief link \
	-takefocus 0
setup_widget_accel .toolbar.view_x {}

Button .toolbar.view_y \
	-command set_view_y \
	-helptext [_ "Front view"] \
	-image [load_image tool_axis_y] \
	-relief link \
	-takefocus 0
setup_widget_accel .toolbar.view_y {}

Button .toolbar.view_p \
	-command set_view_p \
	-helptext [_ "Perspective view"] \
	-image [load_image tool_axis_p] \
	-relief link \
	-takefocus 0
setup_widget_accel .toolbar.view_p {}

Button .toolbar.rotate \
        -image [load_image tool_rotate] \
	-helptext [_ "Toggle between Drag and Rotate Mode \[D\]"] \
        -relief link \
        -command {
            set rotate_mode [expr {!$rotate_mode}]
            if {$rotate_mode} {
                .toolbar.rotate configure -relief sunken
            } else {
                .toolbar.rotate configure -relief link
            }
        }

vrule .toolbar.rule12

Button .toolbar.clear_plot \
	-command clear_live_plot \
	-helptext [_ "Clear live plot \[Ctrl-K\]"] \
	-image [load_image tool_clear] \
	-relief link \
	-takefocus 0
setup_widget_accel .toolbar.clear_plot {}





# Pack widget .toolbar.machine_estop
pack .toolbar.machine_estop \
	-side left

# Pack widget .toolbar.machine_power
pack .toolbar.machine_power \
	-side left

# Pack widget .toolbar.machine_home
pack .toolbar.machine_home \
	-side left


# Pack widget .toolbar.rule0
pack .toolbar.rule0 \
	-fill y \
	-padx 10 \
	-pady 4 \
	-side left


# Pack widget .toolbar.file_open
pack .toolbar.file_open \
	-side left

# Pack widget .toolbar.file_open_usb
pack .toolbar.file_open_usb \
	-side left

# Pack widget .toolbar.reload
pack .toolbar.reload \
	-side left


# Pack widget .toolbar.rule4
pack .toolbar.rule4 \
	-fill y \
	-padx 10 \
	-pady 4 \
	-side left


# Pack widget .toolbar.program_run
pack .toolbar.program_run \
	-side left

# Pack widget .toolbar.program_step
pack .toolbar.program_step \
	-side left

# Pack widget .toolbar.program_pause
pack .toolbar.program_pause \
	-side left

# Pack widget .toolbar.program_stop
pack .toolbar.program_stop \
	-side left


# Pack widget .toolbar.rule8
pack .toolbar.rule8 \
	-fill y \
	-padx 10 \
	-pady 4 \
	-side left


# Pack widget .toolbar.program_blockdelete
pack .toolbar.program_blockdelete \
	-side left

# Pack widget .toolbar.program_optpause
pack .toolbar.program_optpause \
	-side left


# Pack widget .toolbar.rule9
pack .toolbar.rule9 \
	-fill y \
	-padx 10 \
	-pady 4 \
	-side left


# Pack widget .toolbar.view_zoomin
pack .toolbar.view_zoomin \
	-side left

# Pack widget .toolbar.view_zoomout
pack .toolbar.view_zoomout \
	-side left

# Pack widget .toolbar.view_z2
#pack .toolbar.view_z2 \
#	-side left

# Pack widget .toolbar.view_x
pack .toolbar.view_x \
	-side left

# Pack widget .toolbar.view_y
pack .toolbar.view_y \
	-side left

# Pack widget .toolbar.view_z
pack .toolbar.view_z \
	-side left

# Pack widget .toolbar.view_p
pack .toolbar.view_p \
	-side left

# Pack widget .toolbar.rotate
pack .toolbar.rotate \
	-side left


# Pack widget .toolbar.rule12
pack .toolbar.rule12 \
	-fill y \
	-padx 10 \
	-pady 4 \
	-side left


# Pack widget .toolbar.clear_plot
pack .toolbar.clear_plot \
	-side left


#--------------------------------- END TOOL BAR

