`timescale 1ns / 1ps

module VGA_Controller(
    input logic clk,
    input logic reset,
    //input logic [3:0] sw_red,
    //input logic [3:0] sw_green,
    //input logic [3:0] sw_blue,
    output logic rclk,
    output logic h_sync,
    output logic v_sync,
    //output logic [3:0] red_port,
    //output logic [3:0] green_port,
    //output logic [3:0] blue_port
    output logic [9:0] x_pixel,
    output logic [9:0] y_pixel,
    output logic DE
    );

    //logic DE;
    //logic [9:0] x_pixel, y_pixel;

    assign rclk = clk;

    vga_Decoder U_VGA_DEC(
        .clk(clk),
        .reset(reset),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .DE(DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel)
);

endmodule

module vga_Decoder (
    input logic clk,
    input logic reset,
    output logic h_sync,
    output logic v_sync,
    output logic DE,
    output logic [9:0] x_pixel,
    output logic [9:0] y_pixel
);
    logic pclk;
    logic [9:0] h_counter;
    logic [9:0] v_counter;

    pixel_clk_gen U_Pix_Clk_Gen(
        .clk(clk),
        .reset(reset),
        .pclk(pclk)
    );

    pixel_counter U_Pix_Counter(
        .pclk(pclk),
        .reset(reset),
        .h_counter(h_counter),
        .v_counter(v_counter)
    );

    vga_decoder U_VGA_Decoder(
        .h_counter(h_counter),
        .v_counter(v_counter),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .DE(DE)
    );
endmodule

module pixel_clk_gen (
    input logic clk,
    input logic reset,
    output logic pclk
);
    logic [1:0] p_counter;

    always_ff @( posedge clk, posedge reset ) begin 
        if (reset) begin
            p_counter <= 0;
            pclk <= 1'b0;
        end
        else begin
            if (p_counter == 3) begin
                p_counter <= 0;
                pclk <= 1'b1;
            end
            else begin
                p_counter <= p_counter + 1'b1;
                pclk <= 0;
            end
        end
    end
endmodule

module pixel_counter (
    input logic pclk,
    input logic reset,
    output logic [9:0] h_counter,
    output logic [9:0] v_counter
);
    localparam H_MAX = 800, V_MAX = 525;

    always_ff @(posedge pclk, posedge reset) begin : Horizontal_counter
        if (reset) begin
            h_counter <= 0;
        end
        else begin
            if (h_counter == H_MAX - 1) begin
                h_counter <= 0;
            end
            else begin
                h_counter <= h_counter + 1'b1;
            end
        end
    end

    always_ff @( posedge pclk, posedge reset ) begin : Veritical_counter
        if (reset) begin
            v_counter <= 0;
        end
        else begin
            if (h_counter == H_MAX - 1) begin
                if (v_counter == V_MAX - 1) begin
                    v_counter <= 0;
                end
                else begin
                    v_counter <= v_counter + 1'b1;
                end
            end
        end
    end
endmodule



module vga_decoder (
    input  logic [9:0] h_counter,
    input  logic [9:0] v_counter,
    output logic       h_sync,
    output logic       v_sync,
    output logic [9:0] x_pixel,
    output logic [9:0] y_pixel,
    output logic       DE
);
    localparam H_Visible_area = 640;	
    localparam H_Front_porch  = 16;	
    localparam H_Sync_pulse   = 96;	
    localparam H_Back_porch   = 48;	
    localparam H_Whole_line   = 800;

    localparam V_Visible_area = 480;    
    localparam V_Front_porch  = 10;	    
    localparam V_Sync_pulse   = 2;	    
    localparam V_Back_porch   = 33;	    
    localparam V_Whole_frame  = 525;
    
    assign h_sync = !((h_counter >= (H_Visible_area + H_Front_porch)) && (h_counter < (H_Visible_area + H_Front_porch + H_Sync_pulse)));
    assign v_sync = !((v_counter >= (V_Visible_area + V_Front_porch)) && (v_counter < (V_Visible_area + V_Front_porch + V_Sync_pulse)));
    assign DE = (h_counter < H_Visible_area) && (v_counter < V_Visible_area);
    assign x_pixel = DE ? h_counter : 10'bz;
    assign y_pixel = DE ? v_counter : 10'bz;

endmodule

module display_data (
    input logic DE,
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port 
);
    logic x_0, x_1, x_2, x_3, x_4, x_5, x_6;
    logic [7:0] x;

    assign x_0 = ((x_pixel >= 0) & (x_pixel < 91));
    assign x_1 = ((x_pixel >= 91) & (x_pixel < 182));
    assign x_2 = ((x_pixel >= 182) & (x_pixel < 273));
    assign x_3 = ((x_pixel >= 273) & (x_pixel < 364));
    assign x_4 = ((x_pixel >= 364) & (x_pixel < 456));
    assign x_5 = ((x_pixel >= 456) & (x_pixel < 546));
    assign x_6 = ((x_pixel >= 546) & (x_pixel < 637));
    assign x_7 = ((x_pixel >= 637) & (x_pixel < 640));

    assign x = {x_7, x_6, x_5, x_4, x_3, x_2, x_1, x_0};

    logic y_0, y_1, y_2, y_3, y_4, y_5, y_6;
    logic [6:0] y;

    assign y_0 = ((x_pixel >= 0) & (x_pixel <106));
    assign y_1 = ((x_pixel >= 106) & (x_pixel <212));
    assign y_2 = ((x_pixel >= 212) & (x_pixel <318));
    assign y_3 = ((x_pixel >= 318) & (x_pixel <424));
    assign y_4 = ((x_pixel >= 424) & (x_pixel <530));
    assign y_5 = ((x_pixel >= 530) & (x_pixel <636));
    assign y_6 = ((x_pixel >= 636) & (x_pixel < 640));

    assign y = {y_6,y_5, y_4, y_3, y_2, y_1, y_0};

    always_comb begin 
        if (DE) begin
            if(y_pixel < 320) begin
                case (x)
                    8'b0000_0001: begin // white
                        red_port = 4'b1111;
                        green_port = 4'b1111;
                        blue_port = 4'b1111;
                    end
                    8'b0000_0010: begin // yellow
                        red_port = 4'b1111;
                        green_port = 4'b1111;
                        blue_port = 4'b0;
                    end
                    8'b0000_0100: begin // cyan
                        red_port = 4'b0000;
                        green_port = 4'b1111;
                        blue_port = 4'b1111;
                    end
                    8'b0000_1000: begin // green
                        red_port = 4'b0;
                        green_port = 4'b1111;
                        blue_port = 4'b0;
                    end
                    8'b0001_0000: begin // magenta
                        red_port = 4'b1111;
                        green_port = 4'b0;
                        blue_port = 4'b1111;
                    end
                    8'b0010_0000: begin // red
                        red_port = 4'b1111;
                        green_port = 4'b0;
                        blue_port = 4'b0;
                    end
                    8'b0100_0000: begin // blue
                        red_port = 4'b0;
                        green_port = 4'b0;
                        blue_port = 4'b1111;
                    end
                    8'b1000_0000: begin // blue
                        red_port = 4'b0;
                        green_port = 4'b0;
                        blue_port = 4'b1111;
                    end
                    default: begin // white
                        red_port = 4'b1111;
                        green_port = 4'b1111;
                        blue_port = 4'b1111;
                    end
                endcase
            end
            else if (y_pixel < 360) begin
                case (x)
                    8'b0000_0001: begin // blue
                        red_port = 4'b0;
                        green_port = 4'b0;
                        blue_port = 4'b1111;
                    end
                    8'b0000_0010: begin // black
                        red_port = 4'b0;
                        green_port = 4'b0;
                        blue_port = 4'b0;
                    end
                    8'b0000_0100: begin // magenta
                        red_port = 4'b1111;
                        green_port = 4'b0;
                        blue_port = 4'b1111;
                    end
                    8'b0000_1000: begin // black
                        red_port = 4'b0;
                        green_port = 4'b0;
                        blue_port = 4'b0;
                    end
                    8'b0001_0000: begin // cyan
                        red_port = 4'b0;
                        green_port = 4'b1111;
                        blue_port = 4'b1111;
                    end
                    8'b0010_0000: begin // black
                        red_port = 4'b0;
                        green_port = 4'b0;
                        blue_port = 4'b0;
                    end
                    8'b0100_0000: begin // white
                        red_port = 4'b1111;
                        green_port = 4'b1111;
                        blue_port = 4'b1111;
                    end
                    8'b1000_0000: begin // white
                        red_port = 4'b1111;
                        green_port = 4'b1111;
                        blue_port = 4'b1111;
                    end
                    default: begin // last bits ->  cyan
                        red_port = 4'b1111;
                        green_port = 4'b1111;
                        blue_port = 4'b1111;
                    end 
                endcase
            end
            else begin
                case(y)
                    7'b000_001: begin // 남색
                        red_port = 4'b0;
                        green_port = 4'b0010;
                        blue_port = 4'b0101;
                    end
                    7'b000_010: begin // white
                        red_port = 4'b1111;
                        green_port = 4'b1111;
                        blue_port = 4'b1111;
                    end
                    7'b000_100: begin // magenta
                        red_port = 4'b0100;
                        green_port = 4'b0000;
                        blue_port = 4'b1000;
                    end
                    7'b001_000: begin // black
                        red_port = 4'b0;
                        green_port = 4'b000;
                        blue_port = 4'b0;
                    end
                    7'b010_000: begin // very black
                        red_port = 4'b0;
                        green_port = 4'b0;
                        blue_port = 4'b0;
                    end
                    7'b100_000: begin // very very black
                        red_port = 4'b0;
                        green_port = 4'b0;
                        blue_port = 4'b0;
                    end
                    7'b1000_000: begin // very very black
                        red_port = 4'b0;
                        green_port = 4'b0;
                        blue_port = 4'b0;
                    end
                    default: begin
                        red_port = 4'b1111;
                        green_port = 4'b1111;
                        blue_port = 4'b1111;
                    end
                endcase
            end
        end
        else begin
            red_port = 4'bz;
            green_port = 4'bz;
            blue_port = 4'bz;
        end
    end
endmodule