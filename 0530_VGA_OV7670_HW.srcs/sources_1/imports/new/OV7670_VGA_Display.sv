`timescale 1ns / 1ps

module OV7670_VGA_Display(
    input  logic clk,
    input  logic reset,

    output logic        ov7670_xclk,
    input  logic        ov7670_pclk,
    input  logic        ov7670_href,
    input  logic        ov7670_v_sync,
    input  logic [ 7:0] ov7670_data,
    
    output logic        h_sync,
    output logic        v_sync,
    output logic [ 3:0] red_port,
    output logic [ 3:0] green_port,
    output logic [ 3:0] blue_port
    );

    logic we, DE, w_rclk, oe, rclk;
    logic [15:0] wData, rData;
    logic [16:0] wAddr, rAddr;
    logic [9:0] x_pixel, y_pixel;

    pixel_clk_gen U_OV7670_Clk_Gen(
        .clk(clk),
        .reset(reset),
        .pclk(ov7670_xclk)
    );

    VGA_Controller U_VGA_Controller(
        .clk(clk),
        .reset(reset),
        .rclk(w_rclk),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .DE(DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel)
    );

    QVGA_Controller U_QVGA_Controller(
        .clk(w_rclk),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .DE(DE),
        .rclk(rclk),
        .d_en(oe),
        .rAddr(rAddr),
        .rData(rData),
        .red_port(red_port),
        .green_port(green_port),
        .blue_port(blue_port) 
    );

    OV7670_MemController U_OV7670_MemController(
        .pclk(ov7670_pclk),
        .reset(reset),
        .href(ov7670_href),
        .v_sync(ov7670_v_sync),
        .ov7670_data(ov7670_data),
        .we(we),
        .wAddr(wAddr),
        .wData(wData)
    );

    frame_buffer U_frame_buffer(
        .wclk(ov7670_pclk),
        .we(we),
        .wAddr(wAddr),
        .wData(wData),
        .rclk(rclk),
        .oe(oe),
        .rAddr(rAddr),
        .rData(rData)
    );
endmodule
