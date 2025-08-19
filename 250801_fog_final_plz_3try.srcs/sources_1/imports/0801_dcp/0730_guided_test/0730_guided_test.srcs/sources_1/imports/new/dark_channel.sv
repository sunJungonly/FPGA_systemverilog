`timescale 1ns / 1ps

module dark_channel #(
    parameter DATA_DEPTH = 640,
    parameter DATA_WIDTH = 8
)(
    input logic clk,
    input logic pclk,
    input logic rst,
    //input port
    input logic [23:0] pixel_in_888,
    input logic DE,
    input logic [9:0] x_pixel,  // 라인 내 현재 픽셀 좌표 
    input logic [9:0] y_pixel,
    input logic h_sync,
    input logic v_sync,
    //output port
    output logic [7:0] dark_channel_out  // dark channel 결과값
);


    logic [DATA_WIDTH-1:0] r_8bit;
    logic [DATA_WIDTH-1:0] g_8bit;
    logic [DATA_WIDTH-1:0] b_8bit;

    logic [DATA_WIDTH - 1 : 0] src_min_img;
    logic [DATA_WIDTH - 1 : 0] src_block_min_img;

    assign r_8bit = {pixel_in_888[23:16]};
    assign g_8bit = {pixel_in_888[15:8]};
    assign b_8bit = {pixel_in_888[7:0]};

    pixel_min #(
        .DATA_DEPTH(DATA_DEPTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) U_pixel_min (
        .r_in       (r_8bit),           // 8비트 R 채널 입력
        .g_in       (g_8bit),           // 8비트 G 채널 입력
        .b_in       (b_8bit),           // 8비트 B 채널 입력
        .min_val_out(src_min_img)
    );

    block_min #(
        .DATA_DEPTH (DATA_DEPTH),
        .DATA_WIDTH (DATA_WIDTH),
        .KERNEL_SIZE(15)
    ) U_block_min (  // 주변영역(블록) 내에서 최솟값 산출 => 지역적 진짜 어두운 영역 탐지
        .clk        (clk),
        .rst        (rst),
        .pclk       (pclk),
        .pixel_in   (src_min_img),
        .DE         (DE),
        .h_sync     (h_sync),
        .v_sync     (v_sync),
        .x_pixel    (x_pixel),
        .y_pixel    (y_pixel),
        .min_val_out(src_block_min_img)
    );

    always_ff @(posedge pclk or posedge rst) begin
        if (rst) begin
            dark_channel_out <= 0;
        end else begin
            dark_channel_out <= src_block_min_img;
        end
    end


    // assign dark_channel_out = src_block_min_img;

endmodule
