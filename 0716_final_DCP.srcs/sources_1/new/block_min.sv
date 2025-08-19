`timescale 1ns / 1ps
module block_min #(
    parameter DATA_DEPTH  = 320,
    parameter DATA_WIDTH  = 8,
    parameter KERNEL_SIZE = 15
) (
    input logic clk,
    input logic rst,
    //input port
    input logic DE,
    input logic [$clog2(DATA_DEPTH)-1:0] x_pixel,
    input logic [DATA_WIDTH - 1:0] pixel_in,
    //output port
    output logic [DATA_WIDTH - 1:0] min_val_out,
    output logic DE_out,
    output logic [$clog2(DATA_DEPTH)-1:0] x_pixel_out
);

    logic [DATA_WIDTH-1:0] my_matrix[0:KERNEL_SIZE-1][0:KERNEL_SIZE-1];
    logic DE_s0;
    logic [$clog2(DATA_DEPTH)-1:0] x_pixel_s0;

    logic [DATA_WIDTH : 0] min_data;

    logic [DATA_WIDTH : 0] min_data_1;
    logic [DATA_WIDTH : 0] min_data_2;
    logic [DATA_WIDTH : 0] min_data_3;
    logic [DATA_WIDTH : 0] min_data_4;
    logic [DATA_WIDTH : 0] min_data_5;
    logic [DATA_WIDTH : 0] min_data_6;
    logic [DATA_WIDTH : 0] min_data_7;
    logic [DATA_WIDTH : 0] min_data_8;
    logic [DATA_WIDTH : 0] min_data_9;
    logic [DATA_WIDTH : 0] min_data_10;
    logic [DATA_WIDTH : 0] min_data_11;
    logic [DATA_WIDTH : 0] min_data_12;
    logic [DATA_WIDTH : 0] min_data_13;
    logic [DATA_WIDTH : 0] min_data_14;
    logic [DATA_WIDTH : 0] min_data_15;


    matrix_generate_15X15#(
        .DATA_WIDTH(DATA_WIDTH),
        .DATA_DEPTH(DATA_DEPTH)
    ) (
        .clk(clk),
        .rst(rst),

        .DE(DE),
        .x_pixel(x_pixel),
        .pixel_in(pixel_in),

        .DE_out(DE_s0),
        .x_pixel_out(x_pixel_s0),
        .matrix_p(my_matrix)
    );

    // --- 파이프라인 Stage 1: 각 행(Row)의 최솟값 계산 ---
    // 15개 행의 최솟값을 저장할 레지스터 배열
    logic [        DATA_WIDTH-1:0] row_mins_s1     [0:KERNEL_SIZE-1];
    logic                          DE_s1;
    logic [$clog2(DATA_DEPTH)-1:0] x_pixel_s1;
    logic [        DATA_WIDTH-1:0] current_row_min;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            DE_s1 <= 1'b0;
        end else if (DE_s0) begin // Stage 0 출력이 유효할 때만 연산 수행
            // 15개의 행에 대해 병렬로 최솟값 찾기 (for-loop는 병렬 하드웨어를 생성)
            for (int i = 0; i < KERNEL_SIZE; i = i + 1) begin
                current_row_min = my_matrix[i][0];
                for (int j = 1; j < KERNEL_SIZE; j = j + 1) begin
                    if (my_matrix[i][j] < current_row_min) begin
                        current_row_min = my_matrix[i][j];
                    end
                end
                row_mins_s1[i] <= current_row_min; // 각 행의 최솟값을 레지스터에 저장
            end
        end
        // 제어 신호도 한 클럭 지연시켜 동기화
        DE_s1 <= DE_s0;
        x_pixel_s1 <= x_pixel_s0;
    end

    // --- 파이프라인 Stage 2: 최종 최솟값 계산 ---
    logic [        DATA_WIDTH-1:0] final_min_s2;
    logic                          DE_s2;
    logic [$clog2(DATA_DEPTH)-1:0] x_pixel_s2;
    logic [        DATA_WIDTH-1:0] current_total_min = row_mins_s1[0];

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            DE_s2 <= 1'b0;
        end else if (DE_s1) begin // Stage 1 출력이 유효할 때만 연산 수행
            // 15개 '행의 최솟값'들 중에서 최종 최솟값 찾기
            for (int i = 1; i < KERNEL_SIZE; i = i + 1) begin
                if (row_mins_s1[i] < current_total_min) begin
                    current_total_min = row_mins_s1[i];
                end
            end
            final_min_s2 <= current_total_min; // 최종 최솟값을 레지스터에 저장
        end
        // 제어 신호도 한 클럭 지연
        DE_s2 <= DE_s1;
        x_pixel_s2 <= x_pixel_s1;
    end

    // 최종 출력 할당
    // Stage 2의 레지스터 출력을 모듈의 최종 출력으로 할당
    assign min_val_out = final_min_s2;
    assign DE_out      = DE_s2;
    assign x_pixel_out = x_pixel_s2;

endmodule
