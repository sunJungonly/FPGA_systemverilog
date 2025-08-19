`timescale 1ns / 1ps

module DarkChannel#(
    parameter DATA_DEPTH = 320,
    parameter DATA_WIDTH = 8
) (
    input logic clk,
    input logic rst,
    //input port
    input logic [23:0] pixel_in_888,
    input logic DE,
    input logic [$clog2(DATA_DEPTH)-1:0] x_pixel,  // 라인 내 현재 픽셀 좌표 
    //output port
    output logic [DATA_WIDTH - 1:0] dark_channel_out,  // dark channel 결과값
    output logic DE_out,  // 결과 데이터 유효 신호
    output logic [$clog2(DATA_DEPTH)-1:0] x_pixel_out
);

    assign r_8bit = {pixel_in_888[23:16]};
    assign g_8bit = {pixel_in_888[15:8]};
    assign b_8bit = {pixel_in_888[7:0]};

    logic [    DATA_WIDTH - 1 : 0] src_min_img;
    logic [    DATA_WIDTH - 1 : 0] src_block_min_img;
    logic                          src_min_DE;
    logic                          src_block_min_DE;
    logic [$clog2(DATA_DEPTH)-1:0] src_min_x_pixel;
    logic [$clog2(DATA_DEPTH)-1:0] src_block_min_x_pixel;

    pixel_min U_pixel_min ( //픽셀 내에서 가장 어두운 채널을 뽑음
        .clk        (clk),
        .rst        (rst),
        .r_in        (r_8bit), // 8비트 R 채널 입력
        .g_in        (g_8bit), // 8비트 G 채널 입력
        .b_in        (b_8bit), // 8비트 B 채널 입력
        .DE         (DE),
        .x_pixel    (x_pixel),
        .min_val_out(src_min_img),
        .DE_out     (src_min_DE),
        .x_pixel_out(src_min_x_pixel)
    );

    block_min #(
        .DATA_DEPTH(DATA_DEPTH),
        .DATA_WIDTH(DATA_WIDTH),
        .KERNEL_SIZE(15)
    ) U_block_min (  // 주변영역(블록) 내에서 최솟값 산출 => 지역적 진짜 어두운 영역 탐지
        .clk        (clk),
        .rst        (rst),
        .pixel_in   (src_min_img),
        .DE         (src_min_DE),
        .x_pixel    (src_min_x_pixel),
        .min_val_out(src_block_min_img),
        .DE_out     (src_block_min_DE),
        .x_pixel_out(src_block_min_x_pixel)
    );

    assign dark_channel_out = src_block_min_img;
    assign DE_out           = src_block_min_DE;
    assign x_pixel_out      = src_block_min_x_pixel;

endmodule
