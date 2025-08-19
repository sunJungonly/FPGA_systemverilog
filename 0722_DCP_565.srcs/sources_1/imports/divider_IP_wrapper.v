//Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
//Date        : Mon Jul 21 20:37:49 2025
//Host        : DESKTOP-7CFQ9ND running 64-bit major release  (build 9200)
//Command     : generate_target divider_IP_wrapper.bd
//Design      : divider_IP_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module divider_IP_wrapper
   (divided_in_tdata,
    divided_in_tready,
    divided_in_tvalid,
    divided_out_tdata,
    divided_out_tvalid,
    divisor_in_tdata,
    divisor_in_tready,
    divisor_in_tvalid,
    reset_rtl_0,
    sys_clk);
  input [15:0]divided_in_tdata;
  output divided_in_tready;
  input divided_in_tvalid;
  output [31:0]divided_out_tdata;
  output divided_out_tvalid;
  input [15:0]divisor_in_tdata;
  output divisor_in_tready;
  input divisor_in_tvalid;
  input reset_rtl_0;
  input sys_clk;

  wire [15:0]divided_in_tdata;
  wire divided_in_tready;
  wire divided_in_tvalid;
  wire [31:0]divided_out_tdata;
  wire divided_out_tvalid;
  wire [15:0]divisor_in_tdata;
  wire divisor_in_tready;
  wire divisor_in_tvalid;
  wire reset_rtl_0;
  wire sys_clk;

  divider_IP divider_IP_i
       (.divided_in_tdata(divided_in_tdata),
        .divided_in_tready(divided_in_tready),
        .divided_in_tvalid(divided_in_tvalid),
        .divided_out_tdata(divided_out_tdata),
        .divided_out_tvalid(divided_out_tvalid),
        .divisor_in_tdata(divisor_in_tdata),
        .divisor_in_tready(divisor_in_tready),
        .divisor_in_tvalid(divisor_in_tvalid),
        .reset_rtl_0(reset_rtl_0),
        .sys_clk(sys_clk));
endmodule
