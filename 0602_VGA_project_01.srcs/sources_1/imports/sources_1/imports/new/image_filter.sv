`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/29 15:15:57
// Design Name: 
// Module Name: image_filter
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


module image_filter (
    input  logic       sw_1,    //g
    input  logic       sw_2,    //r
    input  logic       sw_3,    //g
    input  logic       sw_4,    //b
    input  logic [3:0] r_data,
    input  logic [3:0] g_data,
    input  logic [3:0] b_data,
    output logic [3:0] r_port,
    output logic [3:0] g_port,
    output logic [3:0] b_port
);
    logic [ 3:0] gray;
    logic [11:0] gray_total;
    logic [3:0] r_port1, g_port1, b_port1;
    logic [3:0] r_port2, g_port2, b_port2;
    assign gray_total = (r_data * 77 + g_data * 150 + b_data * 29);
    assign gray = gray_total[11:8];

    assign r_port = sw_1 ? r_port1 : r_port2;
    assign g_port = sw_1 ? g_port1 : g_port2;
    assign b_port = sw_1 ? b_port1 : b_port2;

    assign r_port1 = gray;
    assign g_port1 = gray;
    assign b_port1 = gray;

    assign r_port2 = sw_2 ? r_data : 0;
    assign g_port2 = sw_3 ? g_data : 0;
    assign b_port2 = sw_4 ? b_data : 0;
endmodule
