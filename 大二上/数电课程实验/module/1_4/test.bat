iverilog -o "1_4_tb.vvp" one_point_four_led_tb.v one_point_four_led.v  
vvp "1_4_tb.vvp"
gtkwave 1_4_tb.vcd