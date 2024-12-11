`timescale 1ms / 1ps

module led_matrix_test;
       reg clk;
       reg [2:0] state;
       reg btn7;
       wire [7:0] red_led,green_led,row;
       wire beeper;

led_matrix led_matrix1(
       .clk(clk),
       .state(state),
       .btn7(btn7),
       .red_led(red_led),
       .green_led(green_led),
       .row(row),
       .beeper(beeper)
);
initial begin
        clk = 0;
        state = 3'b000;
        btn7 = 0;
        forever begin
            #5 clk = ~clk;
        end
    end
initial begin
    #100 state = 3'b001;
    #100 state = 3'b010;
    #100 state = 3'b011;
    #100 state = 3'b100;
    #100 state = 3'b101;
    #100 state = 3'b110;
    #10000 state = 3'b111;
    #100 btn7 = 1;
    #100 btn7 = 0;
    #10000 btn7 = 1;
    #100 btn7 = 0;
    #10000 btn7 = 1;
    #100 btn7 = 0;
    #100
    $finish;
end
initial begin   
		$dumpfile("tb_led_matrix.vcd");   
		$dumpvars(0, led_matrix_test);
end
endmodule