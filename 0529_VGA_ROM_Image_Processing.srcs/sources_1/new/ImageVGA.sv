`timescale 1ns / 1ps

module ImageVGA (
    input  logic       clk,
    input  logic       reset,
    output logic       h_sync,
    output logic       v_sync,
    input  logic       sw,
    input  logic [3:0] sw_red,
    input  logic [3:0] sw_green,
    input  logic [3:0] sw_blue,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port
);
    logic       DE;
    logic [9:0] x_pixel;
    logic [9:0] y_pixel;
    
    logic [3:0] red_data;
    logic [3:0] green_data;
    logic [3:0] blue_data;
    
    logic [11:0] rgb;
    assign rgb = (red_data*77 + green_data*150 + blue_data*29) ;

    assign red_port = sw ? rgb[11:8] : red_data;
    assign green_port= sw ? rgb[11:8] : green_data;
    assign blue_port= sw ? rgb[11:8] : blue_data;

    VGA_Controller U_VGAController (.*);
    ImageRom U_ImageRom (.*);
endmodule
