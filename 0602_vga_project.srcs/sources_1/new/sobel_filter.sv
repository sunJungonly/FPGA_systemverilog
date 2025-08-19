`timescale 1ns / 1ps
/*
x = [-1, 0, 1], [-2, 0 2], [-1, 0, 1]
y = [-1, -2, -1], [0,0,0], [1, 2, 1]
*/
module Sobel_Filter_origin (
    input logic clk,
    input logic [16:0] addr,
    input logic [11:0] data,
    output logic [3:0] sdata
);

    localparam threshold = 1_0000;

    // row, col -> line buffer
    logic [7:0] row;  // 0~239
    logic [8:0] col;  // 0~319

    assign row = addr / 320;
    assign col = addr % 320;

    logic [11:0]
        data_00,
        data_01,
        data_02,
        data_10,
        data_11,
        data_12,
        data_20,
        data_21,
        data_22;

    wire signed [15:0] xdata, ydata;
    logic [15:0] absx, absy;

    reg [11:0] mem0[319:0];
    reg [11:0] mem1[319:0];
    reg [11:0] mem2[319:0];

    // sobel filter
    always_ff @(posedge clk) begin
        mem2[col] <= mem1[col];
        mem1[col] <= mem0[col];
        mem0[col] <= data;
    end

    always_ff @(posedge clk) begin
        data_00 <= (row == 0 || col == 0) ? 0 : mem2[col-1];
        data_01 <= (row == 0) ? 0 : mem2[col];
        data_02 <= (row == 0 || col == 319) ? 0 : mem2[col+1];
        data_10 <= (col == 0) ? 0 : mem1[col-1];
        data_11 <= mem1[col];
        data_12 <= (col == 319) ? 0 : mem1[col+1];
        data_20 <= (col == 0 || row == 239) ? 0 : mem0[col-1];
        data_21 <= (row == 239) ? 0 : mem0[col];
        data_22 <= (col == 319 || row == 239) ? 0 : mem0[col+1];
    end

    assign xdata = data_02 + (data_12 << 1) + data_22 - data_00 - (data_10 << 1) - data_20;
    assign ydata = data_00 + (data_01 << 1) + data_02 - data_20 - (data_21 << 1) - data_22;

    assign absx = xdata[15] ? (~xdata + 1) : xdata;
    assign absy = ydata[15] ? (~ydata + 1) : ydata;

    assign sdata = (absx + absy > threshold) ? 4'hf : 4'h0;
endmodule

module Sobel_Filter (
    input logic clk,
    input logic [11:0] data00,
    input logic [11:0] data01,
    input logic [11:0] data02,
    input logic [11:0] data10,
    input logic [11:0] data11,
    input logic [11:0] data12,
    input logic [11:0] data20,
    input logic [11:0] data21,
    input logic [11:0] data22,
    output logic [3:0] sdata
);

    localparam threshold = 1_0000;

    wire signed [15:0] xdata, ydata;
    logic [15:0] absx, absy;

    assign xdata = data02 + (data12 << 1) + data22 - data00 - (data10 << 1) - data20;
    assign ydata = data00 + (data01 << 1) + data02 - data20 - (data21 << 1) - data22;

    assign absx = xdata[15] ? (~xdata + 1) : xdata;
    assign absy = ydata[15] ? (~ydata + 1) : ydata;

    assign sdata = (absx + absy > threshold) ? 4'hf : 4'h0;
endmodule

module line_buffer (
    input logic clk,
    input logic [16:0] addr,
    input logic [11:0] data,
    output logic data00,
    output logic data01,
    output logic data02,
    output logic data10,
    output logic data11,
    output logic data12,
    output logic data20,
    output logic data21,
    output logic data22
);
    // row, col -> line buffer
    logic [7:0] row;  // 0~239
    logic [8:0] col;  // 0~319

    // median filter parameters
    reg [11:0] fmem0[319:0];
    reg [11:0] fmem1[319:0];
    reg [11:0] fmem2[319:0];

    logic [11:0]
        data_00,
        data_01,
        data_02,
        data_10,
        data_11,
        data_12,
        data_20,
        data_21,
        data_22;

    always_ff @(posedge clk) begin
        fmem2[col] <= fmem1[col];
        fmem1[col] <= fmem0[col];
        fmem0[col] <= data;
    end

    always_ff @(posedge clk) begin
        data_00 <= (row == 0 || col == 0) ? 0 : fmem2[col-1];
        data_01 <= (row == 0) ? 0 : fmem2[col];
        data_02 <= (row == 0 || col == 319) ? 0 : fmem2[col+1];
        data_10 <= (col == 0) ? 0 : fmem1[col-1];
        data_11 <= fmem1[col];
        data_12 <= (col == 319) ? 0 : fmem1[col+1];
        data_20 <= (col == 0 || row == 239) ? 0 : fmem0[col-1];
        data_21 <= (row == 239) ? 0 : fmem0[col];
        data_22 <= (col == 319 || row == 239) ? 0 : fmem0[col+1];
    end

endmodule

module median_filter_bead (
    input  logic [11:0] data00,
    input  logic [11:0] data01,
    input  logic [11:0] data02,
    input  logic [11:0] data10,
    input  logic [11:0] data11,
    input  logic [11:0] data12,
    input  logic [11:0] data20,
    input  logic [11:0] data21,
    input  logic [11:0] data22,
    output logic [11:0] sdata
);

    reg [8:0] beads[11:0];
    integer i, j;
    reg [3:0] count;

    always_comb begin
        beads[0] = {
            data22[0],
            data21[0],
            data20[0],
            data12[0],
            data11[0],
            data10[0],
            data02[0],
            data01[0],
            data00[0]
        };
        beads[1] = {
            data22[1],
            data21[1],
            data20[1],
            data12[1],
            data11[1],
            data10[1],
            data02[1],
            data01[1],
            data00[1]
        };
        beads[2] = {
            data22[2],
            data21[2],
            data20[2],
            data12[2],
            data11[2],
            data10[2],
            data02[2],
            data01[2],
            data00[2]
        };
        beads[3] = {
            data22[3],
            data21[3],
            data20[3],
            data12[3],
            data11[3],
            data10[3],
            data02[3],
            data01[3],
            data00[3]
        };
        beads[4] = {
            data22[4],
            data21[4],
            data20[4],
            data12[4],
            data11[4],
            data10[4],
            data02[4],
            data01[4],
            data00[4]
        };
        beads[5] = {
            data22[5],
            data21[5],
            data20[5],
            data12[5],
            data11[5],
            data10[5],
            data02[5],
            data01[5],
            data00[5]
        };
        beads[6] = {
            data22[6],
            data21[6],
            data20[6],
            data12[6],
            data11[6],
            data10[6],
            data02[6],
            data01[6],
            data00[6]
        };
        beads[7] = {
            data22[7],
            data21[7],
            data20[7],
            data12[7],
            data11[7],
            data10[7],
            data02[7],
            data01[7],
            data00[7]
        };
        beads[8] = {
            data22[8],
            data21[8],
            data20[8],
            data12[8],
            data11[8],
            data10[8],
            data02[8],
            data01[8],
            data00[8]
        };
        beads[9] = {
            data22[9],
            data21[9],
            data20[9],
            data12[9],
            data11[9],
            data10[9],
            data02[9],
            data01[9],
            data00[9]
        };
        beads[10] = {
            data22[10],
            data21[10],
            data20[10],
            data12[10],
            data11[10],
            data10[10],
            data02[10],
            data01[10],
            data00[10]
        };                     
        beads[11] = {
            data22[11],
            data21[11],
            data20[11],
            data12[11],
            data11[11],
            data10[11],
            data02[11],
            data01[11],
            data00[11]
        };

        for (i = 0; i < 12; i = i + 1) begin

            count = 0;
            for (j = 0; j < 9; j = j + 1) begin
                count = count + beads[i][j];
            end
            for (j = 0; j < 9; j = j + 1) begin
                if (j < count) beads[i][j] = 1'b1;
                else beads[i][j] = 1'b0;
            end
        end

        for (i = 0; i < 12; i = i + 1) begin
            sdata[i] = beads[i][4];
        end
    end

endmodule

module frame_buffer1 (
    input logic wclk,
    input logic we,
    input logic [16:0] wAddr,
    input logic [15:0] wData,

    input logic rclk,
    input logic oe,
    input logic [16:0] rAddr,

    output logic [15:0] rData
);

    logic [15:0] mem[0:(320*240) - 1];

    always_ff @(posedge wclk) begin : write
        if (we) begin
            mem[wAddr] <= wData;
        end
    end

    always_ff @(posedge rclk) begin : read
        if (oe) begin
            rData = mem[rAddr];
        end
    end

endmodule

module gaussian_filter (
    input logic [3:0] fdata_00,
    input logic [3:0] fdata_01,
    input logic [3:0] fdata_02,
    input logic [3:0] fdata_10,
    input logic [3:0] fdata_11,
    input logic [3:0] fdata_12,
    input logic [3:0] fdata_20,
    input logic [3:0] fdata_21,
    input logic [3:0] fdata_22,

    output logic [3:0] filter_data 
);
    logic [7:0] avg_data;

    assign avg_data = fdata_00 + (fdata_01 << 1) + fdata_02 + (fdata_10 << 1) + (fdata_11 << 2) + (fdata_12 << 1) + fdata_20 + (fdata_21 << 1) + fdata_22;
    assign filter_data = avg_data >> 4;
endmodule


module canny_filter (
    input logic clk,
    input logic [16:0] addr,
    input logic [11:0] data,
    output logic [3:0] sdata
);
    // parameters
    localparam threshold = 700;
    localparam max = 300;
    localparam min = 100;

    logic [7:0] row;
    logic [8:0] col;

    assign row = addr / 320;
    assign col = addr % 320;

    // 1. Gaussian Filter 
    logic [11:0]
        fdata_00,
        fdata_01,
        fdata_02,
        fdata_10,
        fdata_11,
        fdata_12,
        fdata_20,
        fdata_21,
        fdata_22;

    reg [11:0] fmem0[319:0];
    reg [11:0] fmem1[319:0];
    reg [11:0] fmem2[319:0];

    logic [16:0] avg_data;
    logic [12:0] median_data;

    // 2. Sobel filter 
    logic [1:0] angle;
    logic [16:0] sobel_data;

    logic [12:0]
        data_00,
        data_01,
        data_02,
        data_10,
        data_11,
        data_12,
        data_20,
        data_21,
        data_22;

    wire signed [15:0] xdata, ydata;
    logic [15:0] absx, absy;

    reg [12:0] mem0  [319:0];
    reg [12:0] mem1  [319:0];
    reg [12:0] mem2  [319:0];

    // 3. Non-Maximum Suppression
    reg [18:0] mem0_3[319:0];
    reg [18:0] mem1_3[319:0];
    reg [18:0] mem2_3[319:0];

    logic [16:0] grad_now, grad1, grad2;
    assign grad_now = mem1_3[col][16:0];

    logic strong_neighbor;
    logic [3:0] nms;
    /////////////////////////////////////////////////////////////////////////////////////////////////////////

    // 1. Gaussian Filter 
    always_ff @(posedge clk) begin
        fmem2[col] <= fmem1[col];
        fmem1[col] <= fmem0[col];
        fmem0[col] <= data;
    end

    always_ff @(posedge clk) begin
        fdata_00 <= (row == 0 || col == 0) ? 0 : fmem2[col-1];
        fdata_01 <= (row == 0) ? 0 : fmem2[col];
        fdata_02 <= (row == 0 || col == 319) ? 0 : fmem2[col+1];
        fdata_10 <= (col == 0) ? 0 : fmem1[col-1];
        fdata_11 <= fmem1[col];
        fdata_12 <= (col == 319) ? 0 : fmem1[col+1];
        fdata_20 <= (col == 0 || row == 239) ? 0 : fmem0[col-1];
        fdata_21 <= (row == 239) ? 0 : fmem0[col];
        fdata_22 <= (col == 319 || row == 239) ? 0 : fmem0[col+1];
    end

    assign avg_data = fdata_00 + (fdata_01 << 1) + fdata_02 + (fdata_10 << 1) + (fdata_11 << 2) + (fdata_12 << 1) + fdata_20 + (fdata_21 << 1) + fdata_22;
    assign median_data = avg_data >> 4;

    // 2. Sobel filter
    always_ff @(posedge clk) begin
        mem2[col] <= mem1[col];
        mem1[col] <= mem0[col];
        mem0[col] <= data;
    end

    always_ff @(posedge clk) begin
        data_00 <= (row == 0 || col == 0) ? 0 : mem2[col-1];
        data_01 <= (row == 0) ? 0 : mem2[col];
        data_02 <= (row == 0 || col == 319) ? 0 : mem2[col+1];
        data_10 <= (col == 0) ? 0 : mem1[col-1];
        data_11 <= mem1[col];
        data_12 <= (col == 319) ? 0 : mem1[col+1];
        data_20 <= (col == 0 || row == 239) ? 0 : mem0[col-1];
        data_21 <= (row == 239) ? 0 : mem0[col];
        data_22 <= (col == 319 || row == 239) ? 0 : mem0[col+1];
    end

    assign xdata = data_02 + (data_12 << 1) + data_22 - data_00 - (data_10 << 1) - data_20;
    assign ydata = data_00 + (data_01 << 1) + data_02 - data_20 - (data_21 << 1) - data_22;

    assign absx = xdata[15] ? (~xdata + 1) : xdata;
    assign absy = ydata[15] ? (~ydata + 1) : ydata;

    assign sobel_data = absx + absy;

    // 0 -> 0 , 45 -> 1, 90 -> 2, 135 -> 3, 180 -> 4, 225 -> 5, 270 -> 6, 315 -> 7   
    always_comb begin
        if (absx > absy) begin
            if (xdata >= 0) angle = 1;  // 45
            else angle = 3;  // 135
        end else begin
            if (xdata < 0) angle = 2;  // 90
            else angle = 0;  // 0
        end
    end

    // 3. Non-Maximum Suppression
    always_ff @(posedge clk) begin
        mem2_3[col] <= mem1_3[col];
        mem1_3[col] <= mem0_3[col];
        mem0_3[col] <= {angle, sobel_data};
    end

    always_comb begin
        case (mem1_3[col][18:17])
            2'b00: begin  // ???? 
                grad1 = (col == 0) ? 0 : mem1_3[col-1][16:0];
                grad2 = (col == 319) ? 0 : mem1_3[col+1][16:0];
            end
            2'b01: begin  // ??O??
                grad1 = (row == 0 || col == 319) ? 0 : mem0_3[col+1][16:0];
                grad2 = (row == 239 || col == 0) ? 0 : mem2_3[col-1][16:0];
            end
            2'b10: begin  // ????
                grad1 = (row == 0) ? 0 : mem0_3[col][16:0];
                grad2 = (row == 239) ? 0 : mem2_3[col][16:0];
            end
            2'b11: begin  // ??O??
                grad1 = (row == 0 || col == 0) ? 0 : mem0_3[col-1][16:0];
                grad2 = (row == 239 || col == 319) ? 0 : mem2_3[col+1][16:0];
            end
        endcase
    end

    // 4. hyteresis thresholding
    always_comb begin
        if (grad_now >= grad1 && grad_now >= grad2 && grad_now > threshold) begin
            if (grad_now >= max) begin
                nms = 4'hF;  // strong edge
            end else if (grad_now >= min) begin
                // ??? 8?? ???? ???? ???? ???

                strong_neighbor = (col > 0 && row > 0)     & (mem0_3[col-1][16:0] >= max)
                | (row > 0)                & (mem0_3[col][16:0]   >= max) 
                | (col < 319 && row > 0)   & (mem0_3[col+1][16:0] >= max) 
                | (col > 0)                & (mem1_3[col-1][16:0] >= max) 
                | (col < 319)              & (mem1_3[col+1][16:0] >= max) 
                | (col > 0 && row < 239)   & (mem2_3[col-1][16:0] >= max) 
                | (row < 239)              & (mem2_3[col][16:0]   >= max) 
                | (col < 319 && row < 239) & (mem2_3[col+1][16:0] >= max); // SE

                if (strong_neighbor)
                    nms = 4'hF;  // ???? ?????????? ???? ?????? ???? ?? ????
                else nms = 4'h0;  // ????
            end else begin
                nms = 4'h0;  // ????
            end
        end else begin
            nms = 0;
        end
    end
    assign sdata = nms;
endmodule






































`timescale 1ns / 1ps

