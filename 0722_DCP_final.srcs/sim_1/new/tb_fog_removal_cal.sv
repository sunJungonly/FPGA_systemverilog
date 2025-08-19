`timescale 1ns / 1ps

module tb_fog_removal_cal();

    // =================================================================
    // 파라미터 및 상수 정의
    // =================================================================
    localparam DATA_DEPTH      = 320;
    localparam DATA_WIDTH      = 8;
    localparam DIVIDER_LATENCY = 20;
    localparam CLK_PERIOD      = 10; // 10ns = 100MHz 클럭

    // =================================================================
    // 신호 선언
    // =================================================================
    logic clk;
    logic rst;

    // --- VGA 모듈 연결 신호 ---
    logic        vga_h_sync;
    logic        vga_v_sync;
    logic [8:0]  vga_x_pixel;
    logic [7:0]  vga_y_pixel;
    logic        vga_de;
    logic        vga_pclk;

    // --- DUT(fog_removal_cal) 연결 신호 ---
    // 입력
    logic [23:0]                  dut_pixel_in_888;
    logic [DATA_WIDTH-1:0]        dut_airlight_r;
    logic [DATA_WIDTH-1:0]        dut_airlight_g;
    logic [DATA_WIDTH-1:0]        dut_airlight_b;
    logic [DATA_WIDTH-1:0]        dut_tx_data;
    // 출력 (파형에서 관찰할 신호)
    logic [DATA_WIDTH-1:0]        final_r;
    logic [DATA_WIDTH-1:0]        final_g;
    logic [DATA_WIDTH-1:0]        final_b;
    logic                         dut_de_out;
    logic [$clog2(DATA_DEPTH)-1:0] dut_x_pixel_out;

    // =================================================================
    // 1. 모듈 인스턴스화
    // =================================================================

    // VGA 타이밍 생성기
    VGA_Controller u_vga (
        .clk     (clk),
        .reset   (rst),
        .rclk    (), // not used
        .h_sync  (vga_h_sync),
        .v_sync  (vga_v_sync),
        .x_pixel (vga_x_pixel),
        .y_pixel (vga_y_pixel),
        .DE      (vga_de),
        .pclk    (vga_pclk)
    );

    // 검증 대상 모듈 (DUT: Design Under Test)
    fog_removal_cal #(
        .DATA_DEPTH      (DATA_DEPTH),
        .DATA_WIDTH      (DATA_WIDTH),
        .DIVIDER_LATENCY (DIVIDER_LATENCY)
    ) u_dut (
        .clk           (clk),
        .rst           (rst),
        .DE            (vga_de),
        .pixel_in_888  (dut_pixel_in_888),
        .airlight_r    (dut_airlight_r),
        .airlight_g    (dut_airlight_g),
        .airlight_b    (dut_airlight_b),
        .tx_data       (dut_tx_data),
        .final_r       (final_r),
        .final_g       (final_g),
        .final_b       (final_b),
        .DE_out        (dut_de_out)
    );

    // =================================================================
    // 2. 클럭 및 리셋 생성
    // =================================================================
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // =================================================================
    // 3. 자극 생성 및 시뮬레이션 제어
    // =================================================================
    initial begin
                // --- 시나리오 1: 리셋 및 첫 번째 Airlight 값으로 실행 ---
        rst = 1;
        dut_airlight_r = 8'd50; // 초기 Airlight 값
        dut_airlight_g = 8'd100;
        dut_airlight_b = 8'd130;
        repeat(5) @(posedge clk);
        rst = 0;
        $display("INFO: [Scenario 1] Reset released. Running with default airlight (220).");

        // 첫 번째 프레임이 거의 끝날 때까지 기다림 (약 40만 클럭)
        // 이 시간 동안 파이프라인은 첫 번째 Airlight 값으로 채워짐
        repeat(400_000) @(posedge clk);

        // --- 시나리오 2: Airlight 값 동적 변경 ---
        $display("INFO: [Scenario 2] Dynamically changing airlight value to 150.");
        @(posedge clk); // 클럭 엣지에 맞춰 깨끗하게 변경
        dut_airlight_r = 8'd150;
        dut_airlight_g = 8'd150;
        dut_airlight_b = 8'd150;
        
        // 두 번째 프레임이 끝날 때까지 시뮬레이션 계속
        // 이 시간 동안 바뀐 Airlight 값이 파이프라인에 어떻게 영향을 주는지 관찰
        repeat(450_000) @(posedge clk);

        // --- 시나리오 3: 다시 원래 값으로 변경 ---
        $display("INFO: [Scenario 3] Changing airlight back to 220.");
        @(posedge clk);
        dut_airlight_r = 8'd220;
        dut_airlight_g = 8'd220;
        dut_airlight_b = 8'd220;

        // --- 리셋 구간 ---
        // rst = 1;
        // repeat(5) @(posedge clk);
        // rst = 0;
        // $display("INFO: Reset released. Starting simulation for waveform analysis.");

        // --- 시뮬레이션 실행 ---
        // VGA가 약 1.2 프레임을 생성할 만큼 충분히 기다림
        // 1 프레임 = 400 * 263 pclk = 400 * 263 * 4 sys_clk = 420,800 clk cycles
        // 파이프라인이 모두 채워지고 출력되는 것을 보려면 충분한 시간이 필요함.
        // repeat(500_000) @(posedge clk);
        
        // $display("INFO: Simulation finished. Please check the waveform.");
        // $finish;
    end

    // // --- VGA 타이밍에 맞춰 DUT 입력 데이터 생성 ---
    // always_comb begin
    //     // // Airlight 값은 시뮬레이션 동안 고정
    //     // dut_airlight_r = 8'd220;
    //     // dut_airlight_g = 8'd220;
    //     // dut_airlight_b = 8'd220;

    //     if (vga_de) begin
    //         logic [7:0] r_val, g_val, b_val;

    //         r_val = vga_x_pixel[7:0];
    //         g_val = vga_x_pixel[7:0] + 8'd10; // x_pixel 값에 약간의 offset을 줌
    //         b_val = vga_x_pixel[7:0] - 8'd10; // x_pixel 값에 약간의 offset을 줌

    //         dut_pixel_in_888 = {r_val, g_val, b_val};

    //         // tx_data는 x 좌표에 따라 변화시켜 다양한 케이스를 테스트
    //         // tx_min (26) 보다 작은 값과 큰 값이 모두 들어가도록 함
    //         if (vga_x_pixel < 50) begin
    //             dut_tx_data = vga_x_pixel; // 0~49 (하한값 보정 로직 테스트)
    //         end else begin
    //             dut_tx_data = vga_x_pixel / 2; // 25~159 (일반적인 경우 테스트)
    //         end
    //     end 
    //     else begin
    //         // 유효하지 않은 구간에서는 'z' 상태로 두어 파형에서 쉽게 구분
    //         dut_pixel_in_888 = 24'hzzzzzz;
    //         dut_tx_data      = 8'hzz;
    //     end
    // end
            logic [8:0] b_temp;


    // --- VGA 타이밍에 맞춰 DUT 입력 데이터 생성 (실제 이미지와 유사한 패턴) ---
    always_comb begin
        // initial 블록에서 동적으로 제어되므로, 여기서는 주석 처리
        // dut_airlight_r = 8'd220;
        // dut_airlight_g = 8'd220;
        // dut_airlight_b = 8'd220;

        if (vga_de) begin
            // 실제 이미지와 유사한 부드러운 그라데이션 패턴 생성
            logic [7:0] r_val, g_val, b_val;

            // R 채널: x좌표에 따라 부드럽게 증가 (0 ~ 255)
            // vga_x_pixel (0~319) -> r_val (0~255)로 스케일링
            r_val = vga_x_pixel[8:1]; // 간단하게 2로 나눈 효과 (0~159)

            // G 채널: y좌표에 따라 부드럽게 증가 (0 ~ 239)
            g_val = vga_y_pixel;

            // B 채널: x와 y좌표가 모두 0에서 멀어질수록 진해짐
            // (vga_x_pixel/2 + vga_y_pixel/2) -> 값이 255를 넘지 않도록 saturation 필요
            b_temp = vga_x_pixel[8:1] + {1'b0, vga_y_pixel}; // 9비트 덧셈
            b_val = (b_temp > 255) ? 8'd255 : b_temp[7:0];

            dut_pixel_in_888 = {r_val, g_val, b_val};
            
            // tx_data 생성 로직은 그대로 유지하여 다양한 케이스 테스트
            if (vga_x_pixel < 50) begin
                dut_tx_data = vga_x_pixel;
            end else begin
                dut_tx_data = vga_x_pixel / 2;
            end
        end 
        else begin
            // 유효하지 않은 구간에서는 'z' 상태로 두어 파형에서 쉽게 구분
            dut_pixel_in_888 = 24'hzzzzzz;
            dut_tx_data      = 8'hzz;
        end
    end



endmodule