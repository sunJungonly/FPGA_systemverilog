`timescale 1ns / 1ps
module control_and_sync #(
    parameter IMAGE_WIDTH  = 640,
    parameter IMAGE_HEIGHT = 480,
    parameter DATA_WIDTH   = 8,
    parameter DC_LATENCY   = 64,
    parameter TE_LATENCY   = 23
) (
    input logic clk,
    input logic rst,

    // 원본 입력
    input logic        DE_in,
    input logic [23:0] pixel_in_888,

    input logic [7:0] dark_channel_in,

    // Airlight 피드백 입력
    input logic                  airlight_done_in,
    input logic [DATA_WIDTH-1:0] airlight_r_in,
    input logic [DATA_WIDTH-1:0] airlight_g_in,
    input logic [DATA_WIDTH-1:0] airlight_b_in,

    // Transmission Estimate de_out
    input logic te_de_out,

    // Guided Filter 

    // 다른 모듈로 전달될 출력
    output logic [DATA_WIDTH-1:0] airlight_r_out,     // 프레임 내내 고정될 Airlight
    output logic [DATA_WIDTH-1:0] airlight_g_out,
    output logic [DATA_WIDTH-1:0] airlight_b_out,

    output logic [                    23:0] pixel_for_airlight, // Airlight 계산을 위한 지연된 픽셀
    output logic [                    23:0] pixel_for_guided  // Airlight 계산을 위한 지연된 픽셀
    // output logic [                    23:0] pixel_for_recover   // 최종 복원을 위한 지연된 픽셀
);
    localparam GUIDED_DELAY_DEPTH = DC_LATENCY + TE_LATENCY;

    // airlightA_pixel_in_888  딜레이 : DC_LATENCY
    logic [23:0] pixel_888_delayed[0:GUIDED_DELAY_DEPTH-1];

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

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pixel_888_delayed <= '{default: '0};
        end else if (DE_in) begin
            // Dark Channel 모듈 지연
            pixel_888_delayed[0] <= pixel_in_888;
            for (int i = 0; i < GUIDED_DELAY_DEPTH - 1; i++) begin
                pixel_888_delayed[i+1] <= pixel_888_delayed[i];
            end
        end else if (te_de_out) begin
            pixel_for_guided <= pixel_in_888;
        end


    end

    // 최종 출력 할당
    assign pixel_for_airlight = pixel_888_delayed[DC_LATENCY-1];
    assign pixel_for_guided   = pixel_888_delayed[GUIDED_DELAY_DEPTH-1];
    // assign pixel_for_recover  = 

endmodule
