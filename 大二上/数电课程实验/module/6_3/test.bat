iverilog -o "6_3_tb.vvp" six_point_three_JK_ff_tb.v six_point_three_JK_ff.v
vvp "6_3_tb.vvp"
gtkwave "6_3_tb.vcd"