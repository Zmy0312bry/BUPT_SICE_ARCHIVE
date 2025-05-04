iverilog -o "5_8_tb.vvp" five_point_eight_threading_adder_tb.v five_point_eight_threading_adder.v
vvp "5_8_tb.vvp"
gtkwave "5_8_tb.vcd"