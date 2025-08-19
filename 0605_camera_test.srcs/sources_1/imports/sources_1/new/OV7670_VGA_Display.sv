`timescale 1ns / 1ps

module OV7670_VGA_Display(
    input  logic clk,
    input  logic reset,

    input logic [3:0] sw,

    output logic        ov7670_xclk,
    input  logic        ov7670_pclk,
    input  logic        ov7670_href,
    input  logic        ov7670_v_sync,
    input  logic [ 7:0] ov7670_data,
    
    output logic        h_sync,
    output logic        v_sync,
    output logic [ 3:0] red_port,
    output logic [ 3:0] green_port,
    output logic [ 3:0] blue_port
    );

    logic we, DE, w_rclk, oe, rclk;
    logic [15:0] wData, rData;
    logic [16:0] wAddr, rAddr;
    logic [9:0] x_pixel, y_pixel;

    logic [11:0] mdata00, mdata01, mdata02, mdata10, mdata11, mdata12, mdata20, mdata21, mdata22;
    logic [11:0] fdata00, fdata01, fdata02, fdata10, fdata11, fdata12, fdata20, fdata21, fdata22;
    logic [11:0] sdata;
    logic [11:0] gray;
    logic [3:0] sobel_data, gdata;
    logic pclk;
    logic [3:0] red, green, blue;


    assign red_port = sw[3] ? gdata : sw[2] ? sobel_data : sw[1] ? gray[11:8] : sw[0] ? sdata[11:8] : red;
    assign green_port = sw[3] ? gdata : sw[2] ? sobel_data : sw[1] ? gray[11:8] : sw[0] ? sdata[7:4]: green;
    assign blue_port = sw[3] ? gdata : sw[2] ? sobel_data : sw[1] ? gray[11:8] : sw[0] ?sdata[3:0] : blue;

    pixel_clk_gen U_OV7670_Clk_Gen(
        .clk(clk),
        .reset(reset),
        .pclk(ov7670_xclk)
    );

    VGA_Controller U_VGA_Controller(
        .clk(clk),
        .reset(reset),
        .rclk(w_rclk),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .DE(DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .pclk(pclk)
    );

    QVGA_Controller U_QVGA_Controller(
        .clk(w_rclk),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .DE(DE),
        .rclk(rclk),
        .d_en(oe),
        .rAddr(rAddr),
        .rData(rData),
        .red_port(red),
        .green_port(green),
        .blue_port(blue) 
    );

    OV7670_MemController U_OV7670_MemController(
        .pclk(ov7670_pclk),
        .reset(reset),
        .href(ov7670_href),
        .v_sync(ov7670_v_sync),
        .ov7670_data(ov7670_data),
        .we(we),
        .wAddr(wAddr),
        .wData(wData)
    );

    frame_buffer U_frame_buffer(
        .wclk(ov7670_pclk),
        .we(we),
        .wAddr(wAddr),
        .wData(wData),
        .rclk(pclk/*rclk*/),
        .oe(oe),
        .rAddr(rAddr),
        .rData(rData)
    );

    line_buffer U_median_buffer(
        .clk(pclk),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .data({rData[15:12], rData[10:7], rData[4:1]}),
        .data00(mdata00),
        .data01(mdata01),
        .data02(mdata02), 
        .data10(mdata10),
        .data11(mdata11),
        .data12(mdata12),
        .data20(mdata20),
        .data21(mdata21),
        .data22(mdata22)
    );

    median_filter_bead u_m_filter(
        .data00(mdata00),
        .data01(mdata01),
        .data02(mdata02),
        .data10(mdata10),
        .data11(mdata11),
        .data12(mdata12),
        .data20(mdata20),
        .data21(mdata21),
        .data22(mdata22),
        .sdata(sdata)
    );

    grayscale_converter u_gray(
        .red_port(sdata[11:8]),
        .green_port(sdata[7:4]),
        .blue_port(sdata[3:0]),
        .g_port(gray)
    );

    line_buffer U_sobel_buffer(
        .clk(pclk),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .data(gray),
        .data00(fdata00),
        .data01(fdata01),
        .data02(fdata02), 
        .data10(fdata10),
        .data11(fdata11),
        .data12(fdata12),
        .data20(fdata20),
        .data21(fdata21),
        .data22(fdata22)
    );

    Sobel_Filter u_sobel(
        .data00(fdata00),

        
        .data01(fdata01),
        .data02(fdata02), 
        .data10(fdata10),
        .data11(fdata11),
        .data12(fdata12),
        .data20(fdata20),
        .data21(fdata21),
        .data22(fdata22),
        .sdata(sobel_data)
    );

    Gaussian_filter u_gaussian(
        .data00(fdata00),
        .data01(fdata01),
        .data02(fdata02),
        .data10(fdata10),
        .data11(fdata11),
        .data12(fdata12),
        .data20(fdata20),
        .data21(fdata21),
        .data22(fdata22),
        .gaussian_data(gdata)
    );
endmodule

module Sobel_Filter(
    input  logic [11:0] data00,
    input  logic [11:0] data01,
    input  logic [11:0] data02, 
    input  logic [11:0] data10,
    input  logic [11:0] data11,
    input  logic [11:0] data12,
    input  logic [11:0] data20,
    input  logic [11:0] data21,
    input  logic [11:0] data22,
    output logic [3:0] sdata
    );

    localparam threshold = 700;//600;
    
    wire signed [15:0] xdata, ydata;
    logic [15:0] absx, absy;

    assign xdata = data02 + (data12 << 1) + data22 - data00 - (data10 << 1) - data20;
    assign ydata = data00 + (data01 << 1) + data02 - data20 - (data21 << 1) - data22;
    
    assign absx = xdata[15] ? (~xdata + 1): xdata;
    assign absy = ydata[15] ? (~ydata + 1): ydata;
    
    assign sdata = (absx + absy > threshold) ? 4'hf : 4'h0; 
endmodule

module line_buffer (
    input logic clk,
    input  logic [9:0] x_pixel,
    input  logic [9:0] y_pixel,
    input logic [11:0] data,
    output logic [11:0] data00,
    output logic [11:0] data01,
    output logic [11:0] data02, 
    output logic [11:0] data10,
    output logic [11:0] data11,
    output logic [11:0] data12,
    output logic [11:0] data20,
    output logic [11:0] data21,
    output logic [11:0] data22
);
    
    // median filter parameters
    reg [11:0] fmem0 [639:0];
    reg [11:0] fmem1 [639:0];
    reg [11:0] fmem2 [639:0];

    always_ff @( posedge clk) begin
        fmem2[x_pixel] <= fmem1[x_pixel];
        fmem1[x_pixel] <= fmem0[x_pixel];
        fmem0[x_pixel] <= data;
    end

    always_ff @( posedge clk ) begin 
        data00 <= (y_pixel == 0 || x_pixel == 0) ? 0 : fmem2[x_pixel-1];
        data01 <= (y_pixel == 0) ? 0 : fmem2[x_pixel];
        data02 <= (y_pixel == 0 || x_pixel == 639) ? 0 : fmem2[x_pixel+1];
        data10 <= (x_pixel == 0) ? 0 : fmem1[x_pixel-1];
        data11 <= fmem1[x_pixel];
        data12 <= (x_pixel == 639) ? 0 : fmem1[x_pixel+1];
        data20 <= (x_pixel == 0 || y_pixel == 479) ? 0 : fmem0[x_pixel-1];
        data21 <= (y_pixel == 479) ? 0 : fmem0[x_pixel];
        data22 <= (x_pixel == 639 || y_pixel == 479) ? 0 : fmem0[x_pixel+1];
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

    reg [8:0] beads [11:0]; 
    integer i, j;
    reg [3:0] count; 

    always_comb begin
        beads[0] = {data22[0], data21[0], data20[0], data12[0], data11[0], data10[0], data02[0], data01[0], data00[0]};
        beads[1] = {data22[1], data21[1], data20[1], data12[1], data11[1], data10[1], data02[1], data01[1], data00[1]};
        beads[2] = {data22[2], data21[2], data20[2], data12[2], data11[2], data10[2], data02[2], data01[2], data00[2]};
        beads[3] = {data22[3], data21[3], data20[3], data12[3], data11[3], data10[3], data02[3], data01[3], data00[3]};
        beads[4] = {data22[4], data21[4], data20[4], data12[4], data11[4], data10[4], data02[4], data01[4], data00[4]};
        beads[5] = {data22[5], data21[5], data20[5], data12[5], data11[5], data10[5], data02[5], data01[5], data00[5]};
        beads[6] = {data22[6], data21[6], data20[6], data12[6], data11[6], data10[6], data02[6], data01[6], data00[6]};
        beads[7] = {data22[7], data21[7], data20[7], data12[7], data11[7], data10[7], data02[7], data01[7], data00[7]};
        beads[8] = {data22[8], data21[8], data20[8], data12[8], data11[8], data10[8], data02[8], data01[8], data00[8]};
        beads[9] = {data22[9], data21[9], data20[9], data12[9], data11[9], data10[9], data02[9], data01[9], data00[9]};
        beads[10]= {data22[10],data21[10],data20[10],data12[10],data11[10],data10[10],data02[10],data01[10],data00[10]};
        beads[11]= {data22[11],data21[11],data20[11],data12[11],data11[11],data10[11],data02[11],data01[11],data00[11]};
        
        for (i = 0; i < 12; i = i + 1) begin

            count = 0;
            for (j = 0; j < 9; j = j + 1) begin
                count = count + beads[i][j];
            end
            for (j = 0; j < 9; j = j + 1) begin
                if (j < count)
                    beads[i][j] = 1'b1;
                else
                    beads[i][j] = 1'b0;
            end
        end

        for (i = 0; i < 12; i = i + 1) begin
            sdata[i] = beads[i][4]; 
        end
    end

endmodule

module grayscale_converter (
    input logic [3:0] red_port,
    input logic [3:0] green_port,
    input logic [3:0] blue_port,
    output logic [11:0] g_port
);
    logic [10:0] red;
    logic [11:0] green;
    logic [8:0] blue; 
    logic [12:0] gray;
    assign red = (red_port * 77);
    assign green = (green_port * 150);
    assign blue = (blue_port * 29);
    assign gray = red + green + blue;

    assign g_port = gray[12:1];
endmodule

module Gaussian_filter (
    input  logic [11:0] data00,
    input  logic [11:0] data01,
    input  logic [11:0] data02,
    input  logic [11:0] data10,
    input  logic [11:0] data11,
    input  logic [11:0] data12,
    input  logic [11:0] data20,
    input  logic [11:0] data21,
    input  logic [11:0] data22,
    output logic [11:0] gaussian_data
);

    logic [16:0] avg_data;

    assign avg_data = data00 + (data01 << 1) + data02 + (data10 << 1) + (data11 << 2) + (data12 << 1) + data20 + (data21 << 1) + data22;
    assign gaussian_data = avg_data[16:5];

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