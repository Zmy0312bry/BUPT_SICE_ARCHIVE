module V_IV_selector(
    input clk,
    input [2:0] sel,            //选位信号
	 output reg [7:0] select,    //输入的8位信号
    output out                  //被选出的信号
	 );

    wire clk_out;

	 divider div1(
		  .clk(clk),
		  .clk_out(clk_out)
	 );
    initial begin
        select = 8'b0000_0001;
    end
	 
    always @(posedge clk_out) begin
        select ={select[6:0],select[7]};
    end
	 data_selector selector(
	     .in(select),
		  .sel(sel),
		  .out(out)
	 );
endmodule


module divider(clk,clk_out);
    input wire clk;
    output reg clk_out;
    reg [21:0] counter;
    initial begin
        counter = 0;
        clk_out = 0;
    end
    always @(posedge clk) begin
        if (counter == 21'b1_1111_1111_1111_1111_1111) begin
            counter = 0;
            clk_out = ~clk_out;
        end
        else begin
            counter <= counter + 1;
        end
    end
endmodule