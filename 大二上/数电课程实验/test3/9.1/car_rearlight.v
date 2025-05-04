module car_rearlight( 
input wire clk, 
input wire rst_n, 
// 输入状态 
input wire[3:0] state_in, 
// 左转指示灯 
output reg[2:0] led_left, 
// 右转指示灯 
output reg[2:0] led_right, 
// 流水显示 
output reg[7:0] led_flow 
); 
// 车辆行驶状态 
// STOP 停止 
// GO 行驶 
// LEFT 左转 
// RIGHT 右转 
// BACK 倒车 
localparam STOP = 4'b1111; 
localparam GO = 4'b1110; 
localparam LEFT = 4'b1101; 
localparam RIGHT = 4'b1011; 
localparam BACK = 4'b0111; 
// 车辆处于以上各状态时，LED的亮灭 
localparam stop = 8'b0000_0000; 
localparam left = 8'b1111_0000; 
localparam right = 8'b0000_1111; 
localparam on = 3'b101; 
 localparam off = 3'b111; 
     
    // 用于控制转向时的闪烁 
    wire[2:0] blink; 
     
    // 车辆前进 
    reg[7:0] go = 8'b0111_1111; 
    reg[7:0] back = 8'b1111_1110; 
     
    // 现态与次态 
    reg[3:0] current_state; 
    reg[3:0] next_state; 
     
    //  
    parameter dp_1Hz = 5000_0000; 
    parameter dp_8Hz =  625_0000; 
    wire clkout_1Hz; 
     
    // 分频产生频率为1Hz的时钟（divide模块代码已在之前章节给出） 
    divide #( 
        .WIDTH(30), 
        .N(dp_1Hz) 
    ) divide_1Hz( 
        .clk(clk), 
        .rst_n(rst_n), 
        .clkout(clkout_1Hz) 
    );   
     
    // 通过计数，产生频率为8Hz的时钟，用于驱动LED流水显示 
    reg[27:0] cnt_8Hz = 28'b0; 
    always@(posedge clk) begin 
        cnt_8Hz <= cnt_8Hz + 1; 
        if(cnt_8Hz == dp_8Hz + 1) 
            begin 
                cnt_8Hz <= 0; 
            end 
    end 
         
         
    // 每秒闪烁1次 
    assign blink = {1'b1, clkout_1Hz, 1'b1}; 
     
    // GO状态时，LED向前流水显示 
    always@(posedge clk) begin 
        if (!rst_n) begin 
            go <= 8'b0111_1111; 
        end 
        else begin 
            if (cnt_8Hz == dp_8Hz) begin 
                go <= {go[0], go[7:1]}; 
            end  
            else begin 
                go <= go; 
            end 
        end 
    end 
     
    // BACK状态时，LED向后流水显示 
 always@(posedge clk) begin 
        if (!rst_n) begin 
            back <= 8'b0111_1111; 
        end 
        else begin 
            if (cnt_8Hz == dp_8Hz) begin 
                back <= {back[6:0], back[7]}; 
            end  
            else begin 
                back <= back; 
            end 
        end 
    end 
     
    // 接收输入的状态，作为次态 
    always@(*) begin 
        next_state <= state_in; 
    end 
     
    // 状态转换 
    always@(posedge clk or negedge rst_n) begin 
        if (!rst_n) begin 
            // 若复位信号有效，状态变为STOP 
            current_state <= STOP; 
        end 
        else begin 
            // 正常情况下，现态被次态覆盖 
            current_state <= next_state; 
        end 
    end 
     
    // 输出 
    always@(current_state) begin 
        if (!rst_n) begin 
            // 复位 
            led_left <= blink; 
            led_right <= blink; 
            led_flow <= stop; 
        end 
        else begin 
            // LED在各状态下的输出 
            case(current_state) 
                STOP: begin 
                    led_left <= blink; 
                    led_right <= blink; 
                    led_flow <= stop; 
                end 
                GO: begin 
                    led_left <= on; 
                    led_right <= on; 
                    led_flow <= go; 
                end 
                LEFT: begin 
                    led_left <= blink; 
                    led_right <= off; 
                    led_flow <= left; 
                end 
                RIGHT: begin
					 led_left <= off; 
			   	 led_right <= blink; 
					 led_flow <= right;  
					 end 
					 BACK: begin 
					 led_left <= off; 
					 led_right <= off; 
					 led_flow <= back; 
					 end 
					 default: begin 
					 led_left <= blink; 
					 led_right <= blink; 
					 led_flow <= stop; 
					 end 
            endcase 
        end 
    end 
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
// 当N为奇数也就是N最低位为1，N[0]=1，输出clk_p & clk_n。正周期多所以是相与 
assign clkout = (N == 1) ? clk1 : (N[0] ? clk3 : clk2); // 条件判断表达式 
endmodule