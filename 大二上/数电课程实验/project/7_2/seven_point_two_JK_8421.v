module seven_point_two_JK_8421
(
	input clk,rst,btn,set,
	output [3:0] Q,
	output [8:0] seg_led
);

	reg [8:0] seg [9:0];
	
	debounce debounce_1
	(
		.clk(clk),
		.rst(rst),
		.key(btn),
		.key_pulse(btn_dbs)
	);
	
	JK_ff JK1
	(
		.j(1),
		.k(1),
		.clk(btn_dbs),
		.rst(rst),
		.set(set),
		.q_out(Q[0])
	);
	
	JK_ff JK2
	(
		.j(~Q[3]),
		.k(~Q[3]),
		.clk(Q[0]),
		.rst(rst),
		.set(set),
		.q_out(Q[1])
	);
	
	JK_ff JK3
	(
		.j(1),
		.k(1),
		.clk(Q[1]),
		.rst(rst),
		.set(set),
		.q_out(Q[2])
	);
	
	JK_ff JK4
	(
		.j(Q[2]&Q[1]),
		.k(Q[3]),
		.clk(Q[0]),
		.rst(rst),
		.set(set),
		.q_out(Q[3])
	);
	initial
		begin 
			seg[0] = 9'h3f;
			seg[1] = 9'h06;
			seg[2] = 9'h5b;
			seg[3] = 9'h4f;
			seg[4] = 9'h66;
			seg[5] = 9'h6d;
			seg[6] = 9'h7d;
			seg[7] = 9'h07;
			seg[8] = 9'h7f;
			seg[9] = 9'h6f;
		end	
	assign seg_led = seg[Q];
	
endmodule	

module JK_ff
(
	input j,k,clk,rst,set,
	output reg q_out
);

	always @ (negedge clk or negedge rst or negedge set)
		begin 
			if(!rst)
				begin q_out <= 0; end
			else if(!set)
				begin q_out <= 1; end 
			else 
				begin 
					case({j,k})
						2'b00:q_out <= q_out;
						2'b01:q_out <= 0;
						2'b10:q_out <= 1;
						2'b11:q_out <= ~q_out;
					endcase
				end
		end
		
endmodule

module debounce (clk,rst,key,key_pulse);
 
        parameter       N  =  1;         //要消除的按键的数量
 
	input             clk;
        input             rst;
        input 	[N-1:0]   key;          //输入的按键					
	output  [N-1:0]   key_pulse;        //按键动作产生的脉冲	
 
        reg     [N-1:0]   key_rst_pre;  //定义一个寄存器型变量存储上一个触发时的按键值
        reg     [N-1:0]   key_rst;      //定义一个寄存器变量储存储当前时刻触发的按键值
 
        wire    [N-1:0]   key_edge;      //检测到按键由高到低变化是产生一个高脉冲
 
        //利用非阻塞赋值特点，将两个时钟触发时按键状态存储在两个寄存器变量中
        always @(posedge clk  or  negedge rst)
          begin
             if (!rst) begin
                 key_rst <= {N{1'b1}}; //初始化时给key_rst赋值全为1，{}中表示N个1
                 key_rst_pre <= {N{1'b1}};
             end
             else begin
                 key_rst <= key;       //第一个时钟上升沿触发之后key的值赋给key_rst,
                                       //同时key_rst的值赋给key_rst_pre
                 key_rst_pre <= key_rst;    //非阻塞赋值。
                                            //相当于经过两个时钟触发，
                                            //key_rst存储的是当前时刻key的值，
                                            //key_rst_pre存储的是前一个时钟的key的值
             end    
           end
 
        assign  key_edge = key_rst_pre & (~key_rst);//脉冲边沿检测。
                                                    //当key检测到下降沿时，
                                                    //key_edge产生一个时钟周期的高电平
 
        reg	[17:0]	  cnt;                       //产生延时所用的计数器，系统时钟12MHz，
                                                 //要延时20ms左右时间，至少需要18位计数器     
 
        //产生20ms延时，当检测到key_edge有效是计数器清零开始计数
        always @(posedge clk or negedge rst)
           begin
             if(!rst)
                cnt <= 18'h0;
             else if(key_edge)
                cnt <= 18'h0;
             else
                cnt <= cnt + 1'h1;
             end  
 
        reg     [N-1:0]   key_sec_pre;                //延时后检测电平寄存器变量
        reg     [N-1:0]   key_sec;                    
 
 
        //延时后检测key，如果按键状态变低产生一个时钟的高脉冲。如果按键状态是高的话说明按键无效
        always @(posedge clk  or  negedge rst)
          begin
             if (!rst) 
                 key_sec <= {N{1'b1}};                
             else if (cnt==18'h3ffff)
                 key_sec <= key;  
          end
       always @(posedge clk  or  negedge rst)
          begin
             if (!rst)
                 key_sec_pre <= {N{1'b1}};
             else                   
                 key_sec_pre <= key_sec;             
         end      
       assign  key_pulse = key_sec_pre & (~key_sec);     
 
endmodule