/*
 * @Author: zhao-leo 18055219130@163.com
 * @Date: 2024-10-18 21:28:42
 * @LastEditors: zhao-leo 18055219130@163.com
 * @LastEditTime: 2024-10-18 21:29:50
 * @FilePath: \module\2_1\two_point_one_led_status_flip.v
 */
module two_point_one_led_status_flip(key,rst,led); 
    input key,rst; //按键输入、复位输入
    output reg led; //led 输出
    always @(key or rst)
    if (!rst) //低电平复位
        led = 1; //复位时 led 熄灭
    else if(key == 0) 
        led = ~led; //按键按下时 led 翻转
    else
        led = led;
endmodule
