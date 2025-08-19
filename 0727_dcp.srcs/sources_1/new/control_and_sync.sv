`timescale 1ns / 1ps
module control_and_sync #(
    parameter IMAGE_WIDTH  = 640,
    parameter IMAGE_HEIGHT = 480,
    parameter DATA_WIDTH   = 8,
    parameter DC_LATENCY   = 18, //69,
    parameter TE_LATENCY   = 19, //23,
    parameter GF_LATENCY   = 8964
) (
    input logic clk,
    input logic rst,
    input logic pclk,

    // 원본 입력
    input logic        DE_in,
    input logic [23:0] pixel_in_888,
    input logic        v_sync,

    // input logic     te_tready_in,
    // output logic    dc_de_te,

    // // Airlight 피드백 입력
    // input logic [DATA_WIDTH-1:0] airlight_r_in,
    // input logic [DATA_WIDTH-1:0] airlight_g_in,
    // input logic [DATA_WIDTH-1:0] airlight_b_in,

    // // 다른 모듈로 전달될 출력
    // output logic [DATA_WIDTH-1:0] final_airlight_r_out,     // 프레임 내내 고정될 Airlight
    // output logic [DATA_WIDTH-1:0] final_airlight_g_out,
    // output logic [DATA_WIDTH-1:0] final_airlight_b_out,


    output logic [                    23:0] pixel_for_airlight, // Airlight 계산을 위한 지연된 픽셀
    output logic [                    23:0] pixel_for_guided,  // Airlight 계산을 위한 지연된 픽셀P
    output logic [                    23:0] pixel_for_recover   // 최종 복원을 위한 지연된 픽셀
);
    localparam GUIDED_DELAY_DEPTH = DC_LATENCY + TE_LATENCY + 1;
    localparam TOTAL_DELAY = DC_LATENCY + TE_LATENCY + GF_LATENCY;

    // airlightA_pixel_in_888  딜레이 : DC_LATENCY
    logic [23:0] pixel_888_delayed[0:TOTAL_DELAY-1];

    // logic v_sync_d1;
    // logic vsync_posedge;

    // assign vsync_posedge = ~v_sync_d1 && v_sync;

    // // assign dc_de_te = DE_in && te_tready_in;

    // always_ff @(posedge clk) begin
    //     v_sync_d1 <= v_sync;
    // end

    // // --- 1. Airlight 저장을 위한 레지스터 (피드백 루프) ---
    // always_ff @(posedge clk or posedge rst) begin
    //     if (rst) begin
    //         final_airlight_r_out <= 8'd220;  // 초기값
    //         final_airlight_g_out <= 8'd220;
    //         final_airlight_b_out <= 8'd220;
    //     end else if (vsync_posedge) begin
    //         final_airlight_r_out <= airlight_r_in;
    //         final_airlight_g_out <= airlight_g_in;
    //         final_airlight_b_out <= airlight_b_in;
    //     end
    // end

    // --- 2. 원본 데이터 동기화를 위한 지연 라인 ---

    always_ff @(posedge pclk or posedge rst) begin
        if (rst) begin
            pixel_888_delayed <= '{default: '0};
        end else if (DE_in) begin //dc_de_te
            // Dark Channel 모듈 지연
            pixel_888_delayed[0] <= pixel_in_888;
            for (int i = 0; i < TOTAL_DELAY - 1; i++) begin
                pixel_888_delayed[i+1] <= pixel_888_delayed[i];
            end 
        end
    end

    // 최종 출력 할당
    assign pixel_for_airlight = pixel_888_delayed[DC_LATENCY-1];
    assign pixel_for_guided   = pixel_888_delayed[GUIDED_DELAY_DEPTH-1];
    assign pixel_for_recover  = pixel_888_delayed[TOTAL_DELAY-1];

endmodule
