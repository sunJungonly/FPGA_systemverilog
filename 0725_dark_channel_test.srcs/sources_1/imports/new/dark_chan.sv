`timescale 1ns / 1ps
module dark_chan #(
    parameter PIC_WIDTH = 640
) (
    input  logic         clk,
    input  logic         rst_n,
    //pre input port
    input  logic         pre_frame_vsync,
    input  logic         pre_frame_href,
    input  logic         pre_frame_clken,
    input  logic [ 23:0] pre_img,
    //post output port
    output logic         post_frame_vsync,
    output logic         post_frame_href,
    output logic         post_frame_clken,
    output logic [7 : 0] post_img
);


    logic         src_min_frame_vsync;
    logic         src_min_frame_href;
    logic         src_min_frame_clken;
    logic [7 : 0] src_min_img;

    logic         src_block_min_frame_vsync;
    logic         src_block_min_frame_href;
    logic         src_block_min_frame_clken;
    logic [7 : 0] src_block_min_img;


    pixel_min U_pixel_min (  //픽셀 내에서 가장 어두운 채널을 뽑음
        .clk             (clk),
        .rst_n           (rst_n),
        //pre input port
        .pre_frame_vsync (pre_frame_vsync),
        .pre_frame_href  (pre_frame_href),
        .pre_frame_clken (pre_frame_clken),
        .pre_img         (pre_img),
        //post output port
        .post_frame_vsync(src_min_frame_vsync),
        .post_frame_href (src_min_frame_href),
        .post_frame_clken(src_min_frame_clken),
        .post_img        (src_min_img)
    );

    block_min #(
        .PIC_WIDTH(PIC_WIDTH)
    ) U_block_min (  // 주변영력(블록) 내에서 최솟값 산출 => 지역적 진짜 어두운 영역 탐지
        .clk             (clk),
        .rst_n           (rst_n),
        //pre input port
        .pre_frame_vsync (src_min_frame_vsync),
        .pre_frame_href  (src_min_frame_href),
        .pre_frame_clken (src_min_frame_clken),
        .pre_img         (src_min_img),
        //post output port
        .post_frame_vsync(src_block_min_frame_vsync),
        .post_frame_href (src_block_min_frame_href),
        .post_frame_clken(src_block_min_frame_clken),
        .post_img        (src_block_min_img)
    );



    assign post_frame_vsync = src_block_min_frame_vsync;
    assign post_frame_href  = src_block_min_frame_href;
    assign post_frame_clken = src_block_min_frame_clken;
    assign post_img         = src_block_min_img;



endmodule
