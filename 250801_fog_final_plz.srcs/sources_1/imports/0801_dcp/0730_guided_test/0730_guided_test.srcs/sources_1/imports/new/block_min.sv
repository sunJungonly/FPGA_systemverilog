`timescale 1ns / 1ps

module block_min #(
    parameter DATA_DEPTH  = 640,
    parameter DATA_WIDTH  = 8,
    parameter KERNEL_SIZE = 15
) (
    input logic clk,
    input logic rst,
    input logic pclk,
    //input port
    input logic DE,
    input logic h_sync,
    input logic v_sync,
    input logic [$clog2(DATA_DEPTH)-1:0] x_pixel,
    input logic [9:0] y_pixel,
    input logic [DATA_WIDTH - 1:0] pixel_in,
    //output port
    output logic [DATA_WIDTH - 1:0] min_val_out,
    output logic DE_out,
    output logic h_sync_out,
    output logic v_sync_out,
    output logic [$clog2(DATA_DEPTH)-1:0] x_pixel_out,
    output logic [$clog2(DATA_DEPTH)-1:0] y_pixel_out
);

    logic [DATA_WIDTH-1:0] my_matrix[0:KERNEL_SIZE-1][0:KERNEL_SIZE-1];
    logic DE_s0;
    logic [$clog2(DATA_DEPTH)-1:0] x_pixel_s0;
    logic [$clog2(DATA_DEPTH)-1:0] y_pixel_s0;

    matrix_generate_15X15 #(
        .DATA_WIDTH (DATA_WIDTH),
        .DATA_DEPTH (DATA_DEPTH),
        .KERNEL_SIZE(KERNEL_SIZE)
    ) ass (
        .clk        (clk),
        .rst        (rst),
        .DE         (DE),
        .h_sync     (h_sync),
        .v_sync     (v_sync),
        .x_pixel    (x_pixel),
        .y_pixel    (y_pixel),
        .pixel_in   (pixel_in),
        .DE_out     (DE_s0),
        .h_sync_out (h_sync_s0),
        .v_sync_out (v_sync_s0),
        .x_pixel_out(x_pixel_s0),
        .y_pixel_out(y_pixel_s0),
        .matrix_p   (my_matrix)
    );

    logic [DATA_WIDTH-1:0] row_mins_L1[0:KERNEL_SIZE-1] [0:7];
    logic [DATA_WIDTH-1:0] row_mins_L2[0:KERNEL_SIZE-1] [0:3];
    logic [DATA_WIDTH-1:0] row_mins_L3[0:KERNEL_SIZE-1] [0:1];
    logic [DATA_WIDTH-1:0] row_mins_L4[0:KERNEL_SIZE-1];

    logic DE_s1, DE_s2, DE_s3, DE_s4;  // 각 단계별 DE 신호
    logic [9:0] x_pixel_s1, x_pixel_s2, x_pixel_s3, x_pixel_s4;
    logic [9:0] y_pixel_s1, y_pixel_s2, y_pixel_s3, y_pixel_s4;
    logic
        h_sync_s1,
        h_sync_s2,
        h_sync_s3,
        h_sync_s4,
        h_sync_s5,
        h_sync_s6,
        h_sync_s7;
    logic
        v_sync_s1,
        v_sync_s2,
        v_sync_s3,
        v_sync_s4,
        v_sync_s5,
        v_sync_s6,
        v_sync_s7;

    // Stage 1 - Level 1
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // BUG FIX: 모든 레지스터 리셋
            for (int i = 0; i < KERNEL_SIZE; i++)
            row_mins_L1[i] <= '{default: '0};
            DE_s1 <= 1'b0;
            h_sync_s1 <= 0;
            v_sync_s1 <= 0;
            x_pixel_s1 <= 0;
            y_pixel_s1 <= 0;
        end else begin
            if (DE_s0) begin
                for (int i = 0; i < KERNEL_SIZE; i = i + 1) begin
                    for (int j = 0; j < 8; j = j + 1) begin
                        if (j * 2 + 1 < KERNEL_SIZE) begin
                            row_mins_L1[i][j] <= (my_matrix[i][j*2] < my_matrix[i][j*2+1]) ? my_matrix[i][j*2] : my_matrix[i][j*2+1];
                        end else begin
                            row_mins_L1[i][j] <= my_matrix[i][j*2];
                        end
                    end
                end
            end
            DE_s1 <= DE_s0; // BUG FIX: 제어신호는 리셋 아닐 때 항상 전파
            h_sync_s1 <= h_sync_s0;
            v_sync_s1 <= v_sync_s0;
            x_pixel_s1 <= x_pixel_s0;
            y_pixel_s1 <= y_pixel_s0;
        end
    end

    // Stage 1 - Level 2
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin  // BUG FIX: 리셋 로직 추가
            for (int i = 0; i < KERNEL_SIZE; i++)
            row_mins_L2[i] <= '{default: '0};
            DE_s2 <= 1'b0;
            h_sync_s2 <= 0;
            v_sync_s2 <= 0;
            x_pixel_s2 <= '0;
            y_pixel_s2 <= '0;
        end else begin
            if (DE_s1) begin
                for (int i = 0; i < KERNEL_SIZE; i++) begin
                    for (int j = 0; j < 4; j++) begin
                        row_mins_L2[i][j] <= (row_mins_L1[i][j*2] < row_mins_L1[i][j*2+1]) ? row_mins_L1[i][j*2] : row_mins_L1[i][j*2+1];
                    end
                end
            end
            DE_s2 <= DE_s1;
            h_sync_s2 <= h_sync_s1;
            v_sync_s2 <= v_sync_s1;
            x_pixel_s2 <= x_pixel_s1;
            y_pixel_s2 <= y_pixel_s1;
        end
    end

    // Stage 1 - Level 3
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin  // BUG FIX: 리셋 로직 추가
            for (int i = 0; i < KERNEL_SIZE; i++)
            row_mins_L3[i] <= '{default: '0};
            DE_s3 <= 1'b0;
            h_sync_s3 <= 0;
            v_sync_s3 <= 0;
            x_pixel_s3 <= '0;
            y_pixel_s3 <= '0;
        end else begin
            if (DE_s2) begin
                for (int i = 0; i < KERNEL_SIZE; i++) begin
                    for (int j = 0; j < 2; j++) begin
                        row_mins_L3[i][j] <= (row_mins_L2[i][j*2] < row_mins_L2[i][j*2+1]) ? row_mins_L2[i][j*2] : row_mins_L2[i][j*2+1];
                    end
                end
            end
            DE_s3 <= DE_s2;
            h_sync_s3 <= h_sync_s2;
            v_sync_s3 <= v_sync_s2;
            x_pixel_s3 <= x_pixel_s2;
            y_pixel_s3 <= y_pixel_s2;
        end
    end

    // Stage 1 - Level 4
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin  // BUG FIX: 리셋 로직 추가
            row_mins_L4 <= '{default: '0};
            DE_s4 <= 1'b0;
            h_sync_s4 <= 0;
            v_sync_s4 <= 0;
            x_pixel_s4 <= '0;
            y_pixel_s4 <= '0;
        end else begin
            if (DE_s3) begin
                for (int i = 0; i < KERNEL_SIZE; i++) begin
                    row_mins_L4[i] <= (row_mins_L3[i][0] < row_mins_L3[i][1]) ? row_mins_L3[i][0] : row_mins_L3[i][1];
                end
            end
            DE_s4 <= DE_s3;
            h_sync_s4 <= h_sync_s3;
            v_sync_s4 <= v_sync_s3;
            x_pixel_s4 <= x_pixel_s3;
            y_pixel_s4 <= y_pixel_s3;
        end
    end

    logic [DATA_WIDTH-1:0] final_min_L1[0:7];
    logic [DATA_WIDTH-1:0] final_min_L2[0:3];
    logic [DATA_WIDTH-1:0] final_min_L3[0:1];

    logic
        DE_s5,
        DE_s6,
        DE_s7;  // Stage 2 내부 파이프라인을 위한 DE 신호
    logic [9:0]
        x_pixel_s5,
        x_pixel_s6,
        x_pixel_s7;  // Stage 2 내부 파이프라인을 위한 x_pixel 신호
    logic [9:0]
        y_pixel_s5,
        y_pixel_s6,
        y_pixel_s7;  // Stage 2 내부 파이프라인을 위한 y_pixel 신호

    // Stage 2 - Level 1
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin  // BUG FIX: 리셋 로직 추가
            final_min_L1 <= '{default: '0};
            DE_s5 <= 1'b0;
            h_sync_s5 <= 0;
            v_sync_s5 <= 0;
            x_pixel_s5 <= '0;
            y_pixel_s5 <= '0;
        end else begin
            if (DE_s4) begin
                for (int j = 0; j < 7; j++) begin
                    // if (j * 2 + 1 < KERNEL_SIZE) begin
                    final_min_L1[j] <= (row_mins_L4[j*2] < row_mins_L4[j*2+1]) ? row_mins_L4[j*2] : row_mins_L4[j*2+1];
                    // end else begin
                    // final_min_L1[j] <= row_mins_L4[j];
                    // end
                end
                final_min_L1[7] <= row_mins_L4[14];
            end
            DE_s5 <= DE_s4;
            h_sync_s5 <= h_sync_s4;
            v_sync_s5 <= v_sync_s4;
            x_pixel_s5 <= x_pixel_s4;
            y_pixel_s5 <= y_pixel_s4;
        end
    end

    // Stage 2 - Level 2
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin  // BUG FIX: 리셋 로직 추가
            final_min_L2 <= '{default: '0};
            DE_s6 <= 1'b0;
            h_sync_s6 <= 0;
            v_sync_s6 <= 0;
            x_pixel_s6 <= '0;
            y_pixel_s6 <= '0;
        end else begin
            if (DE_s5) begin
                for (int j = 0; j < 4; j = j + 1) begin
                    final_min_L2[j] <= (final_min_L1[j*2] < final_min_L1[j*2+1]) ? final_min_L1[j*2] : final_min_L1[j*2+1];
                end
            end
            DE_s6 <= DE_s5;
            h_sync_s6 <= h_sync_s5;
            v_sync_s6 <= v_sync_s5;
            x_pixel_s6 <= x_pixel_s5;
            y_pixel_s6 <= y_pixel_s5;
        end
    end

    // Stage 2 - Level 3
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin  // BUG FIX: 리셋 로직 추가
            final_min_L3 <= '{default: '0};
            DE_s7 <= 1'b0;
            h_sync_s7 <= 0;
            v_sync_s7 <= 0;
            x_pixel_s7 <= '0;
            y_pixel_s7 <= '0;
        end else begin

            if (DE_s6) begin
                for (int j = 0; j < 2; j = j + 1) begin
                    final_min_L3[j] <= (final_min_L2[j*2] < final_min_L2[j*2+1]) ? final_min_L2[j*2] : final_min_L2[j*2+1];
                end
            end
            DE_s7 <= DE_s6;
            h_sync_s7 <= h_sync_s6;
            v_sync_s7 <= v_sync_s6;
            x_pixel_s7 <= x_pixel_s6;
            y_pixel_s7 <= y_pixel_s6;
        end
    end
    // Stage 2 - Level 4 (최종 결과)
    always_ff @(posedge pclk or posedge rst) begin
        if (rst) begin
            min_val_out <= '0;
            DE_out      <= 1'b0;
            h_sync_out  <= 0;
            v_sync_out  <= 0;
            x_pixel_out <= '0;
            y_pixel_out <= '0;
        end else begin
            if (DE_s7) begin
                min_val_out <= (final_min_L3[0] < final_min_L3[1]) ? final_min_L3[0] : final_min_L3[1];
            end
            // CORRECTED LOGIC: 제어 신호는 데이터 유효 여부와 상관없이 항상 한 클럭씩 지연되어야 함
            DE_out      <= DE_s7;
            h_sync_out  <= h_sync_s7;
            v_sync_out  <= v_sync_s7;
            x_pixel_out <= x_pixel_s7;
            y_pixel_out <= y_pixel_s7;
        end
    end

endmodule
