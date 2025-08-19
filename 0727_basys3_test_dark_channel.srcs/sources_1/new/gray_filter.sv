`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/06/05 14:08:29
// Design Name: 
// Module Name: gray_filter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module grayscale_filter (
    input  logic [11:0] data_00_i,
    input  logic [11:0] data_01_i,
    input  logic [11:0] data_02_i,
    input  logic [11:0] data_10_i,
    input  logic [11:0] data_11_i,
    input  logic [11:0] data_12_i,
    input  logic [11:0] data_20_i,
    input  logic [11:0] data_21_i,
    input  logic [11:0] data_22_i,
    output logic [11:0] data_00_o,
    output logic [11:0] data_01_o,
    output logic [11:0] data_02_o,
    output logic [11:0] data_10_o,
    output logic [11:0] data_11_o,
    output logic [11:0] data_12_o,
    output logic [11:0] data_20_o,
    output logic [11:0] data_21_o,
    output logic [11:0] data_22_o
);
    grayscale_converter U_GRAY_00 (
        .red_port  (data_00_i[11:8]),
        .green_port(data_00_i[7:4]),
        .blue_port (data_00_i[3:0]),
        .g_port    (data_00_o)
    );
    grayscale_converter U_GRAY_01 (
        .red_port  (data_01_i[11:8]),
        .green_port(data_01_i[7:4]),
        .blue_port (data_01_i[3:0]),
        .g_port    (data_01_o)
    );
    grayscale_converter U_GRAY_02 (
        .red_port  (data_02_i[11:8]),
        .green_port(data_02_i[7:4]),
        .blue_port (data_02_i[3:0]),
        .g_port    (data_02_o)
    );
    grayscale_converter U_GRAY_10 (
        .red_port  (data_10_i[11:8]),
        .green_port(data_10_i[7:4]),
        .blue_port (data_10_i[3:0]),
        .g_port    (data_10_o)
    );
    grayscale_converter U_GRAY_11 (
        .red_port  (data_11_i[11:8]),
        .green_port(data_11_i[7:4]),
        .blue_port (data_11_i[3:0]),
        .g_port    (data_11_o)
    );
    grayscale_converter U_GRAY_12 (
        .red_port  (data_12_i[11:8]),
        .green_port(data_12_i[7:4]),
        .blue_port (data_12_i[3:0]),
        .g_port    (data_12_o)
    );
    grayscale_converter U_GRAY_20 (
        .red_port  (data_20_i[11:8]),
        .green_port(data_20_i[7:4]),
        .blue_port (data_20_i[3:0]),
        .g_port    (data_20_o)
    );
    grayscale_converter U_GRAY_21 (
        .red_port  (data_21_i[11:8]),
        .green_port(data_21_i[7:4]),
        .blue_port (data_21_i[3:0]),
        .g_port    (data_21_o)
    );
    grayscale_converter U_GRAY_22 (
        .red_port  (data_22_i[11:8]),
        .green_port(data_22_i[7:4]),
        .blue_port (data_22_i[3:0]),
        .g_port    (data_22_o)
    );
endmodule

module grayscale_converter (
    input  logic [ 3:0] red_port,
    input  logic [ 3:0] green_port,
    input  logic [ 3:0] blue_port,
    output logic [11:0] g_port
);
    logic [10:0] red;
    logic [11:0] green;
    logic [ 8:0] blue;
    logic [12:0] gray;
    assign red = (red_port * 77);
    assign green = (green_port * 150);
    assign blue = (blue_port * 29);
    assign gray = red + green + blue;

    assign g_port = gray[12:1];
endmodule
