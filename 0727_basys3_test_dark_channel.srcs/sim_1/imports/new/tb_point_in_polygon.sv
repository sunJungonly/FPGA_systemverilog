`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/06/02 18:26:40
// Design Name: 
// Module Name: tb_point_in_polygon
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


module tb_point_in_polygon ();

    logic        p_oe;
    logic        clk;
    logic        pclk;
    logic        rclk;
    logic        DE;
    logic        h_sync;
    logic        v_sync;
    logic        reset;
    logic [ 9:0] x_pixel;
    logic [ 9:0] y_pixel;
    logic [ 6:0] p_Addr;
    logic [37:0] p_Data;
    logic        in_polygon;
    logic        in_polygon_valid;

    logic [ 2:0] pattern_num;
    logic        in_polygon_enable;

    point_in_polygon _DUT (.*);
    pattern_rom _DUT2 (.*);
    VGA_Controller _DUT3 (.*);

    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        reset = 1;
        #10;
        reset = 0;
        pattern_num = 0;
        in_polygon_enable = 1;
        #10;
        in_polygon_enable = 0;
        #1000000;
        pattern_num = 2;
        in_polygon_enable = 1;
        #10;
        in_polygon_enable = 0;
        #1000000;
        $stop;
    end
endmodule
