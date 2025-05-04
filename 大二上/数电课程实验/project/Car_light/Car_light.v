module Car_light(
   input        clk,
	input  [3:0] car_status,
	output [2:0] rgb_led_1_n,
	output [2:0] rgb_led_2_n,
//	output [7:0] segment_1,
//	output [7:0] segment_2,
	output [7:0] status_led_n
);

	wire en_l;
	wire en_r;
	
	flowing_led model(
	.clk(clk),
	.en_l(en_l),
	.en_r(en_r),
	.rgb_led_1_n(rgb_led_1_n),
	.rgb_led_2_n(rgb_led_2_n),
	.status_led_n(status_led_n)
	);

	state_light calculate_state(
		.car_status(car_status),
		.en_l(en_l),
		.en_r(en_r)
	); // 使能信号 en{l,r}


endmodule