module TXT_VGA (
    input  logic               clk,
    input  logic               reset,
    input  logic        [ 1:0] stage,
    input  logic        [ 9:0] x_pixel,
    input  logic        [ 9:0] y_pixel,

    input  logic        [ 9:0] txt_x_pixel, // from game fsm
    input  logic        [ 9:0] txt_y_pixel, // "
    
    input  logic        [ 3:0] txt_mode,
    input  logic signed [19:0] score,
    
    output logic         txt_out,
    output logic               txt_done,
    output logic               tick_1s
);

  logic [95:0] char_buf_flat;
  logic [95:0] char_buf_stage1;
  logic [95:0] char_buf_stage2;
  logic [95:0] char_buf_stage3;
  logic [95:0] char_buf_stage4;

// txt ??? ????
  txt U_txt (
      .clk(clk),
      .x_pixel(x_pixel),
      .y_pixel(y_pixel),
      .txt_x_pixel(txt_x_pixel),
      .txt_y_pixel(txt_y_pixel),
      .scale(scale),
      .char_buf_flat(char_buf_flat),
      .char_buf_stage1(char_buf_stage1),
      .char_buf_stage2(char_buf_stage2),
      .char_buf_stage3(char_buf_stage3),
      .char_buf_stage4(char_buf_stage4),
      .txt_out(txt_out)
  );

