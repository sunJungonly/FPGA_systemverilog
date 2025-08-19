`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/06/02 14:11:45
// Design Name: 
// Module Name: pattern_rom
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


module pattern_rom (
    input  logic        clk,
    input  logic        p_oe,
    input  logic [ 6:0] p_Addr,
    output logic [37:0] p_Data
);
    logic [(10+9+10+9)-1:0] rom[0:(30*8) - 1];  //8 pattern

    always_ff @(posedge clk) begin : pattern_read
        if (p_oe) begin
            p_Data <= rom[p_Addr];
        end
    end
    initial begin
        $readmemh("PATTERN.mem", rom);
    end
endmodule
