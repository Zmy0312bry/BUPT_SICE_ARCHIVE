module standby(clk, times, is_final, rst, score1, score2, rgb_led,is_finish);  
    input clk;
    input times;
    input is_final,is_finish;
    input rst;
    input [3:0] score1, score2;
    output reg [15:0] rgb_led;
	 

    reg [19:0] cnt;
    reg [3:0] score1_reg, score2_reg;

	 initial begin
		cnt<=20'd0;
	 end
    // 同步复位及寄存分数
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            score1_reg <= 4'b0;
            score2_reg <= 4'b0;
        end else begin
            score1_reg <= score1;
            score2_reg <= score2;
        end
    end

    // 计数器逻辑
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            cnt <= 20'd0;
				end else if (!is_final && times) begin  //不是最后一把并且times为高电平
            if (cnt >= 20'd100001) begin   //cnt >= 20'd100001
                cnt <= 20'd0;
            end else begin
                cnt <= cnt + 1;
            end
        end
    end

    // RGB灯光逻辑
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            rgb_led <= 16'b0000_0000_0000_0000;
        end 
		  else if (!is_final) begin
            if (times) begin
                if (rgb_led == 16'd0) begin
                    rgb_led <= 16'b0000_0000_0000_0001;
                end else if (cnt >= 20'd100000) begin   //cnt >= 20'd100000
                    rgb_led <= {rgb_led[0],rgb_led[15:1]};
                end
					 end
				else begin
					rgb_led<=16'b0000_0000_0000_0000;
				end
        end
		  else begin
		  if(times)begin
            if (score1_reg > score2_reg) begin
                rgb_led <= 16'b1111_1111_0000_0000;
            end 
				else begin
                rgb_led <= 16'b0000_0000_1111_1111;
            end
			end
			else begin
				rgb_led<=16'b0000_0000_0000_0000;
			end
        end
    end
endmodule
