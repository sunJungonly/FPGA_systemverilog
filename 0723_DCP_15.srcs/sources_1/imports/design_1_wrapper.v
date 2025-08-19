//Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
//Date        : Mon Jul 21 16:32:10 2025
//Host        : DESKTOP-7CFQ9ND running 64-bit major release  (build 9200)
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (dividend_in_tdata,
    dividend_in_tready,
    dividend_in_tvalid,
    divisor_in_tdata,
    divisor_in_tready,
    divisor_in_tvalid,
    quotient_out_tdata,
    quotient_out_tuser,
    quotient_out_tvalid,
    reset,
    sys_clock);
  input [63:0]dividend_in_tdata;
  output dividend_in_tready;
  input dividend_in_tvalid;
  input [47:0]divisor_in_tdata;
  output divisor_in_tready;
  input divisor_in_tvalid;
  output [111:0]quotient_out_tdata;
  output [0:0]quotient_out_tuser;
  output quotient_out_tvalid;
  input reset;
  input sys_clock;

  wire [63:0]dividend_in_tdata;
  wire dividend_in_tready;
  wire dividend_in_tvalid;
  wire [47:0]divisor_in_tdata;
  wire divisor_in_tready;
  wire divisor_in_tvalid;
  wire [111:0]quotient_out_tdata;
  wire [0:0]quotient_out_tuser;
  wire quotient_out_tvalid;
  wire reset;
  wire sys_clock;

  design_1 design_1_i
       (.dividend_in_tdata(dividend_in_tdata),
        .dividend_in_tready(dividend_in_tready),
        .dividend_in_tvalid(dividend_in_tvalid),
        .divisor_in_tdata(divisor_in_tdata),
        .divisor_in_tready(divisor_in_tready),
        .divisor_in_tvalid(divisor_in_tvalid),
        .quotient_out_tdata(quotient_out_tdata),
        .quotient_out_tuser(quotient_out_tuser),
        .quotient_out_tvalid(quotient_out_tvalid),
        .reset(reset),
        .sys_clock(sys_clock));
endmodule
