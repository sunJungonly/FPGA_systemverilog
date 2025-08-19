//Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
//Date        : Tue Jul 22 15:06:14 2025
//Host        : DESKTOP-7CFQ9ND running 64-bit major release  (build 9200)
//Command     : generate_target FIFO_gen.bd
//Design      : FIFO_gen
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CORE_GENERATION_INFO = "FIFO_gen,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=FIFO_gen,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=1,numReposBlks=1,numNonXlnxBlks=0,numHierBlks=0,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=0,numPkgbdBlks=0,bdsource=USER,da_clkrst_cnt=3,synth_mode=OOC_per_IP}" *) (* HW_HANDOFF = "FIFO_gen.hwdef" *) 
module FIFO_gen
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
  (* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 DATA.DIN DATA" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME DATA.DIN, LAYERED_METADATA undef" *) input [23:0]din;
  (* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 DATA.DOUT DATA" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME DATA.DOUT, LAYERED_METADATA undef" *) output [23:0]dout;
  output empty;
  output full;
  input rd_clk;
  input rd_en;
  input rst;
  output valid;
  input wr_clk;
  input wr_en;

  wire [23:0]din_1;
  wire [23:0]fifo_generator_0_dout;
  wire fifo_generator_0_empty;
  wire fifo_generator_0_full;
  wire fifo_generator_0_valid;
  wire rd_clk_1;
  wire rst_1;
  wire wr_clk_1;
  wire wr_en1_1;
  wire wr_en_1;

  assign din_1 = din[23:0];
  assign dout[23:0] = fifo_generator_0_dout;
  assign empty = fifo_generator_0_empty;
  assign full = fifo_generator_0_full;
  assign rd_clk_1 = rd_clk;
  assign rst_1 = rst;
  assign valid = fifo_generator_0_valid;
  assign wr_clk_1 = wr_clk;
  assign wr_en1_1 = rd_en;
  assign wr_en_1 = wr_en;
  FIFO_gen_fifo_generator_0_0 fifo_generator_0
       (.din(din_1),
        .dout(fifo_generator_0_dout),
        .empty(fifo_generator_0_empty),
        .full(fifo_generator_0_full),
        .rd_clk(rd_clk_1),
        .rd_en(wr_en1_1),
        .rst(rst_1),
        .valid(fifo_generator_0_valid),
        .wr_clk(wr_clk_1),
        .wr_en(wr_en_1));
endmodule
