iverilog -o "6_5_tb.vvp" six_point_five_ls374_tb.v six_point_five_ls374.v
vvp "6_5_tb.vvp"
gtkwave "6_5_tb.vcd"