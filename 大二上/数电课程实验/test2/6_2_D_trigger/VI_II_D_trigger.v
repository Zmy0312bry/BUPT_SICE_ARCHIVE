module VI_II_D_trigger ( 
    input clk, rst_n, 
    input d, 
    output reg q 
); 
    always@(posedge clk) begin  //同步复位 
        if(!rst_n) q <= 0; 
        else        
            q <= d; 
    end 
endmodule 
