`timescale 1ns / 1ps

module tb_airlightA ();

    // --- 파라미터 정의 ---
    localparam IMAGE_WIDTH = 640;
    localparam IMAGE_HEIGHT = 480;
    localparam DATA_WIDTH = 8;

    // 테스트 시나리오 파라미터
    localparam logic [23:0] BG_PIXEL_VAL = 24'hAAAAAA;  // 배경 RGB 값
    localparam logic [7:0] BG_DC_VAL = 8'h10;  // 배경 Dark Channel 값

    localparam logic [23:0] TEST_PIXEL_VAL   = 24'h123456; // Airlight이 되어야 할 목표 RGB 값
    localparam logic [7:0]  TEST_DC_VAL      = 8'hF0;      // 프레임 내 유일한 최대 Dark Channel 값

    localparam int TEST_X_COORD = 10;  // 목표 픽셀의 X 좌표
    localparam int TEST_Y_COORD = 10;  // 목표 픽셀의 Y 좌표

    // --- 신호 선언 ---
    logic       clk;
    logic       reset;

    // VGA 모듈 신호
    logic       vga_h_sync;
    logic       vga_v_sync;
    logic [9:0] vga_x_pixel;
    logic [9:0] vga_y_pixel;
    logic       vga_de;
    logic       vga_pclk;

    // DUT 입력 신호
    logic tb_de, tb_vsync;
    logic [          23:0] tb_pixel_in_888;
    logic [           7:0] tb_dark_channel_in;
    logic [          23:0] dut_pixel_in;
    logic [DATA_WIDTH-1:0] dut_dark_channel_in;

    // DUT 출력 신호 (관찰 대상)
    logic [DATA_WIDTH-1:0] dut_airlight_r_out;
    logic [DATA_WIDTH-1:0] dut_airlight_g_out;
    logic [DATA_WIDTH-1:0] dut_airlight_b_out;
    logic                  dut_airlight_done;

    //======================================================================
    // 1. 모듈 인스턴스화
    //======================================================================

    VGA_Controller U_VGA_Generator (
        .clk    (clk),
        .reset  (reset),
        .h_sync (vga_h_sync),
        .v_sync (tb_vsync),
        .x_pixel(vga_x_pixel),
        .y_pixel(vga_y_pixel),
        .DE     (tb_de),
        .pclk   (vga_pclk)
    );

    airlight_A #(
        .IMAGE_WIDTH (IMAGE_WIDTH),
        .IMAGE_HEIGHT(IMAGE_HEIGHT),
        .DATA_WIDTH  (DATA_WIDTH)
    ) U_DUT (
        .clk            (clk),
        .rst            (reset),
        .DE             (tb_de),
        .v_sync         (tb_vsync),
        .pixel_in_888   (tb_pixel_in_888),
        .dark_channel_in(tb_dark_channel_in),
        .airlight_r_out (dut_airlight_r_out),
        .airlight_g_out (dut_airlight_g_out),
        .airlight_b_out (dut_airlight_b_out)
    );


    //======================================================================
    // 2. 클럭 및 리셋 생성
    //======================================================================
    always #5 clk = ~clk;  // 100MHz 시스템 클럭

    //======================================================================
    // 3. 자극 생성 (Stimulus Generator)
    //======================================================================
    initial begin
        // 1. 초기화
        clk = 0;
        reset = 1;
        tb_de = 0;
        tb_vsync = 0;
        tb_pixel_in_888 = '0;
        tb_dark_channel_in<= '0;
        #20;
        reset = 0;
        #20;

        // --- 가상 프레임 시작 ---
        $display("--- Test Frame Start ---");

        // 2. 첫 번째 픽셀 (초기값 설정 테스트)
        tb_de <= 1;
        tb_pixel_in_888 <= 24'hFF0000;  // Red
        tb_dark_channel_in <= 50;
        $display("[%0t] Input DC: 50, Pixel: Red", $time);
        @(posedge clk);

        // 3. 두 번째 픽셀 (갱신 무시 테스트)
        tb_pixel_in_888 <= 24'h00FF00;  // Green
        tb_dark_channel_in <= 30;  // 50보다 작음
        $display("[%0t] Input DC: 30, Pixel: Green (Max should not change)",
                 $time);
        @(posedge clk);

        // 4. 세 번째 픽셀 (최댓값 갱신 테스트)
        tb_pixel_in_888 <= 24'h0000FF;  // Blue
        tb_dark_channel_in <= 150;  // 50보다 큼 -> 새로운 최댓값!
        $display("[%0t] Input DC: 150, Pixel: Blue (New Max!)", $time);
        @(posedge clk);

        // 5. 네 번째 픽셀 (갱신 무시 테스트)
        tb_pixel_in_888 <= 24'hFFFFFF;  // White
        tb_dark_channel_in <= 120;  // 150보다 작음
        $display("[%0t] Input DC: 120, Pixel: White (Max should not change)",
                 $time);
        @(posedge clk);

        tb_de <= 0;  // 프레임 내 유효 데이터 끝
        #50;

        // 6. 프레임 종료 신호 (vsync 펄스)
        $display("[%0t] Sending vsync pulse...", $time);
        tb_vsync <= 1;
        @(posedge clk);
        tb_vsync <= 0;
        @(posedge clk);

        $display("--- Test Frame End ---");
        #50;
        $stop;
    end

endmodule
