`timescale 1ns / 1ps

module fog_removal_top (
    (* dont_touch = "true" *) input  logic       clk,
    (* dont_touch = "true" *) input  logic       pclk,
    (* dont_touch = "true" *) input  logic       rst,
    //input port
    (* dont_touch = "true" *) input  logic [7:0] red_port,
    (* dont_touch = "true" *) input  logic [7:0] green_port,
    (* dont_touch = "true" *) input  logic [7:0] blue_port,
    (* dont_touch = "true" *) input  logic       DE,
    (* dont_touch = "true" *) input  logic [9:0] x_pixel,
    (* dont_touch = "true" *) input  logic [9:0] y_pixel,
    (* dont_touch = "true" *) input  logic       h_sync,
    (* dont_touch = "true" *) input  logic       v_sync,
    //output port
    (* dont_touch = "true" *) output logic [                     7:0] red_port_out,
    (* dont_touch = "true" *) output logic [                     7:0] green_port_out,
    (* dont_touch = "true" *) output logic [                     7:0] blue_port_out,
    (* dont_touch = "true" *) output logic       debug_DE_out,
    (* dont_touch = "true" *) output  logic [9:0] x_pixel_out,
    (* dont_touch = "true" *) output  logic [9:0] y_pixel_out,
    (* dont_touch = "true" *) output logic       h_sync_out,
    (* dont_touch = "true" *) output logic       v_sync_out,
    (* dont_touch = "true" *) output logic       DE_out,
    (* dont_touch = "true" *) output logic [7:0] final_r,
    (* dont_touch = "true" *) output logic [7:0] final_g,
    (* dont_touch = "true" *) output logic [7:0] final_b
    // output logic [ $clog2(IMAGE_WIDTH)-1:0] x_pixel_out
);


    parameter IMAGE_WIDTH = 640;
    parameter IMAGE_HEIGHT = 480;
    parameter DATA_WIDTH = 8;
    parameter DC_LATENCY = 10;  //10;
    parameter TE_LATENCY = 58;  //20;
    parameter GU_LATENCY = 54;
    parameter RE_LATENCY = 34;

    logic [23:0] pixel_in_888;
    assign pixel_in_888 = {red_port, green_port, blue_port};

    // --- 내부 신호 선언 ---
    logic [DATA_WIDTH-1:0] dc_out, t_out,  g_out;
    logic [7:0] airlight_r,airlight_g, airlight_b;
    logic [7:0] airlight_r_out, airlight_g_out, airlight_b_out;
    logic de_dc, de_te, de_q, airlight_de, guided_de, recover_de;
    logic h_sync_air, v_sync_air;
    logic [$clog2(IMAGE_WIDTH)-1:0] x_dc, y_dc, x_A, y_A, x_te, y_te;
    logic airlight_done;
    //   logic [15:0] q_out;
    logic [9:0] guided_x_pixel;
    logic [9:0] guided_y_pixel;


    // 제어 및 동기화 로직을 위한 출력 신호
    logic [DATA_WIDTH-1:0] airlight_r_reg, airlight_g_reg, airlight_b_reg;
    logic [23:0] pixel_for_airlight, pixel_for_recover, pixel_for_guided;
    logic [$clog2(IMAGE_HEIGHT)-1:0] y_pixel_for_airlight;

    // 1. 제어 및 동기화 모듈    
    control_and_sync #(
        .IMAGE_WIDTH (IMAGE_WIDTH),
        .IMAGE_HEIGHT(IMAGE_HEIGHT),
        .DATA_WIDTH  (DATA_WIDTH),
        .DC_LATENCY  (DC_LATENCY),
        .TE_LATENCY  (TE_LATENCY),
        .GU_LATENCY  (GU_LATENCY)
    ) sync_inst (
        .rst(rst),
        .pclk(pclk),
        .x_pixel_in(x_pixel),
        .y_pixel_in(y_pixel),
        .h_sync_in(h_sync),
        .v_sync_in(v_sync),
        // 원본 입력
        .DE_in(DE),
        .pixel_in_888(pixel_in_888),
        .airlight_r_in(airlight_r),
        .airlight_g_in(airlight_g),
        .airlight_b_in(airlight_b),
        // airlight
        .pixel_for_airlight(pixel_for_airlight),  // Airlight 계산을 위한 지연된 픽셀
        .airlight_de(airlight_de),
        // guided
        .pixel_for_guided  (pixel_for_guided),     // Airlight 계산을 위한 지연된 픽셀
        .guided_de(guided_de),
        // removal
        .pixel_for_recover(pixel_for_recover),
        .recover_de(recover_de),
        .airlight_r_out(airlight_r_out),
        .airlight_g_out(airlight_g_out),
        .airlight_b_out(airlight_b_out),
        .guided_x_pixel_out(guided_x_pixel),
        .guided_y_pixel_out(guided_y_pixel),
        .x_pixel_out(x_pixel_out),
        .y_pixel_out(y_pixel_out),
        .h_sync_air(h_sync_air),
        .v_sync_air(v_sync_air),
        .h_sync_out(h_sync_out),
        .v_sync_out(v_sync_out)
    );

    dark_channel #(
        .DATA_DEPTH  (IMAGE_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
        ) U_DarkChannel (
        .clk             (clk),
        .pclk            (pclk),
        .rst             (rst),
        .pixel_in_888    (pixel_in_888),
        .DE              (DE),
        .h_sync          (h_sync),
        .v_sync          (v_sync),
        .x_pixel         (x_pixel),
        .y_pixel         (y_pixel),

        .dark_channel_out(dc_out)
    );

    airlight_A #(
        .DATA_DEPTH  (IMAGE_WIDTH),
        .IMAGE_HEIGHT(IMAGE_HEIGHT),
        .DATA_WIDTH  (DATA_WIDTH)
    ) U_Airlight (
        .pclk(pclk),
        .rst(rst),
        //input port
        .DE(airlight_de),
        .v_sync(v_sync_air),
        .pixel_in_888(pixel_for_airlight),  // 지연된 원본 픽셀
        .dark_channel_in(dc_out),
        //output port
        .airlight_r_out(airlight_r),
        .airlight_g_out(airlight_g),
        .airlight_b_out(airlight_b)
    );

    TransmissionEstimate #(
        .DATA_DEPTH(IMAGE_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .DELAY(TE_LATENCY)
    ) U_Transmission_Estimate (
        .clk (clk),
        .rst (rst),
        .pclk(pclk),

        //input port
        .DE(airlight_de),
        .x_pixel(),
        .y_pixel(),
        .dark_channel_in(dc_out),  // airlight 만큼 딜레이 고려
        .airlight_r_in(airlight_r),  // airlight에서 받아오면 됨 
        .airlight_g_in(airlight_g),  // airlight에서 받아오면 됨
        .airlight_b_in(airlight_b),  // airlight에서 받아오면 됨

        //output port
        .dark_channel_in_tready(), // this signal isn't used
        .t_out(t_out),
        .DE_out(de_te),
        .x_pixel_out(x_te),
        .y_pixel_out(y_te)
    );

      guided_filter_top guided_inst (
        //   .DATA_WIDTH (24),
        //   .WINDOW_SIZE(15)
          .clk(clk),
          .rst(rst),
          .x_pixel(guided_x_pixel),
          .y_pixel(guided_y_pixel),
          .DE(guided_de),
          .guide_pixel_in(pixel_for_guided),
          .input_pixel_in(t_out),
          .DE_out(),
          .q_i(g_out)
      );


    fog_removal_cal #(
        .DATA_DEPTH(IMAGE_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .DELAY(RE_LATENCY)
    ) U_Recover (
        .clk(clk),
        .rst(rst),
        .pclk(pclk),
        //input port
        .DE(recover_de),                
        .x_pixel(),
        .pixel_in_888(pixel_for_recover),
        .airlight_r(airlight_r_out),
        .airlight_g(airlight_g_out),
        .airlight_b(airlight_b_out),
        .tx_data(g_out),  // guided filter에서 나온 값 guided 추가하고 g_out으로 변경하기
        //output port
        .final_r(final_r),
        .final_g(final_g),
        .final_b(final_b),
        .DE_out(DE_out)
        // .x_pixel_out(x_pixel_out)
    );


    // debugging
    assign red_port_out = dc_out[7:0];
    assign green_port_out = dc_out[7:0];
    assign blue_port_out = dc_out[7:0];
    assign debug_DE_out = airlight_de;

endmodule
