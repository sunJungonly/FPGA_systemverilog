`timescale 1ns / 1ps
module control_and_sync #(
    parameter IMAGE_WIDTH  = 640,
    parameter IMAGE_HEIGHT = 480,
    parameter DATA_WIDTH   = 8,
    parameter DC_LATENCY   = 18,
    parameter TE_LATENCY   = 19,
    parameter GU_LATENCY   = 0,
    parameter RE_LATENCY   = 34
) (
    input logic clk,
    input logic rst,
    input logic pclk,

    // 원본 입력
    input logic h_sync_in,
    input logic v_sync_in,
    input logic [9:0] x_pixel_in,
    input logic [9:0] y_pixel_in,
    input logic        DE_in,
    input logic [23:0] pixel_in_888,

    // airlight
    input logic [7:0] airlight_r_in,
    input logic [7:0] airlight_g_in,
    input logic [7:0] airlight_b_in,
    output logic [                    23:0] pixel_for_airlight, // Airlight 계산을 위한 지연된 픽셀
    output logic airlight_de,

    // guided
    output logic [                    23:0] pixel_for_guided,  // Airlight 계산을 위한 지연된 픽셀
    output logic guided_de,

    // recover
    output logic [                    23:0] pixel_for_recover,  // Airlight 계산을 위한 지연된 픽셀
    output logic recover_de,
    output logic [7:0] airlight_r_out,
    output logic [7:0] airlight_g_out,
    output logic [7:0] airlight_b_out,

    output logic h_sync_air,
    output logic v_sync_air,
    output logic h_sync_out,
    output logic v_sync_out,

    // pixel location
    output logic [9:0] x_pixel_out,
    output logic [9:0] y_pixel_out

);
    localparam GUIDED_DELAY_DEPTH = DC_LATENCY + TE_LATENCY;
    localparam RECOVER_DELAY_DEPTH = GUIDED_DELAY_DEPTH + GU_LATENCY;
    localparam FINAL_DELAY_DEPTH = RECOVER_DELAY_DEPTH + RE_LATENCY;

    // airlightA_pixel_in_888  딜레이 : DC_LATENCY
    logic [23:0] pixel_888_air_delayed[0:DC_LATENCY-1];
    logic air_de_delayed [0:DC_LATENCY-1];
    logic air_h_sync_delayed [0:DC_LATENCY-1];
    logic air_v_sync_delayed [0:DC_LATENCY-1];

    // guided
    logic [23:0] pixel_888_guided_delayed[0:GUIDED_DELAY_DEPTH-1];
    logic guided_de_delayed [0:GUIDED_DELAY_DEPTH-1];

    // recover
    logic [7:0] airlight_r_delayed[0:RECOVER_DELAY_DEPTH-1];
    logic [7:0] airlight_g_delayed[0:RECOVER_DELAY_DEPTH-1];
    logic [7:0] airlight_b_delayed[0:RECOVER_DELAY_DEPTH-1];
    logic [23:0] pixel_888_recover_delayed[0:RECOVER_DELAY_DEPTH-1];
    logic recover_de_delayed [0:RECOVER_DELAY_DEPTH-1];
    
    // final
    logic final_h_sync_delay [0:FINAL_DELAY_DEPTH-1];
    logic final_v_sync_delay [0:FINAL_DELAY_DEPTH-1];
    logic [9:0] x_pixel_delay [0:FINAL_DELAY_DEPTH-1];
    logic [9:0] y_pixel_delay [0:FINAL_DELAY_DEPTH-1];

    always_ff @(posedge pclk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < DC_LATENCY; i = i + 1) begin
                pixel_888_air_delayed[i] <= 0;
                air_de_delayed[i] <= 0;
                air_h_sync_delayed[i] <= 0;
                air_v_sync_delayed[i] <= 0;
            end

            for (int i = 0; i < GUIDED_DELAY_DEPTH; i = i + 1) begin
                pixel_888_guided_delayed[i] <= 0;
                guided_de_delayed[i] <= 0;
            end

            for (int i = 0; i < RECOVER_DELAY_DEPTH; i = i + 1) begin
                pixel_888_recover_delayed[i] <= 0;
                recover_de_delayed[i] <= 0;
                airlight_r_delayed[i] <= 0;
                airlight_g_delayed[i] <= 0;
                airlight_b_delayed[i] <= 0;
            end
            
            for (int i = 0; i < FINAL_DELAY_DEPTH; i = i + 1) begin
                final_h_sync_delay[i] <= 0;
                final_v_sync_delay[i] <= 0;
                x_pixel_delay[i] <= 0;
                y_pixel_delay[i] <= 0;
            end

        end else begin
            air_de_delayed[0] <= DE_in;
            air_h_sync_delayed[0] <= h_sync_in;
            air_v_sync_delayed[0] <= v_sync_in;
            for (int i = 0; i < DC_LATENCY - 1; i++) begin
                air_de_delayed[i+1] <= air_de_delayed[i];
                air_h_sync_delayed[i+1] <= air_h_sync_delayed[i];
                air_v_sync_delayed[i+1] <= air_v_sync_delayed[i];
            end
            if (DE_in | airlight_de) begin
                // Dark Channel 모듈 지연
                pixel_888_air_delayed[0] <= pixel_in_888;
                for (int i = 0; i < DC_LATENCY - 1; i++) begin
                    pixel_888_air_delayed[i+1] <= pixel_888_air_delayed[i];
                end
            end

            guided_de_delayed[0] <= DE_in;
            for (int i = 0; i < GUIDED_DELAY_DEPTH - 1; i++) begin
                guided_de_delayed[i+1] <= guided_de_delayed[i];
            end
            if (DE_in | guided_de) begin
                // Dark Channel 모듈 지연
                pixel_888_guided_delayed[0] <= pixel_in_888;
                for (int i = 0; i < GUIDED_DELAY_DEPTH - 1; i++) begin
                    pixel_888_guided_delayed[i+1] <= pixel_888_guided_delayed[i];
                end
            end

            recover_de_delayed[0] <= DE_in;
            airlight_r_delayed[0] <= airlight_r_in;
            airlight_g_delayed[0] <= airlight_g_in;
            airlight_b_delayed[0] <= airlight_b_in;
            for (int i = 0; i < RECOVER_DELAY_DEPTH - 1; i++) begin
                recover_de_delayed[i+1] <= recover_de_delayed[i];
                airlight_r_delayed[i+1] <= airlight_r_delayed[i];
                airlight_g_delayed[i+1] <= airlight_g_delayed[i];
                airlight_b_delayed[i+1] <= airlight_b_delayed[i];
            end
            if (DE_in | recover_de) begin
                // Dark Channel 모듈 지연
                pixel_888_recover_delayed[0] <= pixel_in_888;
                for (int i = 0; i < RECOVER_DELAY_DEPTH - 1; i++) begin
                    pixel_888_recover_delayed[i+1] <= pixel_888_recover_delayed[i];
                end
            end
            
            final_h_sync_delay[0] <= h_sync_in;
            final_v_sync_delay[0] <= v_sync_in;
            x_pixel_delay[0] <= x_pixel_in;
            y_pixel_delay[0] <= y_pixel_in;
            for (int i = 0; i < FINAL_DELAY_DEPTH - 1; i++) begin
                final_h_sync_delay[i+1] <= final_h_sync_delay[i];
                final_v_sync_delay[i+1] <= final_v_sync_delay[i];
                x_pixel_delay[i+1] <= x_pixel_delay[i];
                y_pixel_delay[i+1] <= y_pixel_delay[i];
            end
        end
    end

    // logic [2:0] de_pipe;
    // always_ff @(posedge clk or posedge rst) begin
    //     if (rst) de_pipe <= 3'b0;
    //     else de_pipe <= {de_pipe[1:0], DE};
    // end

    // 최종 출력 할당
    assign pixel_for_airlight = pixel_888_air_delayed[DC_LATENCY-1];
    assign airlight_de = air_de_delayed[DC_LATENCY-1];
    assign h_sync_air = air_h_sync_delayed [DC_LATENCY-1];
    assign v_sync_air = air_v_sync_delayed [DC_LATENCY-1];

    assign pixel_for_guided   = pixel_888_guided_delayed[GUIDED_DELAY_DEPTH-1];
    assign guided_de = guided_de_delayed[GUIDED_DELAY_DEPTH-1];

    assign pixel_for_recover = pixel_888_recover_delayed[RECOVER_DELAY_DEPTH-1];
    assign recover_de = recover_de_delayed[RECOVER_DELAY_DEPTH-1];
    assign airlight_r_out = airlight_r_delayed[RECOVER_DELAY_DEPTH-1];
    assign airlight_g_out = airlight_g_delayed[RECOVER_DELAY_DEPTH-1];
    assign airlight_b_out = airlight_b_delayed[RECOVER_DELAY_DEPTH-1];
    
    assign h_sync_out = final_h_sync_delay [FINAL_DELAY_DEPTH-1];
    assign v_sync_out = final_v_sync_delay [FINAL_DELAY_DEPTH-1];
    assign x_pixel_out = x_pixel_delay[FINAL_DELAY_DEPTH-1];
    assign y_pixel_out = y_pixel_delay[FINAL_DELAY_DEPTH-1]; 


endmodule
