`timescale 1ns / 1ps

module OV7670_VGA_Display (
    input logic clk,
    input logic reset,

    input  logic       btn_U,
    input  logic       btn_D,
    output logic       ov7670_xclk,
    input  logic       ov7670_pclk,
    input  logic       ov7670_href,
    input  logic       ov7670_v_sync,
    input  logic [7:0] ov7670_data,

    output logic       h_sync,
    output logic       v_sync,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port,

    output logic sda,
    output logic scl,

    output logic buzzer_out
);

    logic we, w_rclk, oe, rclk;
    logic [15:0] wData, rData;
    logic [16:0] wAddr, rAddr;
    logic frame_stop;
    logic pclk;
    //// s0
    logic [9:0] x_pixel_s0, y_pixel_s0;
    logic DE_s0;
    logic h_sync_s0, v_sync_s0;
    //// s1
    logic [9:0] x_pixel_s1, y_pixel_s1;
    logic DE_s1;
    logic v_sync_s1, h_sync_s1;
    logic [3:0] r_s1;
    logic [3:0] g_s1;
    logic [3:0] b_s1;
    //// s2
    logic [9:0] x_pixel_s2, y_pixel_s2;
    logic DE_s2;
    logic v_sync_s2, h_sync_s2;
    logic [11:0] data_00_s2;
    logic [11:0] data_01_s2;
    logic [11:0] data_02_s2;
    logic [11:0] data_10_s2;
    logic [11:0] data_11_s2;
    logic [11:0] data_12_s2;
    logic [11:0] data_20_s2;
    logic [11:0] data_21_s2;
    logic [11:0] data_22_s2;
    logic [11:0] rgb_s2;
    logic [11:0] gray_s2;
    //// s3
    logic [9:0] x_pixel_s3, y_pixel_s3;
    logic DE_s3;
    logic v_sync_s3, h_sync_s3;
    logic        [11:0] data_00_s3;
    logic        [11:0] data_01_s3;
    logic        [11:0] data_02_s3;
    logic        [11:0] data_10_s3;
    logic        [11:0] data_11_s3;
    logic        [11:0] data_12_s3;
    logic        [11:0] data_20_s3;
    logic        [11:0] data_21_s3;
    logic        [11:0] data_22_s3;
    logic        [11:0] data_00_s3_g;
    logic        [11:0] data_01_s3_g;
    logic        [11:0] data_02_s3_g;
    logic        [11:0] data_10_s3_g;
    logic        [11:0] data_11_s3_g;
    logic        [11:0] data_12_s3_g;
    logic        [11:0] data_20_s3_g;
    logic        [11:0] data_21_s3_g;
    logic        [11:0] data_22_s3_g;
    logic        [11:0] rgb_s3;

    // SOBEL FILTER SIGNALS
    logic               sobel;
    // CHROMA FILTER SIGNALS
    logic               chroma;
    // TXT_VGA SIGNALS
    logic        [ 1:0] txt_out;
    logic        [ 3:0] txt_mode;
    logic signed [12:0] score;
    logic               txt_done;
    logic               tick_1s;
    logic        [ 9:0] txt_x_pixel;
    logic        [ 9:0] txt_y_pixel;
    logic        [ 2:0] scale;  //1~6
    logic               score_stage;
    // POINT_IN_POLYGON SIGNALS
    logic               p_oe;
    logic        [ 6:0] p_Addr;
    logic        [37:0] p_Data;
    logic               in_polygon;
    logic               in_polygon_valid;
    logic        [ 2:0] pattern_num;
    logic               in_polygon_enable;
    // BUZZER SIGNALS
    logic        [ 1:0] sound_option;
    assign h_sync = h_sync_s3;
    assign v_sync = v_sync_s3;

    SCCB_Master U_SCCB_Master (
        .clk  (clk),
        .reset(reset),
        .sda  (sda),
        .scl  (scl)
    );

    pixel_clk_gen U_OV7670_Clk_Gen (
        .clk  (clk),
        .reset(reset),
        .pclk (ov7670_xclk)
    );

    VGA_Controller U_VGA_Controller (
        .clk    (clk),
        .reset  (reset),
        .rclk   (w_rclk),
        .h_sync (h_sync_s0),
        .v_sync (v_sync_s0),
        .DE     (DE_s0),
        .x_pixel(x_pixel_s0),
        .y_pixel(y_pixel_s0),
        .pclk   (pclk)
    );

    QVGA_Memcontroller U_QVGA_Memcontroller (
        .clk       (w_rclk),
        .x_pixel   (x_pixel_s0),
        .y_pixel   (y_pixel_s0),
        .DE        (DE_s0),
        .rclk      (rclk),
        .d_en      (oe),
        .rAddr     (rAddr),
        .rData     (rData),
        .red_port  (r_s1),
        .green_port(g_s1),
        .blue_port (b_s1)
    );

    frame_buffer U_frame_buffer (
        .wclk      (ov7670_pclk),
        .we        (we),
        .frame_stop(frame_stop),
        .wAddr     (wAddr),
        .wData     (wData),
        .rclk      (rclk),
        .oe        (oe),
        .rAddr     (rAddr),
        .rData     (rData)
    );

    OV7670_MemController U_OV7670_MemController (
        .pclk       (ov7670_pclk),
        .reset      (reset),
        .href       (ov7670_href),
        .v_sync     (ov7670_v_sync),
        .ov7670_data(ov7670_data),
        .we         (we),
        .wAddr      (wAddr),
        .wData      (wData)
    );

    pipeline_register_s0_s1 U_pipeline_register_s0_s1 (.*);

    line_buffer_640 U_line_buffer_s1_s2 (
        .pclk   (pclk),
        .x_pixel(x_pixel_s1),
        .y_pixel(y_pixel_s1),
        .data   ({r_s1, g_s1, b_s1}),
        .data_00(data_00_s2),
        .data_01(data_01_s2),
        .data_02(data_02_s2),
        .data_10(data_10_s2),
        .data_11(data_11_s2),
        .data_12(data_12_s2),
        .data_20(data_20_s2),
        .data_21(data_21_s2),
        .data_22(data_22_s2)
    );

    pipeline_register_s1_s2 U_pipeline_register_s1_s2 (.*);

    median_filter_bead U_median_filter_bead_s2 (
        .data00(data_00_s2),
        .data01(data_01_s2),
        .data02(data_02_s2),
        .data10(data_10_s2),
        .data11(data_11_s2),
        .data12(data_12_s2),
        .data20(data_20_s2),
        .data21(data_21_s2),
        .data22(data_22_s2),
        .sdata (rgb_s2)
    );

    line_buffer_640 U_line_buffer_s2_s3 (
        .pclk   (pclk),
        .x_pixel(x_pixel_s2),
        .y_pixel(y_pixel_s2),
        .data   (rgb_s2),
        .data_00(data_00_s3),
        .data_01(data_01_s3),
        .data_02(data_02_s3),
        .data_10(data_10_s3),
        .data_11(data_11_s3),
        .data_12(data_12_s3),
        .data_20(data_20_s3),
        .data_21(data_21_s3),
        .data_22(data_22_s3)
    );
    /*
    median_filter_bead U_median_filter_bead_s3 (
        .data00(data_00_s3),
        .data01(data_01_s3),
        .data02(data_02_s3),
        .data10(data_10_s3),
        .data11(data_11_s3),
        .data12(data_12_s3),
        .data20(data_20_s3),
        .data21(data_21_s3),
        .data22(data_22_s3),
        .sdata (rgb_s3)
    );
*/
    grayscale_filter U_grayscale_filter (
        .data_00_i(data_00_s3),
        .data_01_i(data_01_s3),
        .data_02_i(data_02_s3),
        .data_10_i(data_10_s3),
        .data_11_i(data_11_s3),
        .data_12_i(data_12_s3),
        .data_20_i(data_20_s3),
        .data_21_i(data_21_s3),
        .data_22_i(data_22_s3),
        .data_00_o(data_00_s3_g),
        .data_01_o(data_01_s3_g),
        .data_02_o(data_02_s3_g),
        .data_10_o(data_10_s3_g),
        .data_11_o(data_11_s3_g),
        .data_12_o(data_12_s3_g),
        .data_20_o(data_20_s3_g),
        .data_21_o(data_21_s3_g),
        .data_22_o(data_22_s3_g)
    );

    pipeline_register_s2_s3 U_pipeline_register_s2_s3 (.*);

    Sobel_Filter U_Sobel_Filter (  // gray input
        .data00(data_00_s3_g),
        .data01(data_01_s3_g),
        .data02(data_02_s3_g),
        .data10(data_10_s3_g),
        .data11(data_11_s3_g),
        .data12(data_12_s3_g),
        .data20(data_20_s3_g),
        .data21(data_21_s3_g),
        .data22(data_22_s3_g),
        .sdata (sobel)
    );

    chromakey U_chromakey (
        // Line_buffer signals
        .rgbData (data_11_s3),  // rgb_s3
        .DE      (DE_s3),
        // export signals
        .bg_pixel(chroma)
    );

    TXT_VGA U_TXT_VGA (
        .clk(clk),
        .reset(reset),
        .x_pixel(x_pixel_s3),
        .y_pixel(y_pixel_s3),
        .txt_x_pixel(txt_x_pixel),  // 중앙
        .txt_y_pixel(txt_y_pixel),  // 중앙
        .scale(scale),  //1~6
        .txt_mode(txt_mode),  // 원래있던거
        .txt_stage(pattern_num[1:0]),  // pettern_num
        .score_stage(score_stage),
        .score(score),
        .txt_out(txt_out),
        .txt_done(txt_done),
        .tick_1s(tick_1s)
    );

    //////////// 도형 내외부 판단, 내부:1, 외부:0
    point_in_polygon U_point_in_polygon (
        // global signals
        .clk              (clk),
        .pclk             (pclk),
        .reset            (reset),
        // pixcel positions
        .x_pixel          (x_pixel_s0),
        .y_pixel          (y_pixel_s0),
        // patter_rom
        .p_oe             (p_oe),
        .p_Addr           (p_Addr),
        .p_Data           (p_Data),
        // game_state_fsm side signals
        .pattern_num      (pattern_num),
        .in_polygon_enable(in_polygon_enable),
        .in_polygon       (in_polygon),
        .in_polygon_valid (in_polygon_valid)
    );

    pattern_rom U_pattern_rom (
        .clk   (clk),
        .p_oe  (p_oe),
        .p_Addr(p_Addr),
        .p_Data(p_Data)
    );


    // game state fsm
    game_state_fsm U_game_state_fsm (
        .clk         (clk),
        .pclk        (pclk),
        .reset       (reset),
        .btnU        (btn_U),
        .btnD        (btn_D),
        .DE          (DE_s3),
        .x_pixel     (x_pixel_s3),
        .y_pixel     (y_pixel_s3),
        .h_sync      (h_sync_s3),
        .v_sync      (v_sync_s3),
        .chroma      (chroma),
        .sobel       (sobel),
        .in_polygon  (in_polygon),
        .valid       (in_polygon_valid),
        .txt_out     (txt_out),
        .txt_done    (txt_done),
        .tick_1s     (tick_1s),
        .median_red  (data_11_s3[11:8]),
        .median_grn  (data_11_s3[7:4]),
        .median_blu  (data_11_s3[3:0]),
        .txt_mode    (txt_mode),
        .score       (score),
        .enable      (in_polygon_enable),
        .pattern_num (pattern_num),
        .red_port    (red_port),
        .green_port  (green_port),
        .blue_port   (blue_port),
        .frame_stop  (frame_stop),
        .sound_option(sound_option),
        .txt_x_pixel (txt_x_pixel),
        .txt_y_pixel (txt_y_pixel),
        .scale       (scale),              //1~6
        .score_stage (score_stage)
    );

    buzzer_controller U_buzzer_controller (
        .clk(clk),
        .reset(reset),
        .play_pass(sound_option[0]),
        .play_fail(sound_option[1]),
        .buzzer_out(buzzer_out)
    );
endmodule
