`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/24 20:45:24
// Design Name: 
// Module Name: tb_divider_IP
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


module tb_divider_IP(

    );

    // =================================================================
    // 파라미터 및 신호 선언
    // =================================================================
    localparam CLK_PERIOD = 10; // 10ns = 100MHz

    logic clk;
    logic rst;

    // --- DUT 입력 ---
    logic [15:0] dut_dividend_tdata;  // 분자
    logic        dut_dividend_tvalid;
    logic [15:0] dut_divisor_tdata;   // 분모
    logic        dut_divisor_tvalid;
    
    // --- DUT 출력 (관찰 대상) ---
    logic        dut_dividend_tready; // IP가 받을 준비가 되었는지
    logic        dut_divisor_tready;
    logic [31:0] dut_divided_out_tdata; // 32비트 전체 출력
    logic        dut_divided_out_tvalid;

    // =================================================================
    // DUT 인스턴스화
    // =================================================================
    divider_IP_wrapper dut (
        .sys_clk(clk),
        .reset_rtl_0(rst),

        .divided_in_tdata(dut_dividend_tdata),
        .divided_in_tvalid(dut_dividend_tvalid),
        .divided_in_tready(dut_dividend_tready),

        .divisor_in_tdata(dut_divisor_tdata),
        .divisor_in_tvalid(dut_divisor_tvalid),
        .divisor_in_tready(dut_divisor_tready),

        .divided_out_tdata(dut_divided_out_tdata),
        .divided_out_tvalid(dut_divided_out_tvalid)
    );

    // =================================================================
    // 클럭 및 리셋 생성
    // =================================================================
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // =================================================================
    // 자극 생성 및 시뮬레이션 제어
    // =================================================================
    initial begin
        // --- 1. 리셋 및 초기화 ---
        rst = 1;
        dut_dividend_tvalid = 0;
        dut_divisor_tvalid = 0;
        dut_dividend_tdata = 0;
        dut_divisor_tdata = 0;
        repeat(5) @(posedge clk);
        rst = 0;
        $display("INFO: Reset released. Starting IP unit test.");

        // --- 2. 첫 번째 나눗셈 테스트: 9816 / 26 ---
        $display("INFO: Test 1: Sending 9816 / 26");
        @(posedge clk);
        dut_dividend_tdata  <= 16'd9816;
        dut_divisor_tdata   <= 16'd26;
        dut_dividend_tvalid <= 1'b1;
        dut_divisor_tvalid  <= 1'b1;

        // tvalid를 1 클럭 동안만 유지
        @(posedge clk);
        dut_dividend_tvalid <= 1'b0;
        dut_divisor_tvalid  <= 1'b0;

        // 결과가 나올 때까지 충분히 기다림 (약 50 클럭)
        // tvalid가 1이 되는 것을 기다리는 것이 더 좋지만, 수동 분석을 위해 시간으로 기다림
        repeat(50) @(posedge clk);


        // --- 3. 두 번째 나눗셈 테스트: 10072 / 26 ---
        $display("INFO: Test 2: Sending 10072 / 26");
        @(posedge clk);
        dut_dividend_tdata  <= 16'd10072;
        dut_divisor_tdata   <= 16'd26;
        dut_dividend_tvalid <= 1'b1;
        dut_divisor_tvalid  <= 1'b1;

        // tvalid를 1 클럭 동안만 유지
        @(posedge clk);
        dut_dividend_tvalid <= 1'b0;
        dut_divisor_tvalid  <= 1'b0;

        // 결과가 나올 때까지 다시 충분히 기다림
        repeat(50) @(posedge clk);
        
        $display("INFO: Simulation finished. Please check the waveform and log file.");
        $finish;
    end

endmodule