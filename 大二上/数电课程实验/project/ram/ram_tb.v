`timescale 1ns/1ps 
 
module ram_tb; 
     
    reg clk; 
    reg rst; 
    reg we; 
    reg [7:0] addr; 
    reg [3:0] data_in; 
    wire [3:0] data_out; 
     
    ram256x8 ram_test ( 
        .clk(clk), 
        .we(we), 
        .addr(addr), 
        .data_in(data_in), 
        .data_out(data_out)
        //.rst(rst)
    ); 
     
    initial begin 
        clk = 0; 
        forever #5 clk = ~clk; 
    end

    initial begin
        $dumpfile("ram256x8.vcd");
        $dumpvars(0, ram_tb);
    end

    initial begin 
        we = 0; 
        addr = 0; 
        data_in = 0; 
        rst = 0;
        #10
        rst = 1;
        #10 
        we = 1; addr = 8'b00000000; data_in = 4'h1;
        #10 
        we = 1; addr = 8'b00000001; data_in = 4'h2;
        #10 
        we = 1; addr = 8'b00000010; data_in = 4'h3;
        #10 
        we = 1; addr = 8'b00000011; data_in = 4'h4;
        #10
        we = 1; addr = 8'b00000100; data_in = 4'h5;
        #10
        we = 1; addr = 8'b00000101; data_in = 4'h6;
        #10
        we = 1; addr = 8'b00000110; data_in = 4'h7;
        #10
        we = 1; addr = 8'b00000111; data_in = 4'h8;
        #10
        we = 1; addr = 8'b00001000; data_in = 4'h9;
        #10
        we = 1; addr = 8'b00001001; data_in = 4'hA;
        #10
        we = 1; addr = 8'b00001010; data_in = 4'hB;
        #10
        we = 1; addr = 8'b00001011; data_in = 4'hC;
        #10
        we = 1; addr = 8'b00001100; data_in = 4'hD;
        #10
        we = 1; addr = 8'b00001101; data_in = 4'hE;
        #10
        we = 1; addr = 8'b00001110; data_in = 4'hF;
        #10
        we = 1; addr = 8'b00001111; data_in = 4'h0;
        #10
        we = 1; addr = 8'b00010000; data_in = 4'h1;
        #10
        we = 1; addr = 8'b00010001; data_in = 4'h2;
        #10
        we = 1; addr = 8'b00010010; data_in = 4'h3;
        #10
        we = 1; addr = 8'b00010011; data_in = 4'h4;
        #10
        we = 1; addr = 8'b00010100; data_in = 4'h5;
        #10
        we = 1; addr = 8'b00010101; data_in = 4'h6;
        #10
        we = 1; addr = 8'b00010110; data_in = 4'h7;
        #10
        we = 1; addr = 8'b00010111; data_in = 4'h8;
        #10
        we = 1; addr = 8'b00011000; data_in = 4'h9;
        #10
        we = 1; addr = 8'b00011001; data_in = 4'hA;
        #10
        we = 1; addr = 8'b00011010; data_in = 4'hB;
        #10
        we = 1; addr = 8'b00011011; data_in = 4'hC;
        #10
        we = 1; addr = 8'b00011100; data_in = 4'hD;
        #10
        we = 1; addr = 8'b00011101; data_in = 4'hE;
        #10
        we = 1; addr = 8'b00011110; data_in = 4'hF;
        #10
        we = 0; addr = 8'b00000000;
        #10
        we = 0; addr = 8'b00000001;
        #10
        we = 0; addr = 8'b00000010;
        #10
        we = 0; addr = 8'b00000011; 
         
        #10; 
        $finish;
    end
endmodule