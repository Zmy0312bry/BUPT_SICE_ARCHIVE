module counter(dout,clk_div);
 input wire clk_div;
 output [3:0] dout; // 用 reg 保存输出信号状态
 wire q0, q1, q2, q3, J1, J2, J3, K1, K2, K3;  // JK 触发器的输出为 wire
 

 assign J1 = (~q3) & q0;
 assign J2 = q1 & q0;
 assign J3 = q2 & q1 & q0;
 assign K1 = q0;
 assign K2 = q1 & q0;
 assign K3 = q0;
 
 // JK 触发器实例化
 JK_trigger jk0_inst(.J(1), .K(1), .clk(clk_div), .Q(q0), .Qn());
 JK_trigger jk1_inst(.J(J1), .K(K1), .clk(clk_div), .Q(q1), .Qn());
 JK_trigger jk2_inst(.J(J2), .K(K2), .clk(clk_div), .Q(q2), .Qn());
 JK_trigger jk3_inst(.J(J3), .K(K3), .clk(clk_div), .Q(q3), .Qn());


 assign dout = {q3,q2,q1,q0}; // 十进制计数

endmodule

module JK_trigger(J, K, clk, Q, Qn);
 input J,K,clk; // 输入端口
 output reg Q; // 输出端口
 output Qn;
 
     // 仿真时的初始值设置
    initial begin
        Q = 1'b0; // 初始时 Q 设置为 0
    end
assign Qn = ~Q;
 always@(posedge clk)
 case({J,K})
 2'b00: Q <= Q; // 不变
 2'b01: Q <= 1'b0; // 复位m
 2'b10: Q <= 1'b1; // 置位
 2'b11: Q <= ~Q; // 翻转
 endcase
endmodule