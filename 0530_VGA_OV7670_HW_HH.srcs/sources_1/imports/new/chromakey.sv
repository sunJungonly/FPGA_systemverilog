`timescale 1ns / 1ps

module chromakey(
    // Framebuffer signals
    input logic [15:0] rgbData,
    // VGAController signals
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,
    input logic DE,
    // export signals
    output logic bg_pixel
    );
    // RGB 추출 
    logic [3:0] r, g, b;
    assign {r, g, b} = DE ? {rgbData[15:12], rgbData[10:7], rgbData[4:1]} : 12'b0;
    
    // 배경 조건 (크로마키용 초록 배경 인식) 크로마키 배경이이면 0 아니면 1
    assign bg_pixel =  (g > b) && (b > r) && (g >= 7) ? 0 : 1;


    // //크로마키에 쓰이는 배경 색 : 노란색
    // logic [3:0] bg_r = 4'd15;   // Red
    // logic [3:0] bg_g = 4'd15;   // Green
    // logic [3:0] bg_b = 4'd15;   // Blue

    // logic [3:0] red_port, green_port, blue_port;
    // assign {red_port, green_port, blue_port} = bg_pixel ? {bg_r, bg_g, bg_b} : {r, g, b};

    // assign RGB = {red_port, green_port, blue_port};


endmodule
