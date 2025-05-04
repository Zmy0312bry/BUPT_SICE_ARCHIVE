iverilog -o "5_2_tb.vvp" five_point_two_full_adder_tb.v five_point_two_full_adder.v _five_point_two_74LS138.v
vvp "5_2_tb.vvp"
gtkwave "5_2_tb.vcd"