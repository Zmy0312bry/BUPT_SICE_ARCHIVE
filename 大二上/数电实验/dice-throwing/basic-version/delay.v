module delay(clk,start1,start2,is_final，is_wait);  //is_final为最后一局的标志位，is_wait为将要与rst相或的信号
	input clk;
	input start1,start2;
	input is_final;
	output reg is_wait;  //1完成，在计数中一直为0
	output reg is_final_finish;  //对是否结束进行标志
wire [27:0]cnt;
reg flag;	

initial begin
	cnt<=28'd0;
	is_wait<=1;
	flag<=0;
	is_final_finish<=0;
end

always@(negedge start1 or negedge start2 or posedge clk)begin
	if(!start1&&!start2)begin
		flag<=1； //当异步松手，标志开始
		is_wait<=0;
	end
	else begin
		if(flag)begin //如果已经开始
			if(is_final)begin  //判断是不是最后一局
				if(cnt>=28'd60000000)begin
					cnt<=28'd0;
					is_final_finish<=1;
					flag<=0;
					is_wait<=1;
				end
				else begin
					cnt<=cnt+1;
				end
			end
			else begin //并不是最后一局
				if(cnt>=28'd36000000)begin
					cnt<28'd0;
					is_wait<=1;
					flag<=0;
				end
			end
		end
	end
end

endmodule