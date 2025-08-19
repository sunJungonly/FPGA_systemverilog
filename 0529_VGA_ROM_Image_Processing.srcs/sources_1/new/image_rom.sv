`timescale 1ns / 1ps

module ImageRom (
    input  logic [3:0] sw_red,
    input  logic [3:0] sw_green,
    input  logic [3:0] sw_blue,
    input  logic [9:0] x_pixel,
    input  logic [9:0] y_pixel,
    input  logic       DE,
    output logic [3:0] red_data,
    output logic [3:0] green_data,
    output logic [3:0] blue_data

);
    logic [16:0] image_addr;
    logic [15:0] image_data;  //RGB565 => 16'b rrrrr_gggggg_bbbbb 
                              //상위비트 데이터가 많다고 생각하고 하위 비트는 데이터가 적다고 생각하면 됨
    integer i;
    always_comb begin
        if (x_pixel < 320 && y_pixel < 240) begin
            image_addr = 320 * y_pixel + x_pixel;

            for (i = 0; i < 4; i = i + 1) begin
                red_data[i] = !DE ? 4'bz : sw_red[i] ? image_data[12+i] : 4'b0;
                green_data[i] = !DE ? 4'bz : sw_green[i] ? image_data[7+i] : 4'b0;
                blue_data[i]  = !DE ? 4'bz : sw_blue[i] ? image_data[1+i] : 4'b0;
            end
            // red_port   =  !DE ? 4'bz : sw_red   ? image_data[15:12] : 4'b0;
            // green_port = !DE ? 4'bz : sw_blue ? image_data[10:7] : 4'b0;
            // blue_port  = !DE ? 4'bz : sw_green ? image_data[4:1] : 4'b0;
        end else begin
            red_data  = 4'bz;
            green_data = 4'bz;
            blue_data  = 4'bz;
        end
    end


    image_rom U_ROM (
        .addr(image_addr),
        .data(image_data)
    );

endmodule

module image_rom (  // 비동기식 메모리
    input  logic [16:0] addr,  // 640 * 480 / 4
    output logic [15:0] data   // 16bit(2byte)
);
    logic [15:0] rom[0 : 320 * 240 - 1];

    initial begin
        $readmemh("Lenna.mem", rom);
    end

    assign data = rom[addr];
endmodule
