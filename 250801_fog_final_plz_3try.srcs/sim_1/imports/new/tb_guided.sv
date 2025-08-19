`timescale 1ns / 1ps

module tb_guided;

    logic clk;
    logic rst;
    logic DE;
    logic h_sync;
    logic v_sync;
    logic pclk;
    logic [9:0] x_pixel;
    logic [9:0] y_pixel;
    logic [23:0] guide_pixel_in;
    logic [8:0] input_pixel_in;
    logic [7:0] q_i, q_out;
    logic [7:0] red_port, green_port, blue_port;
    logic [7:0] final_r, final_g, final_b;

    parameter DATA_WIDTH = 24;
    parameter WINDOW_SIZE = 15;
    parameter IMAGE_WIDTH = 320;
    parameter IMAGE_HEIGHT = 240;

    logic DE_out;

    initial begin
        clk = 0;
        forever #4 clk = ~clk;
    end

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

    fog_removal_top dut (
        .clk(clk),
        .pclk(pclk),
        .rst(rst),
        .red_port(red_port),
        .green_port(green_port),
        .blue_port(blue_port),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .DE(DE),
        .DE_out(DE_out),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .final_r(final_r),
        .final_g(final_g),
        .final_b(final_b)
    );

    initial begin
        clk = 0;
        rst = 1;
        red_port   <= 0;
        green_port <= 0;
        blue_port  <= 0;
        #10 rst = 0;

        forever begin
            @(posedge clk);
            if (DE) begin
                red_port   <= 512 + x_pixel;
                green_port <= 512 + x_pixel + y_pixel;
                blue_port  <= 532 + y_pixel;
            end else begin
                red_port   <= 0;
                green_port <= 0;
                blue_port  <= 0;
            end
        end
    end


endmodule
