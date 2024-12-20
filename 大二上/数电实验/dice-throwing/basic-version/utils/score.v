module score(
    input clk,rst,
    input start1,
    input start2,
    input [3:0] dice1,
    input [3:0] dice2,
    output reg [3:0] state1,
    output reg [3:0] state2,
    output reg times,
    output reg is_final,
    output reg finish
);

    reg [27:0] cnt;
    wire [3:0] difference;
	 reg start1_before,start2_before,flag1,flag2,sign;
	
    assign difference = (state1 > state2) ? state1 - state2 : state2 - state1;

    // 初始状态
    initial begin
        cnt = 28'd0;
        is_final = 0;
         times = 0;
        state1 = 0;
        state2 = 0;
        finish = 0;
		 flag1 = 0;
		 flag2 = 0;
		  sign = 0;
    end
	 
	 always @(posedge clk or negedge rst) begin
		if (!rst) begin
			start1_before<=0; // 前级状态
			start2_before<=0;
		end else begin
			// start1_before = start1;
			// start2_before = start2;
			if (!flag1 || !flag2) begin
				if((start1_before==1)&&(start1==0))begin //伪下降沿
						flag1<=1;
				end else if((start2_before==1)&&(start2==0))begin // 事实上，这里的检测是不准确的，因为在一个时钟周期内，start1和start2可能同时变化
						flag2<=1;
				end
				if (difference >= 2) begin
					flag1 <= 1;
					flag2 <= 1;
				end
				start1_before <= start1;
				start2_before <= start2;
			end else begin
				sign <=1;
				flag1<=0;
				flag2<=0;
			end
			if (difference < 2) begin
				if(cnt>=28'd3000000)begin
				sign<=0;end
			end else begin
				if(cnt>=28'd5000000)begin
				sign<=0;end
			end
		end
	end


    // 计数逻辑：由时钟信号驱动
    always @(negedge rst or posedge clk) begin
      if(!rst)begin
			cnt<=0;
			finish<=0;
			times<=0;
			is_final<=0;
		end
		else begin
			if (sign) begin
				if (difference < 2) begin
					if (cnt >= 28'd3000000) begin // 计时3秒difference < 2
						cnt <= 28'd0;
						times <= 0;
						finish<=0;
					end else if(cnt>=28'd2999900)begin
							finish<=1;
							cnt<=cnt+1;
					end else begin
						cnt <= cnt + 1;
						times <= 1;
					end
				end else begin
					if (cnt >= 28'd5000000) begin // 计时5秒
						cnt <= 28'd0;
						times <= 0;
						is_final <= 0;
						finish<=0;
					end else if(cnt >= 28'd4999900)begin
							finish<=1;
							cnt<=cnt+1;
					end else begin
						cnt <= cnt + 1;
						times <= 1;
						is_final <= 1;
							finish<=0;
					end
        		end
		 	end
		end
    end

    // 游戏状态更新逻辑：由 times 的上升沿触发
    always @(negedge rst or posedge is_final or posedge finish) begin
        if(!rst)begin
		  	   state1<=4'b0000;
				state2<=4'b0000;
			end
			else begin
			 if (is_final) begin
				if(finish)begin
					state1<=4'b0000;
					state2<=4'b0000;
				end
			  end
			 else begin
				if (dice1 < dice2)
						 state2 <= state2 + 1;
					else if (dice1 > dice2)
						 state1 <= state1 + 1;
			end
		end
    end
	 

endmodule