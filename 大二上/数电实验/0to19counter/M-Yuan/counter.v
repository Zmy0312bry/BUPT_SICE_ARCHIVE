module counter(clk, btn, seg, cat,cat_0);
    input clk;                 // 时钟信号 选为100Hz
    input [1:0] btn;           // 两位按键，高位为btn7，低位为btn1
    output [7:0] seg;          // 八位数码管
    output [1:0] cat;          // 数码管位选信号
    wire clk_1;                // 用来接收分频后的脉冲
	 output reg [5:0] cat_0;

    wire [1:0] btn_state;      // 中间变量，用来存放btn的状态
    wire [7:0] seg_wire;       // 用于连接 segment 模块的输出
    wire [1:0] cat_wire;       // 用于连接 segment 模块的位选输出
	 reg [7:0] bcd_num;         // 设置为bcd编码，表示自增的数字

    // Initial block for simulation only
    initial begin
        bcd_num = 8'b0000_0000;
		  cat_0 <= 6'b1111_11;
    end

    // Prescaler module instance
    prescaler #(
        .DIVIDE_BY(100)
    ) my_prescaler (
        .clk_in(clk),
        .rst(btn_state[1]),
        .clk_out(clk_1)
    );

    // Debounce modules for buttons
    debounce u_debounce_1 (
        .clk(clk),
        .button(btn[0]),
        .btn_state(btn_state[0])
    );

	     debounce2 u_debounce_2 (
        .clk(clk),
        .button(btn[1]),
        .btn_state(btn_state[1])
    );

    // Segment module instance
    segment my_segment (
        .bcd_num(bcd_num),
        .clk(clk),
        .cat(cat_wire),       // 将位选信号输出到 cat_wire
        .signal(seg_wire)     // 将七段显示信号输出到 seg_wire
    );

    // 使用 assign 将 seg_wire 和 cat_wire 赋值给输出端口 seg 和 cat
    assign seg = seg_wire;
    assign cat = cat_wire;



reg [6:0]counter=7'b0000_000;	 
	always@ (posedge clk or posedge btn[1])begin
	if(btn[1])begin
		bcd_num <= 8'b0000_0000;
	end
	else begin
		 if(counter[6:0]==7'b1100_011)begin
			 if(!btn_state[0])begin
				if (bcd_num[7:0] < 8'b0001_1001) begin  // 判断十位是否溢出
					if(bcd_num[3:0]<4'b1001)begin
						bcd_num[3:0] <= bcd_num[3:0]+1;
					end else begin
						bcd_num[3:0] <= 4'b0000;
						bcd_num[7:4] <= bcd_num[7:4]+1;
					end
				 end
				 else begin
					bcd_num[7:0] <= 8'b0000_0000;
				end
			 end
			counter[6:0]<=7'b0000_000;
			end
			else begin
			counter <= counter+1;
			end
		end
		end
		
endmodule
