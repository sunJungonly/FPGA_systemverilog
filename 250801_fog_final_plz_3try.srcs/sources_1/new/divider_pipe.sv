`timescale 1ns / 1ps

// 음수 입력을 처리하지 않는 Unsigned 전용 파이프라인 나눗셈기
module shift_divider_pipelined #(
    parameter DATA_WIDTH = 10,
    parameter FRAC_BITS  = 8
) (
    input  logic                     clk,
    input  logic                     rst,

    // 입력 (모두 Unsigned)
    input  logic [DATA_WIDTH-1:0]    divided_in_tdata, // 분자
    input  logic                     divided_in_tvalid,
    output logic                     divided_in_tready,
    input  logic [DATA_WIDTH-1:0]    divisor_in_tdata, // 분모
    input  logic                     divisor_in_tvalid,

    // 출력 (모두 Unsigned)
    output logic [DATA_WIDTH-1:0]    quotient_integer_out,
    output logic [FRAC_BITS-1:0]     quotient_fractional_out,
    output logic [DATA_WIDTH-1:0]    remainder_out_tdata,
    output logic                     quotient_out_tvalid
);

    // --- 파라미터 및 타입 정의 ---
    localparam FULL_WIDTH = DATA_WIDTH + FRAC_BITS;
    localparam REMAINDER_WIDTH = DATA_WIDTH;

    // --- 파이프라인 레지스터 (부호 관련 레지스터 모두 삭제) ---
    logic [FULL_WIDTH-1:0]           dividend_pipe [FULL_WIDTH];
    logic [REMAINDER_WIDTH:0]        remainder_pipe [FULL_WIDTH];
    logic [FULL_WIDTH-1:0]           quotient_pipe  [FULL_WIDTH];
    logic [REMAINDER_WIDTH-1:0]      divisor_pipe[FULL_WIDTH]; // 'abs' 불필요
    logic                            valid_pipe      [FULL_WIDTH+1];

    // --- 입력단 로직 (절댓값, 부호 계산 로직 모두 삭제) ---
    logic                       input_valid;

    assign divided_in_tready = 1'b1;
    assign input_valid = divided_in_tvalid && divisor_in_tvalid;
    
    // --- 파이프라인 스테이지 생성 (generate-for) ---
    genvar i;
    generate
        for (i = 0; i < FULL_WIDTH; i=i+1) begin : P_STAGE
            // --- 각 스테이지의 조합 로직 ---
            logic [REMAINDER_WIDTH:0]  current_remainder;
            logic [REMAINDER_WIDTH:0]  shifted_remainder;
            logic [REMAINDER_WIDTH:0]  temp_sub;
            logic                      quotient_bit;

            if (i == 0) begin
                assign current_remainder = 0;
            end else begin
                assign current_remainder = remainder_pipe[i-1];
            end
            
            // 핵심 나눗셈 로직은 동일
            assign shifted_remainder = {current_remainder[REMAINDER_WIDTH-1:0], dividend_pipe[i][FULL_WIDTH-1-i]};
            assign temp_sub          = shifted_remainder - divisor_pipe[i];
            assign quotient_bit      = ~temp_sub[REMAINDER_WIDTH];

            // --- 각 스테이지의 순차 로직 (부호 관련 로직 모두 삭제) ---
            always_ff @(posedge clk or posedge rst) begin
                if (rst) begin
                    dividend_pipe[i]  <= '0;
                    remainder_pipe[i] <= '0;
                    quotient_pipe[i]  <= '0;
                    divisor_pipe[i]   <= '0;
                end else begin
                    // 첫 스테이지에서 입력을 받고, 이후 스테이지로 전달
                    if (i == 0) begin
                        dividend_pipe[i] <= divided_in_tdata << FRAC_BITS;
                        divisor_pipe[i]  <= divisor_in_tdata;
                    end else begin
                        dividend_pipe[i] <= dividend_pipe[i-1];
                        divisor_pipe[i]  <= divisor_pipe[i-1];
                    end

                    if (quotient_bit) begin
                        remainder_pipe[i] <= temp_sub[REMAINDER_WIDTH:0];
                    end else begin
                        remainder_pipe[i] <= shifted_remainder[REMAINDER_WIDTH:0];
                    end
                    
                    if (i == 0) begin
                         quotient_pipe[i] <= {{(FULL_WIDTH-1){1'b0}}, quotient_bit};
                    end else begin
                         quotient_pipe[i] <= {quotient_pipe[i-1][FULL_WIDTH-2:0], quotient_bit};
                    end
                end
            end
        end
    endgenerate

    // valid 신호 파이프라인
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int j = 0; j <= FULL_WIDTH; j++) begin
                valid_pipe[j] <= 1'b0;
            end
        end else begin
            valid_pipe[0] <= input_valid;
            for (int j = 1; j <= FULL_WIDTH; j++) begin
                valid_pipe[j] <= valid_pipe[j-1];
            end
        end
    end

    // --- 출력단 로직 (부호 적용 로직 모두 삭제) ---
    logic [FULL_WIDTH-1:0] final_quotient;
    
    assign final_quotient = quotient_pipe[FULL_WIDTH-1];

    // 최종 결과를 정수부와 소수부로 분리
    assign quotient_integer_out    = final_quotient[FULL_WIDTH-1 : FRAC_BITS];
    assign quotient_fractional_out = final_quotient[FRAC_BITS-1 : 0];
    assign remainder_out_tdata     = remainder_pipe[FULL_WIDTH-1][REMAINDER_WIDTH-1:0];
    assign quotient_out_tvalid     = valid_pipe[FULL_WIDTH];

endmodule