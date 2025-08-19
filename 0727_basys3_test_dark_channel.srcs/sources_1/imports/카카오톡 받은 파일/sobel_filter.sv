`timescale 1ns / 1ps
/*
x = [-1, 0, 1], [-2, 0 2], [-1, 0, 1]
y = [-1, -2, -1], [0,0,0], [1, 2, 1]
*/
/*module Sobel_Filter_origin(
    input  logic clk,
    input  logic [16:0] addr,
    input  logic [11:0] data,
    output logic [3:0] sdata
    );

    localparam threshold = 1_0000;

    // row, col -> line buffer
    logic [7:0] row;  // 0~239
    logic [8:0] col;  // 0~319

    assign row = addr / 320;
    assign col = addr % 320;
    
    logic [11:0] data_00, data_01, data_02, data_10, data_11, data_12, data_20, data_21, data_22;
    
    wire signed [15:0] xdata, ydata;
    logic [15:0] absx, absy;

    reg [11:0] mem0 [319:0];
    reg [11:0] mem1 [319:0];
    reg [11:0] mem2 [319:0];

    // sobel filter
    always_ff @( posedge clk) begin
        mem2[col] <= mem1[col];
        mem1[col] <= mem0[col];
        mem0[col] <= data;
    end

    always_ff @( posedge clk ) begin 
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
    
    assign absx = xdata[15] ? (~xdata + 1): xdata;
    assign absy = ydata[15] ? (~ydata + 1): ydata;
    
    assign sdata = (absx + absy > threshold) ? 4'hf : 4'h0; 
endmodule*/

module Sobel_Filter (  // gray input
    input  logic [11:0] data00,
    input  logic [11:0] data01,
    input  logic [11:0] data02,
    input  logic [11:0] data10,
    input  logic [11:0] data11,
    input  logic [11:0] data12,
    input  logic [11:0] data20,
    input  logic [11:0] data21,
    input  logic [11:0] data22,
    output logic        sdata
);

    localparam threshold = 600;

    wire signed [15:0] xdata, ydata;
    logic [15:0] absx, absy;

    assign xdata = data02 + (data12 << 1) + data22 - data00 - (data10 << 1) - data20;
    assign ydata = data00 + (data01 << 1) + data02 - data20 - (data21 << 1) - data22;

    assign absx = xdata[15] ? (~xdata + 1) : xdata;
    assign absy = ydata[15] ? (~ydata + 1) : ydata;

    assign sdata = (absx + absy > threshold) ? 1 : 0;
endmodule

module line_buffer (
    input logic clk,
    input logic [16:0] addr,
    input logic [11:0] data,
    output logic [11:0] data_00,
    output logic [11:0] data_01,
    output logic [11:0] data_02,
    output logic [11:0] data_10,
    output logic [11:0] data_11,
    output logic [11:0] data_12,
    output logic [11:0] data_20,
    output logic [11:0] data_21,
    output logic [11:0] data_22
);
    // row, col -> line buffer
    logic [7:0] row;  // 0~239
    logic [8:0] col;  // 0~319

    assign row = addr / 320;
    assign col = addr % 320;

    // median filter parameters
    reg [11:0] fmem0[319:0];
    reg [11:0] fmem1[319:0];
    reg [11:0] fmem2[319:0];

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

module line_buffer_640 (
    input logic pclk,
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,
    input logic [11:0] data,
    output logic [11:0] data_00,
    output logic [11:0] data_01,
    output logic [11:0] data_02,
    output logic [11:0] data_10,
    output logic [11:0] data_11,
    output logic [11:0] data_12,
    output logic [11:0] data_20,
    output logic [11:0] data_21,
    output logic [11:0] data_22
);
    // median filter parameters
    reg [11:0] fmem0[639:0];
    reg [11:0] fmem1[639:0];
    reg [11:0] fmem2[639:0];
    reg [11:0] temp;
    always_ff @(posedge pclk) begin
        if (x_pixel < 640 && y_pixel < 480) begin
            temp <= fmem2[x_pixel];
            fmem2[x_pixel] <= fmem1[x_pixel];
            fmem1[x_pixel] <= fmem0[x_pixel];
            fmem0[x_pixel] <= data;
        end
    end

    always_ff @(posedge pclk) begin
        data_00 <= (y_pixel == 0 || x_pixel == 0) ? 0 : temp;
        data_01 <= (y_pixel == 0) ? 0 : fmem2[x_pixel];
        data_02 <= (y_pixel == 0 || x_pixel == 639) ? 0 : fmem2[x_pixel+1];
        data_10 <= (x_pixel == 0) ? 0 : fmem2[x_pixel-1];
        data_11 <= fmem1[x_pixel];
        data_12 <= (x_pixel == 639) ? 0 : fmem1[x_pixel+1];
        data_20 <= (x_pixel == 0 || y_pixel == 479) ? 0 : fmem1[x_pixel-1];
        data_21 <= (y_pixel == 479) ? 0 : fmem0[x_pixel];
        data_22 <= (x_pixel == 639 || y_pixel == 479) ? 0 : fmem0[x_pixel+1];
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

/*module frame_buffer1(
    input logic wclk,
    input logic we,
    input logic [16:0] wAddr,
    input logic [15:0] wData,

    input logic rclk,
    input logic oe,
    input logic [16:0] rAddr,
    
    output logic [15:0] rData
    );

    logic [15:0] mem [ 0: (320*240) - 1];

    always_ff @( posedge wclk ) begin : write
        if (we) begin
            mem[wAddr] <= wData; 
        end
    end

    always_ff @( posedge rclk ) begin : read
        if (oe) begin
            rData = mem[rAddr];
        end
    end
     
endmodule

module canny_filter (
    input  logic clk,
    input  logic [16:0] addr,
    input  logic [11:0] data,
    output logic [3:0] sdata
);
    // parameters
    localparam threshold = 20_000;
    localparam max = 300;
    localparam min = 100;
    
    logic [7:0] row;  
    logic [8:0] col;  
    
    assign row = addr / 320;
    assign col = addr % 320;

    // 1. Gaussian Filter 
    logic [11:0] fdata_00, fdata_01, fdata_02, fdata_10, fdata_11, fdata_12, fdata_20, fdata_21, fdata_22;

    reg [11:0] fmem0 [319:0];
    reg [11:0] fmem1 [319:0];
    reg [11:0] fmem2 [319:0];

    logic [16:0] avg_data;
    logic [12:0] median_data;

    // 2. Sobel filter 
    logic [1:0] angle;
    logic [16:0] sobel_data;

    logic [12:0] data_00, data_01, data_02, data_10, data_11, data_12, data_20, data_21, data_22;

    wire signed [15:0] xdata, ydata;
    logic [15:0] absx, absy;

    reg [12:0] mem0 [319:0];
    reg [12:0] mem1 [319:0];
    reg [12:0] mem2 [319:0];

    // 3. Non-Maximum Suppression
    reg [18:0] mem0_3 [319:0];
    reg [18:0] mem1_3 [319:0];
    reg [18:0] mem2_3 [319:0];

    logic [16:0] grad_now, grad1, grad2;
    assign grad_now = mem1_3[col][16:0];

    logic [3:0] nms;
    /////////////////////////////////////////////////////////////////////////////////////////////////////////

    // 1. Gaussian Filter 
    always_ff @( posedge clk) begin
        fmem2[col] <= fmem1[col];
        fmem1[col] <= fmem0[col];
        fmem0[col] <= data;
    end

    always_ff @( posedge clk ) begin 
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
    always_ff @( posedge clk) begin
        mem2[col] <= mem1[col];
        mem1[col] <= mem0[col];
        mem0[col] <= data;
    end

    always_ff @( posedge clk ) begin 
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
    
    assign absx = xdata[15] ? (~xdata + 1): xdata;
    assign absy = ydata[15] ? (~ydata + 1): ydata;
    
    assign sobel_data = absx + absy;

    // 0 -> 0 , 45 -> 1, 90 -> 2, 135 -> 3, 180 -> 4, 225 -> 5, 270 -> 6, 315 -> 7   
    always_comb begin
        if (absx > absy) begin
            if (xdata >= 0)
                angle = 1; // 45
            else 
                angle = 3; // 135
        end 
        else begin
            if (xdata < 0)
                angle = 2; // 90
            else
                angle = 0; // 0
        end
    end

    // 3. Non-Maximum Suppression
    always_ff @( posedge clk) begin
        mem2_3[col] <= mem1_3[col];
        mem1_3[col] <= mem0_3[col];
        mem0_3[col] <= {angle, sobel_data};
    end

    always_comb begin 
        case (mem1_3[col][18:17])
            2'b00: begin // 가로 
                grad1 = (col == 0)     ? 0 : mem1_3[col-1][16:0];
                grad2 = (col == 319)   ? 0 : mem1_3[col+1][16:0];
            end
            2'b01: begin // 대각선
                grad1 = (row == 0 || col == 319)  ? 0 : mem0_3[col+1][16:0];
                grad2 = (row == 239 || col == 0)  ? 0 : mem2_3[col-1][16:0];
            end
            2'b10: begin // 세로
                grad1 = (row == 0)     ? 0 : mem0_3[col][16:0];
                grad2 = (row == 239)   ? 0 : mem2_3[col][16:0];
            end
            2'b11: begin // 대각선
                grad1 = (row == 0 || col == 0)     ? 0 : mem0_3[col-1][16:0];
                grad2 = (row == 239 || col == 319) ? 0 : mem2_3[col+1][16:0];
            end  
        endcase

        if (grad_now >= grad1 && grad_now >= grad2 && grad_now > threshold) begin
            //result = 4'hF;  // 유지
        end
        else begin            
            //result = 4'h0;  // 제거
        end
    end


endmodule
*/

