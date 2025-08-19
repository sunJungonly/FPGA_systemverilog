`timescale 1ns / 1ps
module TransmissionEstimate #(
    parameter DATA_DEPTH = 320,
    parameter DATA_WIDTH = 8
) (
    input logic clk,
    input logic rst,

    input logic                          DE,
    input logic [$clog2(DATA_DEPTH)-1:0] x_pixel,

    input logic [DATA_WIDTH-1:0] dark_channel_in, // 8비트 dark channel
    input logic [DATA_WIDTH-1:0] airlight_r_in,   // 프레임 내내 고정된 Airlight R
    input logic [DATA_WIDTH-1:0] airlight_g_in,
    input logic [DATA_WIDTH-1:0] airlight_b_in,

    output logic [      DATA_WIDTH - 1:0] t_out,
    output logic                          DE_out,
    output logic [$clog2(DATA_DEPTH)-1:0] x_pixel_out
);

    localparam DIVIDER_LATENCY = 20;

    // --- 새로운 로직: R, G, B Airlight 중 대표값(최댓값) 선택 ---
    logic [DATA_WIDTH-1:0] airlight_representative;
    always_comb begin
        if (airlight_r_in > airlight_g_in) begin
            airlight_representative = (airlight_r_in > airlight_b_in) ? airlight_r_in : airlight_b_in;
        end else begin
            airlight_representative = (airlight_g_in > airlight_b_in) ? airlight_g_in : airlight_b_in;
        end
    end

    // --- Stage 1: ω * dark_channel 계산 ---
    // t = 1 - ω * (min(I/A)) 이므로, min(I/A)를 먼저 계산해야 하지만
    // 리소스 고려와 편의상 t = 1 - ω * (dark_channel/A)를 구현
    logic [DATA_WIDTH*2-1:0] omega_mul_dc; // 8비트 * 8비트 = 16비트
    logic DE_s1;
    logic [$clog2(DATA_DEPTH)-1:0] x_pixel_s1;

    // ω = 0.80 (205/256)
    localparam [7:0] OMEGA_FX = 8'd205;

    always_ff @(posedge clk) begin
        if (rst) begin
            omega_mul_dc <= 0;
            DE_s1 <= 0;
            x_pixel_s1 <= 0;
        end else if (DE) begin
            // 파이프라인 곱셈기 사용이 이상적이나, 간단한 연산이므로 조합 로직으로 구현
            omega_mul_dc <= dark_channel_in * OMEGA_FX;
        end
        // 제어 신호 1클럭 지연
        DE_s1 <= DE;
        x_pixel_s1 <= x_pixel;
    end

     // --- Stage 2: 나눗셈 IP 연결 ---
    logic [DATA_WIDTH-1:0] div_quotient_raw; // 나눗셈 결과
    logic                  div_valid_out_raw;    // 나눗셈 결과 유효 신호
    logic                  div_ready_in;

    // AXI-Stream 연결
    // divider_IP_wrapper u_divider (
    //     .sys_clk(clk),
    //     .reset_rtl_0(rst),

    //     // 분자(Dividend) 입력
    //     .divided_in_tdata(omega_mul_dc),   // 1단계 연산 결과
    //     .divided_in_tvalid(DE_s1),         // 1단계 데이터가 유효함을 알림
    //     .divided_in_tready(div_ready_in),  // IP가 받을 준비가 되었는지 (Back-pressure)

    //     // 분모(Divisor) 입력
    //     .divisor_in_tdata(airlight_representative),
    //     .divisor_in_tvalid(DE_s1),
    //     .divisor_in_tready(),              // 일반적으로 분자는 tready만 사용

    //     // 결과(Quotient) 출력
    //     .divided_out_tdata({div_quotient_raw, 8'b0}), // IP 출력 포맷에 맞게 연결 (하위 비트는 버림)
    //     .divided_out_tvalid(div_valid_out_raw)
    //     );

    assign div_quotient_raw = omega_mul_dc / {8'b0, airlight_representative};

    // --- Stage 3: 1 - (나눗셈 결과) & 최종 출력 ---
    // 나눗셈 결과와 제어 신호를 동기화
    logic [DIVIDER_LATENCY-1:0] DE_delay_chain;
    logic [DIVIDER_LATENCY-1:0] [$clog2(DATA_DEPTH)-1:0] x_pixel_delay_chain;
    
    // (DE_s1과 x_pixel_s1을 DIVIDER_LATENCY-1 만큼 지연시키는 로직 필요)
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            DE_delay_chain <= '0;
            x_pixel_delay_chain <= '{default:'0};
        end else begin
            // Stage 1의 제어 신호를 쉬프트 레지스터의 맨 앞에 삽입
            DE_delay_chain[0] <= DE_s1;
            x_pixel_delay_chain[0] <= x_pixel_s1;

            // 기존 데이터를 한 칸씩 뒤로 밀어냄
            for (int i = 0; i < DIVIDER_LATENCY - 1; i = i + 1) begin
                DE_delay_chain[i+1] <= DE_delay_chain[i];
                x_pixel_delay_chain[i+1] <= x_pixel_delay_chain[i];
            end
        end
    end
    
    // 최종 t값 계산
    // 나눗셈 결과(div_quotient)는 8비트 고정소수점 (255)에서 나눗셈 결과 빼기
    assign t_out = 8'd255 - div_quotient_raw;
    
    // 최종 출력 제어신호
    assign DE_out      = DE_delay_chain[DIVIDER_LATENCY-1];
    assign x_pixel_out = x_pixel_delay_chain[DIVIDER_LATENCY-1];

endmodule
