`timescale 1ns / 1ps
module dark_channel #(
    parameter DATA_DEPTH = 320,
    parameter DATA_WIDTH = 8,
    parameter KERNEL_SIZE = 3
) (
    input logic clk,
    input logic rst,
    //input port
    input logic [23:0] pixel_in_888,
    input logic DE,
    input logic [8:0] x_pixel, 
    input logic [8:0] y_pixel, 
    //output port
    output logic [DATA_WIDTH - 1:0] dark_channel_out,  // dark channel 결과값
    output logic DE_out,  // 결과 데이터 유효 신호
    output logic [8:0] x_pixel_out,
    output logic [8:0] y_pixel_out
);

    logic kernel_valid_in;
    assign kernel_valid_in = DE && (y_pixel >= (KERNEL_SIZE - 1)) && ( x_pixel >= (KERNEL_SIZE - 1));

    logic [DATA_WIDTH - 1 : 0] src_min_img;
    logic                      src_min_DE; // 이 신호는 이제 kernel_valid_in을 전달받게 됨
    logic [               8:0] src_min_x_pixel;
    logic [               8:0] src_min_y_pixel;


    pixel_min U_pixel_min ( //픽셀 내에서 가장 어두운 채널을 뽑음
        .clk        (clk),
        .rst        (rst),
        .r_in       (pixel_in_888[23:16]),          // 8비트 R 채널 입력
        .g_in       (pixel_in_888[15:8] ),          // 8비트 G 채널 입력
        .b_in       (pixel_in_888[7:0]  ),          // 8비트 B 채널 입력
        .DE         (kernel_valid_in),
        .x_pixel    (x_pixel),
        .y_pixel    (y_pixel),
        .min_val_out(src_min_img),
        .DE_out     (src_min_DE),
        .x_pixel_out(src_min_x_pixel),
        .y_pixel_out(src_min_y_pixel)
    );

    block_min #(
        .DATA_DEPTH (DATA_DEPTH),
        .DATA_WIDTH (DATA_WIDTH),
        .KERNEL_SIZE(KERNEL_SIZE)
    ) U_block_min (  // 주변영역(블록) 내에서 최솟값 산출 => 지역적 진짜 어두운 영역 탐지
        .clk        (clk),
        .rst        (rst),
        .pixel_in   (src_min_img),
        .DE         (src_min_DE),
        .x_pixel    (src_min_x_pixel),
        .y_pixel    (src_min_y_pixel),
        .min_val_out(dark_channel_out),
        .DE_out     (DE_out),
        .x_pixel_out(x_pixel_out),
        .y_pixel_out(y_pixel_out)
    );


endmodule
