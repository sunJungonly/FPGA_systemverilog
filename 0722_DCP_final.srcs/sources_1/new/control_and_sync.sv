`timescale 1ns / 1ps
module control_and_sync #(
    parameter IMAGE_WIDTH = 320,
    parameter IMAGE_HEIGHT = 240,
    parameter DATA_WIDTH = 8,
    parameter DC_LATENCY = 10,  // LineBuffer(1) + Matrix(7) + BlockMin(2) = 10 
    parameter TE_LATENCY = 20  // TransmissionEstimate의 Divider IP Latency
) (
    input logic clk,
    input logic rst,

    // 원본 입력
    input logic        DE_in,
    input logic [23:0] pixel_in_888,
    input logic [ 8:0] y_pixel_in,

    // Airlight 피드백 입력
    input logic                  airlight_done_in,
    input logic [DATA_WIDTH-1:0] airlight_r_in,
    input logic [DATA_WIDTH-1:0] airlight_g_in,
    input logic [DATA_WIDTH-1:0] airlight_b_in,

    // 다른 모듈로 전달될 출력
    output logic [DATA_WIDTH-1:0] airlight_r_out,     // 프레임 내내 고정될 Airlight
    output logic [DATA_WIDTH-1:0] airlight_g_out,
    output logic [DATA_WIDTH-1:0] airlight_b_out,

    output logic [23:0] pixel_for_airlight, // Airlight 계산을 위한 지연된 픽셀
    output logic [23:0] pixel_for_recover,  // 최종 복원을 위한 지연된 픽셀
    output logic [8:0] y_pixel_for_airlight  // Airlight 계산을 위한 지연된 y좌표
);

    // --- 1. Airlight 저장을 위한 레지스터 (피드백 루프) ---
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            airlight_r_out <= 8'd220;  // 초기값
            airlight_g_out <= 8'd220;
            airlight_b_out <= 8'd220;
        end else if (airlight_done_in) begin
            airlight_r_out <= airlight_r_in;
            airlight_g_out <= airlight_g_in;
            airlight_b_out <= airlight_b_in;
        end
    end

    // --- 2. 원본 데이터 동기화를 위한 지연 라인 ---
    localparam TOTAL_LATENCY = DC_LATENCY + TE_LATENCY; //30

    // pixel_in_888 지연 라인
    logic [23:0] pixel_888_delayed[0:TOTAL_LATENCY-1];

    // y_pixel 지연 라인
    logic [$clog2(IMAGE_HEIGHT)-1:0] y_pixel_delayed[0:DC_LATENCY-1];

    always_ff @(posedge clk) begin
        if (rst) begin
            pixel_888_delayed <= '{default: '0};
            y_pixel_delayed   <= '{default: '0};
        end else if (DE_in) begin
            // 전체 파이프라인 지연
            pixel_888_delayed[0] <= pixel_in_888;
            for (int i = 0; i < TOTAL_LATENCY - 1; i++) begin
                pixel_888_delayed[i+1] <= pixel_888_delayed[i];
            end

            // Dark Channel 모듈 지연
            y_pixel_delayed[0] <= y_pixel_in;
            for (int i = 0; i < DC_LATENCY - 1; i++) begin
                y_pixel_delayed[i+1] <= y_pixel_delayed[i];
            end
        end
    end

    // 최종 출력 할당
    assign pixel_for_airlight = pixel_888_delayed[DC_LATENCY-1];
    assign y_pixel_for_airlight = y_pixel_delayed[DC_LATENCY-1];
    assign pixel_for_recover = pixel_888_delayed[TOTAL_LATENCY-1];

endmodule
