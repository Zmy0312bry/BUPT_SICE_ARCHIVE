iverilog -o "6_4_tb.vvp" six_point_four_shift_reg_tb.v six_point_four_shift_reg.v
vvp "6_4_tb.vvp"
gtkwave "6_4_tb.vcd"