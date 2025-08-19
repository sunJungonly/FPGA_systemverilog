`timescale 1ns / 1ps

module tb_shift_divider ();

    // 파라미터 선언
    localparam DATA_WIDTH = 8;
    localparam FRAC_BITS  = 8;
    localparam CLK_PERIOD = 10;  // 클럭 주기 10ns

    // 테스트벤치 내부 신호 선언
    logic                         clk;
    logic                         rst;

    logic        [DATA_WIDTH-1:0] dividend_in;
    logic                         dividend_valid;
    logic                         dividend_ready;

    logic        [DATA_WIDTH-1:0] divisor_in;
    logic                         divisor_valid;

    logic signed [DATA_WIDTH-1:0] quotient_integer_out;
    logic signed [DATA_WIDTH-1:0] quotient_fractional_out;
    logic signed [DATA_WIDTH-1:0] remainder_out;
    logic                         output_valid;

    // [중요] 아래 DUT는 수정된 최종 코드를 사용해야 합니다.
    // 모듈 이름이 다르다면 여기를 수정해주세요.
    shift_divider #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS (FRAC_BITS)
    ) DUT (
        .clk(clk),
        .rst(rst),
        .divided_in_tdata(dividend_in),
        .divided_in_tvalid(dividend_valid),
        .divided_in_tready(dividend_ready),
        .divisor_in_tdata(divisor_in),
        .divisor_in_tvalid(divisor_valid),
        .quotient_integer_out(quotient_integer_out),
        .quotient_fractional_out(quotient_fractional_out),
        .remainder_out_tdata(remainder_out),
        .quotient_out_tvalid(output_valid)
    );

    // 클럭 생성
    always #(CLK_PERIOD / 2) clk = ~clk;

    // 시뮬레이션 제어 로직
    initial begin
        // 초기화
        clk <= 0;
        rst <= 1;
        dividend_in <= 0;
        dividend_valid <= 0;
        divisor_in <= 0;
        divisor_valid <= 0;
        #20;
        rst <= 0;
        #5;

        // --- 테스트 케이스 1: 50 / 220 ---
        wait (dividend_ready);  // DUT가 준비될 때까지 대기
        @(posedge clk);
        dividend_in <= 50;
        dividend_valid <= 1;
        divisor_in <= 220;
        divisor_valid <= 1;

        @(posedge clk);
        dividend_valid <= 0;  // 입력은 한 클럭 동안만 유지
        divisor_valid  <= 0;

        // 연산이 완료될 때까지 대기
        wait (output_valid);
        @(posedge clk);  // 유효한 출력을 확인
        #20;

        // --- 테스트 케이스 2: -10 / 3 ---
        wait (dividend_ready);  // DUT가 준비될 때까지 대기
        @(posedge clk);
        dividend_in <= -10;
        dividend_valid <= 1;
        divisor_in <= 3;
        divisor_valid <= 1;

        @(posedge clk);
        dividend_valid <= 0;
        divisor_valid  <= 0;

        // 연산이 완료될 때까지 대기
        wait (output_valid);
        @(posedge clk);
        #20;

        // --- 테스트 케이스 3: -123 / -4 ---
        wait (dividend_ready);  // DUT가 준비될 때까지 대기
        @(posedge clk);
        dividend_in <= -123;
        dividend_valid <= 1;
        divisor_in <= -4;
        divisor_valid <= 1;

        @(posedge clk);
        dividend_valid <= 0;
        divisor_valid  <= 0;

        // 연산이 완료될 때까지 대기
        wait (output_valid);
        @(posedge clk);
        #50;

        $stop;
    end
endmodule
