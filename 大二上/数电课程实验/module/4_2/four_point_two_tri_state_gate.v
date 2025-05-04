/*
 * @Author: zhao-leo 18055219130@163.com
 * @Date: 2024-10-18 21:38:18
 * @LastEditors: zhao-leo 18055219130@163.com
 * @LastEditTime: 2024-10-18 21:39:19
 * @FilePath: \module\4_2\four_point_two_tri_state_gate.v
 */
module four_point_two_tri_state_gate(input wire a, input wire enable, output wire y);
    // 当 enable 为 1 时，y 的值为 a，否则 y 为高阻态（'z'）
    assign y = enable ? a : 1'bz;
endmodule