module music(clk,beep,is_final,rst);
	input clk,is_final,rst;
	output reg beep;
	
reg [23:0]cnt;//24位
reg [15:0]note;//记录音符的频率（由频率转化而来的计数次数）
reg [15:0]tmp_note;//辅助计数器
reg up_down;//标志位1代表向上
	
always@(posedge clk or negedge rst)begin  //实现时序逻辑
	if(!rst)begin
		cnt<=24'd0;
	end
	else begin
		case(cnt)
         24'd0: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd0: begin
            cnt <= cnt+1;  
            note <= 16'd758;  
        end
        24'd209772: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd214378: begin
            cnt <= cnt+1;  
            note <= 16'd758;  
        end
        24'd424150: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd643134: begin
            cnt <= cnt+1;  
            note <= 16'd758;  
        end
        24'd852906: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd1071890: begin
            cnt <= cnt+1;  
            note <= 16'd955;  
        end
        24'd1281662: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd1286268: begin
            cnt <= cnt+1;  
            note <= 16'd758;  
        end
        24'd1643425: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd1715024: begin
            cnt <= cnt+1;  
            note <= 16'd637;  
        end
        24'd2072181: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd2572536: begin
            cnt <= cnt+1;  
            note <= 16'd1275;  
        end
        24'd2929693: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd2401032: begin
            cnt <= cnt+1;  
            note <= 16'd1275;  
        end
        24'd2547872: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd2551096: begin
            cnt <= cnt+1;  
            note <= 16'd851;  
        end
        24'd0: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd0: begin
            cnt <= cnt+1;  
            note <= 16'd758;  
        end
        24'd209772: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd214378: begin
            cnt <= cnt+1;  
            note <= 16'd758;  
        end
        24'd424150: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd643134: begin
            cnt <= cnt+1;  
            note <= 16'd758;  
        end
        24'd852906: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd1071890: begin
            cnt <= cnt+1;  
            note <= 16'd955;  
        end
        24'd1281662: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd1286268: begin
            cnt <= cnt+1;  
            note <= 16'd758;  
        end
        24'd1643425: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd1715024: begin
            cnt <= cnt+1;  
            note <= 16'd637;  
        end
        24'd2072181: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd2572536: begin
            cnt <= cnt+1;  
            note <= 16'd1275;  
        end
        24'd2929693: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd2401032: begin
            cnt <= cnt+1;  
            note <= 16'd1275;  
        end
        24'd2547872: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd2551096: begin
            cnt <= cnt+1;  
            note <= 16'd851;  
        end
        24'd2697936: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd2701161: begin
            cnt <= cnt+1;  
            note <= 16'd851;  
        end
        24'd2848001: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd2851225: begin
            cnt <= cnt+1;  
            note <= 16'd1136;  
        end
        24'd2998065: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd3151354: begin
            cnt <= cnt+1;  
            note <= 16'd851;  
        end
        24'd3298194: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd3301419: begin
            cnt <= cnt+1;  
            note <= 16'd1012;  
        end
        24'd3851557: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd4051741: begin
            cnt <= cnt+1;  
            note <= 16'd851;  
        end
        24'd4198581: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd4201806: begin
            cnt <= cnt+1;  
            note <= 16'd1012;  
        end
        24'd4348646: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd4351870: begin
            cnt <= cnt+1;  
            note <= 16'd955;  
        end
        24'd4498710: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd4501935: begin
            cnt <= cnt+1;  
            note <= 16'd851;  
        end
        24'd4751944: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd4802064: begin
            cnt <= cnt+1;  
            note <= 16'd1275;  
        end
        24'd4948904: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd4952128: begin
            cnt <= cnt+1;  
            note <= 16'd851;  
        end
        24'd5098968: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd5102193: begin
            cnt <= cnt+1;  
            note <= 16'd851;  
        end
        24'd5249033: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd5252257: begin
            cnt <= cnt+1;  
            note <= 16'd1136;  
        end
        24'd5399097: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        default: begin
            cnt <= cnt+1;
        end		
		endcase
		
	end
end

always@(posedge clk or negedge rst)begin//赋值逻辑
	if(!rst)begin
		beep<=0;
		up_down<=1;
		tmp_note<=16'd0;
	end
	else begin
		if(is_final)begin
			if(up_down)begin//保持高电平时间
				if(tmp_note>=note)begin
					tmp_note<=0;
					beep<=0;
					up_down<=0;
				end
				else begin
					tmp_note<=tmp_note+1;
					beep<=1;
				end
			end
			else begin
				if(tmp_note>=note)begin
					tmp_note<=0;
					beep<=1;
					up_down<=1;
				end
				else begin
					tmp_note<=tmp_note+1;
					beep<=0;
				end
			end
		end
		else begin
			beep<=0;
		end
	end
end

endmodule