module V_VII_full_adder(
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
	 
	 serial_adder_4bit adder(
	 .a(number1),
	 .b(number2),
	 .cin(cin_status),
	 .sum(result),
	 .cout(cout)
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

module serial_adder_4bit(
    input [3:0] a, b, // 两组 4 位加数
    input cin, // 低位来的进位
    output [3:0] sum, // 加法运算的结果
    output cout // 最高位的进位
);
    wire [3:0] c; // 进位线
    full_adder
    fa0(.a(a[0]), .b(b[0]), .cin(cin), .sum(sum[0]), .cout(c[0]));
    full_adder 
    fa1(.a(a[1]), .b(b[1]), .cin(c[0]), .sum(sum[1]), .cout(c[1]));
    full_adder
    fa2(.a(a[2]), .b(b[2]), .cin(c[1]), .sum(sum[2]), .cout(c[2]));
    full_adder 
    fa3(.a(a[3]), .b(b[3]), .cin(c[2]), .sum(sum[3]), .cout(cout));
endmodule

module full_adder(
    input a, b, cin,
    output sum, cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (cin & (a ^ b));
endmodule
