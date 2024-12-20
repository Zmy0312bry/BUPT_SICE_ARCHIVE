`timescale 1ns / 1ps

module tb_is_roll;

// Declare testbench signals
reg clk;
reg rst;
reg start1;
reg start2;
reg finish;
wire [3:0] dice1;
wire [3:0] dice2;
wire roll1;  // Add the roll1 wire for monitoring
wire roll2;  // Add the roll2 wire for monitoring
wire [19:0]count1,count2;

// Instantiate the is_roll module
is_roll uut (
    .clk(clk),
    .rst(rst),
    .dice1(dice1),
    .dice2(dice2),
    .start1(start1),
    .start2(start2),
    .finish(finish)
);


assign roll1 = uut.roll1;
assign roll2 = uut.roll2;
assign count1 = uut.count1;
assign count2 = uut.count2;

// Clock generation
always begin
    #0.5 clk = ~clk; // 1kHz clock with a period of 1ms (500ns high, 500ns low)
end

// Stimulus generation
initial begin
    // Initialize signals
    clk = 0;
    rst = 1;
    start1 = 0;
    start2 = 0;
    finish = 0;
    

    // Start the first dice roll
    start1 = 1;
    #1000;  // Wait for 1ms
    start1 = 0;
    
    // Start the second dice roll after a short delay
    #2000;  // Wait for 2ms before starting second dice roll
    start2 = 1;
    #1000;
    start2 = 0;
    
    // Finish signal can be tested here
    #5000;  // Wait for 5ms for both rolls to complete
    finish = 1;
    #1000;
    finish = 0;

    // Final states for verification
    #5000;  // Wait a bit before finishing the simulation
    $finish;
end

// Monitor outputs
initial begin
    $monitor("Time: %0t | dice1: %0d | dice2: %0d", $time, dice1, dice2);
end

endmodule
