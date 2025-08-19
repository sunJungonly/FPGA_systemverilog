`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/06/02 16:49:22
// Design Name: 
// Module Name: ray_cross_unit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ray_cross_unit (
    input  logic        clk,
    input  logic [37:0] line,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    output logic        hit
);

    logic [9:0] x1, x2;
    logic [9:0] y1, y2;
    logic [9:0] x_pixel_s0;
    logic [9:0] y_pixel_s0;
    logic [9:0] x_pixel_s1;
    logic [9:0] x_pixel_s2;
    logic       x1x2position;
    logic       x1x2position_s1;

    logic [9:0] dx_s1;
    logic [9:0] dy_s1;
    logic       dx_lt8;
    logic       dx_lt4;
    logic       dy_lt8;
    logic       dy_lt4;
    logic [9:0] y_diff_s1;
    logic [9:0] xmin, xmax;
    logic [9:0] xmin_s1;
    logic [9:0] xmax_s1;
    logic [9:0] ymin, ymax;
    logic y_in_range_s1;
    logic y_in_range_s2;

    logic [9:0] x_intersect_s2;

    always_ff @(posedge clk) begin
        x1         <= line[37:28];  // 10-bit
        y1         <= line[27:19];  // 9-bit
        x2         <= line[18:9];  // 10-bit
        y2         <= line[8:0];  // 9-bit
        x_pixel_s0 <= x_pixel;
        y_pixel_s0 <= y_pixel;
    end

    assign ymin = (y1 > y2) ? y2 : y1;
    assign ymax = (y1 > y2) ? y1 : y2;
    assign xmin = (x1 > x2) ? x2 : x1;
    assign xmax = (x1 > x2) ? x1 : x2;
    assign x1x2position = (y1 > y2) ? (x1 > x2) : (x2 > x1);

    always_ff @(posedge clk) begin
        y_diff_s1       <= y_pixel_s0 - ymin;
        dy_s1           <= ymax - ymin;
        dx_s1           <= xmax - xmin;
        dx_lt8          <= ((xmax - xmin) < 8);
        dy_lt8          <= ((ymax - ymin) < 8);
        dx_lt4          <= ((xmax - xmin) < 4);
        dy_lt4          <= ((ymax - ymin) < 4);
        xmin_s1         <= xmin;
        xmax_s1         <= xmax;
        y_in_range_s1   <= (y_pixel_s0 > ymin) && (y_pixel_s0 <= ymax);
        x_pixel_s1      <= x_pixel_s0;
        x1x2position_s1 <= x1x2position;
    end

    always_ff @(posedge clk) begin
        if (dx_lt4 || dy_lt4) begin  // dx , dy = 00000xx
            case (1)
                (y_diff_s1 <= dy_s1[8:1] * 1): begin
                    if (x1x2position_s1)
                        x_intersect_s2 <= xmin_s1 + dx_s1[8:1] * 1;
                    else x_intersect_s2 <= xmax_s1 - dx_s1[8:1] * 1;
                end
                (y_diff_s1 <= dy_s1): begin
                    if (x1x2position_s1) x_intersect_s2 <= xmax_s1;
                    else x_intersect_s2 <= xmin_s1;
                end
            endcase
        end else if (dx_lt8 || dy_lt8) begin
            case (1)
                (y_diff_s1 <= dy_s1[8:2] * 1): begin
                    if (x1x2position_s1)
                        x_intersect_s2 <= xmin_s1 + dx_s1[8:2] * 1;
                    else x_intersect_s2 <= xmax_s1 - dx_s1[8:2] * 1;
                end
                (y_diff_s1 <= dy_s1[8:2] * 2): begin
                    if (x1x2position_s1)
                        x_intersect_s2 <= xmin_s1 + dx_s1[8:2] * 2;
                    else x_intersect_s2 <= xmax_s1 - dx_s1[8:2] * 2;
                end
                (y_diff_s1 <= dy_s1[8:2] * 3): begin
                    if (x1x2position_s1)
                        x_intersect_s2 <= xmin_s1 + dx_s1[8:2] * 3;
                    else x_intersect_s2 <= xmax_s1 - dx_s1[8:2] * 3;
                end
                (y_diff_s1 <= dy_s1): begin
                    if (x1x2position_s1) x_intersect_s2 <= xmax_s1;
                    else x_intersect_s2 <= xmin_s1;
                end
                default: begin
                    x_intersect_s2 <= xmin_s1;
                end
            endcase
        end else begin
            case (1)
                (y_diff_s1 <= dy_s1[8:3] * 1): begin
                    if (x1x2position_s1)
                        x_intersect_s2 <= xmin_s1 + dx_s1[8:3] * 1;
                    else x_intersect_s2 <= xmax_s1 - dx_s1[8:3] * 1;
                end
                (y_diff_s1 <= dy_s1[8:3] * 2): begin
                    if (x1x2position_s1)
                        x_intersect_s2 <= xmin_s1 + dx_s1[8:3] * 2;
                    else x_intersect_s2 <= xmax_s1 - dx_s1[8:3] * 2;
                end
                (y_diff_s1 <= dy_s1[8:3] * 3): begin
                    if (x1x2position_s1)
                        x_intersect_s2 <= xmin_s1 + dx_s1[8:3] * 3;
                    else x_intersect_s2 <= xmax_s1 - dx_s1[8:3] * 3;
                end
                (y_diff_s1 <= dy_s1[8:3] * 4): begin
                    if (x1x2position_s1)
                        x_intersect_s2 <= xmin_s1 + dx_s1[8:3] * 4;
                    else x_intersect_s2 <= xmax_s1 - dx_s1[8:3] * 4;
                end
                (y_diff_s1 <= dy_s1[8:3] * 5): begin
                    if (x1x2position_s1)
                        x_intersect_s2 <= xmin_s1 + dx_s1[8:3] * 5;
                    else x_intersect_s2 <= xmax_s1 - dx_s1[8:3] * 5;
                end
                (y_diff_s1 <= dy_s1[8:3] * 6): begin
                    if (x1x2position_s1)
                        x_intersect_s2 <= xmin_s1 + dx_s1[8:3] * 6;
                    else x_intersect_s2 <= xmax_s1 - dx_s1[8:3] * 6;
                end
                (y_diff_s1 <= dy_s1[8:3] * 7): begin
                    if (x1x2position_s1)
                        x_intersect_s2 <= xmin_s1 + dx_s1[8:3] * 7;
                    else x_intersect_s2 <= xmax_s1 - dx_s1[8:3] * 7;
                end
                (y_diff_s1 <= dy_s1): begin
                    if (x1x2position_s1) x_intersect_s2 <= xmax_s1;
                    else x_intersect_s2 <= xmin_s1;
                end
                default: begin
                    x_intersect_s2 <= xmin_s1;
                end
            endcase
        end
        y_in_range_s2 <= y_in_range_s1;
        x_pixel_s2    <= x_pixel_s1;
    end

    //assign hit = x_pixel_s1 > xmin_s1;
    assign hit = y_in_range_s2 && (x_intersect_s2 < x_pixel_s2);
endmodule
