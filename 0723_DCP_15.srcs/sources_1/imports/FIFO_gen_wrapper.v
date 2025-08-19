//Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
//Date        : Tue Jul 22 15:06:14 2025
//Host        : DESKTOP-7CFQ9ND running 64-bit major release  (build 9200)
//Command     : generate_target FIFO_gen_wrapper.bd
//Design      : FIFO_gen_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module FIFO_gen_wrapper
   (din,
    dout,
    empty,
    full,
    rd_clk,
    rd_en,
    rst,
    valid,
    wr_clk,
    wr_en);
  input [23:0]din;
  output [23:0]dout;
  output empty;
  output full;
  input rd_clk;
  input rd_en;
  input rst;
  output valid;
  input wr_clk;
  input wr_en;

  wire [23:0]din;
  wire [23:0]dout;
  wire empty;
  wire full;
  wire rd_clk;
  wire rd_en;
  wire rst;
  wire valid;
  wire wr_clk;
  wire wr_en;

  FIFO_gen FIFO_gen_i
       (.din(din),
        .dout(dout),
        .empty(empty),
        .full(full),
        .rd_clk(rd_clk),
        .rd_en(rd_en),
        .rst(rst),
        .valid(valid),
        .wr_clk(wr_clk),
        .wr_en(wr_en));
endmodule
