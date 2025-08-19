`timescale 1ns / 1ps
module block_min #(
    parameter DATA_DEPTH  = 320,
    parameter DATA_WIDTH  = 8,
    parameter KERNEL_SIZE = 3
) (
    input logic clk,
    input logic rst,
    //input port
    input logic [DATA_WIDTH - 1:0] pixel_in,
    input logic DE,
    input logic [8:0] x_pixel,
    input logic [8:0] y_pixel,
    //output port
    output logic [DATA_WIDTH - 1:0] min_val_out,
    output logic DE_out,
    output logic [8:0] x_pixel_out,
    output logic [8:0] y_pixel_out
);

// KERNEL_SIZE에 맞는 매트릭스 선언
    logic [DATA_WIDTH-1:0] my_matrix[0:KERNEL_SIZE-1][0:KERNEL_SIZE-1];
    
    // Stage 0: 매트릭스 생성 후의 신호
    logic DE_s0;
    logic [8:0] x_pixel_s0;
    logic [8:0] y_pixel_s0;

    // [수정] 15x15 전용이 아닌, KERNEL_SIZE를 파라미터로 받는 범용 모듈을 호출해야 합니다.
    matrix_generate_15X15 #(
        .DATA_WIDTH(DATA_WIDTH),
        .DATA_DEPTH(DATA_DEPTH),
        .KERNEL_SIZE(KERNEL_SIZE) // KERNEL_SIZE 파라미터 전달
    ) U_matrix_gen (
        .clk(clk),
        .rst(rst),
        .DE(DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .pixel_in(pixel_in),
        .DE_out(DE_s0),
        .x_pixel_out(x_pixel_s0),
        .y_pixel_out(y_pixel_s0),
        .matrix_p(my_matrix)
    );

    // --- [단순화] 파이프라인 Stage 1: 각 행(Row)의 최솟값 계산 ---
    // 3개 원소의 최솟값은 1개의 스테이지면 충분합니다.
    
    logic [DATA_WIDTH-1:0] row_mins [0:KERNEL_SIZE-1]; // 각 3개 행의 최솟값을 저장
    logic DE_s1;
    logic [8:0] x_pixel_s1, y_pixel_s1;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            row_mins <= '{default: '0};
            DE_s1 <= 1'b0;
            x_pixel_s1 <= '0;
            y_pixel_s1 <= '0;
        end else begin
            if (DE_s0) begin
                for (int i = 0; i < KERNEL_SIZE; i = i + 1) begin
                    // 3개 입력의 최소값을 한 번에 계산
                    logic [DATA_WIDTH-1:0] temp_min;
                    temp_min = (my_matrix[i][0] < my_matrix[i][1]) ? my_matrix[i][0] : my_matrix[i][1];
                    row_mins[i] <= (temp_min < my_matrix[i][2]) ? temp_min : my_matrix[i][2];
                end
            end
            // 제어 신호는 항상 다음 스테이지로 전달
            DE_s1 <= DE_s0;
            x_pixel_s1 <= x_pixel_s0;
            y_pixel_s1 <= y_pixel_s0;
        end
    end
    
    // --- [단순화] 파이프라인 Stage 2: 최종 최솟값 계산 ---
    // 3개의 행별 최솟값들 중 최종 최솟값을 계산합니다. 역시 1개의 스테이지면 충분합니다.

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            min_val_out <= '0;
            DE_out <= 1'b0;
            x_pixel_out <= '0;
            y_pixel_out <= '0;
        end else begin
            logic [DATA_WIDTH-1:0] final_min;
            if (DE_s1) begin
                // 3개의 row_mins 값 중 최종 최소값 계산
                logic [DATA_WIDTH-1:0] temp_min;
                temp_min = (row_mins[0] < row_mins[1]) ? row_mins[0] : row_mins[1];
                final_min = (temp_min < row_mins[2]) ? temp_min : row_mins[2];
                min_val_out <= final_min;
            end
            
            // 최종 출력 제어 신호 업데이트
            x_pixel_out <= x_pixel_s1;
            y_pixel_out <= y_pixel_s1;

            // 최종 DE_out은 파이프라인을 통과했고, 커널 윈도우가 유효 영역 내에 있을 때만 활성화
            // (커널의 좌상단이 (KERNEL_SIZE-1, KERNEL_SIZE-1) 좌표 이상이어야 함)
            if (DE_s1 && (y_pixel_s1 >= (KERNEL_SIZE - 1)) && (x_pixel_s1 >= (KERNEL_SIZE - 1))) begin
                 DE_out <= 1'b1;
            end else begin
                 DE_out <= 1'b0;
            end
        end
    end



endmodule
