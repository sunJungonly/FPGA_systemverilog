`timescale 1ns / 1ps

module tb_sccb ();

    logic       clk;
    logic       reset;
    logic [7:0] reg_addr;
    logic [7:0] data;
    logic [7:0] rom_addr;
    wire        sda;
    logic       scl;


    SCCB_Master dut(
        input logic clk,
        input logic reset,
        inout wire sda,  //sccb data
        output logic scl  //sccb clock
    );


    always #10 clk = ~clk;  // 50MHz (20ns period)


    initial begin
        clk   = 0;
        reset = 1;
        #20;
        reset = 0;

        #1000000;  // 1ms 시뮬레이션 후 종료
        $finish;


    end

endmodule
