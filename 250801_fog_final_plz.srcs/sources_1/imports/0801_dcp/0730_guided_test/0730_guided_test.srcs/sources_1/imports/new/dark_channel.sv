`timescale 1ns / 1ps

module dark_channel (
    input logic clk,
    input logic rst,
    input logic pclk,
    //input port
    input logic [23:0] pixel_in_888,
    input logic DE,
    input logic [9:0] x_pixel,  // 라인 내 현재 픽셀 좌표 
    input logic [9:0] y_pixel,
    input logic h_sync,
    input logic v_sync,
    //output port
    output logic [7:0] dark_channel_out,  // dark channel 결과값
    output logic DE_out,  // 결과 데이터 유효 신호
    output logic h_sync_out,
    output logic v_sync_out,
    output logic [9:0] x_pixel_out,
    output logic [9:0] y_pixel_out
);

    localparam DATA_DEPTH = 640;
    localparam DATA_WIDTH = 8;

    logic [DATA_WIDTH-1:0] r_8bit;
    logic [DATA_WIDTH-1:0] g_8bit;
    logic [DATA_WIDTH-1:0] b_8bit;
    logic h_sync_wire, v_sync_wire;
    assign r_8bit = {pixel_in_888[23:16]};
    assign g_8bit = {pixel_in_888[15:8]};
    assign b_8bit = {pixel_in_888[7:0]};

    logic [DATA_WIDTH - 1 : 0] src_min_img;
    logic [DATA_WIDTH - 1 : 0] src_block_min_img;
    logic                      src_min_DE;
    logic                      src_block_min_DE;
    logic [$clog2(DATA_DEPTH)-1:0] src_min_x_pixel, src_min_y_pixel;
    logic [$clog2(DATA_DEPTH)-1:0] src_block_min_x_pixel, src_block_min_y_pixel;

    logic h_sync_out1, v_sync_out1, DE_out1;

    pixel_min #(
        .DATA_DEPTH(DATA_DEPTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) U_pixel_min (
        .clk        (clk),
        .rst        (rst),
        .r_in       (r_8bit),           // 8비트 R 채널 입력
        .g_in       (g_8bit),           // 8비트 G 채널 입력
        .b_in       (b_8bit),           // 8비트 B 채널 입력
        .DE         (DE),
        .h_sync     (h_sync),
        .v_sync     (v_sync),
        .x_pixel    (x_pixel),
        .y_pixel    (y_pixel),
        .min_val_out(src_min_img),
        .DE_out     (src_min_DE),
        .h_sync_out (h_sync_wire),
        .v_sync_out (v_sync_wire),
        .x_pixel_out(src_min_x_pixel),
        .y_pixel_out(src_min_y_pixel)
    );

    block_min #(
        .DATA_DEPTH (DATA_DEPTH),
        .DATA_WIDTH (DATA_WIDTH),
        .KERNEL_SIZE(15)
    ) U_block_min (  // 주변영역(블록) 내에서 최솟값 산출 => 지역적 진짜 어두운 영역 탐지
        .clk        (clk),
        .rst        (rst),
        .pclk        (pclk),
        .pixel_in   (src_min_img),
        .DE         (src_min_DE && DE),
        .h_sync     (h_sync_wire),
        .v_sync     (v_sync_wire),
        .x_pixel    (src_min_x_pixel),
        .y_pixel    (y_pixel),
        .min_val_out(src_block_min_img),
        .DE_out     (src_block_min_DE),
        .h_sync_out (h_sync_out1),
        .v_sync_out (v_sync_out1),
        .x_pixel_out(src_block_min_x_pixel),
        .y_pixel_out(src_block_min_y_pixel)
    );

    logic DE_pipe[0:52];
    logic h_sync_pipe[0:52];
    logic v_sync_pipe[0:52];
    logic [ 9:0] x_pixel_pipe[0:52];
    logic [ 9:0] y_pixel_pipe[0:52];
    // logic        DE_reg;
    // logic        h_sync_reg;
    // logic        v_sync_reg;
    // logic [ 9:0] x_pixel_reg;
    // logic [ 9:0] y_pixel_reg;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for(int i=0;i<53;i++)begin
                DE_pipe[i]     <= '0;
                h_sync_pipe[i]     <= '0;
                v_sync_pipe[i]     <= '0;
                x_pixel_pipe[i] <= '0;
                y_pixel_pipe[i] <= '0;
            end
        end else begin
            DE_pipe[0]     <= src_block_min_DE;
            h_sync_pipe[0]     <= h_sync_out1;
            v_sync_pipe[0]     <= v_sync_out1;
            x_pixel_pipe[0] <= src_block_min_x_pixel;
            y_pixel_pipe[0] <= src_block_min_y_pixel;
            for(int i=1;i<53;i++)begin
                DE_pipe[i]     <= DE_pipe[i-1];
                h_sync_pipe[i]     <= h_sync_pipe[i-1];
                v_sync_pipe[i]     <= v_sync_pipe[i-1];
                x_pixel_pipe[i] <= x_pixel_pipe[i-1];
                y_pixel_pipe[i] <= y_pixel_pipe[i-1];
            end
        end
    end

    // always_ff @(posedge clk or posedge rst) begin
    //     if (rst) begin
    //         DE_out     <= 0;
    //         h_sync_out     <= 0;
    //         v_sync_out     <= 0;
    //         x_pixel_out     <= 0;
    //         y_pixel_out     <= 0;
    //     end else begin
    //         DE_out     <= DE_pipe[12];
    //         h_sync_out     <= h_sync_pipe[12];
    //         v_sync_out     <= v_sync_pipe[12];
    //         x_pixel_out     <= x_pixel_pipe[12];
    //         y_pixel_out     <= y_pixel_pipe[12];
    //     end
    // end

    assign DE_out           = DE_pipe[51];
    assign h_sync_out       = h_sync_pipe[51];
    assign v_sync_out       = v_sync_pipe[51];
    assign x_pixel_out      = x_pixel_pipe[52];
    assign y_pixel_out      = y_pixel_pipe[52];

    assign dark_channel_out = src_block_min_img;

endmodule
