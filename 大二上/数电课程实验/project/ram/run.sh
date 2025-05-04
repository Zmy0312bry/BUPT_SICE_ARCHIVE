iverilog -o test.vvp ram_tb.v ram256x8.v
vvp -v -n test.vvp
gtkwave -F -g ram256x8.vcd