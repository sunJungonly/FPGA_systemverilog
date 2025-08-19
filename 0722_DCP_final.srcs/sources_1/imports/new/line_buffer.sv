`timescale 1ns / 1ps
module line_buffer (
    input  logic pclk,
    input  logic [9:0] x_pixel,
    input  logic [9:0] y_pixel,
    input  logic [11:0] data,
    output logic [11:0] row_data[0:14],
    output logic DE_out,
    output logic [$clog2(320)-1:0] x_pixel_out
);

    reg [11:0] line_buffer [0:13][0:639];
    reg [11:0] window [0:14][0:14];

    always_ff @( posedge pclk ) begin
        for(int i = 13; i > 0; i = i - 1)begin
            line_buffer[i][x_pixel] <= line_buffer[i - 1][x_pixel];
        end
        line_buffer[0][x_pixel] <= data;
    end

    always_ff @( posedge pclk ) begin
        for(int row = 0; row < 15; row++)begin
            for(int col = 14; col > 0; col--)begin
                window[row][col] <= window[row][col - 1];
            end
            if(!row) window[row][0] <= data;
            else window[row][0] <= line_buffer[row - 1][x_pixel];
        end
    end

    always_ff @( posedge pclk ) begin
        for(int row = 0; row < 15; row++)begin
            row_data[row] <= window[row][14];
        end
    end

endmodule
