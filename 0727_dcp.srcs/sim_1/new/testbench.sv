// 파일 이름: testbench.sv
`timescale 1ns / 1ps

module testbench;

    // 1. DUT에 공급할 신호 선언 (Wrapper 비트 폭과 정확히 일치)
    logic           sys_clock;
    logic           reset;

    logic [63:0]    dividend_in_tdata;
    logic           dividend_in_tvalid;
    logic           dividend_in_tready; // DUT의 출력이므로 wire 타입과 같음

    logic [47:0]    divisor_in_tdata;
    logic           divisor_in_tvalid;
    logic           divisor_in_tready;

    logic [111:0]   quotient_out_tdata;
    logic           quotient_out_tvalid;
    logic           quotient_out_tuser; // 비트 폭 주의


    // 2. DUT(design_1_wrapper) 인스턴스화
    divider_IP dut (
        .sys_clock(sys_clock),
        .reset(reset),
        
        // Dividend 연결
        .dividend_in_tdata(dividend_in_tdata),
        .dividend_in_tvalid(dividend_in_tvalid),
        .dividend_in_tready(dividend_in_tready),

        // Divisor 연결
        .divisor_in_tdata(divisor_in_tdata),
        .divisor_in_tvalid(divisor_in_tvalid),
        .divisor_in_tready(divisor_in_tready),
        
        // Quotient 연결
        .quotient_out_tdata(quotient_out_tdata),
        .quotient_out_tvalid(quotient_out_tvalid),
        .quotient_out_tuser(quotient_out_tuser)
        // 항상 결과를 받을 준비가 되어 있다고 가정
        // 실제 시스템에서는 이 신호를 제어해야 할 수도 있음
        // .quotient_out_tready(1'b1) 
    );
    
    longint expected_result_1;
    longint expected_result_2;

    // 3. 클럭 생성
    initial begin
        sys_clock = 0;
        forever #5 sys_clock = ~sys_clock; // 100MHz 클럭 (주기 10ns)
    end

    // 4. 테스트 시나리오 작성
    initial begin
        // --- 시뮬레이션 초기화 ---
        reset = 1;
        dividend_in_tvalid = 0;
        divisor_in_tvalid  = 0;
        dividend_in_tdata = 0;
        divisor_in_tdata = 0;
        #10; // 100ns 동안 리셋 유지
        reset = 0;
        #50;
         #100;

        // --- 테스트 케이스 1: 800 / 10 = 80 ---
        $display("[%0t ns] Test Case 1: 800 / 10", $time);
        dividend_in_tdata = 800;
        divisor_in_tdata  = 10;
        dividend_in_tvalid = 1;
        divisor_in_tvalid  = 1;

        // 데이터가 전송될 때까지 기다림 (AXI-Stream 핸드셰이크)
        wait (dividend_in_tready == 1 && divisor_in_tready == 1);
        @(posedge sys_clock);
        @(posedge sys_clock);
        // 데이터 전송 후 valid를 0으로 내려주는 것이 일반적인 AXI-Stream 동작
        dividend_in_tvalid = 0;
        divisor_in_tvalid  = 0;

        // 결과가 나올 때까지 기다림
        wait (quotient_out_tvalid == 1);
        $display("[%0t ns] Result received: %d", $time, quotient_out_tdata);
        
        // 결과 검증 (Fractional 모드 고려)
        // Fractional Width가 16이었다고 가정하면, 결과는 16비트 왼쪽 시프트된 값이 나옴
        expected_result_1 = 80 << 16;
        if (quotient_out_tdata == expected_result_1) begin
            $display("Test Case 1 PASSED!");
        end else begin
            $display("Test Case 1 FAILED! Expected: %d, Got: %d", expected_result_1, quotient_out_tdata);
        end
        @(posedge sys_clock); // 결과 확인 후 한 클럭 대기

        #100;

        // --- 테스트 케이스 2: -1000 / 20 = -50 (부호있는 나눗셈) ---
        $display("[%0t ns] Test Case 2: -1000 / 20", $time);


        dividend_in_tdata = -1000; // SystemVerilog는 자동으로 2의 보수로 변환
        divisor_in_tdata  = 20;
        dividend_in_tvalid = 1;
        divisor_in_tvalid  = 1;

        wait (dividend_in_tready == 1 && divisor_in_tready == 1);
        @(posedge sys_clock);
        dividend_in_tvalid = 0;
        divisor_in_tvalid  = 0;

        wait (quotient_out_tvalid == 1);
        // 부호있는 수로 결과를 해석하려면 $signed() 사용
        $display("[%0t ns] Result received: %d", $time, $signed(quotient_out_tdata));
        
        expected_result_2 = -50 << 16;
        if ($signed(quotient_out_tdata) == expected_result_2) begin
            $display("Test Case 2 PASSED!");
        end else begin
            $display("Test Case 2 FAILED! Expected: %d, Got: %d", expected_result_2, $signed(quotient_out_tdata));
        end
        
        #200;
        
        $display("Simulation Finished");
        $finish;
    end

endmodule