// 1?? ????? ?????
  clk_gen_1s U_CLK_DIV (
      .clk  (clk),
      .reset(reset),
      .tick (tick_1s)
  );

    // txt ???? fsm
  txt_fsm U_txt_FSM (
      .clk(clk),
      .reset(reset),
      .tick(tick_1s),
      .state(txt_mode),
      .stage(stage),
      .score(score),
      .txt_done(txt_done),
      .char_buf_flat(char_buf_flat),
      .char_buf_stage1(char_buf_stage1),
      .char_buf_stage2(char_buf_stage2),
      .char_buf_stage3(char_buf_stage3),
      .char_buf_stage4(char_buf_stage4),
      .scale(scale)
  );

endmodule

module txt (
    input  logic        clk,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic [ 9:0] txt_x_pixel,
    input  logic [ 9:0] txt_y_pixel,
    input  logic        scale,
    input  logic [95:0] char_buf_flat,
    input  logic [95:0] char_buf_stage1,
    input  logic [95:0] char_buf_stage2,
    input  logic [95:0] char_buf_stage3,
    input  logic [95:0] char_buf_stage4,
    output logic  txt_out
);
    parameter X_MAX   = 320;
    parameter Y_MAX   = 240;
    
    parameter START_X = 272;
    parameter START_Y = Y_MAX - 8;

    parameter START_SX = 32;
    parameter START_SY = Y_MAX - 32;

    parameter START_STAGE_X = 520;
    parameter START_STAGE_Y = 40;

    parameter CHAR_WIDTH = 8;
    parameter STAGE_WIDTH = 8;
    parameter CHAR_HEIGHT = 8;
    parameter NUM_CHARS = 12;    
    
    parameter SCALE = 6;
    parameter SCALE2 = 4;

    // ------ range -------- //
    // char
    localparam CHAR_X_PRE = START_X;
    localparam CHAR_X_NEXT = START_X + NUM_CHARS * CHAR_WIDTH;
    localparam CHAR_Y_PRE = START_Y;
    localparam CHAR_Y_NEXT = START_Y + CHAR_HEIGHT;

    localparam CHAR_X_SPRE = START_SX;
    localparam CHAR_X_SNEXT = START_X + NUM_CHARS * CHAR_WIDTH * SCALE;
    localparam CHAR_Y_SPRE = START_SY;
    localparam CHAR_Y_SNEXT = START_Y + CHAR_HEIGHT * SCALE;

    // stage
    localparam STAGE1_X_PRE  = START_STAGE_X;
    localparam STAGE1_X_NEXT = START_STAGE_X + NUM_CHARS * CHAR_WIDTH;
    localparam STAGE1_Y_PRE  = START_STAGE_Y;
    localparam STAGE1_Y_NEXT = START_STAGE_Y + CHAR_HEIGHT;

    localparam STAGE2_X_PRE  = START_STAGE_X;
    localparam STAGE2_X_NEXT = START_STAGE_X + NUM_CHARS * CHAR_WIDTH;
    localparam STAGE2_Y_PRE  = 2 * START_STAGE_Y;
    localparam STAGE2_Y_NEXT = 2 * START_STAGE_Y + CHAR_HEIGHT;

    localparam STAGE3_X_PRE  = START_STAGE_X;
    localparam STAGE3_X_NEXT = START_STAGE_X + NUM_CHARS * CHAR_WIDTH;
    localparam STAGE3_Y_PRE  = 3 * START_STAGE_Y;
    localparam STAGE3_Y_NEXT = 3 * START_STAGE_Y + CHAR_HEIGHT;

    localparam STAGE4_X_PRE  = START_STAGE_X;
    localparam STAGE4_X_NEXT = START_STAGE_X + NUM_CHARS * CHAR_WIDTH;
    localparam STAGE4_Y_PRE  = 4 *START_STAGE_Y;
    localparam STAGE4_Y_NEXT = 4 * START_STAGE_Y + CHAR_HEIGHT;
    
    // rom
    logic [7:0] font_rom[0 : (256*8)-1];

    logic       in_char_block;
    logic       in_stage_block1, in_stage_block2, in_stage_block3, in_stage_block4;

    logic [2:0] row_in_char;  // 0~7
    logic [6:0] col_in_char;  // 0~7

    logic [2:0] row_in_stage1;  // 0~7
    logic [2:0] row_in_stage2;  // 0~7
    logic [2:0] row_in_stage3;  // 0~7
    logic [2:0] row_in_stage4;  // 0~7
    
    logic [6:0] col_in_stage;  // 0~7
  
    logic [7:0] font_row_data;
    logic       font_bit;

    logic [7:0] font_row_stage1;
    logic [7:0] font_row_stage2;
    logic [7:0] font_row_stage3;
    logic [7:0] font_row_stage4;

    logic       font_bit_stage1;
    logic       font_bit_stage2;
    logic       font_bit_stage3;
    logic       font_bit_stage4;
  
    logic [7:0] char_buf[0:11];
    logic [7:0] stage_buf1[0:11];
    logic [7:0] stage_buf2[0:11];
    logic [7:0] stage_buf3[0:11];
    logic [7:0] stage_buf4[0:11];

    logic [3:0] char_idx, stage_idx1, stage_idx2, stage_idx3, stage_idx4;
    logic [7:0] char_out, stage_out1, stage_out2, stage_out3, stage_out4;
    logic [9:0] scaled_x, scaled_y;

    logic txt_stage_out;
    logic txt_main_out;

    // scale setting
    assign scaled_x = x_pixel / SCALE;
    assign scaled_y = y_pixel / SCALE;
  
    // state, stage buffer 
    assign {char_buf[11], char_buf[10], char_buf[9], char_buf[8], char_buf[7], char_buf[6], char_buf[5], char_buf[4], char_buf[3], char_buf[2], char_buf[1], char_buf[0]} = char_buf_flat;
    
    assign {
        stage_buf1[11], 
        stage_buf1[10], 
        stage_buf1[9], 
        stage_buf1[8], 
        stage_buf1[7], 
        stage_buf1[6], 
        stage_buf1[5], 
        stage_buf1[4], 
        stage_buf1[3], 
        stage_buf1[2], 
        stage_buf1[1], 
        stage_buf1[0]
        } = char_buf_stage1;

    assign {
        stage_buf2[11], 
        stage_buf2[10], 
        stage_buf2[9], 
        stage_buf2[8], 
        stage_buf2[7], 
        stage_buf2[6], 
        stage_buf2[5], 
        stage_buf2[4], 
        stage_buf2[3], 
        stage_buf2[2], 
        stage_buf2[1], 
        stage_buf2[0]
        } = char_buf_stage2;

    assign {
        stage_buf3[11], 
        stage_buf3[10], 
        stage_buf3[9], 
        stage_buf3[8], 
        stage_buf3[7], 
        stage_buf3[6], 
        stage_buf3[5], 
        stage_buf3[4], 
        stage_buf3[3], 
        stage_buf3[2], 
        stage_buf3[1], 
        stage_buf3[0]
        } = char_buf_stage3;

    assign {
        stage_buf4[11], 
        stage_buf4[10], 
        stage_buf4[9], 
        stage_buf4[8], 
        stage_buf4[7], 
        stage_buf4[6], 
        stage_buf4[5], 
        stage_buf4[4], 
        stage_buf4[3], 
        stage_buf4[2], 
        stage_buf4[1], 
        stage_buf4[0]
        } = char_buf_stage4;

  // -------------------------------
  // position setting
  // -------------------------------

    assign in_char_block = scale ? ((x_pixel >= CHAR_X_SPRE) & (x_pixel < CHAR_X_SNEXT)) & ((y_pixel >= CHAR_Y_SPRE) & (y_pixel < CHAR_Y_SNEXT)) 
                                    : ((x_pixel >= CHAR_Y_PRE) & (x_pixel < CHAR_X_NEXT)) & ((y_pixel >= CHAR_Y_PRE) & (y_pixel < CHAR_Y_NEXT));

    assign in_stage_block1 = ((x_pixel >= STAGE1_X_PRE) & (x_pixel < STAGE1_X_NEXT)) & ((y_pixel >= STAGE1_Y_PRE) & (y_pixel < STAGE1_Y_NEXT));

    assign in_stage_block2 = ((x_pixel >= STAGE2_X_PRE) & (x_pixel < STAGE2_X_NEXT)) & ((y_pixel >= STAGE2_Y_PRE) & (y_pixel < STAGE2_Y_NEXT));

    assign in_stage_block3 = ((x_pixel >= STAGE3_X_PRE) & (x_pixel < STAGE3_X_NEXT)) & ((y_pixel >= STAGE3_Y_PRE) & (y_pixel < STAGE3_Y_NEXT));

    assign in_stage_block4 = ((x_pixel >= STAGE4_X_PRE) & (x_pixel < STAGE4_X_NEXT)) & ((y_pixel >= STAGE4_Y_PRE) & (y_pixel < STAGE4_Y_NEXT));

    always_comb begin
        row_in_char = 0;
        col_in_char = 0;
        char_idx    = 0;
        char_out    = 8'd32;

        row_in_stage1 = 0;
        row_in_stage2 = 0;
        row_in_stage3 = 0;
        row_in_stage4 = 0;

        col_in_stage = 0;
        
        stage_idx1    = 0;
        stage_idx2    = 0;
        stage_idx3    = 0;
        stage_idx4    = 0;

        stage_out1    = 8'd32;
        stage_out2    = 8'd32;
        stage_out3    = 8'd32;
        stage_out4    = 8'd32;

        if (in_char_block) begin
            row_in_char = scale ? (scaled_y - 34) : y_pixel - START_Y;
            col_in_char = scale ? (scaled_x - 5) : x_pixel - START_X;

            char_idx    = col_in_char / CHAR_WIDTH;  // 0~4 ?? ??? ???? ??????
            char_out    = char_buf[char_idx];  // ??? ???? ????
            col_in_char = col_in_char % CHAR_WIDTH;  // ??? ???? ???????? ??
        end

        // stage 1
        if (in_stage_block1) begin
            row_in_stage1 = y_pixel - STAGE1_Y_PRE;
            col_in_stage = x_pixel - STAGE1_X_PRE;

            stage_idx1    = col_in_stage / STAGE_WIDTH;  // 0~4 ?? ??? ???? ??????
            stage_out1    = stage_buf1[stage_idx1];  // ??? ???? ????
            col_in_stage = col_in_stage % STAGE_WIDTH;  // ??? ???? ???????? ??
        end

        // stage 2
        if (in_stage_block2) begin
            row_in_stage2 = y_pixel - STAGE2_Y_PRE;
            col_in_stage = x_pixel - STAGE2_X_PRE;

            stage_idx2    = col_in_stage / STAGE_WIDTH;  // 0~4 ?? ??? ???? ??????
            stage_out2    = stage_buf2[stage_idx2];  // ??? ???? ????
            col_in_stage = col_in_stage % STAGE_WIDTH;  // ??? ???? ???????? ??
        end
        // stage 3
        if (in_stage_block3) begin
            row_in_stage3 = y_pixel - STAGE3_Y_PRE;
            col_in_stage = x_pixel - STAGE3_X_PRE;

            stage_idx3    = col_in_stage / STAGE_WIDTH;  // 0~4 ?? ??? ???? ??????
            stage_out3    = stage_buf3[stage_idx3];  // ??? ???? ????
            col_in_stage = col_in_stage % STAGE_WIDTH;  // ??? ???? ???????? ??
        end
        // stage 4
        if (in_stage_block4) begin
            row_in_stage4 = y_pixel - STAGE4_Y_PRE;
            col_in_stage = x_pixel - STAGE4_X_PRE;

            stage_idx4    = col_in_stage / STAGE_WIDTH;  // 0~4 ?? ??? ???? ??????
            stage_out4    = stage_buf4[stage_idx4];  // ??? ???? ????
            col_in_stage = col_in_stage % STAGE_WIDTH;  // ??? ???? ???????? ??
        end
    end

    // -------------------------------
    // load font_rom
    // -------------------------------
    always_ff @(posedge clk) begin
        if (in_char_block) 
            font_row_data <= font_rom[{char_out, row_in_char}];
        else 
            font_row_data <= 8'h00;

        if (in_stage_block1) 
            font_row_stage1 <= font_rom[{stage_out1, row_in_stage1}];
        else 
            font_row_stage1 <= 8'h00;

        if (in_stage_block2) 
            font_row_stage2 <= font_rom[{stage_out2, row_in_stage2}];
        else 
            font_row_stage2 <= 8'h00;

        if (in_stage_block3) 
            font_row_stage3 <= font_rom[{stage_out3, row_in_stage3}];
        else 
            font_row_stage3 <= 8'h00;

        if (in_stage_block4) 
            font_row_stage4 <= font_rom[{stage_out4, row_in_stage4}];
        else 
            font_row_stage4 <= 8'h00;
    end

    // -------------------------------
    // RGB ??? ????
    // -------------------------------

    assign font_bit = font_row_data[7-col_in_char];
    assign font_bit_stage1 = font_row_stage1[7-col_in_stage];
    assign font_bit_stage2 = font_row_stage2[7-col_in_stage];
    assign font_bit_stage3 = font_row_stage3[7-col_in_stage];
    assign font_bit_stage4 = font_row_stage4[7-col_in_stage];
    
    // stage_text 
    assign txt_stage_out = ((in_stage_block1 & font_bit_stage1) | (in_stage_block2 & font_bit_stage2) | (in_stage_block3 & font_bit_stage3) | (in_stage_block4 & font_bit_stage4)) ? 1'b1 : 1'b0;
    
    // main_text
    assign txt_main_out = (in_char_block && font_bit) ? 1'b1 : 1'b0;

    // final text out
    assign txt_out = (txt_main_out) ? txt_main_out : txt_stage_out;

    initial begin
    // " " (ASCII 32) 
    font_rom[256] = 8'b00000000;
    font_rom[257] = 8'b00000000;
    font_rom[258] = 8'b00000000;
    font_rom[259] = 8'b00000000;
    font_rom[260] = 8'b00000000;
    font_rom[261] = 8'b00000000;
    font_rom[262] = 8'b00000000;
    font_rom[263] = 8'b00000000;

    // ???? '0' (ASCII 0x30 = 48)
    font_rom[384] = 8'b00111100;  // 48 * 8 + 0
    font_rom[385] = 8'b01000010;  // 48 * 8 + 1
    font_rom[386] = 8'b01000110;  // 48 * 8 + 2
    font_rom[387] = 8'b01001010;  // 48 * 8 + 3
    font_rom[388] = 8'b01010010;  // 48 * 8 + 4
    font_rom[389] = 8'b01100010;  // 48 * 8 + 5
    font_rom[390] = 8'b00111100;  // 48 * 8 + 6
    font_rom[391] = 8'b00000000;  // 48 * 8 + 7

    // "1" (ASCII 49)
    font_rom[392] = 8'b00010000;
    font_rom[393] = 8'b00110000;
    font_rom[394] = 8'b00010000;
    font_rom[395] = 8'b00010000;
    font_rom[396] = 8'b00010000;
    font_rom[397] = 8'b00010000;
    font_rom[398] = 8'b00010000;
    font_rom[399] = 8'b01111000;

    // "2" (ASCII 50)
    font_rom[400] = 8'b01111100;
    font_rom[401] = 8'b10000010;
    font_rom[402] = 8'b00000010;
    font_rom[403] = 8'b00011100;
    font_rom[404] = 8'b00100000;
    font_rom[405] = 8'b01000000;
    font_rom[406] = 8'b11111110;
    font_rom[407] = 8'b00000000;

    // "3" (ASCII 51)
    font_rom[408] = 8'b01111100;
    font_rom[409] = 8'b10000010;
    font_rom[410] = 8'b00000010;
    font_rom[411] = 8'b00111100;
    font_rom[412] = 8'b00000010;
    font_rom[413] = 8'b10000010;
    font_rom[414] = 8'b01111100;
    font_rom[415] = 8'b00000000;

    // "4" (ASCII 52)
    font_rom[416] = 8'b00000100;
    font_rom[417] = 8'b00001100;
    font_rom[418] = 8'b00010100;
    font_rom[419] = 8'b00100100;
    font_rom[420] = 8'b01000100;
    font_rom[421] = 8'b11111110;
    font_rom[422] = 8'b00000100;
    font_rom[423] = 8'b00000100;

    // "5" (ASCII 53)
    font_rom[424] = 8'b11111110;
    font_rom[425] = 8'b10000000;
    font_rom[426] = 8'b10000000;
    font_rom[427] = 8'b11111100;
    font_rom[428] = 8'b00000010;
    font_rom[429] = 8'b10000010;
    font_rom[430] = 8'b01111100;
    font_rom[431] = 8'b00000000;

    // "R" (ASCII 82)
    font_rom[656] = 8'b11111100;
    font_rom[657] = 8'b10000010;
    font_rom[658] = 8'b10000010;
    font_rom[659] = 8'b11111100;
    font_rom[660] = 8'b10100000;
    font_rom[661] = 8'b10010000;
    font_rom[662] = 8'b10001000;
    font_rom[663] = 8'b10000100;

    // "E" (ASCII 69)
    font_rom[552] = 8'b01111110;
    font_rom[553] = 8'b01111110;
    font_rom[554] = 8'b01100000;
    font_rom[555] = 8'b01111110;
    font_rom[556] = 8'b01100000;
    font_rom[557] = 8'b01111110;
    font_rom[558] = 8'b01111110;
    font_rom[559] = 8'b00000000;

    // "A" (ASCII 65)
    font_rom[520] = 8'b00111000;
    font_rom[521] = 8'b01000100;
    font_rom[522] = 8'b10000010;
    font_rom[523] = 8'b10000010;
    font_rom[524] = 8'b11111110;
    font_rom[525] = 8'b10000010;
    font_rom[526] = 8'b10000010;
    font_rom[527] = 8'b10000010;

    // "D" (ASCII 68)
    font_rom[544] = 8'b11111000;
    font_rom[545] = 8'b10000100;
    font_rom[546] = 8'b10000010;
    font_rom[547] = 8'b10000010;
    font_rom[548] = 8'b10000010;
    font_rom[549] = 8'b10000100;
    font_rom[550] = 8'b11111000;
    font_rom[551] = 8'b00000000;

    // "Y" (ASCII 89)
    font_rom[712] = 8'b10000010;
    font_rom[713] = 8'b10000010;
    font_rom[714] = 8'b01000100;
    font_rom[715] = 8'b00111000;
    font_rom[716] = 8'b00010000;
    font_rom[717] = 8'b00010000;
    font_rom[718] = 8'b00010000;
    font_rom[719] = 8'b00010000;

    // ???? 'P' (ASCII 0x50 = 80)
    font_rom[640] = 8'b01111100;  // 80 * 8 + 0
    font_rom[641] = 8'b01000010;  // 80 * 8 + 1
    font_rom[642] = 8'b01000010;  // 80 * 8 + 2
    font_rom[643] = 8'b01111100;  // 80 * 8 + 3
    font_rom[644] = 8'b01000000;  // 80 * 8 + 4
    font_rom[645] = 8'b01000000;  // 80 * 8 + 5
    font_rom[646] = 8'b01000000;  // 80 * 8 + 6
    font_rom[647] = 8'b01000000;  // 80 * 8 + 7

    // ???? 'S' (ASCII 0x53 = 83)
    font_rom[664] = 8'b00111110;  // 83 * 8 + 0
    font_rom[665] = 8'b01000000;  // 83 * 8 + 1
    font_rom[666] = 8'b00100000;  // 83 * 8 + 2
    font_rom[667] = 8'b00011100;  // 83 * 8 + 3
    font_rom[668] = 8'b00000010;  // 83 * 8 + 4
    font_rom[669] = 8'b00000010;  // 83 * 8 + 5
    font_rom[670] = 8'b01111100;  // 83 * 8 + 6
    font_rom[671] = 8'b00000000;  // 83 * 8 + 7

    // "F"
    font_rom[560] = 8'b11111111;
    font_rom[561] = 8'b10000000;
    font_rom[562] = 8'b10000000;
    font_rom[563] = 8'b11111110;
    font_rom[564] = 8'b10000000;
    font_rom[565] = 8'b10000000;
    font_rom[566] = 8'b10000000;
    font_rom[567] = 8'b10000000;

    // "I"
    font_rom[584] = 8'b11111110;
    font_rom[585] = 8'b00010000;
    font_rom[586] = 8'b00010000;
    font_rom[587] = 8'b00010000;
    font_rom[588] = 8'b00010000;
    font_rom[589] = 8'b00010000;
    font_rom[590] = 8'b00010000;
    font_rom[591] = 8'b11111110;

    // "L"
    font_rom[608] = 8'b01100000;
    font_rom[609] = 8'b01100000;
    font_rom[610] = 8'b01100000;
    font_rom[611] = 8'b01100000;
    font_rom[612] = 8'b01100000;
    font_rom[613] = 8'b01111110;
    font_rom[614] = 8'b01111110;
    font_rom[615] = 8'b00000000;

    // 'H' (ASCII 72)
    font_rom[576] = 8'b01100110;
    font_rom[577] = 8'b01100110;
    font_rom[578] = 8'b01111110;
    font_rom[579] = 8'b01111110;
    font_rom[580] = 8'b01100110;
    font_rom[581] = 8'b01100110;
    font_rom[582] = 8'b01100110;
    font_rom[583] = 8'b00000000;

    // 'O' (ASCII 79)
    font_rom[632] = 8'b01111110;
    font_rom[633] = 8'b01111110;
    font_rom[634] = 8'b01100110;
    font_rom[635] = 8'b01100110;
    font_rom[636] = 8'b01100110;
    font_rom[637] = 8'b01111110;
    font_rom[638] = 8'b01111110;
    font_rom[639] = 8'b00000000;

    // 'N' (ASCII 78)
    font_rom[624] = 8'b10000010;
    font_rom[625] = 8'b11000010;
    font_rom[626] = 8'b11100010;
    font_rom[627] = 8'b10110010;
    font_rom[628] = 8'b10011010;
    font_rom[629] = 8'b10001110;
    font_rom[630] = 8'b10000110;
    font_rom[631] = 8'b10000010;

    // 'W' (ASCII 87)
    font_rom[696] = 8'b10000010;
    font_rom[697] = 8'b10000010;
    font_rom[698] = 8'b10000010;
    font_rom[699] = 8'b10010010;
    font_rom[700] = 8'b10111010;
    font_rom[701] = 8'b11101110;
    font_rom[702] = 8'b11000110;
    font_rom[703] = 8'b10000010;

    // "G" (ASCII 71)
    font_rom[568] = 8'b00111100;
    font_rom[569] = 8'b01000010;
    font_rom[570] = 8'b10000000;
    font_rom[571] = 8'b10000000;
    font_rom[572] = 8'b10001110;
    font_rom[573] = 8'b10000010;
    font_rom[574] = 8'b01000010;
    font_rom[575] = 8'b00111100;

    // "T" (ASCII 84)
    font_rom[672] = 8'b11111111;
    font_rom[673] = 8'b00011000;
    font_rom[674] = 8'b00011000;
    font_rom[675] = 8'b00011000;
    font_rom[676] = 8'b00011000;
    font_rom[677] = 8'b00011000;
    font_rom[678] = 8'b00011000;
    font_rom[679] = 8'b00011000;

    // "C" (ASCII 67)
    font_rom[536] = 8'b00111100;
    font_rom[537] = 8'b01000010;
    font_rom[538] = 8'b10000000;
    font_rom[539] = 8'b10000000;
    font_rom[540] = 8'b10000000;
    font_rom[541] = 8'b10000000;
    font_rom[542] = 8'b01000010;
    font_rom[543] = 8'b00111100;

    // "6" (ASCII 54)
    font_rom[432] = 8'b00111100;
    font_rom[433] = 8'b01000010;
    font_rom[434] = 8'b10000000;
    font_rom[435] = 8'b11111100;
    font_rom[436] = 8'b10000010;
    font_rom[437] = 8'b10000010;
    font_rom[438] = 8'b01000010;
    font_rom[439] = 8'b00111100;

    // "7" (ASCII 55)
    font_rom[440] = 8'b11111110;
    font_rom[441] = 8'b00000010;
    font_rom[442] = 8'b00000100;
    font_rom[443] = 8'b00001000;
    font_rom[444] = 8'b00010000;
    font_rom[445] = 8'b00100000;
    font_rom[446] = 8'b01000000;
    font_rom[447] = 8'b10000000;

    // "8" (ASCII 56)
    font_rom[448] = 8'b00111100;
    font_rom[449] = 8'b01000010;
    font_rom[450] = 8'b01000010;
    font_rom[451] = 8'b00111100;
    font_rom[452] = 8'b01000010;
    font_rom[453] = 8'b01000010;
    font_rom[454] = 8'b01000010;
    font_rom[455] = 8'b00111100;

    // "9" (ASCII 57)
    font_rom[456] = 8'b00111100;
    font_rom[457] = 8'b01000010;
    font_rom[458] = 8'b01000010;
    font_rom[459] = 8'b00111110;
    font_rom[460] = 8'b00000010;
    font_rom[461] = 8'b00000010;
    font_rom[462] = 8'b01000010;
    font_rom[463] = 8'b00111100;

    // ???? '!'
    font_rom[264] = 8'b00011000;  // ?????? ????? ????? ?????
    font_rom[265] = 8'b00011000;
    font_rom[266] = 8'b00011000;
    font_rom[267] = 8'b00011000;
    font_rom[268] = 8'b00011000;
    font_rom[269] = 8'b00000000;
    font_rom[270] = 8'b00011000;  // ??? ??
    font_rom[271] = 8'b00000000;

    // ":" (ASCII 58)
    font_rom[464] = 8'b00000000;
    font_rom[465] = 8'b00000000;
    font_rom[466] = 8'b00011000;
    font_rom[467] = 8'b00011000;
    font_rom[468] = 8'b00000000;
    font_rom[469] = 8'b00011000;
    font_rom[470] = 8'b00011000;
    font_rom[471] = 8'b00000000;

    // "." (ASCII 46)
    font_rom[368] = 8'b00000000;
    font_rom[369] = 8'b00000000;
    font_rom[370] = 8'b00000000;
    font_rom[371] = 8'b00000000;
    font_rom[372] = 8'b00000000;
    font_rom[373] = 8'b00000000;
    font_rom[374] = 8'b00011000;
    font_rom[375] = 8'b00011000;
  end

