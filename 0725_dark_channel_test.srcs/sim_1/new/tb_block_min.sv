`timescale 1ns / 1ps

module tb_block_min ();

    parameter DATA_WIDTH = 24;
    parameter WINDOW_SIZE = 15;
    parameter IMAGE_WIDTH = 320;
    parameter IMAGE_HEIGHT = 240;

    logic clk, rst;
    logic pclk;
    logic h_sync, v_sync, DE;
    logic [8:0] x_pixel;
    logic [8:0] y_pixel;
    logic [DATA_WIDTH-1:0] pixel_in;

    logic [DATA_WIDTH + $clog2(WINDOW_SIZE*WINDOW_SIZE)-1:0] sum_out;
    logic [DATA_WIDTH*2 + $clog2(WINDOW_SIZE*WINDOW_SIZE)-1:0] sum_sq_out;
    logic valid_out;

    logic [7:0] min_val_out;
    logic DE_out;
    logic [$clog2(320)-1:0] x_pixel_out;

    // Clock generation: 125 MHz → period = 8ns → toggle every 4ns
    
    initial begin
        clk = 0;
        forever #4 clk = ~clk; // 100MHz
    end

    // VGA Controller instantiation
    vga u_vga (
        .clk(clk),
        .reset(rst),
        .rclk(),        // unused
        .h_sync(h_sync),
        .v_sync(v_sync),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .DE(DE),
        .pclk(pclk)
    );

    block_min #(
        .DATA_DEPTH(320),
        .DATA_WIDTH(24),
        .KERNEL_SIZE(15)
    ) dee(
        .clk(clk),
        .rst(rst),
        .DE(DE),
        .x_pixel(x_pixel),
        .pixel_in(pixel_in),
        .min_val_out(min_val_out),
        .DE_out(DE_out),
        .x_pixel_out(x_pixel_out)
    );

    // Simulation image memory

    initial begin
        clk = 0;
        rst = 1;
        pixel_in = 1;
        @(posedge clk);
        @(posedge clk);
        rst = 0;

        // Wait until DE is active and feed pixels
        forever begin
            @(posedge clk);
            if (DE)
                pixel_in <= x_pixel * 1000 + y_pixel * 1000;
            else
                pixel_in <= 0;
        end
    end
endmodule