`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/23 18:56:31
// Design Name: 
// Module Name: tb_vga_dark_channel
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_vga_dark_channel();


    // --- 파라미터 정의 ---
    // DUT 파라미터
    localparam DUT_DATA_DEPTH = 320; // dark_channel의 DATA_DEPTH
    localparam DUT_DATA_WIDTH = 8;
    localparam KERNEL_SIZE    = 15; // dark_channel 내부 block_min의 커널 사이즈

    // 테스트 시나리오 파라미터
    localparam logic [23:0] BG_PIXEL_VAL   = 24'hFFFFFF; // 배경 픽셀 (흰색)
    localparam logic [7:0]  EXPECTED_BG    = 8'hFF;
    localparam logic [23:0] TEST_PIXEL_VAL = 24'h102030; // 어두운 테스트 픽셀
    localparam logic [7:0]  EXPECTED_TEST  = 8'h10;
    localparam int          TEST_X_COORD   = 50;       // 어두운 픽셀의 X 좌표
    localparam int          TEST_Y_COORD   = 50;       // 어두운 픽셀의 Y 좌표
    
    // --- 신호 선언 ---
    // 클럭 및 리셋
    logic clk;
    logic reset;

    // VGA 모듈 출력 신호 (와이어)
    logic        vga_rclk;
    logic        vga_h_sync;
    logic        vga_v_sync;
    logic [8:0]  vga_x_pixel;
    logic [8:0]  vga_y_pixel;
    logic        vga_de;
    logic        vga_pclk;

    // DUT 연결 신호
    logic [23:0] dut_pixel_in;
    logic [DUT_DATA_WIDTH-1:0] dut_dark_channel_out;
    logic        dut_de_out;
    logic [$clog2(DUT_DATA_DEPTH)-1:0] dut_x_pixel_out;
    logic [$clog2(DUT_DATA_DEPTH)-1:0] dut_y_pixel_out;
    
    // 테스트벤치 내부 변수
    integer error_count;
    integer test_min_count;
// --- [추가] 테스트벤치 내부의 예측 모델용 변수 ---
    logic [8:0] tb_x_counter;
    logic [8:0] tb_y_counter;
    logic       tb_kernel_valid;
    logic       tb_expected_de;      // DUT의 DE_out이 나와야 할 타이밍 예측
    logic [7:0] tb_expected_value;   // DUT의 dark_channel_out이 가져야 할 값 예측
    parameter     latency_count = 5; // DUT의 대략적인 파이프라인 지연 (경험적으로 튜닝 필요)
        logic [latency_count-1:0] de_pipe;
        logic [latency_count-1:0] kv_pipe;
    //======================================================================
    // 1. 모듈 인스턴스화
    //======================================================================

    // (1) VGA 타이밍 생성기
    vga U_VGA_Generator (
        .clk    (clk),
        .reset  (reset),
        .rclk   (vga_rclk),
        .h_sync (vga_h_sync),
        .v_sync (vga_v_sync),
        .x_pixel(vga_x_pixel),
        .y_pixel(vga_y_pixel),
        .DE     (vga_de),
        .pclk   (vga_pclk)
    );

    // (2) 검증 대상 DUT
    dark_channel #(
        .DATA_DEPTH(DUT_DATA_DEPTH),
        .DATA_WIDTH(DUT_DATA_WIDTH)
    ) U_DUT (
        .clk         (vga_rclk), // DUT는 시스템 클럭(rclk)을 사용
        .rst         (reset),
        .pixel_in_888(dut_pixel_in),
        .DE          (vga_de),        // VGA의 DE 신호를 DUT의 입력으로
        .x_pixel     (vga_x_pixel),   // VGA의 x_pixel을 DUT의 입력으로
        .y_pixel     (vga_y_pixel),   
        .dark_channel_out(dut_dark_channel_out),
        .DE_out      (dut_de_out),
        .x_pixel_out (dut_x_pixel_out),
        .y_pixel_out (dut_y_pixel_out)
    );

    assign dut_pixel_in = vga_x_pixel * 1000 + vga_y_pixel;
    //======================================================================
    // --- [추가] DUT 동작 예측 모델 ---
    // 1. 테스트벤치 내부에 DUT와 똑같이 동작할 것으로 기대되는 x, y 카운터를 만듭니다.
    //    이 카운터는 VGA 생성기의 DE 신호를 기준으로 동작합니다.
    //======================================================================
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            tb_x_counter <= 0;
            tb_y_counter <= 0;
        end else if (vga_de) begin // 원본 DE 신호가 1일 때
            if (tb_x_counter == DUT_DATA_DEPTH - 1) begin // QVGA 한 줄(319)의 끝이면
                tb_x_counter <= 0;
                tb_y_counter <= tb_y_counter + 1;
            end else begin
                tb_x_counter <= tb_x_counter + 1;
            end
        end
    end

    // --- [추가] ---
    // 2. 예측된 x, y 카운터 값을 기반으로 "커널이 유효해지는 시점"을 예측합니다.
    //    이것이 우리가 기대하는 `kernel_valid` 입니다.
    //======================================================================
    assign tb_kernel_valid = (tb_x_counter >= KERNEL_SIZE - 1) && (tb_y_counter >= KERNEL_SIZE - 1);

    // --- [추가] ---
    // 3. DUT의 출력이 언제, 어떤 값으로 나올지 예측합니다.
    //    - tb_expected_de: 원본 DE가 DUT의 파이프라인 지연(latency)만큼 늦게 나올 것으로 예측
    //    - tb_expected_value: 예측된 시점에 어떤 값이 나와야 하는지 예측
    //======================================================================
    always_ff @(posedge clk) begin
        // 파이프라인 지연(Latency) 모델링
        // DUT의 DE_out은 vga_de 보다 몇 클럭 늦게 나옵니다. 이 지연을 예측합니다.
        // tb_kernel_valid 또한 같은 양만큼 지연시켜야 타이밍이 맞습니다.
        
        de_pipe <= {de_pipe, vga_de};
        kv_pipe <= {kv_pipe, tb_kernel_valid};

        tb_expected_de <= de_pipe[latency_count-1];
        
        // 예상되는 출력값 계산
        if (kv_pipe[latency_count-1]) begin // 커널이 유효할 것으로 예측되는 시점에
            // 어두운 점 주변(100,100)을 지날 때만 EXPECTED_TEST(10)가 나와야 함
            if (tb_y_counter >= TEST_Y_COORD && tb_y_counter < TEST_Y_COORD + KERNEL_SIZE &&
                tb_x_counter >= TEST_X_COORD && tb_x_counter < TEST_X_COORD + KERNEL_SIZE) begin
                tb_expected_value <= EXPECTED_TEST;
            end else begin
                tb_expected_value <= EXPECTED_BG;
            end
        end else begin // 커널이 아직 유효하지 않을 때는 'FF'가 나와야 정상
            tb_expected_value <= EXPECTED_BG;
        end
    end


    //======================================================================
    // 2. 클럭 및 리셋 생성
    //======================================================================
    initial begin
        clk = 1; // 100MHz 클럭 (주기 10ns)
        forever #5 clk = ~clk;
    end

    initial begin
        // 시뮬레이션 시작 및 리셋
        reset = 1;
        #100;
        reset = 0;
        
        
    end

    //======================================================================
    // 3. 자극 생성 (Stimulus Generator)
    // - VGA의 DE와 좌표 신호에 맞춰 픽셀 데이터(RGB)를 생성
    //======================================================================
    // always_comb begin
    //     if (vga_de) begin
    //     // 15x15 크기의 "영역"에 어두운 픽셀을 주입
    //     if ( (vga_y_pixel >= TEST_Y_COORD && vga_y_pixel < (TEST_Y_COORD + KERNEL_SIZE)) &&
    //          (vga_x_pixel >= TEST_X_COORD && vga_x_pixel < (TEST_X_COORD + KERNEL_SIZE)) ) begin
    //         dut_pixel_in = TEST_PIXEL_VAL;
    //     end else begin
    //         dut_pixel_in = BG_PIXEL_VAL;
    //     end
    // end else begin
    //     dut_pixel_in = 24'hzzzzzz;
    // end
// end
    
    //======================================================================
    // 5. 시뮬레이션 제어 및 종료
    //======================================================================
    initial begin
        // VGA가 최소 2개의 전체 프레임을 생성할 만큼 충분히 기다림
        // 1 프레임 = 400 * 263 pclk = 400 * 263 * 4 clk = 420,800 clk
        // 2 프레임 + @ 이므로 대략 1,000,000 클럭 사이클을 기다림
        repeat(1_000_000) @(posedge clk);

        $finish;
    end

endmodule