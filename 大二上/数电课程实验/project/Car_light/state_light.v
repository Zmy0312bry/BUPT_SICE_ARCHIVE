module state_light(
	input [3:0] car_status,
	output reg en_l,
	output reg en_r
);

always @(car_status) begin
	case(car_status)
		4'b1000:begin
			en_l = 1;
			en_r = 0;
		end
		4'b0001:begin
			en_l = 0;
			en_r = 1;
		end
		4'b0100:begin
			en_l = 1;
			en_r = 1;
		end
		4'b0010:begin
			en_l = 1;
			en_r = 1;
		end
		default:begin
			en_l = 0;
			en_r = 0;
		end
	endcase
end
endmodule