`timescale 1ns / 1ps

module tb_dark_channel();

    // DUT 파라미터와 동일하게 설정
    localparam DATA_DEPTH = 320; // DUT의 라인 당 픽셀 수
    localparam DATA_WIDTH = 8;
    localparam KERNEL_SIZE = 15; // DUT의 block_min 모듈과 동일한 커널 사이즈
    
    // 테스트용 이미지 크기 설정 (DUT 파라미터보다 작거나 같게)
    localparam int IMG_WIDTH  = 240;
    localparam int IMG_HEIGHT = 320;
    
    // 시나리오 1용 파라미터
    localparam logic [23:0] BG_PIXEL_VAL   = 24'hFFFFFF; // 배경 픽셀 (흰색)
    localparam logic [7:0]  EXPECTED_BG    = 8'hFF;
    localparam logic [23:0] TEST_PIXEL_VAL = 24'h102030; // 어두운 테스트 픽셀
    localparam logic [7:0]  EXPECTED_TEST  = 8'h10;
    localparam int          TEST_X_COORD   = 100;       // 어두운 픽셀의 X 좌표
    localparam int          TEST_Y_COORD   = 100;       // 어두운 픽셀의 Y 좌표

    // DUT 연결을 위한 신호 선언
    logic clk;
    logic rst;
    logic [23:0] pixel_in_888;
    logic DE;
    logic [$clog2(DATA_DEPTH)-1:0] x_pixel;

    logic [DATA_WIDTH - 1:0] dark_channel_out;
    logic DE_out;
    logic [$clog2(DATA_DEPTH)-1:0] x_pixel_out;

     // 테스트벤치 내부 변수
    integer error_count;
    integer test_min_count; // '10'이 출력된 횟수를 세는 카운터

    //================================================================
    // DUT 인스턴스화
    //================================================================
    dark_channel #(
        .DATA_DEPTH(DATA_DEPTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .pixel_in_888(pixel_in_888),
        .DE(DE),
        .x_pixel(x_pixel),
        .dark_channel_out(dark_channel_out),
        .DE_out(DE_out),
        .x_pixel_out(x_pixel_out)
    );

    //================================================================
    // 1. 클럭 생성기
    //================================================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns 주기 (100MHz)
    end

    //================================================================
    // 2. 자극 생성 및 테스트 시나리오
    //================================================================
    initial begin
        // --- 초기화 ---
        rst = 1;
        DE = 0;
        x_pixel = 0;
        pixel_in_888 = 0;
        error_count = 0;
        test_min_count = 0;

        // --- 리셋 ---
        repeat (5) @(posedge clk);
        rst = 0;
        @(posedge clk);

        $display("INFO: Starting directed test pixel stream injection...");

        // --- 픽셀 데이터 주입 ---
        for (int y = 0; y < IMG_HEIGHT; y++) begin
            for (int x = 0; x < IMG_WIDTH; x++) begin
                @(posedge clk);
                DE = 1;
                x_pixel = x;

                // 특정 좌표에서만 어두운 픽셀 주입
                if (y == TEST_Y_COORD && x == TEST_X_COORD) begin
                    pixel_in_888 = TEST_PIXEL_VAL;
                end else begin
                    pixel_in_888 = BG_PIXEL_VAL;
                end
            end
            @(posedge clk);
            DE = 0; // 라인 사이 공백
        end

        // --- 모든 픽셀 주입 후 ---
        @(posedge clk);
        DE = 0;
        
        $display("INFO: All pixels have been sent.");
        
        // DUT의 파이프라인이 모두 비워질 때까지 충분히 대기
        // (가로 320픽셀 * 세로 15라인) 정도면 매우 충분함
        repeat (DATA_DEPTH * KERNEL_SIZE) @(posedge clk); 

        // --- 최종 결과 검증 ---
        if (error_count == 0) begin
            // 15x15 커널이므로, 최소값은 총 225번 검출되어야 함
            if (test_min_count == KERNEL_SIZE * KERNEL_SIZE) begin
                 $display("=========================================================");
                 $display("==                 TEST PASSED                         ==");
                 $display("== Correctly detected the minimum value %0d times. ==", test_min_count);
                 $display("=========================================================");
            end else begin
                 $display("=========================================================");
                 $display("==        TEST FAILED: Incorrect detection count!      ==");
                 $display("== Expected: %0d, Actual: %0d                      ==", KERNEL_SIZE * KERNEL_SIZE, test_min_count);
                 $display("=========================================================");
            end
        end else begin
            $display("=========================================================");
            $display("==         TEST FAILED (%0d unexpected values)         ==", error_count);
            $display("=========================================================");
        end

        $finish;
    end

    //================================================================
    // 3. 응답 검증기 (Checker) - 훨씬 간단해짐
    //================================================================
    always @(posedge clk) begin
        if (rst) begin
            // 리셋 시 카운터 초기화
            test_min_count <= 0;
        end else if (DE_out) begin
            // 출력이 'FF' 또는 '10'이 아니면 에러
            if (dark_channel_out != EXPECTED_BG && dark_channel_out != EXPECTED_TEST) begin
                $error("Checker: Received unexpected value! Time: %0t, Output: %h", $time, dark_channel_out);
                error_count++;
            end

            // 출력이 예상된 최소값이면 카운트 증가
            if (dark_channel_out == EXPECTED_TEST) begin
                test_min_count <= test_min_count + 1;
            end
        end
    end

endmodule


// 픽셀 데이터 생성 로직
always @(posedge clk) begin
    if (reset) begin
        // 리셋 상태
        x_pos <= 0;
        y_pos <= 0;
        de <= 0;
        r_in <= 0; g_in <= 0; b_in <= 0;
    end else begin
        // VGA 타이밍에 맞춰 좌표 계산 (실제로는 h_sync, v_sync 기반으로 더 정교하게)
        if (x_pos < 640 - 1) begin
            x_pos <= x_pos + 1;
        end else begin
            x_pos <= 0;
            y_pos <= y_pos + 1;
        end

        // 유효 픽셀 구간(DE) 설정
        if (x_pos >= 0 && x_pos < 640 && y_pos >= 0 && y_pos < 480) begin
            de <= 1;
        end else begin
            de <= 0;
        end

        // "가짜 이미지" 데이터 생성
        if (de) begin
            // 이미지 중앙 (300, 200) 근처에 3x3 크기의 어두운 점 생성
            if (x_pos >= 300 && x_pos < 303 && y_pos >= 200 && y_pos < 203) begin
                r_in <= 8'h10;
                g_in <= 8'h10;
                b_in <= 8'h10;
            end else begin
                // 나머지 배경은 회색
                r_in <= 8'h80;
                g_in <= 8'h80;
                b_in <= 8'h80;
            end
        end else begin
            r_in <= 0; g_in <= 0; b_in <= 0;
        end
    end
end