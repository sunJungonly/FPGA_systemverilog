`timescale 1ns / 1ps
module shift_divider #(  // 18pclk 
    parameter DATA_WIDTH = 8,
    parameter FRAC_BITS  = 8
) (
    // ... 포트는 이전과 동일 ...
    input  logic                         clk,
    input  logic                         rst,
    input  logic signed [DATA_WIDTH-1:0] divided_in_tdata,
    input  logic                         divided_in_tvalid,
    output logic                         divided_in_tready,
    input  logic signed [DATA_WIDTH-1:0] divisor_in_tdata,
    input  logic                         divisor_in_tvalid,
    output logic signed [DATA_WIDTH-1:0] quotient_integer_out,    //분자/분모 = 몫의 정수부(음수의 경우 -1.38 => -2의 signed)
    output logic signed [ FRAC_BITS-1:0] quotient_fractional_out, //분자/분모 = 몫의 소수부(음수의 경우 -1.38 => 0.62의 signed)
    output logic signed [DATA_WIDTH-1:0] remainder_out_tdata,     //(분자 << FRAC_BITS)의 나머지 값
    output logic                         quotient_out_tvalid
);

    typedef enum logic [1:0] {
        STATE_IDLE,
        STATE_CALC,
        STATE_DONE
    } state_t;

    localparam FULL_WIDTH = DATA_WIDTH + FRAC_BITS;

    // --- 1. 순차 로직: 실제 레지스터(상태 저장) ---
    state_t current_state, next_state;
    logic sign_dividend, sign_divisor;
    logic signed [FULL_WIDTH-1:0] dividend_reg;
    logic [FULL_WIDTH-1:0] quotient_reg;
    logic [DATA_WIDTH-1:0] abs_divisor_reg;
    logic [DATA_WIDTH : 0] remainder_reg;
    logic [$clog2(FULL_WIDTH):0] bit_counter;


    // --- 2. 조합 로직: 다음 상태를 계산하기 위한 로직/와이어 ---
    // (이 부분은 'logic' 타입으로 선언되어 always_comb에서 계산됩니다)
    logic sign_dividend_next, sign_divisor_next;
    logic signed [FULL_WIDTH-1:0] dividend_reg_next;
    logic [FULL_WIDTH-1:0] quotient_reg_next;
    logic [DATA_WIDTH-1:0] abs_divisor_reg_next;
    logic [DATA_WIDTH : 0] remainder_reg_next;
    logic [$clog2(FULL_WIDTH):0] bit_counter_next;

    // --- 3. 조합 회로 블록 (always_comb) ---
    // "다음에 무엇을 할지" 모든 계산을 여기서 수행
    always_comb begin
        // 기본적으로 현재 값을 유지하도록 설정 (Latch 방지)
        next_state = current_state;
        sign_dividend_next = sign_dividend;
        sign_divisor_next = sign_divisor;
        dividend_reg_next = dividend_reg;
        quotient_reg_next = quotient_reg;
        abs_divisor_reg_next = abs_divisor_reg;
        remainder_reg_next = remainder_reg;
        bit_counter_next = bit_counter;

        divided_in_tready = 1'b0;
        quotient_out_tvalid = 1'b0;

        case (current_state)
            STATE_IDLE: begin
                divided_in_tready = 1'b1;
                if (divided_in_tvalid && divisor_in_tvalid) begin
                    logic [DATA_WIDTH-1:0] abs_dividend;
                    abs_dividend = divided_in_tdata[DATA_WIDTH-1] ? -divided_in_tdata : divided_in_tdata;

                    sign_dividend_next = divided_in_tdata[DATA_WIDTH-1];
                    sign_divisor_next = divisor_in_tdata[DATA_WIDTH-1];
                    dividend_reg_next = FULL_WIDTH'(abs_dividend) << FRAC_BITS;
                    abs_divisor_reg_next = divisor_in_tdata[DATA_WIDTH-1] ? -divisor_in_tdata : divisor_in_tdata;
                    quotient_reg_next = '0;
                    remainder_reg_next = '0;
                    bit_counter_next = FULL_WIDTH;
                    next_state = STATE_CALC;
                end
            end

            STATE_CALC: begin
                if (bit_counter == 0) begin
                    next_state = STATE_DONE;
                end else begin
                    logic [DATA_WIDTH:0] shifted_remainder;
                    logic [DATA_WIDTH:0] temp_sub;

                    shifted_remainder = {
                        remainder_reg[DATA_WIDTH-1:0],
                        dividend_reg[FULL_WIDTH-1]
                    };
                    temp_sub = shifted_remainder - abs_divisor_reg;

                    dividend_reg_next = dividend_reg << 1;
                    bit_counter_next = bit_counter - 1;

                    if (!temp_sub[DATA_WIDTH]) begin  // 뺄셈 결과 양수
                        remainder_reg_next = temp_sub;
                        quotient_reg_next  = (quotient_reg << 1) | 1'b1;
                    end else begin  // 뺄셈 결과 음수
                        remainder_reg_next = shifted_remainder;
                        quotient_reg_next  = (quotient_reg << 1) | 1'b0;
                    end
                    next_state = STATE_CALC; // 다음 사이클에도 계산 유지
                end
            end

            STATE_DONE: begin
                quotient_out_tvalid = 1'b1;
                next_state = STATE_IDLE;
            end
        endcase
    end

    // --- 4. 순차 회로 블록 (always_ff) ---
    // 클럭에 맞춰 조합 로직의 계산 결과를 레지스터에 저장만 함
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= STATE_IDLE;
            sign_dividend <= '0;
            sign_divisor <= '0;
            dividend_reg <= '0;
            quotient_reg <= '0;
            abs_divisor_reg <= '0;
            remainder_reg <= '0;
            bit_counter <= '0;
        end else begin
            current_state <= next_state;
            sign_dividend <= sign_dividend_next;
            sign_divisor <= sign_divisor_next;
            dividend_reg <= dividend_reg_next;
            quotient_reg <= quotient_reg_next;
            abs_divisor_reg <= abs_divisor_reg_next;
            remainder_reg <= remainder_reg_next;
            bit_counter <= bit_counter_next;
        end
    end

    // --- 5. 최종 출력 로직 (조합) ---
    logic [FULL_WIDTH-1:0] signed_quotient;
    assign signed_quotient = (sign_dividend ^ sign_divisor) ? -quotient_reg : quotient_reg;
    assign quotient_integer_out = signed_quotient[FULL_WIDTH-1 : FRAC_BITS];
    assign quotient_fractional_out = signed_quotient[FRAC_BITS-1 : 0];
    assign remainder_out_tdata = sign_dividend ? -remainder_reg[DATA_WIDTH-1:0] : remainder_reg[DATA_WIDTH-1:0];

endmodule
