module buzzer_music(
    input wire clk,       // 输入时钟信号 (1 MHz)
    input wire rst,       // 复位信号
    input wire [3:0] note, // 音符选择，4位控制8个音符
    output reg buzzer     // 蜂鸣器输出信号
);

    // 音符对应的频率分频器值 (1 MHz 时钟)
    reg [15:0] divisor;  // 用于存储分频器值
    reg [15:0] counter;  // 计数器

    // 定义音符到频率分频器的映射 (1 MHz 时钟频率)
    always @(*) begin
        case(note)
            4'b0001: divisor = 2272;  // A4 = 440 Hz
            4'b0010: divisor = 2024;  // B4 = 493.88 Hz
            4'b0011: divisor = 1911;  // C5 = 523.25 Hz
            4'b0100: divisor = 1703;  // D5 = 587.33 Hz
            4'b0101: divisor = 1517;  // E5 = 659.26 Hz
            4'b0110: divisor = 1432;  // F5 = 698.46 Hz
            4'b0111: divisor = 1276;  // G5 = 783.99 Hz
            4'b1000: divisor = 3822;  // C4 = 261.63 Hz
            default: divisor = 2272;  // 默认使用 A4 = 440 Hz
        endcase
    end
	 
	 reg [31:0] cnt;
	 always@(posedge clk)begin
		case(cnt)
			32'h0000_0000:begin
			cnt <= cnt+1;
			end
		endcase
		end

    // 控制蜂鸣器的时序
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
            buzzer <= 0;
        end else begin
            // 计数器递增，达到分频器值后反转蜂鸣器输出
            if (counter == divisor - 1) begin
                counter <= 0;
                buzzer <= ~buzzer; // 翻转蜂鸣器信号产生音符
            end else begin
                counter <= counter + 1;
            end
        end
    end

endmodule
