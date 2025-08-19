`timescale 1ns / 1ps

module tb_airlightA();

    // --- 파라미터 정의 ---
    localparam IMAGE_WIDTH  = 320;
    localparam IMAGE_HEIGHT = 240;
    localparam DATA_WIDTH   = 8;

    // 테스트 시나리오 파라미터
    localparam logic [23:0] BG_PIXEL_VAL     = 24'hAAAAAA; // 배경 RGB 값
    localparam logic [7:0]  BG_DC_VAL        = 8'h10;      // 배경 Dark Channel 값

    localparam logic [23:0] TEST_PIXEL_VAL   = 24'h123456; // Airlight이 되어야 할 목표 RGB 값
    localparam logic [7:0]  TEST_DC_VAL      = 8'hF0;      // 프레임 내 유일한 최대 Dark Channel 값
    
    localparam int          TEST_X_COORD     = 150;        // 목표 픽셀의 X 좌표
    localparam int          TEST_Y_COORD     = 150;        // 목표 픽셀의 Y 좌표

    // --- 신호 선언 ---
    logic clk;
    logic reset;

    // VGA 모듈 신호
    logic        vga_h_sync;
    logic        vga_v_sync;
    logic [8:0]  vga_x_pixel;
    logic [7:0]  vga_y_pixel;
    logic        vga_de;
    logic        vga_pclk;

    // DUT 입력 신호
    logic [23:0] dut_pixel_in;
    logic [DATA_WIDTH-1:0] dut_dark_channel_in;

    // DUT 출력 신호 (관찰 대상)
    logic [DATA_WIDTH-1:0] dut_airlight_r_out;
    logic [DATA_WIDTH-1:0] dut_airlight_g_out;
    logic [DATA_WIDTH-1:0] dut_airlight_b_out;
    logic        dut_airlight_done;
    
    //======================================================================
    // 1. 모듈 인스턴스화
    //======================================================================

    vga U_VGA_Generator (
        .clk    (clk),
        .reset  (reset),
        .h_sync (vga_h_sync),
        .v_sync (vga_v_sync),
        .x_pixel(vga_x_pixel),
        .y_pixel(vga_y_pixel),
        .DE     (vga_de),
        .pclk   (vga_pclk)
    );

    airlight_A #(
        .IMAGE_WIDTH (IMAGE_WIDTH),
        .IMAGE_HEIGHT(IMAGE_HEIGHT),
        .DATA_WIDTH  (DATA_WIDTH)
    ) U_DUT (
        .clk              (clk),
        .rst              (reset),
        .DE               (vga_de),
        .x_pixel          (vga_x_pixel[$clog2(IMAGE_WIDTH)-1:0]),
        .y_pixel          (vga_y_pixel),
        .pixel_in_888     (dut_pixel_in),
        .dark_channel_in  (dut_dark_channel_in),
        .airlight_r_out   (dut_airlight_r_out),
        .airlight_g_out   (dut_airlight_g_out),
        .airlight_b_out   (dut_airlight_b_out),
        .airlight_done    (dut_airlight_done)
    );

    //======================================================================
    // 2. 클럭 및 리셋 생성
    //======================================================================
    initial begin
        clk = 1;
        forever #5 clk = ~clk; // 100MHz 시스템 클럭
    end

    //======================================================================
    // 3. 자극 생성 (Stimulus Generator)
    //======================================================================
    initial begin
        // --- 리셋 구간 ---
        reset = 1;
        #100;
        reset = 0;
        $display("INFO: Reset released. Starting simulation for waveform analysis.");

        // --- 시뮬레이션 실행 ---
        // VGA가 1.5 프레임을 생성할 만큼 충분히 기다림
        // 1 프레임 = 400 * 263 pclk = 400 * 263 * 4 sys_clk = 420,800 clk
        // 첫 프레임이 끝나고 done 신호가 발생하는 것을 보려면 이정도 시간이 필요함.
        repeat(650_000) @(posedge clk);
        
        $display("INFO: Simulation finished. Please check the waveform.");
        $finish;
    end

    // --- VGA 타이밍에 맞춰 RGB 및 Dark Channel 데이터 생성 ---
    always_comb begin
        if (vga_de) begin
            if (vga_y_pixel == TEST_Y_COORD && vga_x_pixel == TEST_X_COORD) begin
                dut_pixel_in = TEST_PIXEL_VAL;
                dut_dark_channel_in = TEST_DC_VAL;
            end else begin
                dut_pixel_in = BG_PIXEL_VAL;
                dut_dark_channel_in = BG_DC_VAL;
            end
        end else begin
            dut_pixel_in = 24'hzzzzzz;
            dut_dark_channel_in = 8'hzz;
        end
    end

endmodule


//     // --- 파라미터 정의 ---
//     // DUT 및 VGA 파라미터
//     localparam IMAGE_WIDTH  = 320;
//     localparam IMAGE_HEIGHT = 240;
//     localparam DATA_WIDTH   = 8;

//     // 테스트 시나리오 파라미터
//     localparam logic [23:0] BG_PIXEL_VAL     = 24'hAAAAAA; // 배경 RGB 값
//     localparam logic [7:0]  BG_DC_VAL        = 8'h10;      // 배경 Dark Channel 값

//     localparam logic [23:0] TEST_PIXEL_VAL   = 24'h123456; // Airlight이 되어야 할 목표 RGB 값
//     localparam logic [7:0]  TEST_DC_VAL      = 8'hF0;      // 프레임 내 유일한 최대 Dark Channel 값
    
//     localparam int          TEST_X_COORD     = 150;        // 목표 픽셀의 X 좌표
//     localparam int          TEST_Y_COORD     = 150;        // 목표 픽셀의 Y 좌표
    
//     // 최종 기대 출력 값
//     localparam logic [7:0]  EXPECTED_A_R     = 8'h12;
//     localparam logic [7:0]  EXPECTED_A_G     = 8'h34;
//     localparam logic [7:0]  EXPECTED_A_B     = 8'h56;

//     // --- 신호 선언 ---
//     logic clk;
//     logic reset;

//     // VGA 모듈 신호
//     logic        vga_h_sync;
//     logic        vga_v_sync;
//     logic [8:0]  vga_x_pixel;
//     logic [7:0]  vga_y_pixel;
//     logic        vga_de;
//     logic        vga_pclk;

//     // DUT 입력 신호
//     logic [23:0] dut_pixel_in;
//     logic [DATA_WIDTH-1:0] dut_dark_channel_in;

//     // DUT 출력 신호
//     logic [DATA_WIDTH-1:0] dut_airlight_r_out;
//     logic [DATA_WIDTH-1:0] dut_airlight_g_out;
//     logic [DATA_WIDTH-1:0] dut_airlight_b_out;
//     logic        dut_airlight_done;
    
//     // 테스트벤치 내부 검증 변수
//     integer      error_count;
//     bit          done_received_flag;

//     //======================================================================
//     // 1. 모듈 인스턴스화
//     //======================================================================

//     // (1) VGA 타이밍 생성기 (제공된 코드 사용)
//     vga U_VGA_Generator (
//         .clk    (clk),
//         .reset  (reset),
//         .h_sync (vga_h_sync),
//         .v_sync (vga_v_sync),
//         .x_pixel(vga_x_pixel),
//         .y_pixel(vga_y_pixel),
//         .DE     (vga_de),
//         .pclk   (vga_pclk)
//     );

//     // (2) 검증 대상 DUT: airlight_A
//     airlight_A #(
//         .IMAGE_WIDTH (IMAGE_WIDTH),
//         .IMAGE_HEIGHT(IMAGE_HEIGHT),
//         .DATA_WIDTH  (DATA_WIDTH)
//     ) U_DUT (
//         .clk              (clk),
//         .rst              (reset),
//         .DE               (vga_de),
//         .x_pixel          (vga_x_pixel[$clog2(IMAGE_WIDTH)-1:0]), // 비트 수 맞춰 연결
//         .y_pixel          (vga_y_pixel),
//         .pixel_in_888     (dut_pixel_in),
//         .dark_channel_in  (dut_dark_channel_in),
//         .airlight_r_out   (dut_airlight_r_out),
//         .airlight_g_out   (dut_airlight_g_out),
//         .airlight_b_out   (dut_airlight_b_out),
//         .airlight_done    (dut_airlight_done)
//     );

//     //======================================================================
//     // 2. 클럭 및 리셋 생성
//     //======================================================================
//     initial begin
//         clk = 1;
//         forever #5 clk = ~clk; // 100MHz 시스템 클럭
//     end

//     initial begin
//         error_count = 0;
//         done_received_flag = 0;
//         reset = 1;
//         #100;
//         reset = 0;
//         $display("INFO: Reset released. Starting Airlight module test.");
//     end

//     //======================================================================
//     // 3. 자극 생성 (Stimulus Generator)
//     // - VGA 타이밍에 맞춰 RGB 및 Dark Channel 데이터 생성
//     //======================================================================
//     always_comb begin
//         if (vga_de) begin // VGA의 유효 데이터 구간에서만
//             // 테스트 좌표일 경우, 특별한 값을 주입
//             if (vga_y_pixel == TEST_Y_COORD && vga_x_pixel == TEST_X_COORD) begin
//                 dut_pixel_in = TEST_PIXEL_VAL;
//                 dut_dark_channel_in = TEST_DC_VAL;
//             end else begin
//                 // 그 외 모든 픽셀은 배경 값을 주입
//                 dut_pixel_in = BG_PIXEL_VAL;
//                 dut_dark_channel_in = BG_DC_VAL;
//             end
//         end else begin
//             // 블랭킹 구간에서는 'don't care'
//             dut_pixel_in = 24'hzzzzzz;
//             dut_dark_channel_in = 8'hzz;
//         end
//     end
    
//     //======================================================================
//     // 4. 응답 확인 (Checker)
//     // - 프레임 종료 후 airlight_done 신호와 출력 값을 확인
//     //======================================================================
//     always_ff @(posedge clk) begin
//         if (dut_airlight_done) begin
//             $display("INFO: 'airlight_done' signal received at time %0t.", $time);
//             done_received_flag = 1;

//             // 기대값과 실제 출력값 비교
//             if (dut_airlight_r_out != EXPECTED_A_R) begin
//                 $error("CHECKER: Mismatch! airlight_r_out is %h, expected %h", dut_airlight_r_out, EXPECTED_A_R);
//                 error_count = error_count + 1;
//             end
//             if (dut_airlight_g_out != EXPECTED_A_G) begin
//                 $error("CHECKER: Mismatch! airlight_g_out is %h, expected %h", dut_airlight_g_out, EXPECTED_A_G);
//                 error_count = error_count + 1;
//             end
//             if (dut_airlight_b_out != EXPECTED_A_B) begin
//                 $error("CHECKER: Mismatch! airlight_b_out is %h, expected %h", dut_airlight_b_out, EXPECTED_A_B);
//                 error_count = error_count + 1;
//             end
//         end
//     end

//     //======================================================================
//     // 5. 시뮬레이션 제어 및 종료
//     //======================================================================
//     initial begin
//         // VGA가 1.5 프레임을 생성할 만큼 충분히 기다림
//         // (1 프레임 = 400 * 263 pclk = 420,800 clk)
//         repeat(650_000) @(posedge clk);

//         // --- 최종 결과 검증 ---
//         if (error_count == 0 && done_received_flag) begin
//              $display("========================================");
//              $display("==            TEST PASSED             ==");
//              $display("========================================");
//         end else begin
//              $display("========================================");
//              $display("==            TEST FAILED             ==");
//              if (!done_received_flag) $display("== Reason: 'airlight_done' signal was never asserted.");
//              if (error_count > 0)     $display("== Reason: %0d data mismatches occurred.", error_count);
//              $display("========================================");
//         end

//         $finish;
//     end

// endmodule

// //======================================================================
// // ** 사용자 제공 VGA 모듈 (변경 없음) **
// // - 아래 모듈들을 별도의 파일로 저장하거나, 테스트벤치 파일에 함께 포함
// //======================================================================

// 
// module vga(...); ... endmodule
// module vga_Decoder(...); ... endmodule
// module pixel_clk_gen(...); ... endmodule
// module pixel_counter(...); ... endmodule
// module vga_decoder(...); ... endmodule
// 