`timescale 1ns / 1ps

module tb_OV7670_VGA_Display;

    // 테스트벤치 신호
    logic clk;
    logic reset;
    logic [4:0] sw;

    logic ov7670_xclk;
    logic ov7670_pclk;
    logic ov7670_href;
    logic ov7670_v_sync;
    logic [7:0] ov7670_data;

    logic h_sync;
    logic v_sync;
    logic [3:0] red_port;
    logic [3:0] green_port;
    logic [3:0] blue_port;

    // UUT 인스턴스
    OV7670_VGA_Display uut (
        .clk(clk),
        .reset(reset),
        .sw(sw),
        .ov7670_xclk(ov7670_xclk),
        .ov7670_pclk(ov7670_pclk),
        .ov7670_href(ov7670_href),
        .ov7670_v_sync(ov7670_v_sync),
        .ov7670_data(ov7670_data),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .red_port(red_port),
        .green_port(green_port),
        .blue_port(blue_port)
    );

    // 클럭 생성
    initial clk = 0;
    always #10 clk = ~clk;  // 50MHz

    initial ov7670_pclk = 0;
    always #5 ov7670_pclk = ~ov7670_pclk;  // 100MHz 카메라 픽셀 클럭

    // 테스트 시나리오
    initial begin
        // 초기값
        reset = 1;
        sw = 5'b00001;
        ov7670_href = 0;
        ov7670_v_sync = 1;
        ov7670_data = 8'h00;

        #100;
        reset = 0;

        // 시뮬레이션: 수직 동기 시작
        #100;
        ov7670_v_sync = 0;

        // 간단한 프레임 시뮬레이션 (5줄, 10픽셀씩)
        repeat (5) begin
            ov7670_href = 1;
            repeat (10) begin
                @(posedge ov7670_pclk);
                ov7670_data = $random;
            end
            @(posedge ov7670_pclk);
            ov7670_href = 0;
        end

        // 프레임 끝
        #100;
        ov7670_v_sync = 1;

        // 잠시 후 종료
        #1000;
        $finish;
    end

endmodule
