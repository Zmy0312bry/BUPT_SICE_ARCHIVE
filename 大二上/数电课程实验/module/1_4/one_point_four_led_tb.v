/*
 * @Author: zhao-leo 18055219130@163.com
 * @Date: 2024-10-18 21:08:13
 * @LastEditors: zhao-leo 18055219130@163.com
 * @LastEditTime: 2024-10-18 21:22:13
 * @FilePath: \module\1_4\one_point_four_led_tb.v
 */
`timescale 1ns/1ps
module one_point_four_led_tb;
    reg [3:0] key;
    reg [3:0] sw;
    wire [7:0] led;
    one_point_four_led test ( // 实例化模块
        .key(key),
        .sw(sw),
        .led(led)
    );
    initial begin
        $dumpfile("1_4_tb.vcd"); //生成的vcd文件名称
        $dumpvars(0, one_point_four_led_tb); //tb模块名称
    end
    initial begin // 初始化输入信号并进行仿真
    // 初始值
        key = 4'b0000;
        sw = 4'b0000;
        // 每隔 10ns，改变 key 与 sw 的值
        #10 key = 4'b1010; sw = 4'b0101;
        #10 key = 4'b1111; sw = 4'b0000;
        #10 key = 4'b0011; sw = 4'b1100;
        #10 key = 4'b1001; sw = 4'b0110;
        // 结束仿真
        $finish;
    end
    // 监视输出信号
    initial begin
        $monitor("At time %t: key = %b, sw = %b, led = %b", $time, key, sw, led);
    end
endmodule