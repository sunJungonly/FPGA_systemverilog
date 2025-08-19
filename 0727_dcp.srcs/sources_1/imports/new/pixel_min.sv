`timescale 1ns / 1ps

module pixel_min #(
    parameter DATA_DEPTH = 640,
    parameter DATA_WIDTH = 8
) (
    input logic clk,
    input logic rst,
    //input port
    input logic [DATA_WIDTH - 1:0] r_in,
    input logic [DATA_WIDTH - 1:0] g_in,
    input logic [DATA_WIDTH - 1:0] b_in,
    input logic DE,
    input logic h_sync,
    input logic v_sync,
    input logic [$clog2(
DATA_DEPTH
)-1:0] x_pixel,  // 라인 내 현재 픽셀 좌표 
    input logic [9:0] y_pixel,
    //output port
    output logic [DATA_WIDTH - 1:0] min_val_out,
    output logic DE_out,  // 결과 데이터 유효 신호
    output logic h_sync_out,
    output logic v_sync_out,
    output logic [$clog2(DATA_DEPTH)-1:0] x_pixel_out,
    output logic [$clog2(DATA_DEPTH)-1:0] y_pixel_out
);

    logic [DATA_WIDTH-1 : 0] pixel_min_of_rgb_1st;
    logic [DATA_WIDTH-1 : 0] pixel_min_of_rgb_2st;
    logic [DATA_WIDTH-1 : 0] pixel_min_of_rgb;

    assign pixel_min_of_rgb_1st = r_in > g_in ? g_in : r_in;
    assign  pixel_min_of_rgb_2st    =   b_in > pixel_min_of_rgb_1st ? pixel_min_of_rgb_1st : b_in;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pixel_min_of_rgb <= 0;
        end else begin  //if (DE)
            pixel_min_of_rgb <= pixel_min_of_rgb_2st;
        end
    end

    assign DE_out = DE;
    assign h_sync_out = h_sync;
    assign v_sync_out = v_sync;
    assign x_pixel_out = x_pixel;
    assign y_pixel_out = y_pixel;
    assign min_val_out = pixel_min_of_rgb;

endmodule
