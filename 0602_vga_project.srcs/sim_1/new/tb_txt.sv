`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/06/09 12:22:41
// Design Name: 
// Module Name: tb_txt
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


module tb_txt();
    logic               clk;
    logic               reset;
    logic        [ 1:0] stage;
    logic        [ 9:0] x_pixel;
    logic        [ 9:0] y_pixel;

    reg        [ 9:0] rx_pixel;
    reg        [ 9:0] ry_pixel;

    logic        [ 9:0] txt_x_pixel; // from game fsm
    logic        [ 9:0] txt_y_pixel; // "
    
    logic        [ 3:0] txt_mode;
    logic signed [19:0] score;
    
    logic         txt_out;
    logic               txt_done;
    logic               tick_1s;
    
    assign x_pixel =rx_pixel;
    assign y_pixel =ry_pixel;

    TXT_VGA dut(
        .*
    );

    always #5 clk = ~clk;

    always_ff @( posedge clk, posedge reset ) begin : blockName
        if (~reset) begin
            if (rx_pixel == 639) begin
                rx_pixel <= 0;
                if (ry_pixel == 479) begin
                    ry_pixel <= 0;
                end
                    ry_pixel <= ry_pixel + 1;
            end
            else begin
               rx_pixel <= rx_pixel + 1; 
            end
        end
        else begin
            rx_pixel <= 0;
            ry_pixel <= 0;
        end
    end

    initial begin
        clk = 0;
        reset = 1; 
        #10;
        reset = 0;
        txt_mode = 0;
        stage = 0;
        score = 50;
        #10;
        stage = 1;
        #10;
        stage = 2;
        #10;
        stage = 3;
    end
endmodule
