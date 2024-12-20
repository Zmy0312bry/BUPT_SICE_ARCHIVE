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
    reg [3:0] difference,state1_tmp,state2_tmp;
	reg start1_before,start2_before,flag1,flag2,sign,start1_sync,start2_sync;

    // 初始状态
    initial begin
        cnt <= 28'd0;
        is_final <= 0;
        times <= 0;
        state1 <= 0;
        state2 <= 0;
        finish <= 0;
		  flag1<=0;
		  flag2<=0;
		  sign<=0;
		  difference<=0;
		  start1_before <= 0;
		  start2_before <= 0;
		  start1_sync <= 0;
		  start1_sync <= 0;
		  state1_tmp<=0;
		  state2_tmp<=0;
    end
	 
	 always @(posedge clk or negedge rst) begin
    if (!rst) begin
		  start1_before <= 0;
		  start2_before <= 0;
		  start1_sync <= 0;
		  start1_sync <= 0;
    end else begin
        start1_before <= start1_sync;
        start2_before <= start2_sync;
		  start1_sync <= start1;
		  start2_sync <= start2;
		  if((start1_before==1)&&(start1==0))begin
				flag1<=1;
		  end
		  if((start2_before==1)&&(start2==0))begin
				flag2<=1;
		  end
		  if(flag1&&flag2)begin
			sign<=1;
			flag1<=0;
			flag2<=0;
		  end
		  if(sign)begin
		  if (difference < 2) begin
			if(cnt>=28'd3000000)begin
			sign<=0;end
			end
		  else begin
			if(cnt>=28'd5000000)begin
			sign<=0;end
		  end
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
						  is_final <= 0;
					end
					 else if(cnt>=28'd2999900)begin
						finish<=1;
						cnt<=cnt+1;
					end
                else begin
                    cnt <= cnt + 1;
                    times <= 1;
                end
            end
				else begin
            if (cnt >= 28'd5000000) begin // 计时5秒
                cnt <= 28'd0;
                times <= 0;
					 finish<=0;
					 
				end
				else if(cnt >= 28'd4999900)begin
					finish<=1;
					cnt<=cnt+1;
				end
            else begin
                cnt <= cnt + 1;
                times <= 1;
                is_final <= 1;
					 finish<=0;
            end
        end
		 end
		end
    end

    // 游戏状态更新逻辑：由 times 的上升沿触发 此时更新的为内在逻辑
    always @(negedge rst or posedge finish or posedge times) begin
        if(!rst)begin
		  	   state1_tmp<=4'b0000;
				state2_tmp<=4'b0000;
				difference = 4'b0;
			end
			else begin
			 if (finish) begin
				if(is_final)begin
					state1_tmp<=4'b0000;
					state2_tmp<=4'b0000;
					difference = 4'b0;
					end
			  end
			 else begin
				if(times)begin
					if (dice1 < dice2)begin
						state2_tmp = state2_tmp + 1;
						difference <= (state1_tmp > state2_tmp) ? state1_tmp - state2_tmp : state2_tmp - state1_tmp;
					end
					else if (dice1 > dice2)begin
						state1_tmp = state1_tmp + 1;
						difference <= (state1_tmp > state2_tmp) ? state1_tmp - state2_tmp : state2_tmp - state1_tmp;
					end
				end
			end
		end
    end
	 
	 
	 //更新显示逻辑
	 always@(negedge rst or negedge times)begin
		if(!rst)begin
			state1<=0;
			state2<=0;
		end
		else begin
			if(!times)begin
				state1<=state1_tmp;
				state2<=state2_tmp;
			end
		end
	 end
	 

endmodule