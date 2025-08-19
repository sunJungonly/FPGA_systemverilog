`timescale 1ns / 1ps

module tb_Ctrl_Sync();

    // =================================================================
    // 파라미터 정의
    // =================================================================
    localparam IMAGE_WIDTH  = 320;
    localparam IMAGE_HEIGHT = 240;
    localparam DATA_WIDTH   = 8;
    localparam DC_LATENCY   = 10;
    localparam TE_LATENCY   = 20;
    localparam TOTAL_LATENCY = DC_LATENCY + TE_LATENCY;
    localparam CLK_PERIOD   = 10; // 10ns = 100MHz

    // =================================================================
    // 신호 선언
    // =================================================================
    logic clk;
    logic rst;

    // --- DUT 입력 ---
    logic        DE_in;
    logic [23:0] pixel_in_888;
    logic [8:0]  y_pixel_in;
    logic        airlight_done_in;
    logic [7:0]  airlight_r_in;
    logic [7:0]  airlight_g_in;
    logic [7:0]  airlight_b_in;

    // --- DUT 출력 (관찰 대상) ---
    logic [7:0]  airlight_r_out;
    logic [7:0]  airlight_g_out;
    logic [7:0]  airlight_b_out;
    logic [23:0] pixel_for_airlight;
    logic [23:0] pixel_for_recover;
    logic [8:0]  y_pixel_for_airlight;


    // =================================================================
    // DUT 인스턴스화
    // =================================================================
    control_and_sync #(
        .IMAGE_WIDTH(IMAGE_WIDTH),
        .IMAGE_HEIGHT(IMAGE_HEIGHT),
        .DATA_WIDTH(DATA_WIDTH),
        .DC_LATENCY(DC_LATENCY),
        .TE_LATENCY(TE_LATENCY)
    ) dut (
        .clk(clk),
        .rst(rst),
        .DE_in(DE_in),
        .pixel_in_888(pixel_in_888),
        .y_pixel_in(y_pixel_in),
        .airlight_done_in(airlight_done_in),
        .airlight_r_in(airlight_r_in),
        .airlight_g_in(airlight_g_in),
        .airlight_b_in(airlight_b_in),
        .airlight_r_out(airlight_r_out),
        .airlight_g_out(airlight_g_out),
        .airlight_b_out(airlight_b_out),
        .pixel_for_airlight(pixel_for_airlight),
        .pixel_for_recover(pixel_for_recover),
        .y_pixel_for_airlight(y_pixel_for_airlight)
    );

    // =================================================================
    // 클럭 및 리셋 생성
    // =================================================================
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // =================================================================
    // 자극 생성 및 시뮬레이션 제어
    // =================================================================
    logic [23:0] pixel_counter = 0;
    logic [8:0]  y_pixel_counter = 0;

    initial begin
        // --- 리셋 구간 ---
        rst = 1;
        DE_in = 0;
        airlight_done_in = 0;
        airlight_r_in = 8'hAA; // 피드백될 새로운 값 미리 준비
        airlight_g_in = 8'hBB;
        airlight_b_in = 8'hCC;
        repeat(5) @(posedge clk);
        rst = 0;
        $display("INFO: Reset released. Starting simulation for waveform analysis.");

        // --- 데이터 입력 구간 ---
        // 파이프라인을 채우고도 남을 만큼 충분히 데이터를 입력
        DE_in = 1;
        repeat (TOTAL_LATENCY + 20) @(posedge clk);
        
        // --- 데이터 입력 중지 ---
        DE_in = 0;
        repeat(10) @(posedge clk);

        // --- Airlight 업데이트 신호 인가 ---
        airlight_done_in = 1;
        @(posedge clk);
        airlight_done_in = 0;

        // --- 안정화 및 종료 ---
        repeat(10) @(posedge clk);
        $display("INFO: Simulation finished. Please check the waveform.");
        $finish;
    end

    // --- DE_in에 맞춰 카운터 값을 입력으로 넣어줌 ---
    always @(posedge clk) begin
        if (rst) begin
            pixel_counter <= 0;
            y_pixel_counter <= 0;
        end else if (DE_in) begin
            pixel_counter <= pixel_counter + 1;
            y_pixel_counter <= y_pixel_counter + 1;
        end
    end

    assign pixel_in_888 = pixel_counter;
    assign y_pixel_in = y_pixel_counter;

endmodule

/*
Airlight 루프 검증:
시뮬레이션 시작 부분에서 rst가 1일 때, airlight_r/g/b_out이 초기값(220)인지 확인합니다.
파형의 뒷부분으로 가서, airlight_done_in이 1이 되는 클럭을 찾습니다.
바로 다음 클럭에서 airlight_r/g/b_out의 값이 airlight_r/g/b_in의 값(h'AA, h'BB, h'CC)으로 바뀌는지 확인합니다.
지연 라인 검증:
입력 시점 찾기: DE_in이 1인 구간에서 pixel_in_888 값이 **1**이 되는 시점을 찾습니다. (이때의 y_pixel_in도 1입니다.)
DC_LATENCY (10클럭) 후 확인: 그 시점으로부터 10 클럭 오른쪽으로 파형을 이동합니다. 이 위치에서 pixel_for_airlight와 y_pixel_for_airlight의 값이 모두 **1**이 되는지 확인합니다.
TOTAL_LATENCY (30클럭) 후 확인: 다시 원래의 입력 시점(값이 1인 곳)으로부터 30 클럭 오른쪽으로 파형을 이동합니다. 이 위치에서 pixel_for_recover의 값이 **1**이 되는지 확인합니다.
다른 입력 값(예: 10)에 대해서도 위 과정을 반복하여 지연 시간이 정확한지 확인합니다.

*/