endmodule

module txt_fsm (
    input logic clk,
    input logic reset,
    input logic tick,
    input logic [3:0] state,
    input logic [1:0] stage,
    input logic signed [19:0] score,
    output logic txt_done,
    output logic [95:0] char_buf_flat,
    output logic [95:0] char_buf_stage1,
    output logic [95:0] char_buf_stage2,
    output logic [95:0] char_buf_stage3,
    output logic [95:0] char_buf_stage4,
    output logic scale
);

  logic [7:0] char_buf[0:11];
  logic [7:0] stage_buf1[0:11];
  logic [7:0] stage_buf2[0:11];
  logic [7:0] stage_buf3[0:11];
  logic [7:0] stage_buf4[0:11];

  assign char_buf_flat = {
    char_buf[11],
    char_buf[10],
    char_buf[9],
    char_buf[8],
    char_buf[7],
    char_buf[6],
    char_buf[5],
    char_buf[4],
    char_buf[3],
    char_buf[2],
    char_buf[1],
    char_buf[0]
  };

    assign char_buf_stage1 = {
        stage_buf1[11], 
        stage_buf1[10], 
        stage_buf1[9], 
        stage_buf1[8], 
        stage_buf1[7], 
        stage_buf1[6], 
        stage_buf1[5], 
        stage_buf1[4], 
        stage_buf1[3], 
        stage_buf1[2], 
        stage_buf1[1], 
        stage_buf1[0]
    };

    assign char_buf_stage2 = {
        stage_buf2[11], 
        stage_buf2[10], 
        stage_buf2[9], 
        stage_buf2[8], 
        stage_buf2[7], 
        stage_buf2[6], 
        stage_buf2[5], 
        stage_buf2[4], 
        stage_buf2[3], 
        stage_buf2[2], 
        stage_buf2[1], 
        stage_buf2[0]
    };

    assign char_buf_stage3 = {
        stage_buf3[11], 
        stage_buf3[10], 
        stage_buf3[9], 
        stage_buf3[8], 
        stage_buf3[7], 
        stage_buf3[6], 
        stage_buf3[5], 
        stage_buf3[4], 
        stage_buf3[3], 
        stage_buf3[2], 
        stage_buf3[1], 
        stage_buf3[0]
    };

    assign char_buf_stage4 = {
        stage_buf4[11], 
        stage_buf4[10], 
        stage_buf4[9], 
        stage_buf4[8], 
        stage_buf4[7], 
        stage_buf4[6], 
        stage_buf4[5], 
        stage_buf4[4], 
        stage_buf4[3], 
        stage_buf4[2], 
        stage_buf4[1], 
        stage_buf4[0]
    };

  typedef enum logic [3:0] {
    S_IDLE = 4'd0,
    S_SPACE = 4'd1,
    S_START = 4'd5,
    S_PASS = 4'd6,
    S_FAIL = 4'd7,
    S_SCORE = 4'd8,
    S_SCORE_FINAL = 4'd9
  } state_t;

  logic tick_1s;

  logic [2:0] cnt5;
  logic [1:0] cnt3;

  logic [3:0] v, w, x, y, z;
  assign abs_score = (score < 0) ? -score : score;
  assign v = abs_score / 10000 % 10;
  assign w = abs_score / 1000 % 10;
  assign x = abs_score / 100 % 10;
  assign y = abs_score / 10 % 10;
  assign z = abs_score % 10;

    always_ff @( posedge clk, posedge reset) begin
        if (reset) begin
            stage_buf1[ 0] <= " ";
            stage_buf1[ 1] <= " ";
            stage_buf1[ 2] <= " ";
            stage_buf1[ 3] <= " ";
            stage_buf1[ 4] <= " ";
            stage_buf1[ 5] <= " ";
            stage_buf1[ 6] <= " ";
            stage_buf1[ 7] <= " ";
            stage_buf1[ 8] <= " ";
            stage_buf1[ 9] <= " ";
            stage_buf1[10] <= " ";
            stage_buf1[11] <= " ";

            stage_buf2[ 0] <= " ";
            stage_buf2[ 1] <= " ";
            stage_buf2[ 2] <= " ";
            stage_buf2[ 3] <= " ";
            stage_buf2[ 4] <= " ";
            stage_buf2[ 5] <= " ";
            stage_buf2[ 6] <= " ";
            stage_buf2[ 7] <= " ";
            stage_buf2[ 8] <= " ";
            stage_buf2[ 9] <= " ";
            stage_buf2[10] <= " ";
            stage_buf2[11] <= " ";

            stage_buf3[ 0] <= " ";
            stage_buf3[ 1] <= " ";
            stage_buf3[ 2] <= " ";
            stage_buf3[ 3] <= " ";
            stage_buf3[ 4] <= " ";
            stage_buf3[ 5] <= " ";
            stage_buf3[ 6] <= " ";
            stage_buf3[ 7] <= " ";
            stage_buf3[ 8] <= " ";
            stage_buf3[ 9] <= " ";
            stage_buf3[10] <= " ";
            stage_buf3[11] <= " ";

            stage_buf4[ 0] <= " ";
            stage_buf4[ 1] <= " ";
            stage_buf4[ 2] <= " ";
            stage_buf4[ 3] <= " ";
            stage_buf4[ 4] <= " ";
            stage_buf4[ 5] <= " ";
            stage_buf4[ 6] <= " ";
            stage_buf4[ 7] <= " ";
            stage_buf4[ 8] <= " ";
            stage_buf4[ 9] <= " ";
            stage_buf4[10] <= " ";
            stage_buf4[11] <= " ";
        end
        else
        case(stage)
            2'b00: begin
                stage_buf1[ 0] <= "S";
                stage_buf1[ 1] <= "T";
                stage_buf1[ 2] <= "A";
                stage_buf1[ 3] <= "G";
                stage_buf1[ 4] <= "E";
                stage_buf1[ 5] <= "1";
                stage_buf1[ 6] <= ":";
                stage_buf1[ 7] <= " ";
                stage_buf1[ 8] <= " ";
                stage_buf1[ 9] <= " ";
                stage_buf1[10] <= " ";
                stage_buf1[11] <= " ";
            end    
            2'b01: begin
                stage_buf2[ 0] <= "S";
                stage_buf2[ 1] <= "T";
                stage_buf2[ 2] <= "A";
                stage_buf2[ 3] <= "G";
                stage_buf2[ 4] <= "E";
                stage_buf2[ 5] <= "2";
                stage_buf2[ 6] <= ":";
                stage_buf2[ 7] <= " ";
                stage_buf2[ 8] <= " ";
                stage_buf2[ 9] <= " ";
                stage_buf2[10] <= " ";
                stage_buf2[11] <= " ";
            end
            2'b10: begin
                stage_buf3[ 0] <= "S";
                stage_buf3[ 1] <= "T";
                stage_buf3[ 2] <= "A";
                stage_buf3[ 3] <= "G";
                stage_buf3[ 4] <= "E";
                stage_buf3[ 5] <= "3";
                stage_buf3[ 6] <= ":";
                stage_buf3[ 7] <= " ";
                stage_buf3[ 8] <= " ";
                stage_buf3[ 9] <= " ";
                stage_buf3[10] <= " ";
                stage_buf3[11] <= " ";
            end
            2'b11: begin
                stage_buf4[ 0] <= "S";
                stage_buf4[ 1] <= "T";
                stage_buf4[ 2] <= "A";
                stage_buf4[ 3] <= "G";
                stage_buf4[ 4] <= "E";
                stage_buf4[ 5] <= "4";
                stage_buf4[ 6] <= ":";
                stage_buf4[ 7] <= " ";
                stage_buf4[ 8] <= " ";
                stage_buf4[ 9] <= " ";
                stage_buf4[10] <= " ";
                stage_buf4[11] <= " ";
            end 
        endcase
    end

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      cnt5 <= 3'd5;
      cnt3 <= 2'd3;
      scale <= 1;
      char_buf[0] <= " ";
      char_buf[1] <= " ";
      char_buf[2] <= " ";
      char_buf[3] <= " ";
      char_buf[4] <= " ";
      char_buf[5] <= " ";
      char_buf[6] <= " ";
      char_buf[7] <= " ";
      char_buf[8] <= " ";
      char_buf[9] <= " ";
      char_buf[10] <= " ";
      char_buf[11] <= " ";
    end else begin
        txt_done <= 0;
      case (state)
        // ???
        S_IDLE: begin
          cnt5 <= 3'd5;
          cnt3 <= 2'd3;
          scale <= 1;
          char_buf[0] <= "H";
          char_buf[1] <= "O";
          char_buf[2] <= "L";
          char_buf[3] <= "E";
          char_buf[4] <= " ";
          char_buf[5] <= "I";
          char_buf[6] <= "N";
          char_buf[7] <= " ";
          char_buf[8] <= "W";
          char_buf[9] <= "A";
          char_buf[10] <= "L";
          char_buf[11] <= "L";
        end
        S_SPACE: begin
          cnt5 <= 3'd5;
          cnt3 <= 2'd3;
          scale <= 1;
          char_buf[0] <= " ";
          char_buf[1] <= " ";
          char_buf[2] <= " ";
          char_buf[3] <= " ";
          char_buf[4] <= " ";
          char_buf[5] <= " ";
          char_buf[6] <= " ";
          char_buf[7] <= " ";
          char_buf[8] <= " ";
          char_buf[9] <= " ";
          char_buf[10] <= " ";
          char_buf[11] <= " ";
        end
        // ???? 5,4,3,2,1?? ????? ????
        S_START: begin
          cnt5 <= 3'd5;
          cnt3 <= 2'd3;
          if (tick) begin
            scale <= 1;
            char_buf[0] <= " ";
            char_buf[1] <= " ";
            char_buf[2] <= " ";
            char_buf[3] <= " ";
            char_buf[4] <= " ";
            char_buf[5] <= " ";
            case (cnt5)
              3'd5: char_buf[6] <= "5";
              3'd4: char_buf[6] <= "4";
              3'd3: char_buf[6] <= "3";
              3'd2: char_buf[6] <= "2";
              3'd1: char_buf[6] <= "1";
              3'd0: char_buf[6] <= "0";
              default: char_buf[6] <= " ";
            endcase
            char_buf[7]  <= " ";
            char_buf[8]  <= " ";
            char_buf[9]  <= " ";
            char_buf[10] <= " ";
            char_buf[11] <= " ";
            if (cnt5 != 3'd0) cnt5 <= cnt5 - 1;
            else begin
              cnt5 <= 3'd0;
              txt_done <= 1;
            end
          end else begin
            // 1?? ????? ??? ????, ?????? ????? char_buf ???? ????
            cnt5 <= cnt5;
            cnt3 <= 2'd3;
            scale <= 1;
            char_buf[0] <= char_buf[0];
            char_buf[1] <= char_buf[1];
            char_buf[2] <= char_buf[2];
            char_buf[3] <= char_buf[3];
            char_buf[4] <= char_buf[4];
            char_buf[5] <= char_buf[5];
            char_buf[6] <= char_buf[6];
            char_buf[7] <= char_buf[7];
            char_buf[8] <= char_buf[8];
            char_buf[9] <= char_buf[9];
            char_buf[10] <= char_buf[10];
            char_buf[11] <= char_buf[11];
          end
        end
        S_PASS: begin
          cnt5  <= 3'd5;
          cnt3  <= 2'd3;
          scale <= 1;
          if (tick) begin
            char_buf[0]  <= " ";
            char_buf[1]  <= " ";
            char_buf[2]  <= " ";
            char_buf[3]  <= " ";
            char_buf[4]  <= "P";
            char_buf[5]  <= "A";
            char_buf[6]  <= "S";
            char_buf[7]  <= "S";
            char_buf[8]  <= "!";
            char_buf[9]  <= " ";
            char_buf[10] <= " ";
            char_buf[11] <= " ";
            if (cnt5 != 3'd0) cnt5 <= cnt5 - 1;
            else begin
              cnt5 <= 3'd0;
            end
          end
        end
        S_FAIL: begin
          cnt5 <= 3'd5;
          cnt3 <= 2'd3;
          scale <= 1;
          char_buf[0] <= " ";
          char_buf[1] <= " ";
          char_buf[2] <= " ";
          char_buf[3] <= " ";
          char_buf[4] <= "F";
          char_buf[5] <= "A";
          char_buf[6] <= "I";
          char_buf[7] <= "L";
          char_buf[8] <= "!";
          char_buf[9] <= " ";
          char_buf[10] <= " ";
          char_buf[11] <= " ";
        end
        // ??????
        S_SCORE: begin
          cnt5 <= 3'd5;
          cnt3 <= 2'd3;
          scale <= 1;
          char_buf[0] <= "S";
          char_buf[1] <= "C";
          char_buf[2] <= "O";
          char_buf[3] <= "R";
          char_buf[4] <= "E";
          char_buf[5] <= ":";
          case (v)
            0: char_buf[6] <= "0";
            1: char_buf[6] <= "1";
            2: char_buf[6] <= "2";
            3: char_buf[6] <= "3";
            4: char_buf[6] <= "4";
            5: char_buf[6] <= "5";
            6: char_buf[6] <= "6";
            7: char_buf[6] <= "7";
            8: char_buf[6] <= "8";
            9: char_buf[6] <= "9";
            default: char_buf[6] <= " ";
          endcase
          case (w)
            0: char_buf[7] <= "0";
            1: char_buf[7] <= "1";
            2: char_buf[7] <= "2";
            3: char_buf[7] <= "3";
            4: char_buf[7] <= "4";
            5: char_buf[7] <= "5";
            6: char_buf[7] <= "6";
            7: char_buf[7] <= "7";
            8: char_buf[7] <= "8";
            9: char_buf[7] <= "9";
            default: char_buf[7] <= " ";
          endcase
          case (x)
            0: char_buf[8] <= "0";
            1: char_buf[8] <= "1";
            2: char_buf[8] <= "2";
            3: char_buf[8] <= "3";
            4: char_buf[8] <= "4";
            5: char_buf[8] <= "5";
            6: char_buf[8] <= "6";
            7: char_buf[8] <= "7";
            8: char_buf[8] <= "8";
            9: char_buf[8] <= "9";
            default: char_buf[8] <= " ";
          endcase
          case (y)
            0: char_buf[9] <= "0";
            1: char_buf[9] <= "1";
            2: char_buf[9] <= "2";
            3: char_buf[9] <= "3";
            4: char_buf[9] <= "4";
            5: char_buf[9] <= "5";
            6: char_buf[9] <= "6";
            7: char_buf[9] <= "7";
            8: char_buf[9] <= "8";
            9: char_buf[9] <= "9";
            default: char_buf[9] <= " ";
          endcase
          case (z)
            0: char_buf[10] <= "0";
            1: char_buf[10] <= "1";
            2: char_buf[10] <= "2";
            3: char_buf[10] <= "3";
            4: char_buf[10] <= "4";
            5: char_buf[10] <= "5";
            6: char_buf[10] <= "6";
            7: char_buf[10] <= "7";
            8: char_buf[10] <= "8";
            9: char_buf[10] <= "9";
            default: char_buf[10] <= " ";
          endcase
          char_buf[11] <= " ";
        end
        // ???? ??????
        S_SCORE_FINAL: begin
          cnt5 <= 3'd5;
          cnt3 <= 2'd3;
          scale <= 1;
          char_buf[0] <= " ";
          char_buf[1] <= "S";
          char_buf[2] <= "C";
          char_buf[3] <= "O";
          char_buf[4] <= "R";
          char_buf[5] <= "E";
          char_buf[6] <= ":";
          char_buf[7] <= " ";
          case (x)
            0: char_buf[8] <= "0";
            1: char_buf[8] <= "1";
            2: char_buf[8] <= "2";
            3: char_buf[8] <= "3";
            4: char_buf[8] <= "4";
            5: char_buf[8] <= "5";
            6: char_buf[8] <= "6";
            7: char_buf[8] <= "7";
            8: char_buf[8] <= "8";
            9: char_buf[8] <= "9";
            default: char_buf[8] <= " ";
          endcase
          case (y)
            0: char_buf[9] <= "0";
            1: char_buf[9] <= "1";
            2: char_buf[9] <= "2";
            3: char_buf[9] <= "3";
            4: char_buf[9] <= "4";
            5: char_buf[9] <= "5";
            6: char_buf[9] <= "6";
            7: char_buf[9] <= "7";
            8: char_buf[9] <= "8";
            9: char_buf[9] <= "9";
            default: char_buf[9] <= " ";
          endcase
          case (z)
            0: char_buf[10] <= "0";
            1: char_buf[10] <= "1";
            2: char_buf[10] <= "2";
            3: char_buf[10] <= "3";
            4: char_buf[10] <= "4";
            5: char_buf[10] <= "5";
            6: char_buf[10] <= "6";
            7: char_buf[10] <= "7";
            8: char_buf[10] <= "8";
            9: char_buf[10] <= "9";
            default: char_buf[10] <= " ";
          endcase
          char_buf[11] <= " ";
        end
        default: begin
          cnt5 <= 3'd5;
          cnt3 <= 2'd3;
          scale <= 1;
          char_buf[0] <= " ";
          char_buf[1] <= " ";
          char_buf[2] <= " ";
          char_buf[3] <= " ";
          char_buf[4] <= " ";
          char_buf[5] <= " ";
          char_buf[6] <= " ";
          char_buf[7] <= " ";
          char_buf[8] <= " ";
          char_buf[9] <= " ";
          char_buf[10] <= " ";
          char_buf[11] <= " ";
        end
      endcase
    end
  end

endmodule

module clk_gen_1s (
    input  logic clk,
    input  logic reset,
    output logic tick
);
    logic [$clog2(100_000_000) - 1:0] counter;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            tick <= 0;
            counter <= 0;
        end 
        
        else begin
            if (counter == 100_000_000 - 1) begin
                tick <= 1;
                counter <= 0;
            end 
            else begin
                tick <= 0;
                counter <= counter + 1;
            end
        end
  end

endmodule
