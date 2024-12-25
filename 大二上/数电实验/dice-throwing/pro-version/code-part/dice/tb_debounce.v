module tb_debounce_double;

  // 定义信号
  reg clk;              // 时钟信号
  reg stop;             // 停止信号
  reg btn_in;           // 按键信号
  wire btn_out;         // 去抖动后的按键信号

  wire btn_sync_0,btn_sync_1;
  wire [16:0]counter;
  // 实例化debounce_double模块
  debounce_double uut (
    .clk(clk),
    .stop(stop),
    .btn_in(btn_in),
    .btn_out(btn_out)
  );

  // 时钟产生
  always begin
    #5 clk = ~clk; // 每5个时间单位反转一次时钟信号100
  end

  assign counter = uut.counter;
  assign btn_sync_0 = uut.btn_sync_0;
  assign btn_sync_1 = uut.btn_sync_1;
  // 初始块，进行仿真信号的初始化和测试流程
  initial begin
    // 初始化信号
    clk = 0;
    stop = 0;
    btn_in = 0;

    // 测试1: 不按键，输出应该保持不变
    #10;
    #1000;

    // 测试2: 按下按钮，检查去抖动输出是否稳定
    btn_in = 1;
    #400;
	 btn_in = 0;
    #1000;


    // 测试4: 按钮抖动，检查去抖动模块是否能消除抖动
    btn_in = 1;
    #100;
    btn_in = 0;
    #10;
    btn_in = 1;
    #10;
	 btn_in=0;
	 #30;
	 btn_in=1;
	 #150;
	 btn_in=0;
	 #10;
	 btn_in=1;
	 #500;
	 btn_in=0;
    #1000;

    // 测试5: 停止信号，btn_out 应该被强制置为 0
    btn_in = 1;
	 #400;
	 stop = 1;
    #10;
    $display("Test 5: stop signal active, btn_out should be 0");
    #1000;

    // 测试结束
    $display("Testbench finished.");
    $finish;
  end

endmodule
