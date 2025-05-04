iverilog -o "6_2_tb.vvp" six_point_two_dff_sync_tb.v six_point_two_dff_sync.v
vvp "6_2_tb.vvp"
gtkwave "6_2_tb.vcd"