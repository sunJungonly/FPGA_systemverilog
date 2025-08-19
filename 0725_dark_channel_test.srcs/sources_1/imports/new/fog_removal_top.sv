`timescale 1ns / 1ps

module fog_removal_top #(
    parameter IMAGE_WIDTH = 320,
    parameter IMAGE_HEIGHT = 240,
    parameter DATA_WIDTH = 8,
    parameter DC_LATENCY = 10,  // LineBuffer(1) + Matrix(7) + BlockMin(2) = 10 
    parameter TE_LATENCY = 20  // TransmissionEstimate의 Divider IP Latency
) (
    input  logic                    clk,
    input  logic                    rst,
    //input port
    input  logic [            23:0] pixel_in_888,
    input  logic                    DE,
    input  logic [             8:0] x_pixel,
    input  logic [             8:0] y_pixel,
    //output port
    output logic [DATA_WIDTH*3-1:0] removal_data,
    output logic                    DE_out,
    output logic [            8:0] x_pixel_out
);

    // --- 내부 신호 선언 ---
    logic [DATA_WIDTH-1:0] dc_out, airlight_r, airlight_g, airlight_b, t_out;
    logic de_dc, de_te;
    logic [$clog2(IMAGE_WIDTH)-1:0] x_dc, x_te;
    logic airlight_done;
    logic [15:0] q_out;

    // 제어 및 동기화 로직을 위한 출력 신호
    logic [DATA_WIDTH-1:0] airlight_r_reg, airlight_g_reg, airlight_b_reg;
    logic [23:0] pixel_for_airlight, pixel_for_recover;
    logic [81:0] y_pixel_for_airlight;

    // 1. 제어 및 동기화 모듈
    control_and_sync #(
        .IMAGE_WIDTH (IMAGE_WIDTH),
        .IMAGE_HEIGHT(IMAGE_HEIGHT),
        .DATA_WIDTH  (DATA_WIDTH),
        .DC_LATENCY  (DC_LATENCY),
        .TE_LATENCY  (TE_LATENCY)
    ) U_Control_Sync (
        .clk(clk),
        .rst(rst),

        // 원본 입력
        .DE_in(DE),
        .pixel_in_888(pixel_in_888),
        .y_pixel_in(y_pixel),

        // Airlight 피드백 입력
        .airlight_done_in(airlight_done),
        .airlight_r_in(airlight_r),
        .airlight_g_in(airlight_g),
        .airlight_b_in(airlight_b),

        // 다른 모듈로 전달될 출력
        .airlight_r_out(airlight_r_reg),  // 프레임 내내 고정될 Airlight
        .airlight_g_out(airlight_g_reg),
        .airlight_b_out(airlight_b_reg),

        .pixel_for_airlight(pixel_for_airlight),     // Airlight 계산을 위한 지연된 픽셀
        .pixel_for_recover(pixel_for_recover),       // 최종 복원을 위한 지연된 픽셀
        .y_pixel_for_airlight(y_pixel_for_airlight)  // Airlight 계산을 위한 지연된 y좌표
    );

    dark_channel #(
        .DATA_DEPTH(IMAGE_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) U_DarkChannel (
        .clk(clk),
        .rst(rst),

        //input port
        .pixel_in_888(pixel_in_888),
        .DE(DE),
        .x_pixel(x_pixel),

        //output port
        .dark_channel_out(dc_out),  // dark channel 결과값
        .DE_out(de_dc),  // 결과 데이터 유효 신호
        .x_pixel_out(x_dc)
    );

    airlight_A #(
        .IMAGE_WIDTH (IMAGE_WIDTH),
        .IMAGE_HEIGHT(IMAGE_HEIGHT),
        .DATA_WIDTH  (DATA_WIDTH)
    ) U_Airlight (
        .clk(clk),
        .rst(rst),

        //input port
        .DE(de_dc),
        .x_pixel(x_dc),
        .y_pixel(y_pixel_for_airlight),  // 지연된 y_pixel
        .pixel_in_888(pixel_for_airlight),  // 지연된 원본 픽셀
        .dark_channel_in(dc_out),

        //output port
        .airlight_r_out(airlight_r),
        .airlight_g_out(airlight_g),
        .airlight_b_out(airlight_b),
        .airlight_done (airlight_done)
    );

    TransmissionEstimate #(
        .DATA_DEPTH(IMAGE_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) U_Transmission_Estimate (
        .clk(clk),
        .rst(rst),

        //input port
        .DE(de_dc),
        .x_pixel(x_dc),
        .dark_channel_in(dc_out),  // 8비트 dark channel
        .airlight_r_in(airlight_r_reg),  // 프레임 내내 고정된 Airlight R
        .airlight_g_in(airlight_g_reg),
        .airlight_b_in(airlight_b_reg),

        //output port
        .t_out(t_out),
        .DE_out(de_te),
        .x_pixel_out(x_te)
    );

    guided_filter_top #(
        .DATA_WIDTH  (24),
        .WINDOW_SIZE (15),
        .SUM_I_WIDTH (20),
        .SUM_II_WIDTH(32)
    ) guided_inst (
        .clk(clk),
        .rst(rst),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .DE(DE),
        .guide_pixel_in(pixel_in_888),
        .input_pixel_in(t_out),
        .q_i(q_out)
    );

    fog_removal_cal #(
        .DATA_DEPTH(IMAGE_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .DIVIDER_LATENCY(37)
    ) U_Recover (
        .clk(clk),
        .rst(rst),

        //input port
        .DE(de_te),
        .x_pixel(x_te),
        .pixel_in_888(pixel_for_recover),
        .airlight_r(airlight_r_reg),
        .airlight_g(airlight_g_reg),
        .airlight_b(airlight_b_reg),
        .tx_data(q_out),  // guided filter에서 나온 값

        //output port
        .removal_data(removal_data),
        .DE_out(DE_out),
        .x_pixel_out(x_pixel_out)
    );

endmodule
