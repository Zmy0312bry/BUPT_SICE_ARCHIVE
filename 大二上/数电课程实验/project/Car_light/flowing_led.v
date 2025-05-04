module flowing_led(
	input clk,
	input en_l,
	input en_r,
	output [2:0] rgb_led_1_n,
	output [2:0] rgb_led_2_n,
	output reg [7:0] status_led_n
);
	wire div_clk; // 1s 的分频信号
	
	clk_divider clk_div(
	.clk_in(clk),
	.rst_n(1'b1),
	.clk_out(div_clk)
	);
	
	
	wire div_clk_2hz;
	
	clk_divider #(
		.N(6000000)
	) clk_2hz (
	.clk_in(clk),
	.rst_n(1'b1),
	.clk_out(div_clk_2hz)
	);

	
	reg status;
	
	reg move;
	
	always@(posedge div_clk_2hz) begin
		if (en_l && en_r) begin
			move = 0;
			if (status == 1'b0) begin
				status_led_n = 8'hff;
				status = 1'b1;
			end else begin
				status_led_n = 8'h00;
				status = 1'b0;
			end
		end else if (en_l) begin
			if(move == 0)begin
				status_led_n = 8'b11110000;
				move = 1;
			end else begin
				status_led_n = {status_led_n[6:0],status_led_n[7]};
			end
		end else if (en_r) begin
			if(move == 0)begin
				status_led_n = 8'b00001111;
				move = 1;
			end else begin
				status_led_n = {status_led_n[0],status_led_n[7:1]};
			end
		end else begin
			move = 0;
			status_led_n = 8'hff;
		end
	end
	
	
	
	wire led_l;  // 高电平有效
	wire led_r;
	assign led_l = ~(div_clk & en_l);
	assign led_r = ~(div_clk & en_r);
	
	assign rgb_led_1_n = {led_l,led_l,led_l};
	assign rgb_led_2_n = {led_r,led_r,led_r};
	
	

endmodule