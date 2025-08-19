`timescale 1ns / 1ps
module TransmissionEstimate #(
    parameter DATA_DEPTH = 320,
    parameter DATA_WIDTH = 8
) (
    input logic clk,
    input logic rst,

    input logic                          DE,
    input logic [$clog2(DATA_DEPTH)-1:0] x_pixel,
    input logic [$clog2(DATA_DEPTH)-1:0] y_pixel,

    input logic [DATA_WIDTH-1:0] dark_channel_in,  // 8비트 dark channel
    output logic dark_channel_in_tready,  // 8비트 dark channel
    input logic [DATA_WIDTH-1:0] airlight_r_in,  // Airlight R
    input logic [DATA_WIDTH-1:0] airlight_g_in,
    input logic [DATA_WIDTH-1:0] airlight_b_in,

    output logic [      DATA_WIDTH - 1:0] t_out,
    output logic                          DE_out,
    output logic [$clog2(DATA_DEPTH)-1:0] x_pixel_out,
    output logic [$clog2(DATA_DEPTH)-1:0] y_pixel_out
);

    localparam DIVIDER_LATENCY = 20;

    // --- 새로운 로직: R, G, B Airlight 중 대표값(최댓값) 선택 ---
    logic [DATA_WIDTH-1:0] airlight_representative;


    // --- Stage 1: ω * dark_channel 계산 ---
    // t = 1 - ω * (min(I/A)) 이므로, min(I/A)를 먼저 계산해야 하지만
    // 리소스 고려와 편의상 t = 1 - ω * (dark_channel/A)를 구현
    // logic [DATA_WIDTH*2-1:0] omega_mul_dc;  // 8비트 * 8비트 = 16비트
    // logic DE_s1;
    // logic [$clog2(DATA_DEPTH)-1:0] x_pixel_s1;

    // ω = 0.80 (205/256)
    localparam [7:0] OMEGA_FX = 8'd205;

    // --- Stage 2: 나눗셈 IP 연결 ---
    logic s1_fire;
    logic [DATA_WIDTH*2-1:0] s1_omega_mul_dc;
    logic s2_tvalid_in;
    logic s2_tready_out;
    logic [$clog2(DATA_DEPTH)-1:0] x_pixel_s1_reg;
    logic [$clog2(DATA_DEPTH)-1:0] y_pixel_s1_reg;

    logic [DATA_WIDTH - 1:0] div_quotient;  // 나눗셈 몫
    logic [DATA_WIDTH - 1:0] div_remainder;  // 나눗셈 몫
    // logic div_valid_out_raw;  // 나눗셈 결과 유효 신호
    // logic div_ready_in;
    logic s3_tvalid_in;

    assign s1_omega_mul_dc = dark_channel_in * 8'd205;  // ω=0.8 곱셈
    //입력이 유효할 때, 다음 나눗셈 받을 준비 되었을때만 받기 위함
    assign s1_fire = DE && s2_tready_out;

    //내가 받을 준비가 된 시점 = 다음 스테이지가 준비된 시점
    assign dark_channel_in_tready = s2_tready_out;

    always_comb begin
        if (airlight_r_in > airlight_g_in) begin
            airlight_representative = (airlight_r_in > airlight_b_in) ? airlight_r_in : airlight_b_in;
        end else begin
            airlight_representative = (airlight_g_in > airlight_b_in) ? airlight_g_in : airlight_b_in;
        end
    end

    // --- Stage 1 -> 2 Register: 나눗셈기에 데이터 전달 ---
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            s2_tvalid_in <= 1'b0;
        end else begin
            // s1_fire 신호가 1일 때만 tvalid를 1로 만들어 데이터를 전달하고,
            // 나눗셈기가 데이터를 받으면(s2_tready_out=1) 다시 tvalid를 0으로 내린다.
            if (s1_fire) begin
                s2_tvalid_in <= 1'b1;
            end else if (s2_tready_out) begin
                s2_tvalid_in <= 1'b0;
            end
        end
    end

    // x_pixel 값은 데이터와 함께 파이프라인을 타야 한다.
    always_ff @(posedge clk) begin
        if (s1_fire) begin
            x_pixel_s1_reg <= x_pixel;
            y_pixel_s1_reg <= y_pixel;
        end
    end

    // --- Stage 2: 나눗셈기 ---
    shift_divider #(
        .DATA_WIDTH(16),
        .FRAC_BITS (8)
    ) u_divider (
        .clk(clk),
        .rst(rst),

        // 분자(Dividend) 입력
        .divided_in_tdata (s1_omega_mul_dc),
        .divided_in_tvalid(s2_tvalid_in),
        .divided_in_tready(s2_tready_out),

        // 분모(Divisor) 입력
        .divisor_in_tdata ({8'b0, airlight_representative}), //이게 맞다!!!! 대신 0.01정도의 오차 있음
        // .divisor_in_tdata ({airlight_representative, 8'b0}),
        .divisor_in_tvalid(s2_tvalid_in),

        // 결과(Quotient) 출력
        .quotient_out_tdata (div_quotient),
        .remainder_out_tdata(div_remainder),
        .divided_out_tvalid (s3_tvalid_in)
    );


    // --- Stage 3: 최종 계산 및 출력 레지스터 ---
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            t_out <= '0;
            DE_out <= 1'b0;
            x_pixel_out <= '0;
            y_pixel_out <= '0;
        end else begin
            // 나눗셈 결과가 유효할 때(s3_tvalid_in) 최종 계산을 수행하고 결과를 저장한다.
            if (s3_tvalid_in) begin
                // t = 1.0 - (결과) 이므로, 255 - (결과의 소수부)
                t_out <= 8'd255 - div_quotient[7:0];
                x_pixel_out <= x_pixel_s1_reg; // 나눗셈기에 들어갔던 데이터와 "동기화된" x_pixel 값
                y_pixel_out <= y_pixel_s1_reg; // 나눗셈기에 들어갔던 데이터와 "동기화된" y_pixel 값
            end

            // 출력 유효 신호는 나눗셈기의 유효 신호를 그대로 따른다.
            DE_out <= s3_tvalid_in;
        end
    end

endmodule
