iverilog -o "5_7_tb.vvp" five_point_seven_serial_adder_4bit_tb.v five_point_seven_serial_adder_4bit.v
vvp "5_7_tb.vvp"
gtkwave 5_7_tb.vcd