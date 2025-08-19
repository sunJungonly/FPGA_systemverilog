`timescale 1ns / 1ps

module frame_buffer (
    input logic wclk,
    input logic we,
    input logic frame_stop,
    input logic [16:0] wAddr,
    input logic [15:0] wData,

    input logic rclk,
    input logic oe,
    input logic [16:0] rAddr,
    output logic [15:0] rData
);
    logic [15:0] mem[0:(320*240) - 1];

    always_ff @(posedge wclk) begin : write
        if (we && !frame_stop) begin
            mem[wAddr] <= wData;
        end else begin
            mem[wAddr] <= mem[wAddr];
        end
    end

    always_ff @(posedge rclk) begin : read
        if (oe) begin
            rData = mem[rAddr];
        end
    end

endmodule
