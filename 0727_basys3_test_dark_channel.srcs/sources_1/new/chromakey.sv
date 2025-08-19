`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/06/05 14:29:57
// Design Name: 
// Module Name: chromakey
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


`timescale 1ns / 1ps

module chromakey(
    // Line_buffer signals
    input logic [11:0] rgbData,
    input logic DE,
    // export signals
    output logic bg_pixel
    );
    // RGB 추출 
    logic [3:0] r, g, b;
    assign {r, g, b} = DE ? {rgbData[11:8], rgbData[7:4], rgbData[3:0]} : 12'b0;
    
    // 배경 조건 (크로마키용 초록 배경 인식) 초록색이면 1 아니면 0
    // assign bg_pixel =  (g > b) && (b > r) && (g >= 8) ? 0 : 1;
    // 조건이 완화된 버전
    assign bg_pixel = (g > r + 1) && (g >= b + 1) && (g >= 1);

    // //크로마키에 쓰이는 배경 색 : 노란색
    // logic [3:0] bg_r = 4'd15;   // Red
    // logic [3:0] bg_g = 4'd15;   // Green
    // logic [3:0] bg_b = 4'd15;   // Blue

    // logic [3:0] red_port, green_port, blue_port;
    // assign {red_port, green_port, blue_port} = bg_pixel ? {bg_r, bg_g, bg_b} : {r, g, b};

    // assign RGB = {red_port, green_port, blue_port};
endmodule
