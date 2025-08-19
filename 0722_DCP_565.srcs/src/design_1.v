//Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
//Date        : Tue Jul 22 11:10:38 2025
//Host        : DESKTOP-7CFQ9ND running 64-bit major release  (build 9200)
//Command     : generate_target design_1.bd
//Design      : design_1
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CORE_GENERATION_INFO = "design_1,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=design_1,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=5,numReposBlks=5,numNonXlnxBlks=0,numHierBlks=0,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=0,numPkgbdBlks=0,bdsource=USER,da_board_cnt=3,da_clkrst_cnt=1,synth_mode=OOC_per_IP}" *) (* HW_HANDOFF = "design_1.hwdef" *) 
module design_1
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
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 dividend_in TDATA" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME dividend_in, CLK_DOMAIN design_1_sys_clock, FREQ_HZ 100000000, HAS_TKEEP 0, HAS_TLAST 0, HAS_TREADY 1, HAS_TSTRB 0, INSERT_VIP 0, LAYERED_METADATA undef, PHASE 0.000, TDATA_NUM_BYTES 8, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0" *) input [63:0]dividend_in_tdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 dividend_in TREADY" *) output dividend_in_tready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 dividend_in TVALID" *) input dividend_in_tvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 divisor_in TDATA" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME divisor_in, CLK_DOMAIN design_1_sys_clock, FREQ_HZ 100000000, HAS_TKEEP 0, HAS_TLAST 0, HAS_TREADY 1, HAS_TSTRB 0, INSERT_VIP 0, LAYERED_METADATA undef, PHASE 0.000, TDATA_NUM_BYTES 6, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0" *) input [47:0]divisor_in_tdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 divisor_in TREADY" *) output divisor_in_tready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 divisor_in TVALID" *) input divisor_in_tvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 quotient_out TDATA" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME quotient_out, CLK_DOMAIN design_1_sys_clock, FREQ_HZ 100000000, HAS_TKEEP 0, HAS_TLAST 0, HAS_TREADY 0, HAS_TSTRB 0, INSERT_VIP 0, LAYERED_METADATA xilinx.com:interface:datatypes:1.0 {TDATA {datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type automatic dependency {} format long minimum {} maximum {}} value 112} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} struct {field_fractional {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value fractional} enabled {attribs {resolve_type generated dependency fract_enabled format bool minimum {} maximum {}} value true} datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type generated dependency fract_width format long minimum {} maximum {}} value 48} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} real {fixed {fractwidth {attribs {resolve_type generated dependency fract_remainder_fractwidth format long minimum {} maximum {}} value 47} signed {attribs {resolve_type generated dependency fract_remainder_signed format bool minimum {} maximum {}} value true}}}}} field_remainder {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value remainder} enabled {attribs {resolve_type generated dependency remainder_enabled format bool minimum {} maximum {}} value false} datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type generated dependency remainder_width format long minimum {} maximum {}} value 0} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} real {fixed {fractwidth {attribs {resolve_type generated dependency fract_remainder_fractwidth format long minimum {} maximum {}} value 47} signed {attribs {resolve_type generated dependency fract_remainder_signed format bool minimum {} maximum {}} value true}}}}} field_quotient {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value quotient} enabled {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value true} datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type generated dependency quotient_width format long minimum {} maximum {}} value 64} bitoffset {attribs {resolve_type generated dependency quotient_offset format long minimum {} maximum {}} value 48} integer {signed {attribs {resolve_type generated dependency quotient_signed format bool minimum {} maximum {}} value true}}}}}}} TDATA_WIDTH 112 TUSER {datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type automatic dependency {} format long minimum {} maximum {}} value 1} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} struct {field_divide_by_zero {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value divide_by_zero} enabled {attribs {resolve_type generated dependency divbyzero_enabled format bool minimum {} maximum {}} value true} datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type generated dependency divbyzero_width format long minimum {} maximum {}} value 1} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0}}} field_divisor_tuser {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value divisor_tuser} enabled {attribs {resolve_type generated dependency divisor_enabled format bool minimum {} maximum {}} value false} datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type generated dependency divisor_width format long minimum {} maximum {}} value 0} bitoffset {attribs {resolve_type generated dependency divisor_offset format long minimum {} maximum {}} value 1} integer {signed {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value false}}}} field_dividend_tuser {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value dividend_tuser} enabled {attribs {resolve_type generated dependency dividend_enabled format bool minimum {} maximum {}} value false} datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value {}} bitwidth {attribs {resolve_type generated dependency dividend_width format long minimum {} maximum {}} value 0} bitoffset {attribs {resolve_type generated dependency dividend_offset format long minimum {} maximum {}} value 1} integer {signed {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value false}}}}}}} TUSER_WIDTH 1}, PHASE 0.000, TDATA_NUM_BYTES 14, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 1" *) output [111:0]quotient_out_tdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 quotient_out TUSER" *) output [0:0]quotient_out_tuser;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 quotient_out TVALID" *) output quotient_out_tvalid;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.RESET RST" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.RESET, INSERT_VIP 0, POLARITY ACTIVE_HIGH" *) input reset;
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.SYS_CLOCK CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.SYS_CLOCK, ASSOCIATED_BUSIF dividend_in:divisor_in:quotient_out, CLK_DOMAIN design_1_sys_clock, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, INSERT_VIP 0, PHASE 0.000" *) input sys_clock;

  wire [63:0]axis_data_fifo_0_M_AXIS_TDATA;
  wire axis_data_fifo_0_M_AXIS_TVALID;
  wire [47:0]axis_data_fifo_1_M_AXIS_TDATA;
  wire axis_data_fifo_1_M_AXIS_TVALID;
  wire [111:0]div_gen_0_M_AXIS_DOUT_TDATA;
  wire [0:0]div_gen_0_M_AXIS_DOUT_TUSER;
  wire div_gen_0_M_AXIS_DOUT_TVALID;
  wire [63:0]dividend_in_1_TDATA;
  wire dividend_in_1_TREADY;
  wire dividend_in_1_TVALID;
  wire [47:0]divisor_in_1_TDATA;
  wire divisor_in_1_TREADY;
  wire divisor_in_1_TVALID;
  wire [0:0]proc_sys_reset_0_peripheral_aresetn;
  wire reset_1;
  wire sys_clock_1;
  wire [0:0]xlconstant_0_dout;

  assign dividend_in_1_TDATA = dividend_in_tdata[63:0];
  assign dividend_in_1_TVALID = dividend_in_tvalid;
  assign dividend_in_tready = dividend_in_1_TREADY;
  assign divisor_in_1_TDATA = divisor_in_tdata[47:0];
  assign divisor_in_1_TVALID = divisor_in_tvalid;
  assign divisor_in_tready = divisor_in_1_TREADY;
  assign quotient_out_tdata[111:0] = div_gen_0_M_AXIS_DOUT_TDATA;
  assign quotient_out_tuser[0] = div_gen_0_M_AXIS_DOUT_TUSER;
  assign quotient_out_tvalid = div_gen_0_M_AXIS_DOUT_TVALID;
  assign reset_1 = reset;
  assign sys_clock_1 = sys_clock;
  design_1_axis_data_fifo_0_0 axis_data_fifo_0
       (.m_axis_tdata(axis_data_fifo_0_M_AXIS_TDATA),
        .m_axis_tready(1'b1),
        .m_axis_tvalid(axis_data_fifo_0_M_AXIS_TVALID),
        .s_axis_aclk(sys_clock_1),
        .s_axis_aresetn(proc_sys_reset_0_peripheral_aresetn),
        .s_axis_tdata(dividend_in_1_TDATA),
        .s_axis_tready(dividend_in_1_TREADY),
        .s_axis_tvalid(dividend_in_1_TVALID));
  design_1_axis_data_fifo_0_1 axis_data_fifo_1
       (.m_axis_tdata(axis_data_fifo_1_M_AXIS_TDATA),
        .m_axis_tready(1'b1),
        .m_axis_tvalid(axis_data_fifo_1_M_AXIS_TVALID),
        .s_axis_aclk(sys_clock_1),
        .s_axis_aresetn(proc_sys_reset_0_peripheral_aresetn),
        .s_axis_tdata(divisor_in_1_TDATA),
        .s_axis_tready(divisor_in_1_TREADY),
        .s_axis_tvalid(divisor_in_1_TVALID));
  design_1_div_gen_0_0 div_gen_0
       (.aclk(sys_clock_1),
        .aresetn(proc_sys_reset_0_peripheral_aresetn),
        .m_axis_dout_tdata(div_gen_0_M_AXIS_DOUT_TDATA),
        .m_axis_dout_tuser(div_gen_0_M_AXIS_DOUT_TUSER),
        .m_axis_dout_tvalid(div_gen_0_M_AXIS_DOUT_TVALID),
        .s_axis_dividend_tdata(axis_data_fifo_0_M_AXIS_TDATA),
        .s_axis_dividend_tvalid(axis_data_fifo_0_M_AXIS_TVALID),
        .s_axis_divisor_tdata(axis_data_fifo_1_M_AXIS_TDATA),
        .s_axis_divisor_tvalid(axis_data_fifo_1_M_AXIS_TVALID));
  design_1_proc_sys_reset_0_0 proc_sys_reset_0
       (.aux_reset_in(1'b1),
        .dcm_locked(xlconstant_0_dout),
        .ext_reset_in(reset_1),
        .mb_debug_sys_rst(1'b0),
        .peripheral_aresetn(proc_sys_reset_0_peripheral_aresetn),
        .slowest_sync_clk(sys_clock_1));
  design_1_xlconstant_0_0 xlconstant_0
       (.dout(xlconstant_0_dout));
endmodule
