module VI_III_JK ( 
    input clk, rst_n,
    input j,k,
    output reg q,
    output wire q_n 
); 
    assign q_n = ~q; 
    always @(negedge clk or negedge rst_n) begin   
        if (!rst_n) begin   
            q <= 1'b0; // 异步复位   
        end else begin   
            case({j,k}) 
                2'b00: q <= q;    // 不变 
                2'b01: q <= 1'b0; // 复位 
                2'b10: q <= 1'b1; // 置位 
                2'b11: q <= ~q;   // 翻转 
            endcase 
        end 
    end 
endmodule 