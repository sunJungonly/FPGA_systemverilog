`timescale 1ns / 1ps

module test_top(

    );

    dark_channel asd(
        .clk(clk),
        .pclk(pclk),
        .rst(rst),
        .pixel_in_888(pixel_in),
        .DE(DE),
        .h_sync         (h_sync),
        .v_sync         (v_sync),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .dark_channel_out(dark_channel_out),
        .DE_out(DE_out),
        .h_sync_out         (h_sync_out),
        .v_sync_out         (v_sync_out),
        .x_pixel_out(x_pixel_out)
    );

  airlight_A #(
      .IMAGE_WIDTH (IMAGE_WIDTH),
      .IMAGE_HEIGHT(IMAGE_HEIGHT),
      .DATA_WIDTH  (DATA_WIDTH)
  ) U_Airlight (
      .clk(sys_clk),
      .rst(reset_sync),

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
      .clk(sys_clk),
      .rst(reset_sync),

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



endmodule
