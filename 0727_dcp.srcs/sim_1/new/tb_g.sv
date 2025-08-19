`timescale 1ns / 1ps


module tb_g ();


    //--- 시뮬레이션 파라미터 ---
    localparam IMAGE_WIDTH = 640;
    localparam IMAGE_HEIGHT = 480;

    //--- DUT 파라미터 (DUT와 동일하게 설정) ---
    localparam DATA_WIDTH = 24;
    localparam WINDOW_SIZE = 15;

    //--- 테스트벤치 신호 선언 ---
    logic        clk;
    logic        rst;
    logic [ 9:0] tb_x_pixel;
    logic [ 9:0] tb_y_pixel;
    logic        tb_de;
    logic [23:0] tb_guide_pixel_in;
    logic [ 7:0] tb_input_pixel_in;

    // DUT 출력 신호
    wire         dut_de_out;
    wire  [ 7:0] dut_q_i;

    //--- DUT (Device Under Test) 인스턴스 ---
    guided_filter_top #(
        .DATA_WIDTH (DATA_WIDTH),
        .WINDOW_SIZE(WINDOW_SIZE)
    ) UUT (
        .clk(clk),
        .rst(rst),
        .x_pixel(tb_x_pixel),
        .y_pixel(tb_y_pixel),
        .DE(tb_de),
        .guide_pixel_in(tb_guide_pixel_in),
        .input_pixel_in(tb_input_pixel_in),
        .q_i(dut_q_i),
        .DE_out(dut_de_out)
    );

    //--- 1. 클럭 및 리셋 생성 ---
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        tb_x_pixel = 0;
        tb_y_pixel = 0;
        tb_de = 0;
        tb_guide_pixel_in = 0;
        tb_input_pixel_in = 0;
        #50;
        rst = 0;

        #20;

        for (int y = 0; y < IMAGE_HEIGHT; y = y + 1) begin
            for (int x = 0; x < IMAGE_WIDTH; x = x + 1) begin
                // 유효한 픽셀 데이터 인가
                tb_de <= 1;
                tb_x_pixel <= x;
                tb_y_pixel <= y;

                // 간단한 테스트 데이터 (좌표 기반 그래디언트)
                tb_guide_pixel_in <= {8'(x[7:0]), 8'(x[7:0]), 8'(x[7:0])};
                tb_input_pixel_in <= y[7:0];

                @(posedge clk);
            end
        end

        // 프레임 종료
        tb_de <= 0;

        // 출력이 모두 나올 때까지 충분히 시뮬레이션 계속
        #500;

        $stop;

    end

endmodule
