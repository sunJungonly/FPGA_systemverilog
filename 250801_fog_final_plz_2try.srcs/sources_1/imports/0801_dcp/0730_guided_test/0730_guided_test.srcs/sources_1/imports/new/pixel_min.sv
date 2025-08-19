`timescale 1ns / 1ps

module pixel_min #(
    parameter DATA_DEPTH = 640,
    parameter DATA_WIDTH = 8
) (
    //input port
    input logic [DATA_WIDTH - 1:0] r_in,
    input logic [DATA_WIDTH - 1:0] g_in,
    input logic [DATA_WIDTH - 1:0] b_in,
    //output port
    output logic [DATA_WIDTH - 1:0] min_val_out
);

    logic [DATA_WIDTH-1 : 0] pixel_min_of_rgb_1st;
    logic [DATA_WIDTH-1 : 0] pixel_min_of_rgb_2st;
    
    assign pixel_min_of_rgb_1st = r_in > g_in ? g_in : r_in;
    assign  pixel_min_of_rgb_2st    =   b_in > pixel_min_of_rgb_1st ? pixel_min_of_rgb_1st : b_in;

    assign min_val_out = pixel_min_of_rgb_2st;

endmodule
