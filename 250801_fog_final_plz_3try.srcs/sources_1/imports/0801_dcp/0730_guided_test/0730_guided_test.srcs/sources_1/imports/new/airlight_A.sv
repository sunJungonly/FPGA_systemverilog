`timescale 1ns / 1ps

module airlight_A #(
    parameter DATA_DEPTH   = 640,
    parameter IMAGE_HEIGHT = 480,
    parameter DATA_WIDTH   = 8,
    // --- EMA를 위한 파라미터 추가 ---
    // alpha 값을 결정합니다. 2 -> a=1/4, 3 -> a=1/8, 4 -> a=1/16
    // 값이 클수록 더 부드러워집니다 (이전 값의 영향이 커짐). 2 또는 3으로 시작하는 것을 추천합니다.
    parameter EMA_SHIFT   = 2,
    // R,G,B 값의 최대-최소 차이 허용치. 이 값보다 차이가 크면 유색으로 판단.
    parameter COLOR_THRESHOLD   = 25
) (
    input logic pclk,
    input logic rst,

    //input port
    input logic                            DE,
    input logic                            v_sync,
    input logic [                    23:0] pixel_in_888,
    input logic [          DATA_WIDTH-1:0] dark_channel_in,

    //output port
    output logic [DATA_WIDTH-1:0] airlight_r_out,
    output logic [DATA_WIDTH-1:0] airlight_g_out,
    output logic [DATA_WIDTH-1:0] airlight_b_out
);

    logic [DATA_WIDTH - 1:0] r_8bit;
    logic [DATA_WIDTH - 1:0] g_8bit;
    logic [DATA_WIDTH - 1:0] b_8bit;

    assign r_8bit = {pixel_in_888[23:16]};
    assign g_8bit = {pixel_in_888[15:8]};
    assign b_8bit = {pixel_in_888[7:0]};

    // 프레임 내에서 가장 밝은 DC값과 그 때의 원본 픽셀값을 저장할 레지스터
    logic [DATA_WIDTH-1:0] max_dc_val_reg;
    logic [DATA_WIDTH-1:0] A_r_reg, A_g_reg, A_b_reg;


    // 프레임의 마지막 픽셀인지 확인하는 신호
    logic v_sync_d1;
    logic vsync_posedge;
    assign vsync_posedge = ~v_sync_d1 && v_sync;

    always_ff @(posedge pclk) begin
        v_sync_d1 <= v_sync;
    end

    //색상 제약을 위한 로작
    logic [DATA_WIDTH-1:0] max_rgb, min_rgb;
    logic is_plausible_color;

    // 현재 픽셀의 R,G,B 중 최대값과 최소값 찾기 (조합 회로)
    always_comb begin
        // max 찾기
        if (r_8bit > g_8bit) max_rgb = r_8bit; else max_rgb = g_8bit;
        if (b_8bit > max_rgb) max_rgb = b_8bit;

        // min 찾기
        if (r_8bit < g_8bit) min_rgb = r_8bit; else min_rgb = g_8bit;
        if (b_8bit < min_rgb) min_rgb = b_8bit;
    end
    
    assign is_plausible_color = (max_rgb - min_rgb) < COLOR_THRESHOLD;
    
    //  --- 역할 1: 프레임 내에서 최고의 후보를 '탐색' (pclk 기준) ---
    always_ff @(posedge pclk or posedge rst) begin
        if (rst) begin
            max_dc_val_reg <= '0;
            A_r_reg <= 'd222;
            A_g_reg <= 'd222;
            A_b_reg <= 'd222;
        // 매 프레임 시작 시, 새로운 탐색을 위해 내부 레지스터를 리셋
        end else if (vsync_posedge) begin
            max_dc_val_reg <= '0;
            A_r_reg <= 'd222;
            A_g_reg <= 'd222;
            A_b_reg <= 'd222;
        // 프레임 진행 중, 유효 데이터가 들어오면 비교 및 갱신
        end else if (DE) begin
            if (dark_channel_in > max_dc_val_reg && is_plausible_color) begin
                max_dc_val_reg <= dark_channel_in;
                A_r_reg <= r_8bit;
                A_g_reg <= g_8bit;
                A_b_reg <= b_8bit;
            end
        end
    end

    // --- 역할 2: 최종 결과를 '래칭'하여 안정적으로 출력 (pclk 기준) ---
    always_ff @(posedge pclk or posedge rst) begin
        if (rst) begin
            // 리셋 시 기본값 출력
            airlight_r_out <= 'd222;
            airlight_g_out <= 'd222;
            airlight_b_out <= 'd222;
        // 오직 프레임이 끝나는 순간에만, 탐색된 최종 결과로 출력을 갱신
        end else if (vsync_posedge) begin
            // EMA 공식: new_A = (1/4)*current_A + (3/4)*previous_A
            // 하드웨어 구현: new_A = (current_A >> 2) + (previous_A - (previous_A >> 2))
            //   - current_A: 방금 탐색이 끝난 A_r_reg, A_g_reg, A_b_reg
            //   - previous_A: 현재 출력 레지스터에 저장된 airlight_c_out 값
            airlight_r_out <= (A_r_reg >> EMA_SHIFT) + (airlight_r_out - (airlight_r_out >> EMA_SHIFT));
            airlight_g_out <= (A_g_reg >> EMA_SHIFT) + (airlight_g_out - (airlight_g_out >> EMA_SHIFT));
            airlight_b_out <= (A_b_reg >> EMA_SHIFT) + (airlight_b_out - (airlight_b_out >> EMA_SHIFT));
        end
    end

endmodule
