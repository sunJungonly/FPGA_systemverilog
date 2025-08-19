`timescale 1ns / 1ps

module matrix_generate_15X15 #(
    parameter DATA_WIDTH  = 8,
    parameter DATA_DEPTH  = 640,
    parameter KERNEL_SIZE = 15
) (
    input logic clk,
    input logic rst,
    //input port
    input logic DE,
    input logic h_sync,
    input logic v_sync,
    input logic [$clog2(DATA_DEPTH)-1:0] x_pixel,
    input logic [9:0] y_pixel,
    input logic [DATA_WIDTH - 1:0] pixel_in,
    //output port
    output logic DE_out,
    output logic h_sync_out,
    output logic v_sync_out,
    output logic [$clog2(DATA_DEPTH)-1:0] x_pixel_out,
    output logic [$clog2(DATA_DEPTH)-1:0] y_pixel_out,
    output logic [DATA_WIDTH - 1:0] matrix_p[0:KERNEL_SIZE-1][0:KERNEL_SIZE-1]
);

    // row_data[1] ~ row_data[15]에 각 줄 최신 픽셀값이 들어온다고 가정
    logic [        DATA_WIDTH-1:0] row_data        [0:KERNEL_SIZE-1];
    logic                          DE_from_lb;
    logic                          h_sync_lb;
    logic                          v_sync_lb;
    logic [$clog2(DATA_DEPTH)-1:0] x_pixel_from_lb;
    logic [$clog2(DATA_DEPTH)-1:0] y_pixel_from_lb;
    logic [                   1:0] counter;

    Line_Buffer_for_DCP #(
        .IMAGE_WIDTH(DATA_DEPTH),
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_ROWS(KERNEL_SIZE)
    ) U_Line_Buffer (
        .clk         (clk),
        .rst         (rst),
        .pixel_in    (pixel_in),
        .DE          (DE),
        .h_sync      (h_sync),
        .v_sync      (v_sync),
        .x_pixel     (x_pixel),
        .y_pixel     (y_pixel),
        .row_data_out(row_data),
        .DE_out      (DE_from_lb),       // 지_out DE 출력
        .h_sync_out  (h_sync_lb),
        .v_sync_out  (v_sync_lb),
        .x_pixel_out (x_pixel_from_lb),  // 지연된 x_pixel 출력
        .y_pixel_out (y_pixel_from_lb)   // 지연된 x_pixel 출력
    );

    // --- Stage 1: 매트릭스 shift & 업데이트 ---
    integer r, c;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int r = 0; r < KERNEL_SIZE; r++) begin
                for (int c = 0; c < KERNEL_SIZE; c++) begin
                    matrix_p[r][c] <= '0;
                end
            end
            counter <= 0;
        end else if (DE_from_lb) begin  // 라인 버퍼 출력이 유효할 때 // && (x_pixel >= 1)
            counter <= counter + 1;
            if (counter == 3) begin
                counter <= 0;
                for (int r = 0; r < KERNEL_SIZE; r++) begin
                    for (int c = 0; c < KERNEL_SIZE - 1; c++) begin
                        matrix_p[r][c] <= matrix_p[r][c+1];
                        matrix_p[r][KERNEL_SIZE-1] <= row_data[r];
                    end
                end
            end
        end
    end

    // --- Stage 2: 수평 윈도우 지연 처리 및 최종 제어 신호 생성 (가장 중요한 부분) ---
    localparam H_DELAY = KERNEL_SIZE / 2; // 매트릭스 중심까지의 지연 (7)
    logic DE_delayed[0:H_DELAY];
    logic h_sync_delayed[0:H_DELAY];
    logic v_sync_delayed[0:H_DELAY];
    logic [$clog2(DATA_DEPTH)-1:0] x_pixel_delayed[0:H_DELAY];
    logic [$clog2(DATA_DEPTH)-1:0] y_pixel_delayed[0:H_DELAY];

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i <= H_DELAY; i++) begin
                DE_delayed[i] <= 1'b0;
                h_sync_delayed[i] <= 1'b0;
                v_sync_delayed[i] <= 1'b0;
                x_pixel_delayed[i] <= 0;
                y_pixel_delayed[i] <= 0;
            end
        end else begin
            // 제어 신호를 H_DELAY 만큼 파이프라인 레지스터를 통해 지연시킴
            DE_delayed[0] <= DE_from_lb;
            h_sync_delayed[0] <= h_sync_lb;
            v_sync_delayed[0] <= v_sync_lb;
            x_pixel_delayed[0] <= x_pixel_from_lb;
            y_pixel_delayed[0] <= y_pixel_from_lb;
            for (int i = 0; i < H_DELAY; i++) begin
                DE_delayed[i+1] <= DE_delayed[i];
                h_sync_delayed[i+1] <= h_sync_delayed[i];
                v_sync_delayed[i+1] <= v_sync_delayed[i];
                x_pixel_delayed[i+1] <= x_pixel_delayed[i];
                y_pixel_delayed[i+1] <= y_pixel_delayed[i];
            end
        end
    end

    // 최종적으로 지연된 제어 신호를 출력에 할당
    assign DE_out = DE_delayed[H_DELAY];
    assign h_sync_out = h_sync_delayed[H_DELAY];
    assign v_sync_out = v_sync_delayed[H_DELAY];
    assign x_pixel_out = x_pixel_delayed[H_DELAY];
    assign y_pixel_out = y_pixel_delayed[H_DELAY];

endmodule
