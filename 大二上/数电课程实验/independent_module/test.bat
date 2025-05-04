iverilog -o "test.vvp" "tb_Colorful_led.v" "Colorful_led.v" "clk_divider.v" "pwm_line.v" "pwm.v"
vvp  "test.vvp"
gtkwave "tb_colorful_led.vcd"