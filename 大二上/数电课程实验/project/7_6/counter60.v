module counter60 ( 
    input wire clk, rst, 
    input wire key, // 启动暂停按键 
    output wire [8:0] segment_led_1, segment_led_2 // 数码管输出 
); 
 
    wire clk1h; 
    reg [7:0] cnt; 
    reg flag; 
 
    // 实例化分频器产生1秒时钟信号 
    divide #( 
        .WIDTH(24), 
        .N(12_000_000) 
    ) u1 ( 
        .clk(clk), 
        .rst_n(rst), 
        .clkout(clk1h) 
    ); 
 
    // 产生标志信号 
    always @(posedge clk)  
        if (!rst) 
            flag = 1'b0; 
        else if (!key) 
            flag = ~flag; 
        else 
            flag = flag; 
 
    // 产生60进制计数器 
    always @(posedge clk1h) begin 
        // 数码管显示要按照十进制的方式显示 
        if (!rst) 
            cnt <= 8'h00; // 复位初值显示00 
        else if (flag) begin 
            // 启动暂停标志 
            if (cnt[3:0] == 4'd9) begin 
                // 个位满九？ 
                cnt[3:0] <= 4'd0; // 个位清零 
                if (cnt[7:4] == 4'd5)  
                    // 十位满五？ 
                    cnt[7:4] <= 4'd0; // 十位清零 
                else 
                    cnt[7:4] <= cnt[7:4] + 1'b1; // 十位加一 
            end else 
                cnt[3:0] <= cnt[3:0] + 1'b1; // 个位加一 
        end else 
            cnt <= cnt; 
    end 
 
    // 实例化数码管显示模块 
    segment u2 ( 
        .seg_data_1(cnt[7:4]), // seg_data input 
        .seg_data_2(cnt[3:0]), // seg_data input 
        .segment_led_1(segment_led_1), // MSB~LSB = 
//SEG,DP,G,F,E,D,C,B,A
			.segment_led_2(segment_led_2)  // MSB~LSB = 
//SEG,DP,G,F,E,D,C,B,A 
); 
endmodule

module segment 
( 
input wire [3:0] seg_data_1, //四位输入数据信号 
input wire [3:0] seg_data_2, //四位输入数据信号 
output wire [8:0] segment_led_1, //数码管 1，MSB~LSB = 
//SEG,DP,G,F,E,D,C,B,A 
output wire [8:0] segment_led_2 //数码管 2，MSB~LSB = 
//SEG,DP,G,F,E,D,C,B,A 
); 
reg [8:0] seg [15:0]; //存储7段数码管译码数据 
initial begin 
seg[0]  = 9'h3f; // 0 
seg[1]  = 9'h06; // 1 
seg[2]  = 9'h5b; // 2 
seg[3]  = 9'h4f; // 3 
seg[4]  = 9'h66; // 4 
seg[5]  = 9'h6d; // 5 
seg[6]  = 9'h7d; // 6 
seg[7]  = 9'h07; // 7 
seg[8]  = 9'h7f; // 8 
seg[9]  = 9'h6f; // 9 
seg[10] = 9'h77; // A 
seg[11] = 9'h7C; // b 
seg[12] = 9'h39; // C 
seg[13] = 9'h5e; // d 
seg[14] = 9'h79; // E 
seg[15] = 9'h71; // F 
end 
assign segment_led_1 = seg[seg_data_1];  
assign segment_led_2 = seg[seg_data_2];  
endmodule 
module divide # 
( 
    // parameter是verilog里参数定义 
    parameter WIDTH = 24,            
    parameter N = 12_000_000        // 分频系数 
) 
( 
    input clk,                     // clk连接到FPGA的C1脚，频率为12MHz 
    input rst_n,                   // 复位信号，低有效 
    output clkout                  // 输出信号，可以连接到LED观察分频的时钟 
); 
    reg [WIDTH-1:0] cnt_p, cnt_n;   
    reg clk_p, clk_n;               
 
    // 上升沿触发时计数器的控制 
    always @(posedge clk or negedge rst_n) begin 
        if (!rst_n) 
            cnt_p <= 1'b0; 
        else if (cnt_p == (N-1)) 
            cnt_p <= 1'b0; 
        else  
            cnt_p <= cnt_p + 1'b1;   
    // 计数器一直计数，当计数到N-1的时候清零，这是一个模N的计数器 
    end 
 
    always @(posedge clk or negedge rst_n) begin 
        if (!rst_n) 
            clk_p <= 1'b0; 
        else if (cnt_p < (N >> 1))      
 // N >> 1表示右移一位，相当于除以2取商 
            clk_p <= 1'b0; 
        else  
            clk_p <= 1'b1;            
// 得到的分频时钟正周期比负周期多一个clk时钟 
    end 
 
    // 下降沿触发时计数器的控制 
    always @(negedge clk or negedge rst_n) begin 
        if (!rst_n) 
            cnt_n <= 1'b0; 
        else if (cnt_n == (N-1)) 
            cnt_n <= 1'b0; 
        else  
            cnt_n <= cnt_n + 1'b1; 
    end 
	 // 下降沿触发的分频时钟输出，和clk_p相差半个clk时钟 
always @(negedge clk or negedge rst_n) begin 
if (!rst_n) 
clk_n <= 1'b0; 
else if (cnt_n < (N >> 1))   
clk_n <= 1'b0; 
else  
clk_n <= 1'b1;            
// 得到的分频时钟正周期比负周期多一个clk时钟 
end 
wire clk1 = clk; // 当N=1时，直接输出clk 
wire clk2 = clk_p;   
// 当N为偶数也就是N的最低位为0，N[0]=0，输出clk_p 
wire clk3 = clk_p & clk_n;     
// 当N为奇数也就是N最低位为1，N[0]=1，输出clk_p & clk_n。正周期多所
//以是相与 
assign clkout = (N == 1) ? clk1 : (N[0] ? clk3 : clk2); // 条件判
//断表达式 
endmodule 

