`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/06/02 15:37:05
// Design Name: 
// Module Name: point_in_polygon
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


module point_in_polygon (
    // global signals
    input  logic        clk,
    input  logic        pclk,
    input  logic        reset,
    // pixcel positions
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    // patter_rom
    output logic        p_oe,
    output logic [ 6:0] p_Addr,
    input  logic [37:0] p_Data,
    // to game_state_fsm
    input  logic [ 2:0] pattern_num,
    input  logic        in_polygon_enable,
    output logic        in_polygon,
    output logic        in_polygon_valid
);
    logic state, state_next;
    logic [4:0] line_count_reg, line_count_next;
    logic [37:0] lines[0:30];
    logic [29:0] hits;
    logic [6:0] p_Addr_reg, p_Addr_next;
    logic p_oe_reg, p_oe_next;
    assign p_Addr = p_Addr_reg;
    assign p_oe   = p_oe_reg;
    localparam IDLE = 0, GET_PATTERN = 1;
    always_ff @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            line_count_reg <= 0;
            p_Addr_reg <= 0;
            p_oe_reg <= 0;
        end else begin
            state <= state_next;
            line_count_reg <= line_count_next;
            p_Addr_reg <= p_Addr_next;
            p_oe_reg <= p_oe_next;
        end
    end

    always_ff @(posedge clk) begin
        if (p_oe_reg) begin
            lines[line_count_reg] <= p_Data;
        end
    end

    always_comb begin
        p_oe_next = p_oe_reg;
        state_next = state;
        line_count_next = line_count_reg;
        p_Addr_next = p_Addr_reg;
        case (state)
            IDLE: begin
                p_oe_next = 0;
                if (in_polygon_enable) begin
                    state_next = GET_PATTERN;
                    line_count_next = 0;
                    p_oe_next = 1;
                    case (pattern_num)
                        0: p_Addr_next = 30 * 0;
                        1: p_Addr_next = 30 * 1;
                        2: p_Addr_next = 30 * 2;
                        3: p_Addr_next = 30 * 3;
                        4: p_Addr_next = 30 * 4;
                        5: p_Addr_next = 30 * 5;
                        6: p_Addr_next = 30 * 6;
                        7: p_Addr_next = 30 * 7;
                    endcase
                end
            end
            GET_PATTERN: begin
                p_oe_next = 1;
                if (line_count_reg == 30) begin
                    state_next = IDLE;
                    line_count_next = 0;
                    p_oe_next = 0;
                end else begin
                    line_count_next = line_count_reg + 1;
                    p_Addr_next = p_Addr_reg + 1;
                end
            end
        endcase
    end

    genvar i;
    generate
        for (i = 0; i < 30; i = i + 1) begin : ray_cross_units
            ray_cross_unit U_ray_cross_unit (
                .clk    (pclk),
                .line   (lines[i+1]),
                .x_pixel(x_pixel),
                .y_pixel(y_pixel),
                .hit    (hits[i])
            );
        end
    endgenerate
    logic in_polygon_f;
    always_ff @(posedge pclk) begin
        in_polygon <= in_polygon_f;
    end

    assign in_polygon_f = ^hits;  // XOR reduction — 홀수 개의 1이면 1, 아니면 0
    assign in_polygon_valid = state == IDLE;  // 모든 라인 다 받아온 후 유효

endmodule
