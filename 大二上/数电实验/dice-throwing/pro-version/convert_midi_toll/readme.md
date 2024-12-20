# 说明文档
## 依赖安装
运行前在虚拟环境中运行如下命令
````bash
pip install mido
pip install pandas
````
该项目参考资料如下

https://blog.csdn.net/hans_yu/article/details/113818152

## 使用步骤
1. 运行py文件
2. 在弹出的输入框中输入起始时间和终止时间，和倍速，最后会根据输入的时间进行生成
3. 复制以下文件，将...内容替换为生成txt文件内内容
4. **注意：** `is_final`信号为使能信号，在实例化时进行替换
5. 将以下全局变量替换为你的时钟频率和计数器位数
```python
CLK_FREQ = 1000000  # 定义时钟频率的变量，这里是1MHz
MAX_CNT = 24 # 最大计数器位数
```

```verilog
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
        ... //此处代码由midi_extract.py生成
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
```

## midi资源网站

找midi文件的网站:https://bitmidi.com/
