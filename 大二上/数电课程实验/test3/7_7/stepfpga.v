//按键计数器，用于实现数码管显示按键次数,seg_led_1显示按键次数的十位，
//seg_led_2 显示按键次数的个位 
module stepfpga(clk, rst, key, seg_led_1, seg_led_2); 
input clk; 
input rst; 
input key; 
output [8:0] seg_led_1; 
output [8:0] seg_led_2; 
reg [8:0] seg[9:0]; 
reg [7:0] counter;  //计数器，由于最高显示到99，所以只需要8位 
initial begin 
seg[0] = 9'h3f; //显示数字0 
seg[1] = 9'h06; //显示数字1 
seg[2] = 9'h5b; //显示数字2 
seg[3] = 9'h4f; //显示数字3 
seg[4] = 9'h66; //显示数字4 
seg[5] = 9'h6d; //显示数字5 
seg[6] = 9'h7d; //显示数字6 
seg[7] = 9'h07; //显示数字7
 seg[8] = 9'h7f; //显示数字8 
        seg[9] = 9'h6f; //显示数字9 
    end 
    always @(posedge clk or negedge rst) begin 
        if(!rst) begin 
            counter <= 8'h00; 
        end 
        else begin 
            if(key_pulse) begin 
                if(counter < 100)begin 
                    counter <= counter + 1; 
                end 
                else begin 
                    counter <= 8'h00; 
                end 
            end 
        end 
    end 
    assign seg_led_1 = seg[counter / 10];   //显示十位 
    assign seg_led_2 = seg[counter % 10];   //显示个位 
    debounce u1(.clk (clk), //实例化按键去抖模块 
                .rst (rst), 
                .key (key), 
                .key_pulse (key_pulse)); 
endmodule 
module debounce (clk,rst,key,key_pulse); 
parameter       N  =  1;         //要消除的按键的数量 
    input             clk; 
    input             rst; 
    input   [N-1:0]   key;           //输入的按键                     
    output  [N-1:0]   key_pulse;    //按键动作产生的脉冲  
    reg     [N-1:0]   key_rst_pre;  //存储上一个触发时的按键值 
    reg     [N-1:0]   key_rst;       //储存储当前时刻触发的按键值 
    wire    [N-1:0]   key_edge;      //按键由高到低变化时产生一个高脉冲 
//利用非阻塞赋值特点，将两个时钟触发的按键状态存储在两个寄存器变量中 
    always @(posedge clk  or  negedge rst) begin 
        if (!rst) begin 
            key_rst <= {N{1'b1}};   //初始化时给key_rst赋值全为1 
            key_rst_pre <= {N{1'b1}}; 
        end 
        else begin 
//第一个时钟上升沿将key的值赋给key_rst,同时key_rst的值赋给key_rst_pre 
//非阻塞赋值，相当于经过两个时钟触发，key_rst存储当前时刻key的值，
//key_rst_pre存储前一个时钟的key的值 
key_rst <= key;        
            key_rst_pre <= key_rst;     
         end     
     end 
     //脉冲边沿检测。当key检测到下降沿时，key_edge产生一个时钟周期的高电平 
     assign  key_edge = key_rst_pre & (~key_rst); 
  
     reg [17:0] cnt;     //产生延时所用的计数器，系统时钟12MHz      
  
     //产生20ms延时，当检测到key_edge有效是计数器清零开始计数 
     always @(posedge clk or negedge rst)  begin 
         if(!rst) 
             cnt <= 18'h0; 
         else if(key_edge) 
             cnt <= 18'h0; 
         else 
              cnt <= cnt + 1'h1; 
      end   
  
      reg [N-1:0]   key_sec_pre;        //延时后检测电平寄存器变量 
      reg [N-1:0]   key_sec;                     
  
      //延时后检测key，如果按键状态变低则按键有效，产生一个时钟周期的高电平。 
      always @(posedge clk  or  negedge rst) begin 
          if (!rst)  
              key_sec <= {N{1'b1}};                 
          else if (cnt==18'h3ffff) 
              key_sec <= key;   
       end 
 
       always @(posedge clk  or  negedge rst)begin 
           if (!rst) 
key_sec_pre <= {N{1'b1}}; 
else                    
key_sec_pre <= key_sec;              
end  
assign  key_pulse = key_sec_pre & (~key_sec);      
endmodule 