
// `timescale 1ns / 1ps

// module airlight_A #(
//     parameter DATA_DEPTH   = 640,
//     parameter IMAGE_HEIGHT = 480,
//     parameter DATA_WIDTH   = 8
// ) (
//     input logic pclk,
//     input logic rst,

//     //input port
//     input logic                            DE,
//     input logic                            v_sync,
//     input logic [                    23:0] pixel_in_888,
//     input logic [          DATA_WIDTH-1:0] dark_channel_in,

//     //output port
//     output logic [DATA_WIDTH-1:0] airlight_r_out,
//     output logic [DATA_WIDTH-1:0] airlight_g_out,
//     output logic [DATA_WIDTH-1:0] airlight_b_out
// );

//     logic [DATA_WIDTH - 1:0] r_8bit;
//     logic [DATA_WIDTH - 1:0] g_8bit;
//     logic [DATA_WIDTH - 1:0] b_8bit;

//     assign r_8bit = {pixel_in_888[23:16]};
//     assign g_8bit = {pixel_in_888[15:8]};
//     assign b_8bit = {pixel_in_888[7:0]};

//     // 프레임 내에서 가장 밝은 DC값과 그 때의 원본 픽셀값을 저장할 레지스터
//     logic [DATA_WIDTH-1:0] max_dc_val_reg;
//     logic [DATA_WIDTH-1:0] A_r_reg, A_g_reg, A_b_reg;

//     // 마지막 유효 픽셀의 좌표를 저장할 레지스터 추가
//     // logic [9:0] last_valid_x;
//     // logic [9:0] last_valid_y;

//     // 프레임의 마지막 픽셀인지 확인하는 신호
//     logic v_sync_d1;
//     logic vsync_posedge;
//     assign vsync_posedge = ~v_sync_d1 && v_sync;

//     always_ff @(posedge pclk) begin
//         v_sync_d1 <= v_sync;
//     end

//     //  --- 역할 1: 프레임 내에서 최고의 후보를 '탐색' (pclk 기준) ---
//     always_ff @(posedge pclk or posedge rst) begin
//         if (rst) begin
//             max_dc_val_reg <= '0;
//             A_r_reg <= 'd222;
//             A_g_reg <= 'd222;
//             A_b_reg <= 'd222;
//         // 매 프레임 시작 시, 새로운 탐색을 위해 내부 레지스터를 리셋
//         end else if (vsync_posedge) begin
//             max_dc_val_reg <= '0;
//             A_r_reg <= 'd222;
//             A_g_reg <= 'd222;
//             A_b_reg <= 'd222;
//         // 프레임 진행 중, 유효 데이터가 들어오면 비교 및 갱신
//         end else if (DE) begin
//             if (dark_channel_in > max_dc_val_reg) begin
//                 max_dc_val_reg <= dark_channel_in;
//                 A_r_reg <= r_8bit;
//                 A_g_reg <= g_8bit;
//                 A_b_reg <= b_8bit;
//             end
//         end
//     end

//     // --- 역할 2: 최종 결과를 '래칭'하여 안정적으로 출력 (pclk 기준) ---
//     always_ff @(posedge pclk or posedge rst) begin
//         if (rst) begin
//             // 리셋 시 기본값 출력
//             airlight_r_out <= 'd222;
//             airlight_g_out <= 'd222;
//             airlight_b_out <= 'd222;
//         // 오직 프레임이 끝나는 순간에만, 탐색된 최종 결과로 출력을 갱신
//         end else if (vsync_posedge) begin
//             airlight_r_out <= A_r_reg;
//             airlight_g_out <= A_g_reg;
//             airlight_b_out <= A_b_reg;
//         end
//     end


// endmodule

`timescale 1ns / 1ps

module airlight_A #(
    parameter DATA_DEPTH   = 640,
    parameter IMAGE_HEIGHT = 480,
    parameter DATA_WIDTH   = 8,
    parameter THRESH_SCALE = 90    // 상위 10% 픽셀 선택 (0~100 비율)
) (
    input logic pclk,
    input logic rst,

    //input port
    input logic                  DE,
    input logic                  v_sync,
    input logic [          23:0] pixel_in_888,
    input logic [DATA_WIDTH-1:0] dark_channel_in,

    //output port
    output logic [DATA_WIDTH-1:0] airlight_r_out,
    output logic [DATA_WIDTH-1:0] airlight_g_out,
    output logic [DATA_WIDTH-1:0] airlight_b_out
);

    logic [DATA_WIDTH - 1:0] r_8bit, g_8bit, b_8bit;
    assign r_8bit = {pixel_in_888[23:16]};
    assign g_8bit = {pixel_in_888[15:8]};
    assign b_8bit = {pixel_in_888[7:0]};

    // 프레임 내에서 가장 밝은 DC값과 그 때의 원본 픽셀값을 저장할 레지스터
    logic [DATA_WIDTH-1:0] max_dc_val_reg;

    // 2. 상위 픽셀 누적 (Threshold: max_dc * THRESH_SCALE%)
    logic [31:0] sum_r, sum_g, sum_b;
    logic [31:0] pixel_count;

    // 프레임의 마지막 픽셀인지 확인하는 신호
    logic v_sync_d1;
    logic vsync_posedge;
    assign vsync_posedge = ~v_sync_d1 && v_sync;

    always_ff @(posedge pclk) begin
        v_sync_d1 <= v_sync;
    end

    //  --- 역할 1: 프레임 내에서 최고의 후보를 '탐색' (pclk 기준) ---
    always_ff @(posedge pclk or posedge rst) begin
        if (rst) begin
            max_dc_val_reg <= '0;
        end else if (vsync_posedge) begin
            max_dc_val_reg <= '0;
        end else if (DE) begin
            if (dark_channel_in > max_dc_val_reg) begin
                max_dc_val_reg <= dark_channel_in;
            end
        end
    end

    // --- 역할 2: 최종 결과를 '래칭'하여 안정적으로 출력 (pclk 기준) ---
    always_ff @(posedge pclk or posedge rst) begin
        if (rst) begin
            sum_r <= 0;
            sum_g <= 0;
            sum_b <= 0;
            pixel_count <= 0;
            // 오직 프레임이 끝나는 순간에만, 탐색된 최종 결과로 출력을 갱신
        end else if (vsync_posedge) begin
            sum_r <= 0;
            sum_g <= 0;
            sum_b <= 0;
            pixel_count <= 0;
        end else if (DE) begin
            if (dark_channel_in >= (max_dc_val_reg * THRESH_SCALE / 100)) begin
                sum_r <= sum_r + r_8bit;
                sum_g <= sum_g + g_8bit;
                sum_b <= sum_b + b_8bit;
                pixel_count <= pixel_count + 1;
            end
        end
    end

    always_ff @(posedge pclk or posedge rst) begin
        if (rst) begin
            airlight_r_out <= 8'd222;
            airlight_g_out <= 8'd222;
            airlight_b_out <= 8'd222;
        end else if (vsync_posedge) begin
            if (pixel_count != 0) begin
                airlight_r_out <= sum_r / pixel_count;
                airlight_g_out <= sum_g / pixel_count;
                airlight_b_out <= sum_b / pixel_count;
            end
        end
    end
endmodule
