`timescale 1ns / 1ps

module matrix_generate_15X15 #(
    parameter DATA_WIDTH  = 8,
    parameter DATA_DEPTH  = 640,
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
    output logic DE_out,
    output logic [DATA_WIDTH - 1:0] matrix_p[0:KERNEL_SIZE-1][0:KERNEL_SIZE-1]
);

    // row_data[1] ~ row_data[15]에 각 줄 최신 픽셀값이 들어온다고 가정
    logic [        DATA_WIDTH-1:0] row_data        [0:KERNEL_SIZE-1];
    logic                          DE_from_lb;

    Line_Buffer_for_DCP #(
        .IMAGE_WIDTH(DATA_DEPTH),
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_ROWS(KERNEL_SIZE)
    ) U_Line_Buffer (
        .clk         (clk),
        .pclk        (pclk),
        .rst         (rst),
        .pixel_in    (pixel_in),
        .DE          (DE),
        .h_sync      (h_sync),
        .v_sync      (v_sync),
        .x_pixel     (x_pixel),
        .y_pixel     (y_pixel),
        .row_data_out(row_data),
        .DE_out      (DE_from_lb)       // 지_out DE 출력
    );

    // --- Stage 1: 매트릭스 shift & 업데이트 ---
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int r = 0; r < KERNEL_SIZE; r++) begin
                for (int c = 0; c < KERNEL_SIZE; c++) begin
                    matrix_p[r][c] <= '0;
                end
            end
        end else if (DE_from_lb) begin  // 라인 버퍼 출력이 유효할 때 // && (x_pixel >= 1)
                // counter <= counter + 1;
                for (int r = 0; r < KERNEL_SIZE; r++) begin
                    for (int c = 0; c < KERNEL_SIZE - 1; c++) begin
                        matrix_p[r][c] <= matrix_p[r][c+1];
                        matrix_p[r][KERNEL_SIZE-1] <= row_data[r];
                    end
                end
        end
    end

    // --- Stage 2: 수평 윈도우 지연 처리 및 최종 제어 신호 생성 (가장 중요한 부분) ---
    localparam H_DELAY = KERNEL_SIZE / 2; // 매트릭스 중심까지의 지연 (7)
    logic DE_delayed;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
                DE_delayed <= 1'b0;
        end else begin
            // 제어 신호를 H_DELAY 만큼 파이프라인 레지스터를 통해 지연시킴
            DE_delayed <= DE_from_lb;
        end
    end

    // 최종적으로 지연된 제어 신호를 출력에 할당
    assign DE_out = DE_delayed;

endmodule
