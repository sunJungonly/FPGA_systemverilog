`timescale 1ns / 1ps
// pclk를 사용하도록 포트 리스트를 수정하고, 불필요한 clk는 삭제합니다.
module TransmissionEstimate #( // 5개 분배기 병렬 처리 버전
parameter DATA_DEPTH = 640,
parameter DATA_WIDTH = 8,
parameter DELAY = 70 // 분배기 지연시간(25) + Mux/Demux 로직 지연(약 4)
) (
input logic clk,
input logic rst,
input logic pclk, // 모든 로직의 기준이 되는 픽셀 클럭

input logic                          DE,
input logic [$clog2(DATA_DEPTH)-1:0] x_pixel,
input logic [$clog2(DATA_DEPTH)-1:0] y_pixel,

input logic [DATA_WIDTH-1:0] dark_channel_in,
input logic [DATA_WIDTH-1:0] airlight_r_in,
input logic [DATA_WIDTH-1:0] airlight_g_in,
input logic [DATA_WIDTH-1:0] airlight_b_in,

output logic dark_channel_in_tready,
output logic [DATA_WIDTH - 1:0] t_out,
output logic DE_out,
output logic [$clog2(DATA_DEPTH)-1:0] x_pixel_out,
output logic [$clog2(DATA_DEPTH)-1:0] y_pixel_out

);

    // --- 상수 및 공통 로직 ---
    localparam NUM_DIVIDERS = 20;
    localparam [7:0] OMEGA_FX = 8'd250; // ω = 0.80

    // =================================================================
    //  1단계: Dispatcher (안내원) - 데이터를 5개 분배기로 분산
    // =================================================================

    logic [7:0] rdivider_quotient_int_out;
    logic [7:0] gdivider_quotient_int_out;
    logic [7:0] bdivider_quotient_int_out;

    logic [7:0] rdivider_quotient_frac_out;
    logic [7:0] gdivider_quotient_frac_out;
    logic [7:0] bdivider_quotient_frac_out;
    // 각 분배기로 들어갈 tvalid 신호를 생성

    // =================================================================
    //  2단계: 5개의 분배기 (계산대) - 병렬 계산 수행
    // =================================================================

    shift_divider_pipelined #(
        .DATA_WIDTH(8),
        .FRAC_BITS(8)
    ) u_divider_inst0 (
        .clk(pclk), // 모든 모듈은 pclk 사용
        .rst(rst),
        .divided_in_tdata (dark_channel_in),
        .divided_in_tvalid(1'b1), // j번째 분배기의 tvalid
        .divided_in_tready(),
        .divisor_in_tdata(airlight_r_in),
        .divisor_in_tvalid(1'b1),
        .quotient_integer_out(rdivider_quotient_int_out),
        .quotient_fractional_out(rdivider_quotient_frac_out),
        .remainder_out_tdata(),
        .quotient_out_tvalid()
    );

    shift_divider_pipelined #(
        .DATA_WIDTH(8),
        .FRAC_BITS(8)
    ) u_divider_inst1 (
        .clk(pclk), // 모든 모듈은 pclk 사용
        .rst(rst),
        .divided_in_tdata (dark_channel_in),
        .divided_in_tvalid(1'b1), // j번째 분배기의 tvalid
        .divided_in_tready(),
        .divisor_in_tdata(airlight_g_in), // 이거 수정
        .divisor_in_tvalid(1'b1),
        .quotient_integer_out(gdivider_quotient_int_out),
        .quotient_fractional_out(gdivider_quotient_frac_out),
        .remainder_out_tdata(),
        .quotient_out_tvalid()
    );

    shift_divider_pipelined #(
        .DATA_WIDTH(8),
        .FRAC_BITS(8)
    ) u_divider_inst2 (
        .clk(pclk), // 모든 모듈은 pclk 사용
        .rst(rst),
        .divided_in_tdata (dark_channel_in),
        .divided_in_tvalid(1'b1), // j번째 분배기의 tvalid
        .divided_in_tready(),
        .divisor_in_tdata(airlight_b_in),
        .divisor_in_tvalid(1'b1),
        .quotient_integer_out(bdivider_quotient_int_out),
        .quotient_fractional_out(bdivider_quotient_frac_out),
        .remainder_out_tdata(),
        .quotient_out_tvalid()
    );

    // =================================================================
    //  3단계: Collector (결과 확인 직원) - 결과 취합 및 최종 계산
    // =================================================================
    logic [15:0] rvalue, gvalue, bvalue;
    logic [15:0] min_data_1, min_data_2;
    logic [31:0] mul_data;
    logic [31:0] t_m;

    assign rvalue = {rdivider_quotient_int_out,rdivider_quotient_frac_out};
    assign gvalue = {gdivider_quotient_int_out,gdivider_quotient_frac_out};
    assign bvalue = {bdivider_quotient_int_out,bdivider_quotient_frac_out};

    assign min_data_1 = rvalue > gvalue ? gvalue : rvalue;
    assign min_data_2 = min_data_1 > bvalue ? bvalue : min_data_1;   
    assign mul_data = (16'h00FA * min_data_2);

    assign t_m = {16'b1,16'b0} - mul_data;

// 정규화 범위: min = 0.1, max = 1.0
// Q8.8 고정소수점 기반 계산

    logic [31:0] t_max_16_16 = 32'd327680;// 1.0 * 65536
    logic [31:0] t_min_16_16 = 32'd6554;
    logic [31:0] t_range     = 32'd58982;  // 1.0 - 0.1 = 0.9 * 65536

    logic [31:0] t_m_clamped;
    logic [31:0] t_scaled;

    // 1단계: t_m을 0.1 ~ 0.9 사이로 클램핑
    always_comb begin
        if (t_m <= t_min_16_16)
            t_m_clamped = t_min_16_16;
        else if (t_m >= t_max_16_16)
            t_m_clamped = t_max_16_16;
        else
            t_m_clamped = t_m;
    end

    // 2단계: 정규화 (0~255 사이 값으로)
    // t_scaled = ((t_m_clamped - t_min) * 255) / range
    logic [31:0] norm_val;
    always_comb begin
        norm_val  = t_m_clamped - t_min_16_16;
    end

    shift_divider_pipelined #(
        .DATA_WIDTH(32),
        .FRAC_BITS(8)
    ) u_divider_inst3 (
        .clk(pclk), // 모든 모듈은 pclk 사용
        .rst(rst),
        .divided_in_tdata ((norm_val * 8'd255)),
        .divided_in_tvalid(1'b1), // j번째 분배기의 tvalid
        .divided_in_tready(),
        .divisor_in_tdata(t_range),
        .divisor_in_tvalid(1'b1),
        .quotient_integer_out(t_scaled),
        .quotient_fractional_out(),
        .remainder_out_tdata(),
        .quotient_out_tvalid()
    );

    assign t_out = (DE_out) ? t_scaled[7:0] : 0;

    // =================================================================
    //  x_pixel 동기화를 위한 시간 지연 벨트 (핵심 부품)
    // =================================================================

    logic [9:0] x_pixel_pipe[0:DELAY-1];
    logic [9:0] y_pixel_pipe[0:DELAY-1];
    logic       DE_pipe     [0:DELAY-1];

    always_ff @(posedge pclk or posedge rst) begin 
        if (rst) begin
            for (int k = 0; k < DELAY; k++) begin
                x_pixel_pipe[k] <= 0;
                y_pixel_pipe[k] <= 0;
                DE_pipe[k]      <= 0;
            end
        end else begin
            x_pixel_pipe[0] <= x_pixel;
            y_pixel_pipe[0] <= y_pixel;
            DE_pipe[0]      <= DE;
            for (int k = 1; k < DELAY; k++) begin
                x_pixel_pipe[k] <= x_pixel_pipe[k-1];
                y_pixel_pipe[k] <= y_pixel_pipe[k-1];
                DE_pipe[k]      <= DE_pipe[k-1];
            end
        end
    end

    assign x_pixel_out = x_pixel_pipe[DELAY-1];
    assign y_pixel_out = y_pixel_pipe[DELAY-1];
    assign DE_out = DE_pipe[DELAY-1];

endmodule