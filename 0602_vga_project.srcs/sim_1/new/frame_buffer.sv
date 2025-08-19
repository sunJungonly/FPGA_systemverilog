`timescale 1ns/1ps

module frame_buffer_tb;

    logic wclk, rclk, we, oe;
    logic [8:0] h_counter;
    logic [7:0] v_counter;
    logic [16:0] wAddr, rAddr;
    logic [15:0] wData;

    logic [15:0] rData00, rData01, rData02;
    logic [15:0] rData10, rData11, rData12;
    logic [15:0] rData20, rData21, rData22;

    frame_buffer uut (
        .wclk(wclk),
        .we(we),
        .h_counter(h_counter),
        .v_counter(v_counter),
        .wAddr(wAddr),
        .wData(wData),

        .rclk(rclk),
        .oe(oe),
        .rAddr(rAddr),

        .rData00(rData00), .rData01(rData01), .rData02(rData02),
        .rData10(rData10), .rData11(rData11), .rData12(rData12),
        .rData20(rData20), .rData21(rData21), .rData22(rData22)
    );

    // Clock generation
    always #5 wclk = ~wclk;
    always #7 rclk = ~rclk;

    initial begin
        wclk = 0;
        rclk = 0;
        we = 0;
        oe = 0;
        h_counter = 0;
        v_counter = 0;
        wAddr = 0;
        wData = 0;
        rAddr = 0;

        // ----------------------------
        // STEP 1: write test pattern
        // ----------------------------
        @(posedge wclk);
        for (int y = 0; y < 5; y++) begin
            for (int x = 0; x < 5; x++) begin
                v_counter = y;
                h_counter = x << 1;  // emulate h_counter[9:1] = x
                wAddr = y * 320 + x;
                wData = y * 10 + x; // test data
                we = 1;
                @(posedge wclk);
            end
        end
        we = 0;

        // ----------------------------
        // STEP 2: read from center pixel (2,2)
        // ----------------------------
        @(posedge rclk);
        v_counter = 2;
        h_counter = 4;       // h_counter[9:1] = 2
        rAddr = 2 * 320 + 2;
        oe = 1;
        @(posedge rclk);
        oe = 0;

        // Wait and print
        #10;
        $display("Center (2,2) read:");
        $display("rData00=%0d rData01=%0d rData02=%0d", rData00, rData01, rData02);
        $display("rData10=%0d rData11=%0d rData12=%0d", rData10, rData11, rData12);
        $display("rData20=%0d rData21=%0d rData22=%0d", rData20, rData21, rData22);

        // ----------------------------
        // STEP 3: read from corner pixel (0,0) s0
        // ----------------------------
        @(posedge rclk);
        v_counter = 0;
        h_counter = 0;       // h_counter[9:1] = 0
        rAddr = 0 * 320 + 0;
        oe = 1;
        @(posedge rclk);
        oe = 0;

        #10;
        $display("Corner (0,0) read:");
        $display("rData00=%0d rData01=%0d rData02=%0d", rData00, rData01, rData02);
        $display("rData10=%0d rData11=%0d rData12=%0d", rData10, rData11, rData12);
        $display("rData20=%0d rData21=%0d rData22=%0d", rData20, rData21, rData22);

        // ----------------------------
        $finish;
    end

endmodule
