module pwm_line #(
	parameter N = 46875      
)
(
	input clk,               //系统时钟
	input rst_n,
	input [7:0] offset_line, //总体时钟偏置
	output pwm_out
);
	wire clk_line;           //包络线
	reg flag;
	
	clk_divider #(
	.N(N)
	) clk_div (
	.clk_in(clk),
	.rst_n(rst_n),
	.clk_out(clk_line)
	);

	reg [7:0] cnt_line;

	pwm pwm_signal ( 
        .clk(clk), 
        .rst_n(rst_n), 
        .duty_cycle(cnt_line), 
        .offset(8'h00), 
        .pwm_out(pwm_out)
	);
	
	initial begin
		cnt_line = offset_line;
		flag = 0;
		//pwm_out = 0;
	end
	always @ (posedge clk_line or negedge rst_n) begin
		if (!rst_n) begin
			cnt_line <= offset_line;
			flag = 0;
		end else begin
			if (flag == 0) begin
				cnt_line = cnt_line + 1;
				if (cnt_line == 8'hff) flag = 1;
			end else if (flag == 1) begin
				cnt_line = cnt_line - 1;
				if (cnt_line == 8'h00) flag = 0;
			end
		end
	end
endmodule