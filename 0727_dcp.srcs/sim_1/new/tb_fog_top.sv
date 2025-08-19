`timescale 1ns / 1ps

module tb_fog_top ();

    parameter IMAGE_WIDTH = 640;
    parameter IMAGE_HEIGHT = 480;
    parameter WINDOW_SIZE = 15;
    parameter DATA_WIDTH = 8;
    parameter DC_LATENCY = 64;
    parameter TE_LATENCY = 23;

    logic clk, rst;
    logic pclk;
    logic h_sync, v_sync, DE;
    logic [9:0] x_pixel;
    logic [9:0] y_pixel;
    logic [DATA_WIDTH-1:0] pixel_in;

    logic [DATA_WIDTH + $clog2(WINDOW_SIZE*WINDOW_SIZE)-1:0] sum_out;
    logic [DATA_WIDTH*2 + $clog2(WINDOW_SIZE*WINDOW_SIZE)-1:0] sum_sq_out;
    logic valid_out;

    logic [DATA_WIDTH - 1:0] matrix_p[0:15-1][0:15-1];

    logic [7:0] min_val_out;
    logic DE_out;
    logic [8:0] x_pixel_out;

    logic [7:0] dark_channel_out;
    logic h_sync_out, v_sync_out;

    logic [ 4:0] red_port_in;
    logic [ 5:0] green_port_in;
    logic [ 4:0] blue_port_in;

    // x*1000 + y -> 최대 약 320*1000 + 240 = 320240 (19비트 필요)
    logic [18:0] unique_pixel_value;

    VGA_Controller u_vga (
        .clk    (clk),
        .reset  (rst),
        .rclk   (),         // unused
        .h_sync (h_sync),
        .v_sync (v_sync),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .DE     (DE),
        .pclk   (pclk)
    );

    fog_removal_top#(
        .IMAGE_WIDTH(320),
        .IMAGE_HEIGHT(240),
        .DATA_WIDTH(DATA_WIDTH),
        .DC_LATENCY(DC_LATENCY),
        .TE_LATENCY(TE_LATENCY)  // TransmissionEstimate의 Divider IP Latency
    ) dut (
        .sys_clk(clk),
        .pclk(pclk),
        .rst(rst),
        .red_port(red_port_in),
        .green_port(green_port_in),
        .blue_port(blue_port_in),
        .DE,
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .red_port_out(red_port_out),
        .green_port_out(green_port_out),
        .blue_port_out(blue_port_out),
        .DE_out(DE_out),
        .h_sync_out(h_sync_out),
        .v_sync_out(v_sync_out)
    );

    always #5 clk = ~clk;

    always @(posedge pclk) begin
        if (DE) begin
            // 각 픽셀 좌표에 대한 고유한 값을 생성
            unique_pixel_value = x_pixel * 1000 + y_pixel;

            // 생성된 고유 값을 5-6-5 형식의 RGB로 분배
            red_port_in   <= unique_pixel_value[15:11];
            green_port_in <= unique_pixel_value[10:5];
            blue_port_in  <= unique_pixel_value[4:0];
        end else begin
            red_port_in   <= 5'b0;
            green_port_in <= 6'b0;
            blue_port_in  <= 5'b0;
        end
    end

    initial begin
        clk = 0;
        rst = 1;
        #20;
        rst = 0;

        // 5 프레임 동안 시뮬레이션을 실행하고 종료
        repeat (5) begin
            @(posedge v_sync);
        end
        $display("Simulation finished after 5 frames.");
        $finish;
        // Wait until DE is active and feed pixels
    end
endmodule
