module dot_matrix (
    input wire clk,           // 时钟信号
    input wire rst,           // 复位信号
	 input stop,
    input wire [3:0] dice1,    // 输入骰子数字（1-9）
	 input wire [3:0] dice2,       //第二个骰子
    output reg [7:0] row,     // 行信号（ROW7 - ROW0）
    output reg [7:0] r_col,    // 红色列信号（R_COL7 - R_COL0）
	 output reg [7:0] g_col     // 绿色列信号
);


    reg [7:0] row_patterns;  // 行信号
    reg [2:0] red_patterns[2:0];  // 红色列信号
	 reg [2:0] green_patterns[2:0];  //绿色信号 
    reg [2:0] scan_index;         // 当前扫描行索引（0~7）
	 reg [1:0] sel;   //这是来选择列信号的，每一个时钟周期变化一次

	initial //参数初始化
	begin
		r_col <= 8'b0000_0000;
		g_col <= 8'b0000_0000;
	end
	 
	 
always@(*)begin   //给红色信号的低三位赋值
	 case(dice1)
	 4'b0001:begin  //1
		red_patterns[0] = 3'b000;
		red_patterns[1] = 3'b010;
		red_patterns[2] = 3'b000;
		end
	 4'b0010:begin  //2
		red_patterns[0] = 3'b001;
		red_patterns[1] = 3'b000;
		red_patterns[2] = 3'b100;
		end
	 4'b0011:begin  //3
		red_patterns[0] = 3'b100;
		red_patterns[1] = 3'b010;
		red_patterns[2] = 3'b001;
		end
	 4'b0100:begin  //4
		red_patterns[0] = 3'b101;
		red_patterns[1] = 3'b000;
		red_patterns[2] = 3'b101;
		end
	 4'b0101:begin  //5
		red_patterns[0] = 3'b101;
		red_patterns[1] = 3'b010;
		red_patterns[2] = 3'b101;
		end
	 4'b0110:begin  //6
		red_patterns[0] = 3'b111;
		red_patterns[1] = 3'b000;
		red_patterns[2] = 3'b111;
	   end
	 4'b0111:begin   //7
		red_patterns[0] = 3'b111;
		red_patterns[1] = 3'b010;
		red_patterns[2] = 3'b111;
		end
	 4'b1000:begin    //8
		red_patterns[0] = 3'b111;
		red_patterns[1] = 3'b101;
		red_patterns[2] = 3'b111;
		end
	 4'b1001:begin    //9
		red_patterns[0] = 3'b111;
		red_patterns[1] = 3'b111;
		red_patterns[2] = 3'b111;
		end
		default:begin  //默认都不亮
		red_patterns[0] = 3'b000;
		red_patterns[1] = 3'b000;
		red_patterns[2] = 3'b000;
		end
	 endcase
	 
	 case(dice2)   //给绿色信号的高三位赋值
	 4'b0001:begin  //1
		green_patterns[0] = 3'b000;
		green_patterns[1] = 3'b010;
		green_patterns[2] = 3'b000;
		end
	 4'b0010:begin  //2
		green_patterns[0] = 3'b001;
		green_patterns[1] = 3'b000;
		green_patterns[2] = 3'b100;
		end
	 4'b0011:begin  //3
		green_patterns[0] = 3'b100;
		green_patterns[1] = 3'b010;
		green_patterns[2] = 3'b001;
		end
	 4'b0100:begin  //4
		green_patterns[0] = 3'b101;
		green_patterns[1] = 3'b000;
		green_patterns[2] = 3'b101;
		end
	 4'b0101:begin  //5
		green_patterns[0] = 3'b101;
		green_patterns[1] = 3'b010;
		green_patterns[2] = 3'b101;
		end
	 4'b0110:begin  //6
		green_patterns[0] = 3'b111;
		green_patterns[1] = 3'b000;
		green_patterns[2] = 3'b111;
	   end
	 4'b0111:begin   //7
		green_patterns[0] = 3'b111;
		green_patterns[1] = 3'b010;
		green_patterns[2] = 3'b111;
		end
	 4'b1000:begin    //8
		green_patterns[0] = 3'b111;
		green_patterns[1] = 3'b101;
		green_patterns[2] = 3'b111;
		end
	 4'b1001:begin    //9
		green_patterns[0] = 3'b111;
		green_patterns[1] = 3'b111;
		green_patterns[2] = 3'b111;
		end
	 default:begin
		green_patterns[0] = 3'b000;
		green_patterns[1] = 3'b000;
		green_patterns[2] = 3'b000;
		end
	 endcase
end

reg [2:0]flag;//计八个数
reg assist;
initial begin
	flag<=0;
end

    // 显示点阵逻辑
    always @(posedge clk or negedge rst ) begin
		  if (!rst) begin
            row <= 8'b1111_1111;  // 所有行禁用
            r_col <= 8'b0000_0000; // 红色列全灭
				g_col <= 8'b0000_0000;
        end else begin
				if(flag==3'b000)begin
					row <= 8'b01111111; // 使用移位来进行赋值
					r_col[2:0] <= red_patterns[0];//将红色低三位赋值给列
					g_col <= 8'b0000_0000;
					flag <=flag +1 ;
				end
				if(flag==3'b001) begin
					row <= 8'b10111111;
					r_col[2:0] <= red_patterns[1];//将绿色高三位赋值给列信号
					flag <= flag+1;
					end
				if(flag==3'b010)begin
					row <= 8'b1101_1111;
					r_col[2:0] <= red_patterns[2];
					flag <= flag +1;
					end
				if(flag == 3'b011)begin
					row <= 8'b1110_1111;
					flag <= flag +1;
					r_col <= 8'b0000_0000;
				end
				if(flag == 3'b100)begin
					row <= 8'b1111_0111;
					flag <= flag+1;
				end
				if(flag ==3'b101)begin
					row <= 8'b1111_1011;
					g_col[7:5] <= green_patterns[0];
					flag <= flag+1;
				end
				if(flag == 3'b110)begin
					row <= 8'b1111_1101;
					g_col[7:5] <= green_patterns[1];
					flag <= flag+1;
				end
				if(flag == 3'b111)begin
					row <= 8'b1111_1110;
					g_col[7:5] <= green_patterns[2];
					flag <= 3'b000;
				end
			end
    end

endmodule
