/*
 * @Author: zhao-leo 18055219130@163.com
 * @Date: 2024-10-18 21:25:15
 * @LastEditors: zhao-leo 18055219130@163.com
 * @LastEditTime: 2024-10-18 21:25:30
 * @FilePath: \module\1_5\one_point_five_rgb_led.v
 */
module one_point_five_rgb_led (sw,led);
    input [2:0] sw; //开关输入信号，利用了其中3个开关
    output [2:0] led; //输出信号到RGB LED
    assign led = sw; //assign连续赋值。
endmodule