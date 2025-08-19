`timescale 1ns / 1ps

module tb_shift_divider_pipelined;

    // --- 파라미터 정의 ---
    // fog_removal_cal 모듈에서 사용하는 값과 동일하게 설정
    localparam DATA_WIDTH = 16;
    localparam FRAC_BITS  = 8;
    // 파이프라인 지연 시간 (Latency)
    localparam LATENCY    = DATA_WIDTH + FRAC_BITS;

    // --- DUT 신호 ---
    logic                     clk;
    logic                     rst;
    logic [DATA_WIDTH-1:0]    divided_in_tdata;
    logic                     divided_in_tvalid;
    logic                     divided_in_tready;
    logic [DATA_WIDTH-1:0]    divisor_in_tdata;
    logic                     divisor_in_tvalid;
    logic [DATA_WIDTH-1:0]    quotient_integer_out;
    logic [FRAC_BITS-1:0]     quotient_fractional_out;
    logic [DATA_WIDTH-1:0]    remainder_out_tdata;
    logic                     quotient_out_tvalid;

    // --- DUT 인스턴스화 ---
    shift_divider_pipelined #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) dut (
        .clk(clk),
        .rst(rst),
        .divided_in_tdata(divided_in_tdata),
        .divided_in_tvalid(divided_in_tvalid),
        .divided_in_tready(divided_in_tready),
        .divisor_in_tdata(divisor_in_tdata),
        .divisor_in_tvalid(divisor_in_tvalid),
        .quotient_integer_out(quotient_integer_out),
        .quotient_fractional_out(quotient_fractional_out),
        .remainder_out_tdata(remainder_out_tdata),
        .quotient_out_tvalid(quotient_out_tvalid)
    );

    // --- 테스트 데이터 및 예상 결과 ---
    localparam NUM_TESTS = 5;
    logic signed [DATA_WIDTH-1:0] test_dividends [NUM_TESTS] = '{-40, 200, 0, -1, 100};
    logic        [7:0]          test_divisors  [NUM_TESTS] = '{97, 128, 100, 255, 26}; // t0값(26) 테스트 포함
    logic signed [DATA_WIDTH-1:0] expected_results [NUM_TESTS];
    integer                       test_idx;
    integer                       result_idx;

    // 예상 결과 미리 계산
    initial begin
        for (int i = 0; i < NUM_TESTS; i++) begin
            // Verilog의 실수 나눗셈을 이용해 예상값 계산
            real dividend_real = test_dividends[i];
            real divisor_real = test_divisors[i] / 255.0;
            if (divisor_real == 0) divisor_real = 1.0; // 0으로 나누기 방지
            expected_results[i] = $floor(dividend_real / divisor_real);
        end
    end

    // --- Clock 생성 ---
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // --- 테스트 시퀀스 ---
    initial begin
        // 초기화
        rst = 1;
        divided_in_tdata = 0;
        divided_in_tvalid = 0;
        divisor_in_tdata = 0;
        divisor_in_tvalid = 0;
        test_idx = 0;
        result_idx = 0;
        $display("=====================================================================");
        $display("Test Start: Pipelined Divider for Fog Removal");
        $display("DATA_WIDTH=%0d, FRAC_BITS=%0d, LATENCY=%0d", DATA_WIDTH, FRAC_BITS, LATENCY);
        $display("=====================================================================");
        repeat (2) @(posedge clk);
        rst = 0;
        
        // --- 데이터 입력 루프 (파이프라인 방식) ---
        // 매 클럭마다 새로운 데이터를 계속 입력
        while (test_idx < NUM_TESTS) begin
            @(posedge clk);
            if (dut.divided_in_tready) begin
                divided_in_tdata  <= test_dividends[test_idx];
                // 분모는 하위 8비트에만 값을 할당
                divisor_in_tdata  <= test_divisors[test_idx];
                divided_in_tvalid <= 1;
                divisor_in_tvalid <= 1;
                $display("[%0t] >> INPUT [%0d]: Dividend=%6d, Divisor_Ratio=%3d, Expected=%6d", 
                         $time, test_idx, test_dividends[test_idx], test_divisors[test_idx], expected_results[test_idx]);
                test_idx++;
            end
        end

        // 마지막 입력 후 valid 신호 내리기
        @(posedge clk);
        divided_in_tvalid <= 0;
        divisor_in_tvalid <= 0;

        // --- 결과 확인 루프 ---
        // 모든 결과가 나올 때까지 대기
        while (result_idx < NUM_TESTS) begin
            @(posedge clk);
            if (quotient_out_tvalid) begin
                logic signed [DATA_WIDTH-1:0] received_q = $signed(quotient_integer_out);
                logic signed [DATA_WIDTH-1:0] expected_q = expected_results[result_idx];

                if (received_q == expected_q) begin
                    $display("[%0t] << PASS  [%0d]: Received=%6d, Expected=%6d", 
                             $time, result_idx, received_q, expected_q);
                end else begin
                    // 오차 허용 (실수<->고정소수점 변환으로 1정도 차이날 수 있음)
                    if (received_q >= expected_q - 1 && received_q <= expected_q + 1) begin
                         $display("[%0t] << WARN  [%0d]: Received=%6d, Expected=%6d (Acceptable rounding error)", 
                                  $time, result_idx, received_q, expected_q);
                    end else begin
                        $error("[%0t] << FAIL  [%0d]: Received=%6d, Expected=%6d", 
                               $time, result_idx, received_q, expected_q);
                    end
                end
                result_idx++;
            end
        end

        repeat (5) @(posedge clk);
        $display("=====================================================================");
        $display("Test End");
        $display("=====================================================================");
        $stop;
    end
endmodule