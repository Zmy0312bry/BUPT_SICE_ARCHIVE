# Copyright (C) Mingyuan 2024. All rights reserved.
# Quartus Prime: Pin Assignment Tcl File
# File: counter.tcl
# Generated on: 2024-11-11 09:39

# Load Quartus Prime Tcl Project package
package require ::quartus::project

# Check if the right project is open
if {[is_project_open]} {
    if {[string compare $quartus(project) "counter"]} {
        puts "Project counter is not open"
    }
} else {
    # Only open if not already open
    if {[project_exists counter]} {
        project_open -revision counter counter
    } else {
        project_new -revision counter counter
    }
}

# Set pin assignments
set_location_assignment PIN_18 -to clk
set_location_assignment PIN_73 -to led[7]
set_location_assignment PIN_74 -to led[6]
set_location_assignment PIN_75 -to led[5]
set_location_assignment PIN_76 -to led[4]
set_location_assignment PIN_77 -to led[3]
set_location_assignment PIN_78 -to led[2]
set_location_assignment PIN_79 -to led[1]
set_location_assignment PIN_80 -to led[0]
set_location_assignment PIN_125 -to sw[7]
set_location_assignment PIN_127 -to sw[6]
set_location_assignment PIN_129 -to sw[5]
set_location_assignment PIN_130 -to sw[4]
set_location_assignment PIN_131 -to sw[3]
set_location_assignment PIN_132 -to sw[2]
set_location_assignment PIN_133 -to sw[1]
set_location_assignment PIN_134 -to sw[0]
set_location_assignment PIN_31 -to cat[7]
set_location_assignment PIN_30 -to cat[6]
set_location_assignment PIN_70 -to cat[5]
set_location_assignment PIN_69 -to cat[4]
set_location_assignment PIN_68 -to cat[3]
set_location_assignment PIN_67 -to cat[2]
set_location_assignment PIN_66 -to cat[1]
set_location_assignment PIN_63 -to cat[0]
# Commit assignments
export_assignments

# Close project (optional)
project_close
