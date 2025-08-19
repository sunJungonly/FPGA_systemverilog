`timescale 1ns / 1ps

module OV7670_VGA_Display (
    input logic clk,
    input logic reset,

    input  logic [4:0] sw,
    output logic       ov7670_xclk,
    input  logic       ov7670_pclk,
    input  logic       ov7670_href,
    input  logic       ov7670_v_sync,
    input  logic [7:0] ov7670_data,

    output logic       h_sync,
    output logic       v_sync,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port
);
    logic [3:0] r_data, g_data, b_data;


    logic we, DE, w_rclk, oe, rclk;
    logic [15:0] wData, rData;
    logic [16:0] wAddr, rAddr;
    logic [9:0] x_pixel, y_pixel;

    logic chrmoakey;

    pixel_clk_gen U_OV7670_Clk_Gen (
        .clk  (clk),
        .reset(reset),
        .pclk (ov7670_xclk)
    );

    VGA_Controller U_VGA_Controller (
        .clk(clk),
        .reset(reset),
        .rclk(w_rclk),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .DE(DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel)
    );

    chromakey U_Chromakey (
        // Framebuffer signals
        .rgbData(rData),
        // VGAController signals
        .x_pixel(),
        .y_pixel(),
        .DE(DE),
        // export signals
        .bg_pixel(bg_pixel)
    );

    frame_buffer U_frame_buffer (
        .wclk(ov7670_pclk),
        .we(we),
        .wAddr(wAddr),
        .wData(wData),
        .rclk(rclk),
        .oe(oe),
        .rAddr(rAddr),
        .rData(rData)
    );

    QVGA_Memcontroller U_QVGA_Memcontroller (
        //
        .sw_0(sw[0]),
        //
        .clk(w_rclk),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .DE(DE),
        .rclk(rclk),
        .d_en(oe),
        .rAddr(rAddr),
        .rData(rData),
        .red_port(r_data),
        .green_port(g_data),
        .blue_port(b_data)
    );

    OV7670_MemController U_OV7670_MemController (
        .pclk(ov7670_pclk),
        .reset(reset),
        .href(ov7670_href),
        .v_sync(ov7670_v_sync),
        .ov7670_data(ov7670_data),
        .we(we),
        .wAddr(wAddr),
        .wData(wData)
    );


    image_filter U_image_filter (
        // .sw_1(sw[1]),  //g
        .sw_1(bg_pixel),  //chrmoakey
        .sw_2(sw[2]),  //r
        .sw_3(sw[3]),  //g
        .sw_4(sw[4]),  //b
        .r_data(r_data),
        .g_data(g_data),
        .b_data(b_data),
        .r_port(red_port),
        .g_port(green_port),
        .b_port(blue_port)
    );

endmodule
