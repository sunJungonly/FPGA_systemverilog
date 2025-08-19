`timescale 1ns / 1ps

module airlight_A #(
    parameter IMAGE_WIDTH  = 320,
    parameter IMAGE_HEIGHT = 240,
    parameter DATA_WIDTH = 8
) (
    input logic clk,
    input logic rst,
    
    //input port
    input logic DE,
    input logic [$clog2(IMAGE_WIDTH)-1:0] x_pixel, 
    input logic [$clog2(IMAGE_HEIGHT)-1:0] y_pixel, 
    input logic [23:0] pixel_in_888,  
    input logic [DATA_WIDTH-1:0] dark_channel_in,  
    
    //output port
    output logic [DATA_WIDTH-1:0] airlight_r_out,
    output logic [DATA_WIDTH-1:0] airlight_g_out,
    output logic [DATA_WIDTH-1:0] airlight_b_out,
    output logic airlight_done
);

    assign r_8bit = {pixel_in_888[23:16]};
    assign g_8bit = {pixel_in_888[15:8]};
    assign b_8bit = {pixel_in_888[7:0]};

        // 프레임 내에서 가장 밝은 DC값과 그 때의 원본 픽셀값을 저장할 레지스터
    logic [DATA_WIDTH-1:0] max_dc_val_reg;
    logic [DATA_WIDTH-1:0] A_r_reg, A_g_reg, A_b_reg;

    // 프레임의 마지막 픽셀인지 확인하는 신호
    logic is_last_pixel;
    assign is_last_pixel = (x_pixel == IMAGE_WIDTH-1) && (y_pixel == IMAGE_HEIGHT-1);

    // 한 프레임 동안 가장 밝은 Dark Channel 픽셀과 그 때의 원본 픽셀을 찾는 로직
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            max_dc_val_reg <= '0;
            A_r_reg <= '0;
            A_g_reg <= '0;
            A_b_reg <= '0;
        end else if (DE) begin
            // 첫 픽셀일 경우, 현재 값으로 초기화
            if (x_pixel == 0 && y_pixel == 0) begin
                max_dc_val_reg <= dark_channel_in;
                A_r_reg <= r_8bit;
                A_g_reg <= g_8bit;
                A_b_reg <= b_8bit;
            end else begin
                // 현재 DC값이 기존의 최대값보다 크면 갱신
                if (dark_channel_in > max_dc_val_reg) begin
                    max_dc_val_reg <= dark_channel_in;
                    A_r_reg <= r_8bit;
                    A_g_reg <= g_8bit;
                    A_b_reg <= b_8bit;
                end
            end
        end
    end

    // 프레임이 끝나면, 최종 확정된 Airlight 값과 done 신호를 출력
    logic [DATA_WIDTH-1:0] final_A_r, final_A_g, final_A_b;
    logic final_A_done;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            final_A_r <= '0;
            final_A_g <= '0;
            final_A_b <= '0;
            final_A_done <= 1'b0;
        end else begin
            // 마지막 픽셀이 처리된 '다음' 클럭에 done 신호를 1로 만든다.
            final_A_done <= DE && is_last_pixel;
            if (DE && is_last_pixel) begin
                final_A_r <= A_r_reg;
                final_A_g <= A_g_reg;
                final_A_b <= A_b_reg;
            end
        end
    end

    assign airlight_r_out = final_A_r;
    assign airlight_g_out = final_A_g;
    assign airlight_b_out = final_A_b;
    assign airlight_done  = final_A_done;

endmodule
