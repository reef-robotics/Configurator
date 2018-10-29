label $_tabs_manual.axis
setup_widget_accel $_tabs_manual.axis [_ "Axis:"]

frame $_tabs_manual.axes

radiobutton $_tabs_manual.axes.axisx \
	-anchor w \
	-padx 0 \
	-value x \
	-variable current_axis \
	-width 2 \
        -text X \
        -command axis_activated

radiobutton $_tabs_manual.axes.axisy \
	-anchor w \
	-padx 0 \
	-value y \
	-variable current_axis \
	-width 2 \
        -text Y \
        -command axis_activated

radiobutton $_tabs_manual.axes.axisz \
	-anchor w \
	-padx 0 \
	-value z \
	-variable current_axis \
	-width 2 \
        -text Z \
        -command axis_activated

radiobutton $_tabs_manual.axes.axisa \
	-anchor w \
	-padx 0 \
	-value a \
	-variable current_axis \
	-width 2 \
        -text A \
        -command axis_activated

radiobutton $_tabs_manual.axes.axisb \
	-anchor w \
	-padx 0 \
	-value b \
	-variable current_axis \
	-width 2 \
        -text B \
        -command axis_activated

radiobutton $_tabs_manual.axes.axisc \
	-anchor w \
	-padx 0 \
	-value c \
	-variable current_axis \
	-width 2 \
        -text C \
        -command axis_activated

radiobutton $_tabs_manual.axes.axisu \
	-anchor w \
	-padx 0 \
	-value u \
	-variable current_axis \
	-width 2 \
        -text U \
        -command axis_activated

radiobutton $_tabs_manual.axes.axisv \
	-anchor w \
	-padx 0 \
	-value v \
	-variable current_axis \
	-width 2 \
        -text V \
        -command axis_activated

radiobutton $_tabs_manual.axes.axisw \
	-anchor w \
	-padx 0 \
	-value w \
	-variable current_axis \
	-width 2 \
        -text W \
        -command axis_activated

# Grid widget $_tabs_manual.axes.axisu
grid $_tabs_manual.axes.axisu \
	-column 0 \
	-row 2 \
	-padx 4

# Grid widget $_tabs_manual.axes.axisv
grid $_tabs_manual.axes.axisv \
	-column 1 \
	-row 2 \
	-padx 4

# Grid widget $_tabs_manual.axes.axisw
grid $_tabs_manual.axes.axisw \
	-column 2 \
	-row 2 \
	-padx 4




# Grid widget $_tabs_manual.axes.axisb
grid $_tabs_manual.axes.axisb \
	-column 1 \
	-row 1 \
	-padx 4

# Grid widget $_tabs_manual.axes.axisc
grid $_tabs_manual.axes.axisc \
	-column 2 \
	-row 1 \
	-padx 4

# Grid widget $_tabs_manual.axes.axisx
grid $_tabs_manual.axes.axisx \
	-column 0 \
	-row 0 \
	-padx 4

# Grid widget $_tabs_manual.axes.axisy
grid $_tabs_manual.axes.axisy \
	-column 1 \
	-row 0 \
	-padx 4

# Grid widget $_tabs_manual.axes.axisz
grid $_tabs_manual.axes.axisz \
	-column 2 \
	-row 0 \
	-padx 4

# Grid widget $_tabs_manual.axes.axisa
grid $_tabs_manual.axes.axisa \
	-column 3 \
	-row 0 \
	-padx 4






frame $_tabs_manual.joints

radiobutton $_tabs_manual.joints.joint0 \
	-anchor w \
	-padx 0 \
	-value x \
	-variable current_axis \
	-width 2 \
        -text 0 \
        -command axis_activated

radiobutton $_tabs_manual.joints.joint1 \
	-anchor w \
	-padx 0 \
	-value y \
	-variable current_axis \
	-width 2 \
        -text 1 \
        -command axis_activated

radiobutton $_tabs_manual.joints.joint2 \
	-anchor w \
	-padx 0 \
	-value z \
	-variable current_axis \
	-width 2 \
        -text 2 \
        -command axis_activated

radiobutton $_tabs_manual.joints.joint3 \
	-anchor w \
	-padx 0 \
	-value a \
	-variable current_axis \
	-width 2 \
        -text 3 \
        -command axis_activated

radiobutton $_tabs_manual.joints.joint4 \
	-anchor w \
	-padx 0 \
	-value b \
	-variable current_axis \
	-width 2 \
        -text 4 \
        -command axis_activated

radiobutton $_tabs_manual.joints.joint5 \
	-anchor w \
	-padx 0 \
	-value c \
	-variable current_axis \
	-width 2 \
        -text 5 \
        -command axis_activated


radiobutton $_tabs_manual.joints.joint6 \
	-anchor w \
	-padx 0 \
	-value u \
	-variable current_axis \
	-width 2 \
        -text 6 \
        -command axis_activated

radiobutton $_tabs_manual.joints.joint7 \
	-anchor w \
	-padx 0 \
	-value v \
	-variable current_axis \
	-width 2 \
        -text 7 \
        -command axis_activated

radiobutton $_tabs_manual.joints.joint8 \
	-anchor w \
	-padx 0 \
	-value w \
	-variable current_axis \
	-width 2 \
        -text 8 \
        -command axis_activated

# Grid widget $_tabs_manual.joints.joint0
grid $_tabs_manual.joints.joint0 \
	-column 0 \
	-row 0 \
	-padx 4

# Grid widget $_tabs_manual.joints.joint1
grid $_tabs_manual.joints.joint1 \
	-column 1 \
	-row 0 \
	-padx 4

# Grid widget $_tabs_manual.joints.joint2
grid $_tabs_manual.joints.joint2 \
	-column 2 \
	-row 0 \
	-padx 4

# Grid widget $_tabs_manual.joints.joint3
grid $_tabs_manual.joints.joint3 \
	-column 0 \
	-row 1 \
	-padx 4

# Grid widget $_tabs_manual.joints.joint4
grid $_tabs_manual.joints.joint4 \
	-column 1 \
	-row 1 \
	-padx 4

# Grid widget $_tabs_manual.joints.joint5
grid $_tabs_manual.joints.joint5 \
	-column 2 \
	-row 1 \
	-padx 4

# Grid widget $_tabs_manual.joints.joint6
grid $_tabs_manual.joints.joint6 \
	-column 0 \
	-row 2 \
	-padx 4

# Grid widget $_tabs_manual.joints.joint7
grid $_tabs_manual.joints.joint7 \
	-column 1 \
	-row 2 \
	-padx 4

# Grid widget $_tabs_manual.joints.joint8
grid $_tabs_manual.joints.joint8 \
	-column 2 \
	-row 2 \
	-padx 4

