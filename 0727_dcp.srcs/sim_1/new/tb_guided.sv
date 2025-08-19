`timescale 1ns / 1ps

module tb_guided;

//     // ------------------------------------------------------------
//     // Parameters (frame size matching your image spec)
//     // ------------------------------------------------------------
//     parameter IMAGE_WIDTH  = 320;
//     parameter IMAGE_HEIGHT = 240;

//     // ------------------------------------------------------------
//     // DUT IO
//     // ------------------------------------------------------------
//     logic        clk;
//     logic        rst;
//     logic [8:0]  x_pixel;
//     logic [7:0]  y_pixel;
//     logic        DE;
//     logic [23:0] guide_pixel_in;
//     logic [7:0]  input_pixel_in;
//     logic [7:0]  q_i;

//     // ------------------------------------------------------------
//     // Clock generation
//     // ------------------------------------------------------------
//     always #4 clk = ~clk;  // 125MHz clock

//     // ------------------------------------------------------------
//     // DUT Instance
//     // ------------------------------------------------------------
//     guided_filter_top #(
//         .DATA_WIDTH(24),
//         .WINDOW_SIZE(15)
//     ) dut (
//         .clk(clk),
//         .rst(rst),
//         .x_pixel(x_pixel),
//         .y_pixel(y_pixel),
//         .DE(DE),
//         .guide_pixel_in(guide_pixel_in),
//         .input_pixel_in(input_pixel_in),
//         .q_i(q_i)
//     );

//     // ------------------------------------------------------------
//     // Initial setup
//     // ------------------------------------------------------------
//     initial begin
//         clk = 0;
//         rst = 1;
//         DE  = 0;
//         x_pixel = 0;
//         y_pixel = 0;
//         guide_pixel_in = 0;
//         input_pixel_in = 0;

//         #20 rst = 0;

//         // Wait a few clocks after reset
//         repeat (5) @(posedge clk);

//         // Feed test frame
//         feed_frame();

//         // Wait for final output
//         #1000;

//         $finish;
//     end

//     // ------------------------------------------------------------
//     // Task: Feed one test frame
//     // ------------------------------------------------------------
//     task automatic feed_frame;
//         for (int y = 0; y < IMAGE_HEIGHT; y++) begin
//             for (int x = 0; x < IMAGE_WIDTH; x++) begin
//                 @(posedge clk);
//                 x_pixel        <= x;
//                 y_pixel        <= y;
//                 DE             <= 1;
//                 guide_pixel_in <= {8'h20 + x[3:0], 8'h40 + y[3:0], 8'h60}; // Simple RGB pattern
//                 input_pixel_in <= x[7:0] + y[7:0]; // Gradient input
//             end
//         end
//         @(posedge clk);
//         DE <= 0;
//     endtask

//     // ------------------------------------------------------------
//     // Monitor output
//     // ------------------------------------------------------------
//     always_ff @(posedge clk) begin
//         if (DE)
//             $display("X:%0d Y:%0d G_in:%h I_in:%h --> q_i:%h", x_pixel, y_pixel, guide_pixel_in, input_pixel_in, q_i);
//     end

//❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗linebufferDCP❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗


    // // --- DUT 파라미터 ---
    // localparam IMAGE_WIDTH = 320;
    // localparam IMAGE_HEIGHT = 240;
    // localparam NUM_ROWS = 15;
    // // pixel_in 값을 담기 위해 DATA_WIDTH를 충분히 크게 설정
    // // 320*1000 + 240 = 320240 이므로, 19비트면 충분 (2^19 = 524288)
    // localparam DATA_WIDTH = 24; 
    // localparam KERNEL_SIZE = 15; 

    // // --- 테스트벤치 신호 ---
    // logic clk;
    // logic rst;
    // logic [DATA_WIDTH-1:0] pixel_in;
    // logic DE;
    // logic [8:0] x_pixel, x_pixel_out;
    // logic [8:0] y_pixel;
    // logic DE_out;

    // logic [DATA_WIDTH - 1:0] matrix_p[0:KERNEL_SIZE-1][0:KERNEL_SIZE-1];
    // // DUT 출력 와이어
    // logic [DATA_WIDTH-1:0] row_data_out [NUM_ROWS-1:0];

    //     logic test_passed;
    // // --- DUT 인스턴스화 ---

    // VGA_Controller u_vga (
    //     .clk(clk),
    //     .reset(rst),
    //     .rclk(),        // unused
    //     .h_sync(h_sync),
    //     .v_sync(v_sync),
    //     .x_pixel(x_pixel),
    //     .y_pixel(y_pixel),
    //     .DE(DE),
    //     .pclk(pclk)
    // );

    // matrix_generate_15X15 #(
    //     .DATA_WIDTH(24),
    //     .DATA_DEPTH(320),
    //     .KERNEL_SIZE(15)
    // ) u_matrix(
    //     .clk(clk),
    //     .rst(rst),
    //     .DE(DE),
    //     .x_pixel(x_pixel),
    //     .pixel_in(pixel_in),
    //     .DE_out(DE_out),
    //     .x_pixel_out(x_pixel_out),
    //     .matrix_p(matrix_p)
    // );

    // // --- 1. Clock 생성 ---
    // initial begin
    //     clk = 0;
    //     forever #4 clk = ~clk; // 100MHz
    // end

    // // --- 3. 픽셀 입력 생성기 ---
    // // 요청하신 대로 pixel_in = x*1000 + y
    // always @(posedge clk) begin
    //     if (DE) begin
    //         pixel_in <= x_pixel * 1000 + y_pixel;
    //     end else begin
    //         pixel_in <= '0;
    //     end
    // end

    // // --- 4. 테스트 시퀀스 및 검증 ---
    // initial begin
    //     // --- 초기화 ---
    //     rst = 1;
    //     $display("T=%0t: [INFO] Simulation Started. Reset is ON.", $time);
    //     repeat(5) @(posedge clk);
    //     rst = 0;
    //     @(posedge clk);
    //     $display("T=%0t: [INFO] Reset is OFF. Starting pixel stream.", $time);

    //     // --- 특정 좌표에서 멈춰서 값 확인 ---
    //     // 윈도우가 완전히 유효해지는 첫 시점: y = 14, x = 0
    //     // (라인 버퍼 RAM의 읽기 지연이 1클럭이라고 가정)
    //     wait(y_pixel == (NUM_ROWS - 1) && x_pixel == 0);
    //     @(posedge clk); // 데이터가 안정될 때까지 한 클럭 더 대기
        
    //     $display("------------------------------------------------------------------");
    //     $display("T=%0t: [CHECK] At coordinate (x=%0d, y=%0d)", $time, x_pixel, y_pixel);
        
    //     test_passed = 1'b1;
    //     for (int i = 0; i < NUM_ROWS; i = i + 1) begin
    //         logic [DATA_WIDTH-1:0] expected_val;
    //         logic [7:0] expected_y;
            
    //         // 예상되는 y 좌표 계산 (현재 y부터 위로 i칸)
    //         expected_y = y_pixel - i;
    //         // 예상되는 픽셀 값 계산
    //         expected_val = x_pixel * 1000 + expected_y;

    //         $display("  - row_data_out[%2d]: Expected val for (x=%d, y=%d) -> %d. Got: %d", 
    //                  i, x_pixel, expected_y, expected_val, row_data_out[i]);
            
    //         if (row_data_out[i] !== expected_val) begin
    //             $error("    -> MISMATCH! Row %2d failed.", i);
    //             test_passed = 1'b0;
    //         end
    //     end
        
    //     if (test_passed) begin
    //         $display("[RESULT] PASS: All rows have correct delayed values at (x=%d, y=%d).", x_pixel, y_pixel);
    //     end else begin
    //         $error("[RESULT] FAIL: Mismatch detected.");
    //     end
    //     $display("------------------------------------------------------------------");

    //     // 다른 좌표에서도 확인 (예: x=10)
    //     wait(x_pixel == 10);
    //     @(posedge clk);
        
    //     $display("T=%0t: [CHECK] At coordinate (x=%0d, y=%0d)", $time, x_pixel, y_pixel);
    //     // ... (위와 동일한 검증 로직 반복) ...

    //     repeat(100) @(posedge clk);
    //     $finish;
    // end

//❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗window sum cal❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗

    parameter DATA_WIDTH = 24;
    parameter WINDOW_SIZE = 15;
    parameter IMAGE_WIDTH = 320;
    parameter IMAGE_HEIGHT = 240;

    logic clk, rst;
    logic pclk;
    logic h_sync, v_sync, DE;
    logic [9:0] x_pixel;
    logic [9:0] y_pixel;
    logic [DATA_WIDTH-1:0] pixel_in;

    logic [DATA_WIDTH + $clog2(WINDOW_SIZE*WINDOW_SIZE)-1:0] sum_out;
    logic [DATA_WIDTH*2 + $clog2(WINDOW_SIZE*WINDOW_SIZE)-1:0] sum_sq_out;
    logic valid_out;

    logic [DATA_WIDTH - 1:0] matrix_p[0:15-1][0:15-1];

    logic [7:0] min_val_out;
    logic DE_out;
    logic [8:0] x_pixel_out;

    logic [7:0] dark_channel_out;
    logic h_sync_out, v_sync_out;
    
    initial begin
        clk = 0;
        forever #4 clk = ~clk;
    end

    VGA_Controller u_vga (
        .clk(clk),
        .reset(rst),
        .rclk(),        // unused
        .h_sync(h_sync),
        .v_sync(v_sync),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .DE(DE),
        .pclk(pclk)
    );

    // matrix_generate_15X15 #(
    //     .DATA_WIDTH(24),
    //     .DATA_DEPTH(320),
    //     .KERNEL_SIZE(15)
    // ) u_matrix(
    //     .clk(clk),
    //     .rst(rst),
    //     .DE(DE),
    //     .h_sync         (h_sync),
    //     .v_sync         (v_sync),
    //     .x_pixel(x_pixel),
    //     .y_pixel    (y_pixel),
    //     .pixel_in(pixel_in),
    //     .DE_out(DE_out),
    //     .h_sync_out         (),
    //     .v_sync_out         (),
    //     .x_pixel_out(x_pixel_out),
    //     .matrix_p(matrix_p)
    // );

    dark_channel #(
        .DATA_DEPTH(640),
        .DATA_WIDTH(8)
    ) asd(
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

    // window_sum_calculator #(
    //     .IMAGE_WIDTH(320),
    //     .IMAGE_HEIGHT(240),
    //     .WINDOW_SIZE(15),
    //     .DATA_WIDTH(24)
    // ) dut (
    //     .clk(clk),
    //     .rst(rst),
    //     .pixel_in(pixel_in),
    //     .DE(DE),
    //     .x_pixel(x_pixel),
    //     .y_pixel(y_pixel),
    //     .sum_out(sum_out),
    //     .sum_sq_out(sum_sq_out),
    //     .valid_out(valid_out)
    // );

    // block_min #(
    //     .DATA_DEPTH(320),
    //     .DATA_WIDTH(24),
    //     .KERNEL_SIZE(15)
    // ) dee(
    //     .clk(clk),
    //     .rst(rst),
    //     .DE(DE),
    //     .x_pixel(x_pixel),
    //     .pixel_in(pixel_in),
    //     .min_val_out(min_val_out),
    //     .DE_out(DE_out),
    //     .x_pixel_out(x_pixel_out)
    // );

    // Simulation image memory

    initial begin
        clk = 0;
        rst = 1;
        pixel_in = 1;
        @(posedge clk);
        @(posedge clk);
        rst = 0;

        // Wait until DE is active and feed pixels
        forever begin
            @(posedge clk);
            if (DE)
                pixel_in <= 24'h999798;
            else
                pixel_in <= 0;
        end
    end

    //❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗AB_CAL❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗

    
    // // DUT 파라미터와 동일하게 설정
    // localparam WINDOW_SIZE      = 15;
    // localparam DATA_WIDTH       = 24;
    // localparam SUM_I_WIDTH      = 32;
    // localparam SUM_II_WIDTH     = 56;
    // localparam SUM_P_WIDTH      = 16;
    // localparam SUM_IP_WIDTH     = 40;
    // localparam DIVIDER_LATENCY  = 116; // DUT의 지연 시간과 반드시 일치시켜야 함

    // // 테스트벤치 내부 신호
    // logic                         clk;
    // logic                         rst;
    // logic                         valid_in;
    // logic [SUM_I_WIDTH-1:0]       sum_i;
    // logic [SUM_II_WIDTH-1:0]      sum_ii;
    // logic [SUM_P_WIDTH-1:0]       sum_p;
    // logic [SUM_IP_WIDTH-1:0]      sum_ip;
    
    // wire signed [19:0]                       a_k_out;
    // wire signed [DATA_WIDTH+5:0]             b_k_out;
    // wire                                     valid_out;

    // // DUT(Design Under Test) 인스턴스화
    // AB_Calculator #(
    //     .WINDOW_SIZE      (WINDOW_SIZE),
    //     .DATA_WIDTH       (DATA_WIDTH),
    //     .SUM_I_WIDTH      (SUM_I_WIDTH),
    //     .SUM_II_WIDTH     (SUM_II_WIDTH),
    //     .SUM_P_WIDTH      (SUM_P_WIDTH),
    //     .SUM_IP_WIDTH     (SUM_IP_WIDTH)
    // ) uut (
    //     .clk        (clk),
    //     .rst        (rst),
    //     .valid_in   (valid_in),
    //     .sum_i      (sum_i),
    //     .sum_ii     (sum_ii),
    //     .sum_p      (sum_p),
    //     .sum_ip     (sum_ip),
    //     .a_k_out    (a_k_out),
    //     .b_k_out    (b_k_out),
    //     .valid_out  (valid_out)
    // );


    // // 1. Clock 생성
    // initial begin
    //     clk = 0;
    //     forever #5 clk = ~clk; // 10ns 주기, 100MHz 클럭
    // end

    // // 2. Reset 및 테스트 시퀀스
    // initial begin
    //     // --- 초기화 ---
    //     rst = 1;
    //     valid_in = 0;
    //     sum_i = '0;
    //     sum_ii = '0;
    //     sum_p = '0;
    //     sum_ip = '0;
    //     repeat(5) @(posedge clk);
    //     rst = 0;
    //     @(posedge clk);
    //     $display("-------------------------------------------------");
    //     $display("INFO: Reset de-asserted. Starting test sequence.");
    //     $display("-------------------------------------------------");

    //     // --- 테스트 케이스 1: 기본 값 ---
    //     run_test_case(1, 22500, 3800000, 11250, 1900000);

    //     // --- 테스트 케이스 2: a_k가 1에 가까운 값 ---
    //     run_test_case(2, 30000, 5000000, 30000, 5000000);

    //     // --- 테스트 케이스 3: 분모가 0에 가까운 경우 (EPSILON 테스트) ---
    //     run_test_case(3, 225*10, 225*100, 225*20, 225*200);

    //     // --- 테스트 케이스 4: 연속 데이터 입력 (Back-to-back) ---
    //     $display("\nINFO: Starting back-to-back transaction test.");
    //     // 두 개의 테스트 케이스를 연달아 입력
    //     fork
    //         begin
    //             apply_stimulus(40000, 7000000, 20000, 3500000);
    //         end
    //         begin
    //             @(posedge clk); // 한 클럭 뒤에 다음 데이터 입력
    //             apply_stimulus(40005, 7000005, 20005, 3500005);
    //         end
    //     join

    //     // 시뮬레이션 종료 전까지 충분한 시간 대기
    //     repeat(DIVIDER_LATENCY + 20) @(posedge clk);
    //     $display("-------------------------------------------------");
    //     $display("INFO: Test sequence finished.");
    //     $display("-------------------------------------------------");
    //     $finish;
    // end

    // // 3. 출력 모니터링
    // // valid_out이 1일 때 실제 출력과 예상 출력을 비교
    // always @(posedge clk) begin
    //     if (valid_out) begin
    //         // 이 블록은 실제 검증 로직에서 채워져야 합니다.
    //         // 여기서는 단순히 출력 값을 표시합니다.
    //         $display("T=%0t: [OUTPUT] valid_out Asserted!", $time);
    //         $display("  -> a_k_out = %d (0x%h)", a_k_out, a_k_out);
    //         $display("  -> b_k_out = %d (0x%h)", b_k_out, b_k_out);
    //     end
    // end

    // // ----------------- TASKS AND FUNCTIONS -----------------

    // // 자극(Stimulus) 인가 태스크
    // task apply_stimulus(
    //     input [SUM_I_WIDTH-1:0]  s_i,
    //     input [SUM_II_WIDTH-1:0] s_ii,
    //     input [SUM_P_WIDTH-1:0]  s_p,
    //     input [SUM_IP_WIDTH-1:0] s_ip
    // );
    //     @(posedge clk);
    //     valid_in <= 1'b1;
    //     sum_i    <= s_i;
    //     sum_ii   <= s_ii;
    //     sum_p    <= s_p;
    //     sum_ip   <= s_ip;
    //     $display("T=%0t: [INPUT] valid_in Asserted with new data.", $time);
    //     @(posedge clk);
    //     valid_in <= 1'b0;
    // endtask

    // // 전체 테스트 케이스 실행 태스크
    // task run_test_case(
    //     input int                case_num,
    //     input [SUM_I_WIDTH-1:0]  s_i,
    //     input [SUM_II_WIDTH-1:0] s_ii,
    //     input [SUM_P_WIDTH-1:0]  s_p,
    //     input [SUM_IP_WIDTH-1:0] s_ip
    // );
    //     logic signed [19:0]                       expected_ak;
    //     logic signed [DATA_WIDTH+5:0]             expected_bk;

    //     $display("\n--- Test Case %0d ---", case_num);
        
    //     // 1. 예상 결과 계산 (Golden Model)
    //     calculate_expected(s_i, s_ii, s_p, s_ip, expected_ak, expected_bk);

    //     // 2. 입력 인가
    //     apply_stimulus(s_i, s_ii, s_p, s_ip);

    //     // 3. 결과 대기 및 확인
    //     // DUT의 valid_in 처리 파이프라인(2클럭) + Divider Latency
    //     // 총 지연 시간 = 2 + DIVIDER_LATENCY
    //     repeat(2 + DIVIDER_LATENCY) @(posedge clk); 

    //     // 다음 클럭의 상승 엣지에서 valid_out이 1이 되어야 함
    //     @(posedge clk);
    //     if (valid_out) begin
    //         $display("T=%0t: [CHECK] valid_out is high as expected.", $time);
    //         // a_k 결과 확인
    //         if (a_k_out == expected_ak) begin
    //             $display("  -> a_k: PASS (Expected: %d, Got: %d)", expected_ak, a_k_out);
    //         end else begin
    //             $error("  -> a_k: FAIL (Expected: %d, Got: %d)", expected_ak, a_k_out);
    //         end
    //         // b_k 결과 확인
    //         if (b_k_out == expected_bk) begin
    //             $display("  -> b_k: PASS (Expected: %d, Got: %d)", expected_bk, b_k_out);
    //         end else begin
    //             $error("  -> b_k: FAIL (Expected: %d, Got: %d)", expected_bk, b_k_out);
    //         end
    //     end else begin
    //         $error("T=%0t: [CHECK] valid_out is LOW, but was expected to be HIGH.", $time);
    //     end
    //     @(posedge clk);
    // endtask

    // // 예상 결과를 계산하는 함수 (DUT의 로직을 정확히 모방)
    // function void calculate_expected(
    //     input  [SUM_I_WIDTH-1:0]       f_sum_i,
    //     input  [SUM_II_WIDTH-1:0]      f_sum_ii,
    //     input  [SUM_P_WIDTH-1:0]       f_sum_p,
    //     input  [SUM_IP_WIDTH-1:0]      f_sum_ip,
    //     output logic signed [19:0]                       f_ak,
    //     output logic signed [DATA_WIDTH+5:0]             f_bk
    // );
    //     // DUT 내부 파라미터와 동일하게 사용
    //     localparam N = WINDOW_SIZE * WINDOW_SIZE;
    //     localparam AK_FRAC_BITS = 16;
    //     localparam signed [47:0] EPSILON = 1;
        
    //     // 중간 계산을 위한 변수들
    //     logic signed [63:0] var_num, cov_num;
    //     logic signed [63:0] dividend_ak;
    //     logic signed [47:0] divisor_ak;
    //     logic signed [63:0] b_k_num;
        
    //     // DUT의 파이프라인과 동일한 계산 수행
    //     var_num = $signed(f_sum_ii * N) - $signed(f_sum_i * f_sum_i);
    //     cov_num = $signed(f_sum_ip * N) - $signed(f_sum_i * f_sum_p);
        
    //     // a_k 계산
    //     dividend_ak = cov_num <<< AK_FRAC_BITS;
    //     divisor_ak  = var_num + EPSILON;
    //     // SystemVerilog의 정수 나눗셈으로 Divider IP 동작 모방
    //     f_ak = dividend_ak / divisor_ak;
        
    //     // b_k 계산
    //     b_k_num = ($signed(f_sum_p) <<< AK_FRAC_BITS) - (f_ak * $signed(f_sum_i));
    //     f_bk = b_k_num >>> ($clog2(N) + AK_FRAC_BITS);
    // endfunction


  //❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗AB_CAL❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗




//     // --- 파라미터 ---
//     // IP의 지연 시간을 알아야 언제 출력을 확인할지 알 수 있습니다.
//     localparam DIVIDER_LATENCY = 116; 
    
//     // --- 테스트벤치 신호 (레지스터 및 와이어) ---
//     logic        clk;
//     logic        rst;

//     // DUT 입력 신호 (logic으로 선언하여 값 할당)
//     logic [63:0] dividend_in_tdata;
//     logic        dividend_in_tvalid;
//     logic [47:0] divisor_in_tdata;
//     logic        divisor_in_tvalid;

//     // DUT 출력 신호 (wire로 선언하여 DUT 출력 연결)
//     wire         dividend_in_tready;
//     wire         divisor_in_tready;
//     wire [111:0] quotient_out_tdata;
//     wire         quotient_out_tvalid;
//     wire [0:0]   quotient_out_tuser;


//     // --- DUT (Design Under Test) 인스턴스화 ---
//     design_1 uut (
//         .sys_clock(clk),
//         .reset(rst),
        
//         .dividend_in_tdata(dividend_in_tdata),
//         .dividend_in_tvalid(dividend_in_tvalid),
//         .dividend_in_tready(dividend_in_tready),

//         .divisor_in_tdata($signed(divisor_in_tdata)),
//         .divisor_in_tvalid(divisor_in_tvalid),
//         .divisor_in_tready(divisor_in_tready),
        
//         .quotient_out_tdata(quotient_out_tdata),
//         .quotient_out_tvalid(quotient_out_tvalid),
//         .quotient_out_tuser(quotient_out_tuser)
//     );

//     // --- 1. Clock 생성 ---
//     initial begin
//         clk = 0;
//         forever #5 clk = ~clk; // 10ns 주기 (100MHz)
//     end

//     // --- 2. 테스트 시퀀스 ---
//     initial begin
//         // --- 초기화 단계 ---
//         $display("T=%0t: [INFO] Simulation Started. Asserting Reset.", $time);
//         rst = 0;
//         dividend_in_tvalid = 0;
//         divisor_in_tvalid = 0;
//         dividend_in_tdata = 0;
//         divisor_in_tdata = 0;
        
//         // 리셋을 몇 클럭 동안 유지
//         repeat(5) @(posedge clk);
//         rst = 1;
//         @(posedge clk);
//         $display("T=%0t: [INFO] Reset De-asserted.", $time);
        
//         // --- 입력 값 설정 및 인가 ---
//         // 여기에 확인하고 싶은 값을 넣으세요.
// // initial 블록 내부
// dividend_in_tdata = 64'sd1000; // signed decimal
// divisor_in_tdata  = 48'sd25;   // signed decimal

//         // IP가 데이터를 받을 준비가 될 때까지 대기
//         wait(dividend_in_tready && divisor_in_tready);
//         @(posedge clk);

//         // tvalid를 1로 만들어 데이터가 유효함을 알림
//         $display("T=%0t: [INPUT] Driving data: dividend=%d, divisor=%d", $time, dividend_in_tdata, divisor_in_tdata);
//         dividend_in_tvalid = 1;
//         divisor_in_tvalid  = 1;
        
//         // 1 클럭 동안만 유효 신호를 유지
//         @(posedge clk);
//         dividend_in_tvalid = 0;
//         divisor_in_tvalid  = 0;

//         $display("T=%0t: [INFO] Input sent. Waiting for output...", $time);
        
//         // --- 결과 대기 ---
//         // IP의 지연 시간(latency)만큼 기다립니다.
//         repeat(DIVIDER_LATENCY) @(posedge clk);
        
//         $display("T=%0t: [INFO] Checking for output now.", $time);

//         // --- 결과 확인 ---
//         // 다음 클럭에 출력이 나올 것을 기대
//         @(posedge clk);
//         if (quotient_out_tvalid) begin
//             $display("--------------------------------------------------");
//             $display("SUCCESS: Valid output received!");
//             $display("  -> Dividend: %d", 64'd1000); // 확인을 위해 입력값 다시 표시
//             $display("  -> Divisor:  %d", 48'd25);
//             $display("  -> Quotient: %d (0x%h)", quotient_out_tdata, quotient_out_tdata);
//             $display("--------------------------------------------------");
            
//             // 예상 결과와 비교 (선택 사항)
//             if (quotient_out_tdata == 40) begin
//                 $display("  -> Verification: PASS (Expected: 40, Got: %d)", quotient_out_tdata);
//             end else begin
//                 $error("  -> Verification: FAIL (Expected: 40, Got: %d)", quotient_out_tdata);
//             end

//         end else begin
//             $error("FAILURE: Output was not valid after %0d cycles.", DIVIDER_LATENCY + 1);
//         end
        
//         // 시뮬레이션 종료
//         repeat(10) @(posedge clk);
//         $finish;
//     end
    
//     // (선택 사항) 모니터링을 위한 always 블록
//     always @(posedge clk) begin
//         if (quotient_out_tvalid) begin
//             $display("T=%0t: [MONITOR] quotient_out_tvalid is HIGH. Data = %d", $time, quotient_out_tdata);
//         end
//     end




endmodule
