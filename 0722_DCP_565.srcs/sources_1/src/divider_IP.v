//Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
//Date        : Mon Jul 21 20:37:49 2025
//Host        : DESKTOP-7CFQ9ND running 64-bit major release  (build 9200)
//Command     : generate_target divider_IP.bd
//Design      : divider_IP
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CORE_GENERATION_INFO = "divider_IP,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=divider_IP,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=5,numReposBlks=5,numNonXlnxBlks=0,numHierBlks=0,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=0,numPkgbdBlks=0,bdsource=USER,da_board_cnt=1,synth_mode=OOC_per_IP}" *) (* HW_HANDOFF = "divider_IP.hwdef" *) 
module divider_IP
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
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 divided_in TDATA" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME divided_in, CLK_DOMAIN divider_IP_sys_clk, FREQ_HZ 100000000, HAS_TKEEP 0, HAS_TLAST 0, HAS_TREADY 1, HAS_TSTRB 0, INSERT_VIP 0, LAYERED_METADATA undef, PHASE 0.000, TDATA_NUM_BYTES 2, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0" *) input [15:0]divided_in_tdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 divided_in TREADY" *) output divided_in_tready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 divided_in TVALID" *) input divided_in_tvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 divided_out TDATA" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME divided_out, CLK_DOMAIN divider_IP_sys_clk, FREQ_HZ 100000000, HAS_TKEEP 0, HAS_TLAST 0, HAS_TREADY 0, HAS_TSTRB 0, INSERT_VIP 0, LAYERED_METADATA xilinx.com:interface:datatypes:1.0 {TDATA {datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type automatic dependency {} format long minimum {} maximum {}} value 32} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} struct {field_fractional {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value fractional} enabled {attribs {resolve_type generated dependency fract_enabled format bool minimum {} maximum {}} value false} datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type generated dependency fract_width format long minimum {} maximum {}} value 0} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} real {fixed {fractwidth {attribs {resolve_type generated dependency fract_remainder_fractwidth format long minimum {} maximum {}} value 0} signed {attribs {resolve_type generated dependency fract_remainder_signed format bool minimum {} maximum {}} value true}}}}} field_remainder {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value remainder} enabled {attribs {resolve_type generated dependency remainder_enabled format bool minimum {} maximum {}} value true} datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type generated dependency remainder_width format long minimum {} maximum {}} value 16} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} real {fixed {fractwidth {attribs {resolve_type generated dependency fract_remainder_fractwidth format long minimum {} maximum {}} value 0} signed {attribs {resolve_type generated dependency fract_remainder_signed format bool minimum {} maximum {}} value true}}}}} field_quotient {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value quotient} enabled {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value true} datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type generated dependency quotient_width format long minimum {} maximum {}} value 16} bitoffset {attribs {resolve_type generated dependency quotient_offset format long minimum {} maximum {}} value 16} integer {signed {attribs {resolve_type generated dependency quotient_signed format bool minimum {} maximum {}} value true}}}}}}} TDATA_WIDTH 32 TUSER {datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type automatic dependency {} format long minimum {} maximum {}} value 0} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} struct {field_divide_by_zero {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value divide_by_zero} enabled {attribs {resolve_type generated dependency divbyzero_enabled format bool minimum {} maximum {}} value false} datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type generated dependency divbyzero_width format long minimum {} maximum {}} value 0} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0}}} field_divisor_tuser {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value divisor_tuser} enabled {attribs {resolve_type generated dependency divisor_enabled format bool minimum {} maximum {}} value false} datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type generated dependency divisor_width format long minimum {} maximum {}} value 0} bitoffset {attribs {resolve_type generated dependency divisor_offset format long minimum {} maximum {}} value 0} integer {signed {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value false}}}} field_dividend_tuser {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value dividend_tuser} enabled {attribs {resolve_type generated dependency dividend_enabled format bool minimum {} maximum {}} value false} datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type generated dependency dividend_width format long minimum {} maximum {}} value 0} bitoffset {attribs {resolve_type generated dependency dividend_offset format long minimum {} maximum {}} value 0} integer {signed {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value false}}}}}}} TUSER_WIDTH 0}, PHASE 0.000, TDATA_NUM_BYTES 4, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0" *) output [31:0]divided_out_tdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 divided_out TVALID" *) output divided_out_tvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 divisor_in TDATA" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME divisor_in, CLK_DOMAIN divider_IP_sys_clk, FREQ_HZ 100000000, HAS_TKEEP 0, HAS_TLAST 0, HAS_TREADY 1, HAS_TSTRB 0, INSERT_VIP 0, LAYERED_METADATA undef, PHASE 0.000, TDATA_NUM_BYTES 2, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0" *) input [15:0]divisor_in_tdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 divisor_in TREADY" *) output divisor_in_tready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 divisor_in TVALID" *) input divisor_in_tvalid;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.RESET_RTL_0 RST" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.RESET_RTL_0, INSERT_VIP 0, POLARITY ACTIVE_LOW" *) input reset_rtl_0;
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.SYS_CLK CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.SYS_CLK, ASSOCIATED_BUSIF divided_out:divided_in:divisor_in, CLK_DOMAIN divider_IP_sys_clk, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, INSERT_VIP 0, PHASE 0.000" *) input sys_clk;

  wire [15:0]axis_data_fifo_0_M_AXIS_TDATA;
  wire axis_data_fifo_0_M_AXIS_TVALID;
  wire [15:0]axis_data_fifo_1_M_AXIS_TDATA;
  wire axis_data_fifo_1_M_AXIS_TVALID;
  wire [31:0]div_gen_0_M_AXIS_DOUT_TDATA;
  wire div_gen_0_M_AXIS_DOUT_TVALID;
  wire [15:0]divided_in_1_TDATA;
  wire divided_in_1_TREADY;
  wire divided_in_1_TVALID;
  wire [15:0]divisor_in_1_TDATA;
  wire divisor_in_1_TREADY;
  wire divisor_in_1_TVALID;
  wire [0:0]proc_sys_reset_0_peripheral_aresetn;
  wire reset_rtl_1;
  wire sys_clk_1;
  wire [0:0]xlconstant_0_dout;

  assign divided_in_1_TDATA = divided_in_tdata[15:0];
  assign divided_in_1_TVALID = divided_in_tvalid;
  assign divided_in_tready = divided_in_1_TREADY;
  assign divided_out_tdata[31:0] = div_gen_0_M_AXIS_DOUT_TDATA;
  assign divided_out_tvalid = div_gen_0_M_AXIS_DOUT_TVALID;
  assign divisor_in_1_TDATA = divisor_in_tdata[15:0];
  assign divisor_in_1_TVALID = divisor_in_tvalid;
  assign divisor_in_tready = divisor_in_1_TREADY;
  assign reset_rtl_1 = reset_rtl_0;
  assign sys_clk_1 = sys_clk;
  divider_IP_axis_data_fifo_0_0 axis_data_fifo_0
       (.m_axis_tdata(axis_data_fifo_0_M_AXIS_TDATA),
        .m_axis_tready(1'b1),
        .m_axis_tvalid(axis_data_fifo_0_M_AXIS_TVALID),
        .s_axis_aclk(sys_clk_1),
        .s_axis_aresetn(proc_sys_reset_0_peripheral_aresetn),
        .s_axis_tdata(divided_in_1_TDATA),
        .s_axis_tready(divided_in_1_TREADY),
        .s_axis_tvalid(divided_in_1_TVALID));
  divider_IP_axis_data_fifo_0_1 axis_data_fifo_1
       (.m_axis_tdata(axis_data_fifo_1_M_AXIS_TDATA),
        .m_axis_tready(1'b1),
        .m_axis_tvalid(axis_data_fifo_1_M_AXIS_TVALID),
        .s_axis_aclk(sys_clk_1),
        .s_axis_aresetn(proc_sys_reset_0_peripheral_aresetn),
        .s_axis_tdata(divisor_in_1_TDATA),
        .s_axis_tready(divisor_in_1_TREADY),
        .s_axis_tvalid(divisor_in_1_TVALID));
  divider_IP_div_gen_0_0 div_gen_0
       (.aclk(sys_clk_1),
        .m_axis_dout_tdata(div_gen_0_M_AXIS_DOUT_TDATA),
        .m_axis_dout_tvalid(div_gen_0_M_AXIS_DOUT_TVALID),
        .s_axis_dividend_tdata(axis_data_fifo_0_M_AXIS_TDATA),
        .s_axis_dividend_tvalid(axis_data_fifo_0_M_AXIS_TVALID),
        .s_axis_divisor_tdata(axis_data_fifo_1_M_AXIS_TDATA),
        .s_axis_divisor_tvalid(axis_data_fifo_1_M_AXIS_TVALID));
  divider_IP_proc_sys_reset_0_0 proc_sys_reset_0
       (.aux_reset_in(1'b1),
        .dcm_locked(xlconstant_0_dout),
        .ext_reset_in(reset_rtl_1),
        .mb_debug_sys_rst(1'b0),
        .peripheral_aresetn(proc_sys_reset_0_peripheral_aresetn),
        .slowest_sync_clk(sys_clk_1));
  divider_IP_xlconstant_0_0 xlconstant_0
       (.dout(xlconstant_0_dout));
endmodule
