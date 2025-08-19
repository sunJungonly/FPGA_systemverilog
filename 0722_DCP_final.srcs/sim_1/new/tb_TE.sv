`timescale 1ns / 1ps

module tb_TE ();
    localparam IMAGE_WIDTH = 640;
    localparam IMAGE_HEIGHT = 480;
    localparam DATA_DEPTH = 32;
    localparam DATA_WIDTH = 8;
    localparam DC_LATENCY = 64;
    localparam TE_LATENCY = 23;
    // --- 파라미터 정의 ---
    // DUT 파라미터
    localparam DUT_DATA_DEPTH = 640;  // dark_channel의 DATA_DEPTH
    localparam DUT_DATA_WIDTH = 8;
    localparam KERNEL_SIZE    = 15; // dark_channel 내부 block_min의 커널 사이즈

    // 테스트 시나리오 파라미터
    localparam logic [23:0] BG_PIXEL_VAL   = 24'hFFFFFF; // 배경 픽셀 (흰색)
    localparam logic [7:0] EXPECTED_BG = 8'hFF;
    localparam logic [23:0] TEST_PIXEL_VAL = 24'h102030; // 어두운 테스트 픽셀
    localparam logic [7:0] EXPECTED_TEST = 8'h10;
    localparam int TEST_X_COORD = 50;  // 어두운 픽셀의 X 좌표
    localparam int TEST_Y_COORD = 50;  // 어두운 픽셀의 Y 좌표

    // --- 신호 선언 ---
    // 클럭 및 리셋
    logic clk;
    logic rst;

    // VGA 모듈 출력 신호 (와이어)
    logic vga_rclk;
    logic vga_h_sync;
    logic vga_v_sync;
    logic [9:0] vga_x_pixel;
    logic [9:0] vga_y_pixel;
    logic vga_de;
    logic vga_pclk;

    // DUT 연결 신호
    logic [23:0] dut_pixel_in;
    logic [DUT_DATA_WIDTH-1:0] dut_dark_channel_out;
    logic dut_de_out;
    logic [$clog2(DUT_DATA_DEPTH)-1:0] dut_x_pixel_out;
    logic [$clog2(DUT_DATA_DEPTH)-1:0] dut_y_pixel_out;
    logic [23:0] pixel_for_airlight, pixel_for_recover, pixel_for_guided;
    logic [DATA_WIDTH-1:0] airlight_r_out, airlight_g_out, airlight_b_out;
    logic [DATA_WIDTH-1:0]
        airlight_r_out_cs, airlight_g_out_cs, airlight_b_out_cs;
    logic dark_channel_in_tready;  // 8비트 dark channel
    logic [DATA_WIDTH - 1:0] t_out;
    logic DE_out;
    logic [$clog2(DATA_DEPTH)-1:0] x_te;
    logic [$clog2(DATA_DEPTH)-1:0] y_te;
    // 테스트벤치 내부 변수
    integer error_count;
    integer test_min_count;
    // --- [추가] 테스트벤치 내부의 예측 모델용 변수 ---
    logic [8:0] tb_x_counter;
    logic [8:0] tb_y_counter;
    logic tb_kernel_valid;
    logic tb_expected_de;  // DUT의 DE_out이 나와야 할 타이밍 예측
    logic [7:0] tb_expected_value;   // DUT의 dark_channel_out이 가져야 할 값 예측
    parameter     latency_count = 5; // DUT의 대략적인 파이프라인 지연 (경험적으로 튜닝 필요)
    logic [latency_count-1:0] de_pipe;
    logic [latency_count-1:0] kv_pipe;
    //======================================================================
    // 1. 모듈 인스턴스화
    //======================================================================

    // (1) VGA 타이밍 생성기
    VGA_Controller U_VGA_Generator (
        .clk    (clk),
        .reset  (rst),
        .rclk   (vga_rclk),
        .h_sync (vga_h_sync),
        .v_sync (vga_v_sync),
        .x_pixel(vga_x_pixel),
        .y_pixel(vga_y_pixel),
        .DE     (vga_de),
        .pclk   (vga_pclk)
    );

    // (2) 검증 대상 DUT
    dark_channel U_DUT (
        .clk(vga_rclk),  // DUT는 시스템 클럭(rclk)을 사용
        .pclk(vga_pclk),
        .rst(rst),
        .pixel_in_888(dut_pixel_in),
        .DE(dc_de_out),  // VGA의 DE 신호를 DUT의 입력으로
        .x_pixel(vga_x_pixel),  // VGA의 x_pixel을 DUT의 입력으로
        .y_pixel(vga_y_pixel),
        .h_sync(vga_h_sync),
        .v_sync(vga_v_sync),
        .dark_channel_out(dut_dark_channel_out),
        .DE_out(dut_de_out),
        .h_sync_out(h_sync_out),
        .v_sync_out(v_sync_out),
        .x_pixel_out(dut_x_pixel_out),
        .y_pixel_out(dut_y_pixel_out)
    );


    // Airlight 모듈
    airlight_A #(
        .DATA_DEPTH  (IMAGE_WIDTH),
        .IMAGE_HEIGHT(IMAGE_HEIGHT),
        .DATA_WIDTH  (DATA_WIDTH)
    ) U_Airlight (
        .clk(clk),
        .rst(rst),
        .DE(dut_de_out),
        .v_sync(v_sync_out),
        .pixel_in_888(pixel_for_airlight),
        .dark_channel_in(dut_dark_channel_out),
        .airlight_r_out(airlight_r_out),
        .airlight_g_out(airlight_g_out),
        .airlight_b_out(airlight_b_out)
    );

    // Control and Sync 모듈
    control_and_sync #(
        .IMAGE_WIDTH (IMAGE_WIDTH),
        .IMAGE_HEIGHT(IMAGE_HEIGHT),
        .DATA_WIDTH  (DATA_WIDTH),
        .DC_LATENCY  (DC_LATENCY),
        .TE_LATENCY  (TE_LATENCY)
    ) U_Control_and_Sync (
        .clk(clk),
        .rst(rst),
        .DE_in(vga_de),
        .pixel_in_888(dut_pixel_in),
        .v_sync(vga_v_sync),
        .te_tready_in(dark_channel_in_tready),
        .dc_de_out(dc_de_out),
        .airlight_r_in(airlight_r_out),
        .airlight_g_in(airlight_g_out),
        .airlight_b_in(airlight_b_out),
        .final_airlight_r_out(airlight_r_out_cs),
        .final_airlight_g_out(airlight_g_out_cs),
        .final_airlight_b_out(airlight_b_out_cs),
        .pixel_for_airlight(pixel_for_airlight),
        .pixel_for_guided(pixel_for_guided),
        .pixel_for_recover(pixel_for_recover)
    );

    TransmissionEstimate #(
        .DATA_DEPTH(IMAGE_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) U_Transmission_Estimate (
        .clk(clk),
        .rst(rst),

        //input port
        .DE(dut_de_out),
        .x_pixel(dut_x_pixel_out),
        .y_pixel(dut_y_pixel_out),
        .dark_channel_in(dut_dark_channel_out),  // airlight 만큼 딜레이 고려
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

    // always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        #20;

        rst = 0;
        forever #5 clk = ~clk;  // 100MHz
    end

    // --- 3. 픽셀 입력 생성기 ---
    // 요청하신 대로 pixel_in = x*1000 + y
    always @(posedge clk) begin
        if (vga_de) begin
            dut_pixel_in <= vga_x_pixel * 1000 + vga_y_pixel;
        end else begin
            dut_pixel_in <= '0;
        end
    end



endmodule
