
`timescale 1ns/1ps

module tb_sobel_filter;

    // DUT 입력 및 출력
    logic signed [15:0] data_00, data_01, data_02;
    logic signed [15:0] data_10, data_11, data_12;
    logic signed [15:0] data_20, data_21, data_22;
    logic [15:0] sdata;

    // DUT 인스턴스
    Sobel_Filter uut (
        .data_00(data_00), .data_01(data_01), .data_02(data_02),
        .data_10(data_10), .data_11(data_11), .data_12(data_12),
        .data_20(data_20), .data_21(data_21), .data_22(data_22),
        .sdata(sdata)
    );

    // 초기 블록
    initial begin
        $display("Starting Sobel Filter Testbench");

        // Case 1: No edge (flat area)
        data_00 = 16'd10; data_01 = 16'd10; data_02 = 16'd10;
        data_10 = 16'd10; data_11 = 16'd10; data_12 = 16'd10;
        data_20 = 16'd10; data_21 = 16'd10; data_22 = 16'd10;
        #10;
        $display("Test 1 - Flat: sdata = %0d", sdata);

        // Case 2: Horizontal edge
        data_00 = 16'd0;  data_01 = 16'd0;  data_02 = 16'd0;
        data_10 = 16'd0;  data_11 = 16'd0;  data_12 = 16'd0;
        data_20 = 16'd255; data_21 = 16'd255; data_22 = 16'd255;
        #10;
        $display("Test 2 - Horizontal Edge: sdata = %0d", sdata);

        // Case 3: Vertical edge
        data_00 = 16'd0; data_01 = 16'd255; data_02 = 16'd255;
        data_10 = 16'd0; data_11 = 16'd255; data_12 = 16'd255;
        data_20 = 16'd0; data_21 = 16'd255; data_22 = 16'd255;
        #10;
        $display("Test 3 - Vertical Edge: sdata = %0d", sdata);

        // Case 4: Diagonal edge
        data_00 = 16'd255; data_01 = 16'd0; data_02 = 16'd0;
        data_10 = 16'd0;   data_11 = 16'd0; data_12 = 16'd0;
        data_20 = 16'd0;   data_21 = 16'd0; data_22 = 16'd255;
        #10;
        $display("Test 4 - Diagonal Edge: sdata = %0d", sdata);

        // 종료
        $display("Test Completed");
        $finish;
    end

endmodule
