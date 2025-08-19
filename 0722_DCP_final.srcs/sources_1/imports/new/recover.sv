`timescale 1ns / 1ps

module recover#(
    parameter DATA_DEPTH = 640,
    parameter DATA_WIDTH = 16
) (
    input logic clk,
    input logic rst,

    input logic                          DE,
    input logic [$clog2(DATA_DEPTH)-1:0] x_pixel,
    input logic [      DATA_WIDTH - 1:0] pixel_in,
    input logic [      DATA_WIDTH - 1:0] removal_data,
    
    output logic                          DE_out,
    output logic [$clog2(DATA_DEPTH)-1:0] x_pixel_out
    );


endmodule
