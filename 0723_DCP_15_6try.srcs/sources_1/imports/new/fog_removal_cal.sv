`timescale 1ns / 1ps

module fog_removal_cal #(
    parameter DATA_DEPTH = 320,
    parameter DATA_WIDTH = 8,
    parameter DIVIDER_LATENCY = 26
) (
    input logic clk,
    input logic rst,
    input logic DE,
    input logic [$clog2(DATA_DEPTH)-1:0] x_pixel,
    input logic [23:0] pixel_in_888,
    input logic [DATA_WIDTH-1:0] airlight_r,
    input logic [DATA_WIDTH-1:0] airlight_g,
    input logic [DATA_WIDTH-1:0] airlight_b,
    input logic [DATA_WIDTH - 1:0] tx_data,  // guided filter에서 나온 값

    output logic [        DATA_WIDTH-1:0] final_r,
    output logic [        DATA_WIDTH-1:0] final_g,
    output logic [        DATA_WIDTH-1:0] final_b,
    output logic                          DE_out,
    output logic [$clog2(DATA_DEPTH)-1:0] x_pixel_out
);
    localparam DIVIDER_WIDTH = DATA_WIDTH * 2 + 2;

    logic [DATA_WIDTH - 1:0] r_8bit;
    logic [DATA_WIDTH - 1:0] g_8bit;
    logic [DATA_WIDTH - 1:0] b_8bit;

    assign r_8bit = {pixel_in_888[23:16]};
    assign g_8bit = {pixel_in_888[15:8]};
    assign b_8bit = {pixel_in_888[7:0]};

    parameter   tx_min   =   8'd26;//=0.1 * 2^8 하한값 t0=0.1로 설정한 것을 8비트 고정 소수점으로 나타냄
    logic [DATA_WIDTH - 1 : 0] tx_value;
    assign tx_value = tx_data < tx_min ? tx_min : tx_data;


    // --- Stage 1: J = ((I-A)*2^8 + A*t) 계산 ---
    logic signed [DATA_WIDTH*2+1:0]
        value_tem_r, value_tem_g, value_tem_b;  // 비트 폭 재계산 필요
    logic DE_s1;
    logic [$clog2(DATA_DEPTH)-1:0] x_pixel_s1;

    // --- Stage 2: 나눗셈 IP 연결 ---
    logic signed [DIVIDER_WIDTH - 1:0] removal_data_r_quo, removal_data_g_quo, removal_data_b_quo;
    logic signed [DIVIDER_WIDTH - 1:0] removal_data_r_rema, removal_data_g_rema, removal_data_b_rema;
    logic r_valid_out, g_valid_out, b_valid_out;

    logic [9:0] result_integer_r, result_integer_g, result_integer_b;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            value_tem_r <= '0;
            value_tem_g <= '0;
            value_tem_b <= '0;
            DE_s1 <= 1'b0;
            x_pixel_s1 <= '0;
        end else begin
            if (DE) begin
                value_tem_r <= ( (signed'(r_8bit) - signed'(airlight_r)) <<< 8 ) + signed'(airlight_r) * signed'(tx_value);
                value_tem_g <= ( (signed'(g_8bit) - signed'(airlight_g)) <<< 8 ) + signed'(airlight_g) * signed'(tx_value);
                value_tem_b <= ( (signed'(b_8bit) - signed'(airlight_b)) <<< 8 ) + signed'(airlight_b) * signed'(tx_value);
            end
            DE_s1 <= DE;
            x_pixel_s1 <= x_pixel;
        end
    end

    shift_divider #(
        .DATA_WIDTH(DIVIDER_WIDTH),
        .FRAC_BITS (8)
    ) u_div_r (
        .clk(clk),
        .rst(rst),

        // 분자(Dividend) 입력
        .divided_in_tdata (value_tem_r),
        .divided_in_tvalid(DE_s1),
        .divided_in_tready(),

        // 분모(Divisor) 입력
        .divisor_in_tdata ({10'b0, tx_value}),
        .divisor_in_tvalid(DE_s1),

        // 결과(Quotient) 출력
        .quotient_out_tdata (removal_data_r_quo),
        .remainder_out_tdata(removal_data_r_rema),
        .divided_out_tvalid (r_valid_out)
    );

    shift_divider #(
        .DATA_WIDTH(DIVIDER_WIDTH),
        .FRAC_BITS (8)
    ) u_div_g (
        .clk(clk),
        .rst(rst),

        // 분자(Dividend) 입력
        .divided_in_tdata (value_tem_g),
        .divided_in_tvalid(DE_s1),
        .divided_in_tready(),

        // 분모(Divisor) 입력
        .divisor_in_tdata ({10'b0, tx_value}),
        .divisor_in_tvalid(DE_s1),

        // 결과(Quotient) 출력
        .quotient_out_tdata (removal_data_g_quo),
        .remainder_out_tdata(removal_data_g_rema),
        .divided_out_tvalid (g_valid_out)
    );

    shift_divider #(
        .DATA_WIDTH(DIVIDER_WIDTH),
        .FRAC_BITS (8)
    ) u_div_b (
        .clk(clk),
        .rst(rst),

        // 분자(Dividend) 입력
        .divided_in_tdata (value_tem_b),
        .divided_in_tvalid(DE_s1),
        .divided_in_tready(),

        // 분모(Divisor) 입력
        .divisor_in_tdata ({10'b0, tx_value}),
        .divisor_in_tvalid(DE_s1),

        // 결과(Quotient) 출력
        .quotient_out_tdata (removal_data_b_quo),
        .remainder_out_tdata(removal_data_b_rema),
        .divided_out_tvalid (b_valid_out)
    );

    // ---  Stage 3: 제어 신호 동기화 (쉬프트 레지스터 방식)  ---
    logic [DIVIDER_LATENCY-1:0][$clog2(DATA_DEPTH)-1:0] x_pixel_delay;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            x_pixel_delay <= '{default: '0};
        end else if (DE_s1) begin // IP에 데이터가 들어갈 때만 쉬프트!
            x_pixel_delay[0] <= x_pixel_s1;
            for (int i = 0; i < DIVIDER_LATENCY - 1; i = i + 1) begin
                x_pixel_delay[i+1] <= x_pixel_delay[i];
            end
        end
    end

    // --- 최종 출력 할당 ---

    // 나눗셈 결과의 "정수부"를 추출합니다. [17:8] 이므로 10비트입니다.
    assign result_integer_r = removal_data_r_quo[17:8];
    assign result_integer_g = removal_data_g_quo[17:8];
    assign result_integer_b = removal_data_b_quo[17:8];

    // 포화 로직 적용
    assign final_r = ($signed(result_integer_r) < 0) ? 8'd0 : ($signed(result_integer_r) > 255) ? 8'd255 : result_integer_r[7:0];
    assign final_g = ($signed(result_integer_g) < 0) ? 8'd0 : ($signed(result_integer_g) > 255) ? 8'd255 : result_integer_g[7:0];
    assign final_b = ($signed(result_integer_b) < 0) ? 8'd0 : ($signed(result_integer_b) > 255) ? 8'd255 : result_integer_b[7:0];


    assign DE_out      = b_valid_out; // IP의 유효 신호를 최종 유효 신호로 사용
    assign x_pixel_out = x_pixel_delay[DIVIDER_LATENCY-1]; // 지연된 x_pixel 값 출력

endmodule
