`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/06/04 11:21:18
// Design Name: 
// Module Name: tb_VGA
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


module tb_VGA ();

    logic       clk;
    logic       reset;
    logic       btn_L;
    logic       sw_0;
    logic       ov7670_xclk;
    logic       ov7670_pclk;
    logic       ov7670_href;
    logic       ov7670_v_sync;
    logic [7:0] ov7670_data;
    logic       h_sync;
    logic       v_sync;
    logic [3:0] red_port;
    logic [3:0] green_port;
    logic [3:0] blue_port;
    OV7670_VGA_Display U_OV7670_VGA_Display (.*);

    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        reset = 1;
        #10;
        reset = 0;
        btn_L = 1;
        #100000000;
        $stop;
    end
endmodule
