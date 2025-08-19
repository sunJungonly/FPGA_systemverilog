`timescale 1ns / 1ps

module OV7670_VGA_Display(
    input  logic clk,
    input  logic reset,
    input  logic [6:0] sw, 

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
    
    logic [3:0] sdata, fdata;

    logic [16:0] wAddr, rAddr;
    logic [9:0] x_pixel, y_pixel;
    logic [3:0] red, green, blue;
    logic [3:0] gred, ggreen, gblue; // gussian
    logic [3:0] mred, mgreen, mblue; // 선_shar
    logic [3:0] sred, sgreen, sblue; // gpt_shar
    logic [3:0] ured, ugreen, ublue; // 선_unsharp
    logic [11:0] data00, data01, data02, data10, data11, data12, data20, data21, data22;
    logic [11:0] fdata00, fdata01, fdata02, fdata10, fdata11, fdata12, fdata20, fdata21, fdata22;
    logic [11:0] gray;
    logic txt;
    
    assign red_port = sw[3] ? ured : sw[2] ? sred : sw[1] ? mred : sw[0] ? gred : red;
    assign green_port = sw[3] ? ugreen : sw[2] ? sgreen : sw[1] ? mgreen : sw[0] ? ggreen : green;
    assign blue_port = sw[3] ? ublue : sw[2] ? sblue : sw[1] ? mblue : sw[0] ? gblue : blue;

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
        .y_pixel(y_pixel)
    );

    QVGA_Controller U_QVGA_Controller(
        .clk(w_rclk),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .DE(DE),
        .sw(sw[4]),
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

    frame_buffer1 U_frame_buffer(
        .wclk(ov7670_pclk),
        .we(we),
        .wAddr(wAddr),
        .wData(wData),
        .rclk(rclk),
        .oe(oe),
        .rAddr(rAddr),
        .rData(rData)
    );

    line_buffer_640 u_buffer(
        .pclk(ov7670_xclk),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .data({rData[15:12], rData[10:7], rData[4:1]}),
        .data_00(data00),
        .data_01(data01),
        .data_02(data02),
        .data_10(data10),
        .data_11(data11),
        .data_12(data12),
        .data_20(data20),
        .data_21(data21),
        .data_22(data22)
);

    gaussian_filter fred(
        .fdata_00(data00[11:8]),
        .fdata_01(data01[11:8]),
        .fdata_02(data02[11:8]),
        .fdata_10(data10[11:8]),
        .fdata_11(data11[11:8]),
        .fdata_12(data12[11:8]),
        .fdata_20(data20[11:8]),
        .fdata_21(data21[11:8]),
        .fdata_22(data22[11:8]),
        .filter_data(gred) 
    );

    gaussian_filter fgren(
        .fdata_00(data00[7:4]),
        .fdata_01(data01[7:4]),
        .fdata_02(data02[7:4]),
        .fdata_10(data10[7:4]),
        .fdata_11(data11[7:4]),
        .fdata_12(data12[7:4]),
        .fdata_20(data20[7:4]),
        .fdata_21(data21[7:4]),
        .fdata_22(data22[7:4]),
        .filter_data(ggreen) 
    );

    gaussian_filter fblue(
        .fdata_00(data00[3:0]),
        .fdata_01(data01[3:0]),
        .fdata_02(data02[3:0]),
        .fdata_10(data10[3:0]),
        .fdata_11(data11[3:0]),
        .fdata_12(data12[3:0]),
        .fdata_20(data20[3:0]),
        .fdata_21(data21[3:0]),
        .fdata_22(data22[3:0]),
        .filter_data(gblue) 
    );

    line_buffer_640 u_buff(
        .pclk(ov7670_xclk),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .data({gred, ggreen, gblue}),
        .data_00(fdata00),
        .data_01(fdata01),
        .data_02(fdata02),
        .data_10(fdata10),
        .data_11(fdata11),
        .data_12(fdata12),
        .data_20(fdata20),
        .data_21(fdata21),
        .data_22(fdata22)
);

    Sharpening_Filter u_sfil(
        .data00(fdata00), 
        .data01(fdata01), 
        .data02(fdata02),
        .data10(fdata10), 
        .data11(fdata11), 
        .data12(fdata12),
        .data20(fdata20), 
        .data21(fdata21), 
        .data22(fdata22),
        .shdata({mred, mgreen, mblue})
);

Unsharp_Masking_Filter  U_unsharp (
    .data00(fdata00),
    .data01(fdata01),
    .data02(fdata02),
    .data10(fdata10),
    .data11(fdata11),
    .data12(fdata12),
    .data20(fdata20),
    .data21(fdata21),
    .data22(fdata22),
    .unsharp_data({ured, ugreen, ublue})
);
    unsharp_masking umred(
        .original(red),   
        .blurred(gred),    
        .sharpened(sred)   
    );
    unsharp_masking umgreen(
        .original(green),   
        .blurred(ggreen),    
        .sharpened(sgreen)   
    );
    unsharp_masking umblue(
        .original(blue),   
        .blurred(gblue),    
        .sharpened(sblue)   
    );

    /*TXT_VGA u_txt(
        .clk(clk),
        .reset(reset),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .stage(sw[6:5]),
        .txt_x_pixel(), // from game fsm
        .txt_y_pixel(), // "
    
        .txt_mode(sw[3:0]),
        .score(19'd50),
    
        .txt_out(txt),
        .txt_done(),
        .tick_1s()
    );*/

    /*Sobel_Filter_origin U_ORI(
        .clk(clk),
        .addr(rAddr),
        .data({rData[15:12], rData[10:7], rData[4:1]}),
        .sdata(fdata)
    );*/

    /*Sobel_Filter U_sobel(
        .clk(clk),
        .addr(rAddr),
        .data({rData[15:12], rData[10:7], rData[4:1]}),
        .sdata()
    );*/

    /*canny_filter u_canny(
    .clk(clk),
    .addr(rAddr),
    .data(gray),
    .sdata(sdata)
    );*/

    /*grayscale_converter (
        .red_port(rData[15:12]),
        .green_port(rData[10:7]),
        .blue_port(rData[4:1]),
        .gray_port(gray)
);*/
endmodule

module grayscale_converter (
    input logic [3:0] red_port,
    input logic [3:0] green_port,
    input logic [3:0] blue_port,
    output logic [11:0] gray_port
);
    logic [10:0] red;
    logic [11:0] green;
    logic [8:0] blue; 
    logic [12:0] gray;
    assign red = (red_port * 77);
    assign green = (green_port * 150);
    assign blue = (blue_port * 29);
    assign gray = red + green + blue;

    assign gray_port = gray[12:1];
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

module unsharp_masking (
    input  logic [3:0] original,   // 원본 픽셀
    input  logic [3:0] blurred,    // 가우시안 필터 결과
    output logic [3:0] sharpened   // 샤프닝된 결과
);
    logic [4:0] doubled_original;
    wire signed [4:0] temp_sharpened;

    // 원본 × 2
    assign doubled_original = original << 1;

    // Sharpened = 2 * original - blurred
    assign temp_sharpened = doubled_original - blurred;

    // Saturation 처리 (0~15 범위로 클램핑)
    always_comb begin
        if (temp_sharpened > 5'sd15)
            sharpened = 4'hf;
        else if (temp_sharpened < 5'sd0)
            sharpened = 4'h0;
        else
            sharpened = temp_sharpened[3:0];
    end
endmodule

module Sharpening_Filter (
    input  logic [11:0] data00, data01, data02,
    input  logic [11:0] data10, data11, data12,
    input  logic [11:0] data20, data21, data22,
    output logic [11:0] shdata
);

    logic signed [11:0] win[0:8];  //음수일 수도 있어서 signed 처리
    logic signed [13:0] filtered;  //음수일 수도 있어서 signed 처리
    logic [3:0] r_result, g_result, b_result;

    logic [3:0] R[0:8];
    logic [3:0] G[0:8];
    logic [3:0] B[0:8];

    assign win[0] = data00;  // P0
    assign win[1] = data10;  // P1
    assign win[2] = data20;  // P2
    assign win[3] = data01;  // P3
    assign win[4] = data11;  // P4 (중앙)
    assign win[5] = data21;  // P5
    assign win[6] = data02;  // P6
    assign win[7] = data12;  // P7
    assign win[8] = data22;  // P8

    always_comb begin
        for (int i = 0; i < 9; i++) begin
            R[i] = win[i][11:8];  // 상위 4비트
            G[i] = win[i][7:4];  // 중간 4비트
            B[i] = win[i][3:0];  // 하위 4비트
        end
    end

    //assign filtered = -win[1] - win[3] + 5 * win[4] - win[5] - win[7];

    // R 필터
    logic signed [7:0] r_filtered;
    assign r_filtered = -R[1] - R[3] + 5 * R[4] - R[5] - R[7] + 2;
    assign r_result = (r_filtered < 0) ? 4'd0 :(r_filtered > 15) ? 4'd15 : r_filtered[3:0];

    // G 필터
    logic signed [7:0] g_filtered;
    assign g_filtered = -G[1] - G[3] + 5 * G[4] - G[5] - G[7] + 2;
    assign g_result = (g_filtered < 0) ? 4'd0 :(g_filtered > 15) ? 4'd15 : g_filtered[3:0];

    // B 필터
    logic signed [7:0] b_filtered;
    assign b_filtered = -B[1] - B[3] + 5 * B[4] - B[5] - B[7] + 2;
    assign b_result = (b_filtered < 0) ? 4'd0 : (b_filtered > 15) ? 4'd15 : b_filtered[3:0];


    assign shdata = {r_result, g_result, b_result};  // 12비트 R4G4B4 출력
endmodule

module Unsharp_Masking_Filter  (
    input  logic [11:0] data00, data01, data02,
    input  logic [11:0] data10, data11, data12,
    input  logic [11:0] data20, data21, data22,
    output logic [11:0] unsharp_data
);

    logic [11:0] blur_data;

    gaussian_filter U_Gaussian_Filter(
        .fdata_00(fdata_00),
        .fdata_01(fdata_01),
        .fdata_02(fdata_02),
        .fdata_10(fdata_10),
        .fdata_11(fdata_11),
        .fdata_12(fdata_12),
        .fdata_20(fdata_20),
        .fdata_21(fdata_21),
        .fdata_22(fdata_22),
        .filter_data(blur_data) 
    );

    // 언샤프 마스킹 공식: result = 2 * original - blur
    logic signed [7:0] R_orig, G_orig, B_orig;
    logic signed [7:0] R_blur, G_blur, B_blur;
    logic signed [7:0] R_sharp, G_sharp, B_sharp;

    always_comb begin
        R_orig = data11[11:8];
        G_orig = data11[7:4];
        B_orig = data11[3:0];

        R_blur = blur_data[11:8];
        G_blur = blur_data[7:4];
        B_blur = blur_data[3:0];

        // 2 * original - blur
        // R_sharp = (2 * R_orig) - R_blur;
        // G_sharp = (2 * G_orig) - G_blur;
        // B_sharp = (2 * B_orig) - B_blur;
        // gain = 1.5 → 3/2 로 가정
        // R_sharp = ((3 * R_orig) - R_blur) >>> 1;
        // G_sharp = ((3 * G_orig) - G_blur) >>> 1;
        // B_sharp = ((3 * B_orig) - B_blur) >>> 1;
        //gain = 1로 가정 좋은데???
        R_sharp = (1 * R_orig) - R_blur;
        G_sharp = (1 * G_orig) - G_blur;
        B_sharp = (1 * B_orig) - B_blur;
        //gain = 1.25 -> 5/4로 가정 약간 진한회색빛 돌아 별루임
        // R_sharp = ((5 * R_orig) - R_blur) >>> 4;
        // G_sharp = ((5 * G_orig) - G_blur) >>> 4;
        // B_sharp = ((5 * B_orig) - B_blur) >>> 4;

        // 클리핑
        unsharp_data[11:8] = (R_sharp < 0) ? 4'd0 : (R_sharp > 15) ? 4'd15 : R_sharp[3:0];
        unsharp_data[7:4]  = (G_sharp < 0) ? 4'd0 : (G_sharp > 15) ? 4'd15 : G_sharp[3:0];
        unsharp_data[3:0]  = (B_sharp < 0) ? 4'd0 : (B_sharp > 15) ? 4'd15 : B_sharp[3:0];
    end

endmodule