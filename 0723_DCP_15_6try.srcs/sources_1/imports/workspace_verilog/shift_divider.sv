`timescale 1ns / 1ps
module shift_divider #(
    parameter DATA_WIDTH = 64,
    parameter FRAC_BITS  = 16
) (
    input logic clk,
    input logic rst,

    // 분자(Dividend) 입력
    input  logic signed [DATA_WIDTH-1:0] divided_in_tdata,
    input  logic                         divided_in_tvalid,
    output logic                         divided_in_tready,

    // 분모(Divisor) 입력
    input logic [DATA_WIDTH-1:0] divisor_in_tdata,
    input logic                  divisor_in_tvalid,

    // 결과(Quotient) 출력
    output logic signed [DATA_WIDTH-1:0] quotient_out_tdata,
    output logic signed [DATA_WIDTH-1:0] remainder_out_tdata,
    output logic                         divided_out_tvalid
);

    typedef enum logic [1:0] {
        STATE_IDLE,
        STATE_CALC,
        STATE_DONE
    } state_t;

    state_t current_state, next_state;

    localparam FULL_WIDTH = DATA_WIDTH + FRAC_BITS; // <--- 전체 비트 폭 계산

    logic sign_dividend, sign_divisor;
    // logic signed [DATA_WIDTH-1:0] dividend_reg;  // 분자
    // logic signed [DATA_WIDTH-1:0] divisor_reg;  // 분모
    logic signed [FULL_WIDTH-1:0] dividend_reg;  // 분자 (확장됨)
    logic [FULL_WIDTH-1:0] quotient_reg;  // 몫 (확장됨)
    // logic [DATA_WIDTH-1:0] quotient_reg;  // 몫
    logic [DATA_WIDTH-1:0] abs_dividend;
    logic [DATA_WIDTH-1:0] abs_divisor_reg;
    logic [DATA_WIDTH  :0] remainder_reg; // 나머지, 뺄셈을 위해 1비트 추가
    logic [$clog2(FULL_WIDTH):0] bit_counter;

    logic [DATA_WIDTH:0] shifted_remainder;
    logic [DATA_WIDTH:0] temp_sub;
    logic [FULL_WIDTH-1:0] signed_quotient;
    assign signed_quotient = (sign_dividend ^ sign_divisor) ? -quotient_reg : quotient_reg;

    assign abs_dividend = divided_in_tdata[DATA_WIDTH-1] ? -divided_in_tdata : divided_in_tdata;

    always_comb begin
        next_state         = current_state;
        divided_in_tready  = 1'b0;
        divided_out_tvalid = 1'b0;
        case (current_state)
            STATE_IDLE: begin
                divided_in_tready = 1'b1; // IDLE 상태에서만 입력 받을 준비 완료
                // 입력 데이터가 유효하면 연산 시작 상태로 전환
                if (divided_in_tvalid && divisor_in_tvalid) begin
                    next_state = STATE_CALC;
                end
            end
            STATE_CALC: begin
                shifted_remainder = {
                    remainder_reg[DATA_WIDTH-1:0], dividend_reg[FULL_WIDTH-1]
                };
                temp_sub = shifted_remainder - abs_divisor_reg;
                if (bit_counter == 0) begin
                    next_state = STATE_DONE;
                end else begin
                    next_state = STATE_CALC;
                end
            end
            STATE_DONE: begin
                divided_out_tvalid = 1'b1;
                next_state = STATE_IDLE;
            end
            default: begin
                next_state = STATE_IDLE;
            end
        endcase
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= STATE_IDLE;
            quotient_reg <= '0;
            bit_counter <= '0;
            remainder_reg <= '0;
            dividend_reg <= '0;
            abs_divisor_reg <= '0;
            sign_dividend <= 1'b0;
            sign_divisor <= 1'b0;
        end else begin
            current_state <= next_state;
            case (current_state)
                STATE_IDLE: begin
                    if (next_state == STATE_CALC) begin
                        sign_dividend <= divided_in_tdata[DATA_WIDTH-1];
                        sign_divisor <= divisor_in_tdata[DATA_WIDTH-1];

                        dividend_reg <= FULL_WIDTH'(abs_dividend) << FRAC_BITS;

                        abs_divisor_reg <= divisor_in_tdata[DATA_WIDTH-1] ? -divisor_in_tdata : divisor_in_tdata;

                        quotient_reg <= '0;
                        remainder_reg <= '0;
                        bit_counter <= FULL_WIDTH;
                    end
                end
                STATE_CALC: begin
                    if (bit_counter > 0) begin
                        dividend_reg <= dividend_reg << 1;
                        temp_sub <= shifted_remainder - abs_divisor_reg;
                        if (!temp_sub[DATA_WIDTH]) begin // 뺄셈 결과가 양수
                            remainder_reg <= temp_sub;
                            quotient_reg  <= (quotient_reg << 1) | 1'b1;
                        end else begin  // 뺄셈 결과가 음수
                            remainder_reg <= shifted_remainder;  // 값 복원
                            quotient_reg  <= (quotient_reg << 1) | 1'b0;
                        end
                        bit_counter <= bit_counter - 1;
                    end
                end
                STATE_DONE: begin

                end
                default: begin
                    current_state <= STATE_IDLE;
                end
            endcase
        end
    end

    // 1. 몫의 부호 결정 (입력 부호가 다르면 음수)
    assign quotient_out_tdata = signed_quotient[DATA_WIDTH-1:0];

    // 2. 나머지의 부호 결정 (피제수의 부호를 따름)
    assign remainder_out_tdata = sign_dividend ? -remainder_reg[DATA_WIDTH-1:0] : remainder_reg[DATA_WIDTH-1:0];

endmodule
