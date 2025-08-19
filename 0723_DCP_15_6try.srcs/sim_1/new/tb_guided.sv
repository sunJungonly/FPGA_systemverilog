`timescale 1ns / 1ps

module tb_guided;


//❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗window sum cal❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗

    // parameter DATA_WIDTH = 24;
    // parameter WINDOW_SIZE = 15;
    // parameter IMAGE_WIDTH = 320;
    // parameter IMAGE_HEIGHT = 240;

    // logic clk, rst;
    // logic pclk;
    // logic h_sync, v_sync, DE;
    // logic [9:0] x_pixel;
    // logic [9:0] y_pixel;
    // logic [DATA_WIDTH-1:0] pixel_in;

    // logic [DATA_WIDTH + $clog2(WINDOW_SIZE*WINDOW_SIZE)-1:0] sum_out;
    // logic [DATA_WIDTH*2 + $clog2(WINDOW_SIZE*WINDOW_SIZE)-1:0] sum_sq_out;
    // logic valid_out;

    // logic [DATA_WIDTH - 1:0] matrix_p[0:15-1][0:15-1];

    // logic [7:0] min_val_out;
    // logic DE_out;
    // logic [8:0] x_pixel_out;

    // logic [23:0] dark_channel_out;
    // logic h_sync_out, v_sync_out;
    
    // initial begin
    //     clk = 0;
    //     forever #4 clk = ~clk;
    // end

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

    // dark_channel asd(
    //     .clk(clk),
    //     .pclk(pclk),
    //     .rst(rst),
    //     .pixel_in_888(pixel_in),
    //     .DE(DE),
    //     .h_sync         (h_sync),
    //     .v_sync         (v_sync),
    //     .x_pixel(x_pixel),
    //     .y_pixel(y_pixel),
    //     .dark_channel_out(dark_channel_out),
    //     .DE_out(DE_out),
    //     .h_sync_out         (h_sync_out),
    //     .v_sync_out         (v_sync_out),
    //     .x_pixel_out(x_pixel_out)
    // );

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

    // initial begin
    //     clk = 0;
    //     rst = 1;
    //     pixel_in = 1;
    //     @(posedge clk);
    //     @(posedge clk);
    //     rst = 0;

    //     // Wait until DE is active and feed pixels
    //     forever begin
    //         @(posedge clk);
    //         if (DE)
    //             // pixel_in <= 24'h999798;
    //             // pixel_in <= 24'h000001;
    //             pixel_in <= x_pixel * 1000 + y_pixel;
    //         else
    //             pixel_in <= 0;
    //     end
    // end

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
    
    // logic signed [19:0]                       a_k_out;
    // logic signed [DATA_WIDTH+5:0]             b_k_out;
    // logic                                     valid_out;

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


//❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗GUIDED FILTER❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗❗


    logic clk;
    logic rst;
    logic DE;
    logic h_sync;
    logic v_sync;
    logic pclk;
    logic [9:0] x_pixel;
    logic [9:0] y_pixel;
    logic [23:0] guide_pixel_in;
    logic [8:0] input_pixel_in;
    logic [8:0] q_i, q_out;
    logic [8:0] red_port, green_port, blue_port;

    parameter DATA_WIDTH = 24;
    parameter WINDOW_SIZE = 15;
    parameter IMAGE_WIDTH = 320;
    parameter IMAGE_HEIGHT = 240;

    logic DE_out;

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

    // guided_filter_top #(
    //     .DATA_WIDTH(24),
    //     .WINDOW_SIZE(15)
    // )dut(
    //     .clk(clk),
    //     .rst(rst),
    //     .x_pixel(x_pixel),
    //     .y_pixel(y_pixel),
    //     .DE(DE),
    //     .guide_pixel_in(guide_pixel_in), // 원본 이미지
    //     .input_pixel_in(input_pixel_in), // 전송맵
    //     .DE_out(DE_out),
    //     .q_i(q_i)
    // );


fog_removal_top dut(
    .clk(clk),
    .pclk(pclk),
    .rst(rst),
    .red_port(red_port),
    .green_port(green_port),
    .blue_port(blue_port),
    .h_sync(h_sync),
    .v_sync(v_sync),
    .DE(DE),
    .x_pixel(x_pixel),
    .y_pixel(y_pixel),
    .q_out(q_out)
);

    initial begin
        clk = 0;
        rst = 1;
        // guide_pixel_in = 0;
        // input_pixel_in = 0;
        #10 rst = 0;

        forever begin
            @(posedge clk);
            if (DE) begin
                // guide_pixel_in <= x_pixel * 1000 + y_pixel;
                // input_pixel_in <= y_pixel;
                red_port <= 512 + x_pixel;
                green_port <= 512 + x_pixel + y_pixel;
                blue_port <= 512 + y_pixel;
            end
            else begin
                // guide_pixel_in <= 0;
                // input_pixel_in <= 0;
                red_port <= 0;
                green_port <= 0;
                blue_port <= 0;
            end
        end
    end


endmodule
