module V_VIII_full_adder_thread(
	 input clk,         // 系统时钟
	 input rst,         // 复位按钮
    input [3:0] Input, // 输入数字
    input btn,         // 状态切换(输入1，输入2，show result)
	 output [7:0] seg1, // 数码管1
	 output [7:0] seg2, // 数码管2
	 input cin,         // 前级进位
	 output reg cin_status,
	 output cout        // 后级进位
);
	 wire change;
	 wire cin_pulse;
    reg [1:0] status;
	 reg [3:0] number1;
	 reg [3:0] number2;
	 wire [3:0] result;
	 reg [3:0] show_number;
	
	 
	 debounce d1(
	 .clk(clk),
	 .rst(rst),
	 .key(btn),
	 .key_pulse(change)
	 );
	 
	 debounce d2(
	 .clk(clk),
	 .rst(rst),
	 .key(cin),
	 .key_pulse(cin_pulse)
	 );
	 
	 segment_decoder seg_dcdr(
	 .digit_in(show_number),
	 .seg_out_1(seg1),
	 .seg_out_2(seg2)
	 );
	 
	 full_adder_thread_4bit adder(
	 .A(number1),
	 .B(number2),
	 .Cin(cin_status),
	 .S(result),
	 .Cout(cout)
	 );

	 
	 initial begin
	     status = 2'b00;
		  number1 = 4'b0000;
		  number2 = 4'b0000;
		  show_number = 4'b0000;
		  cin_status = 0;
	 end
	 
	 always @ (negedge rst or posedge clk) begin
	     if(!rst) begin
		      number1 = 4'b0000;
				number2 = 4'b0000;
				status = 2'b00;
				cin_status = 0;
				show_number = 4'b0000;
		  end else begin
				if (cin_pulse) begin
					cin_status = ~cin_status;
				end
		      case(status)
				2'b00:begin
					 if (change) begin
					     number1 <= Input;
						  show_number <= Input;
						  status <=2'b01;
					 end
				end
				2'b01:begin
					if (change) begin
						 number2 <= Input;
						 show_number <= Input;
						 status <=2'b10;
					end
				end
				2'b10:begin
					if (change) begin
					    show_number <= result;
						 status <=2'b11;
					end
				end
				2'b11:begin
					if (change) begin
						 status <=2'b00;
						 number1 = 4'b0000;
					    number2 = 4'b0000;
						 //cin_status = 0;
					    show_number = 4'b0000;
					end
				end
				endcase
		  end
	 end
endmodule

module full_adder_thread_4bit(
 input [3:0]A, B,
 input Cin,
 output [3:0] S,
 output Cout
);
    wire [3:0] Ci;
    assign Ci[0] = Cin;
    assign Ci[1] = (A[0] & B[0]) | ((A[0]^B[0]) & Ci[0]);
    //assign Ci[2] = (A[1] & B[1]) | ((A[1]^B[1]) & Ci[1]);
    assign Ci[2] = (A[1] & B[1]) | ((A[1]^B[1]) & ((A[0] & B[0]) | ((A[0]^B[0]) & Ci[0])));
    //assign Ci[3] = (A[2] & B[2]) | ((A[2]^B[2]) & Ci[2]); 
    assign Ci[3] = (A[2] & B[2]) | ((A[2]^B[2]) & ((A[1] & B[1]) | ((A[1]^B[1]) & ((A[0] & B[0]) | ((A[0]^B[0]) & Ci[0])))));
    //assign Cout = (A[3] & B[3]) | ((A[3]^B[3]) & Ci[3]);
    assign Cout = (A[3] & B[3]) | ((A[3]^B[3]) & ((A[2] & B[2]) | ((A[2]^B[2]) & ((A[1] & B[1]) | ((A[1]^B[1]) & ((A[0] & B[0]) | ((A[0]^B[0]) & Ci[0])))))));
    assign S = A^B^Ci;
endmodule