`timescale 1ns / 1ps

module game_state(
    // chromakey signals
    input logic bg_pixel,
    // edge detector signals   
    //  out of bounds signals   
    // text signals
    // output
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port
    );

    // //크로마키에 쓰이는 배경 색 : 흰색
    logic [3:0] bg_r = 4'd15;   // Red
    logic [3:0] bg_g = 4'd15;   // Green
    logic [3:0] bg_b = 4'd0;    // Blue

    //  // bg_pixel =  초록색이면 0 아니면 1
    // logic [3:0] red_port, green_port, blue_port;
    // assign {red_port, green_port, blue_port} = !bg_pixel ? {bg_r, bg_g, bg_b} : 
    // 원래의 정보;

    assign RGB = {red_port, green_port, blue_port};

endmodule
