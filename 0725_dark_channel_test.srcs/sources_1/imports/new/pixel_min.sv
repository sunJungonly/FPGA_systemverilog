`timescale 1ns / 1ps

module pixel_min #(
    parameter DATA_DEPTH = 320,
    parameter DATA_WIDTH = 8
) (
    input logic clk,
    input logic rst,
    //input port
    input logic [DATA_WIDTH - 1:0] r_in,
    input logic [DATA_WIDTH - 1:0] g_in,
    input logic [DATA_WIDTH - 1:0] b_in,
    input logic DE,
    input logic [8:0] x_pixel,
    input logic [8:0] y_pixel,
    //output port
    output logic [DATA_WIDTH - 1:0] min_val_out,
    output logic DE_out,  // 결과 데이터 유효 신호
    output logic [8:0] x_pixel_out,
    output logic [8:0] y_pixel_out
);

    logic [7 : 0] pixel_min_of_rgb_1st;
    logic [7 : 0] pixel_min_of_rgb_2st;

    logic [7 : 0] pixel_min_of_rgb_reg;

    assign pixel_min_of_rgb_1st = r_in > g_in ? g_in : r_in;
    assign  pixel_min_of_rgb_2st    =   b_in > pixel_min_of_rgb_1st ? pixel_min_of_rgb_1st : b_in;


    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pixel_min_of_rgb_reg <= 0;
            DE_out               <= 0;
            x_pixel_out          <= 0;
            y_pixel_out          <= 0;
        end else begin
            DE_out <= DE;

            if (DE) begin
                pixel_min_of_rgb_reg <= pixel_min_of_rgb_2st;
                x_pixel_out <= x_pixel;
                y_pixel_out <= y_pixel;
            end
        end
    end

    assign min_val_out = pixel_min_of_rgb_reg;

endmodule
