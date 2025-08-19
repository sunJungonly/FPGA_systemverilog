
`timescale 1ns / 1ps

module airlight_A #(
    parameter DATA_DEPTH   = 640,
    parameter IMAGE_HEIGHT = 480,
    parameter DATA_WIDTH   = 8
) (
    input logic clk,
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

    // 마지막 유효 픽셀의 좌표를 저장할 레지스터 추가
    logic [9:0] last_valid_x;
    logic [9:0] last_valid_y;

    // 프레임의 마지막 픽셀인지 확인하는 신호
    logic v_sync_d1;
    logic vsync_posedge;
    assign vsync_posedge = ~v_sync_d1 && v_sync;

    always_ff @(posedge clk) begin
        v_sync_d1 <= v_sync;
    end

    // 한 프레임 동안 가장 밝은 Dark Channel 픽셀과 그 때의 원본 픽셀을 찾는 로직
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            max_dc_val_reg <= '0;
            A_r_reg <= '0;
            A_g_reg <= '0;
            A_b_reg <= '0;
        end else begin
            if (vsync_posedge) begin 
                max_dc_val_reg <= '0;
                A_r_reg <= '0;
                A_g_reg <= '0;
                A_b_reg <= '0;
            end else if (DE) begin
                if (dark_channel_in > max_dc_val_reg) begin
                    max_dc_val_reg <= dark_channel_in;
                    A_r_reg <= r_8bit;
                    A_g_reg <= g_8bit;
                    A_b_reg <= b_8bit;
                end
            end
        end
    end

    always_ff @(posedge clk) begin
        if (DE) begin // 입력이 유효할 때, 현재까지의 best-so-far 값을 출력
            airlight_r_out <= A_r_reg;
            airlight_g_out <= A_g_reg;
            airlight_b_out <= A_b_reg;
        end
end

endmodule
