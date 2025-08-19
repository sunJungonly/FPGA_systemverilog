`timescale 1ns / 1ps

module fog_removal_top #(
    parameter IMAGE_WIDTH  = 320,
    parameter IMAGE_HEIGHT = 240,
    parameter DATA_WIDTH   = 8,
    parameter DC_LATENCY   = 64,
    parameter TE_LATENCY   = 23    // TransmissionEstimate의 Divider IP Latency
) (
    (* dont_touch = "true" *) input  logic       sys_clk,
    (* dont_touch = "true" *) input  logic       pclk,
    (* dont_touch = "true" *) input  logic       rst,
    //input port
    (* dont_touch = "true" *) input  logic [4:0] red_port,
    (* dont_touch = "true" *) input  logic [5:0] green_port,
    (* dont_touch = "true" *) input  logic [4:0] blue_port,
    (* dont_touch = "true" *) input  logic       DE,
    (* dont_touch = "true" *) input  logic [9:0] x_pixel,
    (* dont_touch = "true" *) input  logic [9:0] y_pixel,
    (* dont_touch = "true" *) input  logic       h_sync,
    (* dont_touch = "true" *) input  logic       v_sync,
    //output port
    (* dont_touch = "true" *) output logic [4:0] red_port_out,
    (* dont_touch = "true" *) output logic [5:0] green_port_out,
    (* dont_touch = "true" *) output logic [4:0] blue_port_out,
    (* dont_touch = "true" *) output logic       DE_out,
    (* dont_touch = "true" *) output logic       h_sync_out,
    (* dont_touch = "true" *) output logic       v_sync_out
);
    logic [ 7:0] r_8bit;
    logic [ 7:0] g_8bit;
    logic [ 7:0] b_8bit;

    logic [23:0] pixel_in_888;  // 24비트 픽셀 데이터

    assign r_8bit = {red_port, red_port[4:2]};
    assign g_8bit = {green_port, green_port[5:4]};
    assign b_8bit = {blue_port, blue_port[4:2]};

    assign pixel_in_888 = {r_8bit, g_8bit, b_8bit};

    // --- 내부 신호 선언 ---
    logic [DATA_WIDTH-1:0]
        dc_out, airlight_r, airlight_g, airlight_b, t_out, dc_for_te;
    logic [DATA_WIDTH-1:0] airlight_r_out, airlight_g_out, airlight_b_out;
    logic [DATA_WIDTH-1:0]
        airlight_r_out_cs, airlight_g_out_cs, airlight_b_out_cs;
    logic de_dc, de_te, de_g;
    logic h_sync_dc, v_sync_dc;
    logic [$clog2(IMAGE_WIDTH)-1:0] x_dc, y_dc, x_A, y_A, x_te, y_te;
    logic dark_channel_in_tready, dc_de_out ;
    logic [15:0] q_out;

    // 제어 및 동기화 로직을 위한 출력 신호
    logic [DATA_WIDTH-1:0] airlight_r_reg, airlight_g_reg, airlight_b_reg;
    logic [23:0] pixel_for_airlight, pixel_for_recover, pixel_for_guided;

    // assign de_for_dc = DE & dark_channel_in_tready;

    dark_channel U_DarkChannel (
        .clk (sys_clk),
        .pclk(pclk),
        .rst (rst),

        //input port
        .pixel_in_888(pixel_in_888),
        .DE(dc_de_out),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .h_sync(h_sync),
        .v_sync(v_sync),

        //output port
        .dark_channel_out(dc_out),  // dark channel 결과값
        .DE_out(de_dc),  // 결과 데이터 유효 신호
        .h_sync_out(h_sync_dc),
        .v_sync_out(v_sync_dc),
        .x_pixel_out(x_dc),
        .y_pixel_out(y_dc)
    );

    airlight_A #(
        .DATA_DEPTH  (IMAGE_WIDTH),
        .IMAGE_HEIGHT(IMAGE_HEIGHT),
        .DATA_WIDTH  (DATA_WIDTH)
    ) U_Airlight (
        .clk(sys_clk),
        .rst(rst),

        //input port
        .DE(de_dc),
        .v_sync(v_sync_dc),
        .pixel_in_888(pixel_for_airlight),  // DC만큼 지연된 원본 픽셀
        .dark_channel_in(dc_out),

        //output port
        .airlight_r_out(airlight_r_out),
        .airlight_g_out(airlight_g_out),
        .airlight_b_out(airlight_b_out)
    );

    // 제어 및 동기화 모듈
    control_and_sync#(
        .IMAGE_WIDTH(IMAGE_WIDTH),
        .IMAGE_HEIGHT(IMAGE_HEIGHT),
        .DATA_WIDTH(DATA_WIDTH),
        .DC_LATENCY(64),
        .TE_LATENCY(23)
    ) U_Control_and_Sync (
        .clk(clk),
        .rst(rst),
        .pclk(pclk),

        // 원본 입력
        .DE_in(DE),
        .pixel_in_888(pixel_in_888),
        .v_sync(v_sync),
        
        .te_tready_in(dark_channel_in_tready),
        .dc_de_out(dc_de_out),

        // Airlight 피드백 입력
        .airlight_r_in(airlight_r_out),
        .airlight_g_in(airlight_g_out),
        .airlight_b_in(airlight_b_out),

        // 다른 모듈로 전달될 출력
        .final_airlight_r_out(airlight_r_out_cs),     // 프레임 내내 고정될 Airlight
        .final_airlight_g_out(airlight_g_out_cs),
        .final_airlight_b_out(airlight_b_out_cs),

        .pixel_for_airlight(pixel_for_airlight),  // Airlight 계산을 위한 지연된 픽셀
        .pixel_for_guided(pixel_for_guided),       // Airlight 계산을 위한 지연된 픽셀
        .pixel_for_recover(pixel_for_recover)     // 최종 복원을 위한 지연된 픽셀
    );

    TransmissionEstimate #(
        .DATA_DEPTH(IMAGE_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) U_Transmission_Estimate (
        .clk(sys_clk),
        .rst(rst),

        //input port
        .DE(de_dc),
        .x_pixel(x_dc),
        .y_pixel(y_dc),
        .dark_channel_in(dc_out),  // airlight 만큼 딜레이 고려
        .airlight_r_in(airlight_r_out),  // airlight에서 받아오면 됨 
        .airlight_g_in(airlight_g_out),  // airlight에서 받아오면 됨
        .airlight_b_in(airlight_b_out),  // airlight에서 받아오면 됨

        //output port
        .dark_channel_in_tready(dark_channel_in_tready),
        .t_out(t_out),
        .DE_out(de_te),
        .x_pixel_out(x_te),
        .y_pixel_out(y_te)
    );

    guided_filter_top #(
        .DATA_WIDTH (24),
        .WINDOW_SIZE(15)
    ) guided_inst (
        .clk(sys_clk),
        .rst(rst),
        .x_pixel(x_te),
        .y_pixel(y_te),
        .DE(de_te),
        .guide_pixel_in(pixel_for_guided), // control_and_sync //딜레이 된 원본데이터
        .input_pixel_in(t_out),  // TransmissionEstimate 결과 
        .q_i(q_out),
        .DE_out(de_g)
    );

    fog_removal_cal #(
        .DATA_DEPTH(IMAGE_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .DIVIDER_LATENCY(26)
    ) U_Recover (
        .clk(sys_clk),
        .rst(rst),

        //input port
        .DE          (de_g),
        // .x_pixel     (x_te),
        // .y_pixel     (y_te),
        .pixel_in_888(pixel_for_recover),  //control_and_sync
        .airlight_r  (airlight_r_out_cs),     //control_and_sync
        .airlight_g  (airlight_g_out_cs),     //control_and_sync
        .airlight_b  (airlight_b_out_cs),     //control_and_sync
        .tx_data     (q_out),              // guided filter에서 나온 값

        //output port
        .final_r($unsigned(red_port_out)),
        .final_g($unsigned(green_port_out)),
        .final_b($unsigned(blue_port_out)),
        .DE_out(DE_out)
    );


endmodule
