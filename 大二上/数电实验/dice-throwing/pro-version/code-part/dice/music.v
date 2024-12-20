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
        24'd104886: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd107189: begin
            cnt <= cnt+1;  
            note <= 16'd758;  
        end
        24'd212075: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd321567: begin
            cnt <= cnt+1;  
            note <= 16'd758;  
        end
        24'd426453: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd535945: begin
            cnt <= cnt+1;  
            note <= 16'd955;  
        end
        24'd640831: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd643134: begin
            cnt <= cnt+1;  
            note <= 16'd758;  
        end
        24'd821712: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd857512: begin
            cnt <= cnt+1;  
            note <= 16'd637;  
        end
        24'd1036090: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd1286268: begin
            cnt <= cnt+1;  
            note <= 16'd1275;  
        end
        24'd1464846: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd1200516: begin
            cnt <= cnt+1;  
            note <= 16'd1275;  
        end
        24'd1273936: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd1275548: begin
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
        24'd104886: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd107189: begin
            cnt <= cnt+1;  
            note <= 16'd758;  
        end
        24'd212075: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd321567: begin
            cnt <= cnt+1;  
            note <= 16'd758;  
        end
        24'd426453: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd535945: begin
            cnt <= cnt+1;  
            note <= 16'd955;  
        end
        24'd640831: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd643134: begin
            cnt <= cnt+1;  
            note <= 16'd758;  
        end
        24'd821712: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd857512: begin
            cnt <= cnt+1;  
            note <= 16'd637;  
        end
        24'd1036090: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd1286268: begin
            cnt <= cnt+1;  
            note <= 16'd1275;  
        end
        24'd1464846: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd1200516: begin
            cnt <= cnt+1;  
            note <= 16'd1275;  
        end
        24'd1273936: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd1275548: begin
            cnt <= cnt+1;  
            note <= 16'd851;  
        end
        24'd1348968: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd1350580: begin
            cnt <= cnt+1;  
            note <= 16'd851;  
        end
        24'd1424000: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd1425612: begin
            cnt <= cnt+1;  
            note <= 16'd1136;  
        end
        24'd1499032: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd1575677: begin
            cnt <= cnt+1;  
            note <= 16'd851;  
        end
        24'd1649097: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd1650709: begin
            cnt <= cnt+1;  
            note <= 16'd1012;  
        end
        24'd1925778: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd2025870: begin
            cnt <= cnt+1;  
            note <= 16'd851;  
        end
        24'd2099290: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd2100903: begin
            cnt <= cnt+1;  
            note <= 16'd1012;  
        end
        24'd2174323: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd2175935: begin
            cnt <= cnt+1;  
            note <= 16'd955;  
        end
        24'd2249355: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd2250967: begin
            cnt <= cnt+1;  
            note <= 16'd851;  
        end
        24'd2375972: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd2401032: begin
            cnt <= cnt+1;  
            note <= 16'd1275;  
        end
        24'd2474452: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd2476064: begin
            cnt <= cnt+1;  
            note <= 16'd851;  
        end
        24'd2549484: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd2551096: begin
            cnt <= cnt+1;  
            note <= 16'd851;  
        end
        24'd2624516: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd2626128: begin
            cnt <= cnt+1;  
            note <= 16'd1136;  
        end
        24'd2699548: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd2776193: begin
            cnt <= cnt+1;  
            note <= 16'd851;  
        end
        24'd2849613: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd2851225: begin
            cnt <= cnt+1;  
            note <= 16'd1012;  
        end
        24'd3126294: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd3601548: begin
            cnt <= cnt+1;  
            note <= 16'd1275;  
        end
        24'd3674968: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd3676580: begin
            cnt <= cnt+1;  
            note <= 16'd851;  
        end
        24'd3750000: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd3751612: begin
            cnt <= cnt+1;  
            note <= 16'd851;  
        end
        24'd3825032: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd3826644: begin
            cnt <= cnt+1;  
            note <= 16'd1136;  
        end
        24'd3900064: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd3976709: begin
            cnt <= cnt+1;  
            note <= 16'd851;  
        end
        24'd4050129: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd4051741: begin
            cnt <= cnt+1;  
            note <= 16'd1012;  
        end
        24'd4326810: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd4426902: begin
            cnt <= cnt+1;  
            note <= 16'd851;  
        end
        24'd4500322: begin
            cnt <= cnt+1;  
            note <= 16'd0;  
        end
        24'd4501935: begin
            cnt <= cnt+1;  
            note <= 16'd1012;
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