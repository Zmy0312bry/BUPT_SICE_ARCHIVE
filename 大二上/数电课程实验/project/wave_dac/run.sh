iverilog -o test.vvp wave_dac_tb.v wave_dac.v
vvp -v test.vvp
gtkwave -F -g wave_dac_tb.vcd