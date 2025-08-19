`timescale 1ns / 1ps

module vga_rgb_switch (
    input  logic [3:0] sw_red,
    input  logic [3:0] sw_green,
    input  logic [3:0] sw_blue,
    input  logic       DE,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port
);

    assign red_port   = DE ? sw_red : 4'b0;
    assign blue_port  = DE ? sw_blue : 4'b0;
    assign green_port = DE ? sw_green : 4'b0;
endmodule
