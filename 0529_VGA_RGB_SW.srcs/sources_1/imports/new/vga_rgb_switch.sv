`timescale 1ns / 1ps

module vga_rgb_display (
    input  logic       DE,
    input  logic [3:0] sw_red,
    input  logic [3:0] sw_green,
    input  logic [3:0] sw_blue,
    input  logic       sw,
    input  logic [9:0] x_pixel,
    input  logic [9:0] y_pixel,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port
);

    logic [3:0] x_block;
    logic [4:0] x_block_2;
    logic [1:0] y_block;

    logic [3:0] r_port, g_port, b_port;

    assign red_port = !DE ? 4'bz : sw ? r_port : sw_red;
    assign blue_port = !DE ? 4'bz : sw ? b_port : sw_blue;
    assign green_port = !DE ? 4'bz : sw ? g_port : sw_green;


    assign x_block = x_pixel / 91;
    assign x_block_2 = x_pixel / 35;  //

    always_comb begin
        if (y_pixel < 313) begin
            y_block = 0;
        end else if (y_pixel < 361) begin
            y_block = 1;
        end else begin
            y_block = 2;
        end

        // 기본 색 초기화
        r_port = 4'd0;
        g_port = 4'd0;
        b_port = 4'd0;

        if (DE) begin
            case (y_block)
                2'd0: begin  // 상단 컬러 바
                    case (x_block)
                        0: begin
                            r_port = 4'd11;
                            g_port = 4'd11;
                            b_port = 4'd11;
                        end  //gray
                        1: begin
                            r_port = 4'd11;
                            g_port = 4'd11;
                            b_port = 4'd0;
                        end  //YELLOW;
                        2: begin
                            r_port = 4'd0;
                            g_port = 4'd11;
                            b_port = 4'd11;
                        end  //CYAN;
                        3: begin
                            r_port = 4'd0;
                            g_port = 4'd11;
                            b_port = 4'd0;
                        end  //GREEN;
                        4: begin
                            r_port = 4'd11;
                            g_port = 4'd0;
                            b_port = 4'd11;
                        end  //MAGENTA;
                        5: begin
                            r_port = 4'd11;
                            g_port = 4'd0;
                            b_port = 4'd0;
                        end  //RED;
                        6: begin
                            r_port = 4'd0;
                            g_port = 4'd0;
                            b_port = 4'd11;
                        end  //BLUE;
                        default: begin
                            r_port = 4'd0;
                            g_port = 4'd0;
                            b_port = 4'd0;
                        end
                    endcase
                end
                2'd1: begin  // 중간 검정 줄
                    case (x_block)
                        0: begin
                            r_port = 4'd0;
                            g_port = 4'd0;
                            b_port = 4'd11;
                        end  //BLUE;
                        1: begin
                            r_port = 4'd1;
                            g_port = 4'd1;
                            b_port = 4'd1;
                        end  //BLACK;
                        2: begin
                            r_port = 4'd11;
                            g_port = 4'd0;
                            b_port = 4'd11;
                        end  //MAGENTA;
                        3: begin
                            r_port = 4'd1;
                            g_port = 4'd1;
                            b_port = 4'd1;
                        end  //BLACK;
                        4: begin
                            r_port = 4'd0;
                            g_port = 4'd11;
                            b_port = 4'd11;
                        end  //CYAN;
                        5: begin
                            r_port = 4'd1;
                            g_port = 4'd1;
                            b_port = 4'd1;
                        end  //BLACK;
                        6: begin
                            r_port = 4'd11;
                            g_port = 4'd11;
                            b_port = 4'd11;
                        end  //gray
                        default: begin
                            r_port = 4'd0;
                            g_port = 4'd0;
                            b_port = 4'd0;
                        end
                    endcase
                end
                2'd2: begin  // 하단 그라데이션
                    case (x_block_2)
                        0, 1, 2: begin
                            r_port = 4'd0;
                            g_port = 4'd2;
                            b_port = 4'd4;
                        end
                        3, 4, 5: begin
                            r_port = 4'd15;
                            g_port = 4'd15;
                            b_port = 4'd15;
                        end
                        6, 7, 8: begin
                            r_port = 4'd3;
                            g_port = 4'd0;
                            b_port = 4'd6;
                        end
                        9, 10, 11: begin
                            r_port = 4'd1;
                            g_port = 4'd1;
                            b_port = 4'd1;
                        end
                        12: begin
                            r_port = 4'd1;
                            g_port = 4'd1;
                            b_port = 4'd1;
                        end
                        13: begin
                            r_port = 4'd2;
                            g_port = 4'd2;
                            b_port = 4'd2;
                        end
                        14: begin
                            r_port = 4'd3;
                            g_port = 4'd3;
                            b_port = 4'd3;
                        end
                        15, 16, 17: begin
                            r_port = 4'd1;
                            g_port = 4'd1;
                            b_port = 4'd1;
                        end
                        default: begin
                            r_port = 4'd0;
                            g_port = 4'd0;
                            b_port = 4'd0;
                        end
                    endcase
                end
                default: begin
                    r_port = 4'd0;
                    g_port = 4'd0;
                    b_port = 4'd0;
                end
            endcase
        end
    end
endmodule
