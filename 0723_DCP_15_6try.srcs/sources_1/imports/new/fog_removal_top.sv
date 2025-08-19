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
    // (* dont_touch = "true" *) output logic [                     8:0] red_port_out,
    // (* dont_touch = "true" *) output logic [                     8:0] green_port_out,
    // (* dont_touch = "true" *) output logic [                     8:0] blue_port_out
    (* dont_touch = "true" *) output logic       de_g,
    (* dont_touch = "true" *) output logic [7:0] q_out
    // output logic [ $clog2(IMAGE_WIDTH)-1:0] x_pixel_out
);

  parameter IMAGE_WIDTH = 640;
  parameter IMAGE_HEIGHT = 480;
  parameter DATA_WIDTH = 8;
  parameter DC_LATENCY = 10;
  parameter TE_LATENCY = 20;

  logic [23:0] pixel_in_888;

  // --- 내부 신호 선언 ---
  logic [DATA_WIDTH-1:0] dc_out, airlight_r, airlight_g, airlight_b, t_out;
  logic de_dc, de_te, de_q;
  logic [$clog2(IMAGE_WIDTH)-1:0] x_dc, y_dc, x_A, y_A, x_te, y_te;
  logic airlight_done;
  //   logic [15:0] q_out;

  // 제어 및 동기화 로직을 위한 출력 신호
  logic [DATA_WIDTH-1:0] airlight_r_reg, airlight_g_reg, airlight_b_reg;
  logic [23:0] pixel_for_airlight, pixel_for_recover;
  logic [$clog2(IMAGE_HEIGHT)-1:0] y_pixel_for_airlight;

  //fifo 내부 신호
  logic [23:0] removal1_data;
  logic empty, full, vaild, vaild1, DE_out;

  logic [7:0] airlight_r_out;
  logic [7:0] airlight_g_out;
  logic [7:0] airlight_b_out;
  logic [23:0] pixel_for_guided;

  assign pixel_in_888   = {red_port, green_port, blue_port};

  assign red_port_out   = removal1_data[15:11];
  assign green_port_out = removal1_data[10:5];
  assign blue_port_out  = removal1_data[4:0];


  // 1. 제어 및 동기화 모듈    
  control_and_sync #(
      .IMAGE_WIDTH (IMAGE_WIDTH),
      .IMAGE_HEIGHT(IMAGE_HEIGHT),
      .DATA_WIDTH  (DATA_WIDTH),
      .DC_LATENCY  (64),
      .TE_LATENCY  (23)
  ) sync_inst (
      .clk(clk),
      .rst(rst),

      // 원본 입력
      .DE_in(DE),
      .pixel_in_888(pixel_in_888),

      .dark_channel_in(dc_out),

      // Airlight 피드백 입력
      .airlight_done_in(airlight_done),
      .airlight_r_in(airlight_r_out),
      .airlight_g_in(airlight_g_out),
      .airlight_b_in(airlight_b_out),

      .te_de_out(de_te),

      // 다른 모듈로 전달될 출력
      .airlight_r_out(airlight_r_out_cs),  // 프레임 내내 고정될 Airlight
      .airlight_g_out(airlight_g_out_cs),
      .airlight_b_out(airlight_b_out_cs),

      .pixel_for_airlight(pixel_for_airlight),  // Airlight 계산을 위한 지연된 픽셀
      .pixel_for_guided  (pixel_for_guided)     // Airlight 계산을 위한 지연된 픽셀
  );

  dark_channel U_DarkChannel (
      .clk             (clk),
      .rst             (rst),
      .pixel_in_888    (pixel_in_888),
      .DE              (DE),
      .h_sync          (h_sync),
      .v_sync          (v_sync),
      .x_pixel         (x_pixel),
      .y_pixel         (y_pixel),
      .dark_channel_out(dc_out),
      .DE_out          (de_dc),
      .h_sync_out      (h_sync_out),
      .v_sync_out      (v_sync_out),
      .x_pixel_out     (x_dc),
      .y_pixel_out     (y_dc)
  );

  airlight_A #(
      .DATA_DEPTH (IMAGE_WIDTH),
      .IMAGE_HEIGHT(IMAGE_HEIGHT),
      .DATA_WIDTH  (DATA_WIDTH)
  ) U_Airlight (
      .clk(clk),
      .rst(rst),
      //input port
      .DE(de_dc),
      .v_sync(v_sync_out),
      .pixel_in_888(pixel_for_airlight),  // 지연된 원본 픽셀
      .dark_channel_in(dc_out),
      //output port
      .airlight_r_out(airlight_r),
      .airlight_g_out(airlight_g),
      .airlight_b_out(airlight_b)
  );

  TransmissionEstimate #(
      .DATA_DEPTH(IMAGE_WIDTH),
      .DATA_WIDTH(DATA_WIDTH)
  ) U_Transmission_Estimate (
      .clk(clk),
      .rst(rst),

      //input port
      .DE             (de_dc),
      .x_pixel        (x_dc),
      .y_pixel        (y_dc),
      .dark_channel_in(dc_out),          // airlight 만큼 딜레이 고려
      .airlight_r_in  (airlight_r),  // airlight에서 받아오면 됨 
      .airlight_g_in  (airlight_g),  // airlight에서 받아오면 됨
      .airlight_b_in  (airlight_b),  // airlight에서 받아오면 됨

      //output port
      .t_out(t_out),
      .DE_out(de_te),
      .x_pixel_out(x_te),
      .y_pixel_out(y_te)
  );

  guided_filter_top #(
      .DATA_WIDTH (24),
      .WINDOW_SIZE(15)
  ) guided_inst (
      .clk(clk),
      .rst(rst),
      .x_pixel(x_te),
      .y_pixel(y_te),
      .DE(de_te),
      .guide_pixel_in(pixel_for_guided),
      .input_pixel_in(t_out),
      .DE_out(de_g),
      .q_i(q_out)
  );

  //   fog_removal_cal #(
  //       .DATA_DEPTH(IMAGE_WIDTH),
  //       .DATA_WIDTH(DATA_WIDTH),
  //       .DIVIDER_LATENCY(37)
  //   ) U_Recover (
  //       .clk(clk),
  //       .rst(rst),
  //       //input port
  //       .DE(de_te),
  //       .x_pixel(x_te),
  //       .pixel_in_888(pixel_for_recover),
  //       .airlight_r(airlight_r_reg),
  //       .airlight_g(airlight_g_reg),
  //       .airlight_b(airlight_b_reg),
  //       .tx_data(q_out),  // guided filter에서 나온 값
  //       //output port
  //       .removal_data(removal1_data),
  //       .DE_out(DE_out),
  //       .x_pixel_out(x_pixel_out)
  //   );



endmodule
