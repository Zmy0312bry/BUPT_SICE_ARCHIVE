/*
 * @Author: zhao-leo 18055219130@163.com
 * @Date: 2024-10-18 21:04:44
 * @LastEditors: zhao-leo 18055219130@163.com
 * @LastEditTime: 2024-10-18 21:09:42
 * @FilePath: \module\1_4\one_point_four_led.v
 */
module one_point_four_led(
    input [3:0] key, // key：4 位，按键输入
    input [3:0] sw, // sw：4 位，开关输入
    output [7:0] led // led：8 位，LED 输出
);
    assign led = {key, sw}; // 大括号为拼接符，key 输出至 led 的高 4 位
endmodule
