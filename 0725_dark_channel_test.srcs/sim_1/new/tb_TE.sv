`timescale 1ns / 1ps

module tb_TE ();

    localparam DATA_DEPTH = 320;
    localparam DATA_WIDTH = 8;

    logic clk;
    logic rst;

    //INPUT
    logic DE;
    logic [8:0] x_pixel;
    logic [DATA_WIDTH-1:0] dark_channel_in;  // 8비트 dark channel
    logic [DATA_WIDTH-1:0] airlight_r_in;   // 프레임 내내 고정된 Airlight R
    logic [DATA_WIDTH-1:0] airlight_g_in;
    logic [DATA_WIDTH-1:0] airlight_b_in;

    //OUTPUT
    logic [DATA_WIDTH - 1:0] t_out;
    logic DE_out;
    logic [8:0] x_pixel_out;

    TransmissionEstimate#(
        .DATA_DEPTH(DATA_DEPTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut(
        .clk(clk),
        .rst(rst),
        .DE(DE),
        .x_pixel(x_pixel),
        .dark_channel_in(dark_channel_in),  // 8비트 dark channel
        .airlight_r_in(airlight_r_in),  // 프레임 내내 고정된 Airlight R
        .airlight_g_in(airlight_g_in),
        .airlight_b_in(airlight_b_in),
        .t_out(t_out),
        .DE_out(DE_out),
        .x_pixel_out(x_pixel_out)
    );
    //검증하기 위한 추가 요소
    logic [7:0] dc_counter = 0;
    logic [8:0] x_pixel_counter = 0;

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        DE = 0;
        //airlight 값은 시뮬레이션 동안 고정하여 대표값 선택 로직 확인
        airlight_r_in = 8'd210;
        airlight_g_in = 8'd220;  //G를 최대값으로 가정
        airlight_b_in = 8'd200;
        repeat (5) @(posedge clk);
        rst = 0;

        // 데이터 입력 구간
        // 파이프 라인을 채우고도 남을 만큼 충분히 데이터를 입력할 예정임
        // (1(stage1) + 20(IP) + 1(statge3)) = 22정도의 latency
        DE  = 1;
        repeat (30) @(posedge clk);

        @(posedge clk);
        airlight_r_in = 8'd110;
        airlight_g_in = 8'd120;  //G를 최대값으로 가정
        airlight_b_in = 8'd100;
        repeat (30) @(posedge clk);

        // --- 데이터 입력 중지 및 종료 ---
        DE = 0;
        repeat (10) @(posedge clk);
    end

    // --- DE에 맞춰 카운터 값을 입력으로 넣어줌 ---
    always_ff @(posedge clk) begin
        if (rst) begin
            x_pixel_counter <= 0;
            dc_counter      <= 0;
        end else if (DE) begin
            x_pixel_counter <= x_pixel_counter + 1;
            dc_counter <= dc_counter + 1;
        end
    end

    assign x_pixel = x_pixel_counter; //변화하는 x-Pixel값을 표현하기 위함
    assign dark_channel_in = dc_counter; //변화하는 dc값을 표현하기 위함

endmodule
