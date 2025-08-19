`timescale 1ns / 1ps

module tb_AB_Calculator;

    // Parameters
    localparam WINDOW_SIZE      = 15;
    localparam DATA_WIDTH       = 24;
    localparam SUM_I_WIDTH      = 20;
    localparam SUM_II_WIDTH     = 32;
    localparam SUM_P_WIDTH      = 16;
    localparam SUM_IP_WIDTH     = 28;
    localparam N                = WINDOW_SIZE * WINDOW_SIZE;

    // Inputs
    logic                         clk;
    logic                         rst;
    logic [9:0]                   x_pixel;
    logic                         valid_in;
    logic [SUM_I_WIDTH-1:0]       sum_i;
    logic [SUM_II_WIDTH-1:0]      sum_ii;
    logic [SUM_P_WIDTH-1:0]       sum_p;
    logic [SUM_IP_WIDTH-1:0]      sum_ip;

    // Outputs
    logic signed [19:0]           a_k_out;
    logic signed [DATA_WIDTH+5:0] b_k_out;
    logic                         valid_out;

    // Instantiate the Unit Under Test (UUT)
    AB_Calculator #(
        .WINDOW_SIZE(WINDOW_SIZE),
        .DATA_WIDTH(DATA_WIDTH),
        .SUM_I_WIDTH(SUM_I_WIDTH),
        .SUM_II_WIDTH(SUM_II_WIDTH),
        .SUM_P_WIDTH(SUM_P_WIDTH),
        .SUM_IP_WIDTH(SUM_IP_WIDTH)
    ) uut (
        .clk(clk),
        .rst(rst),
        .x_pixel(x_pixel),
        .valid_in(valid_in),
        .sum_i(sum_i),
        .sum_ii(sum_ii),
        .sum_p(sum_p),
        .sum_ip(sum_ip),
        .a_k_out(a_k_out),
        .b_k_out(b_k_out),
        .valid_out(valid_out)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz

    // Stimulus
    initial begin
        rst = 1;
        valid_in = 0;
        x_pixel = 0;
        sum_i = 0;
        sum_ii = 0;
        sum_p = 0;
        sum_ip = 0;

        #20;
        rst = 0;
        valid_in <= 1;

        // Test vector 1 (handpicked values with known result)
        // Example values (these should result in non-zero a_k, b_k)
        // You may compute manually:
        // sum_i = 100
        // sum_ii = 15000
        // sum_p = 80
        // sum_ip = 12000

        @(posedge clk);
        
        x_pixel <= 10'd10;
        sum_i   = 300;
        sum_p   = 1000;
        sum_ip  = 20000;
        sum_ii  = 2500;

        @(posedge clk);
        //valid_in <= 0; // hold inputs only for one cycle
        x_pixel <= 10'd11;
        sum_i = 100;
        sum_ii = 15000;
        sum_p = 80;
        sum_ip = 12000;

        @(posedge clk);
        x_pixel <= 10'd12;
        sum_i = 100;
        sum_p = 10000;
        sum_ip = 50000;
        sum_ii = 25000;
        // Wait for output
        @(posedge clk)
        x_pixel <= 10'd13;
        wait (valid_out);

        $display("a_k_out = %d", a_k_out);
        $display("b_k_out = %d", b_k_out);

        // Add more test cases if desired...

        #100;
        $finish;
    end

endmodule
