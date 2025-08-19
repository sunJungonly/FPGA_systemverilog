`timescale 1ns / 1ps

module fog_removal_top #(
    parameter IMAGE_WIDTH  = 320,
    parameter IMAGE_HEIGHT = 240,
    parameter DATA_WIDTH   = 8,
    parameter DC_LATENCY = 10,  // LineBuffer(1) + Matrix(7) + BlockMin(2) = 10 
    parameter TE_LATENCY = 37   // TransmissionEstimate의 Divider IP Latency
) (
    input  logic                            clk,
    input  logic                            rst,
    //input port
    input  logic [                    23:0] pixel_in_888,

    input  logic                            DE,
    input  logic [ $clog2(IMAGE_WIDTH)-1:0] x_pixel,
    input  logic [$clog2(IMAGE_HEIGHT)-1:0] y_pixel,
    //output port
    output logic [        DATA_WIDTH*3-1:0] removal_data,
    output logic                            DE_out,
    output logic [ $clog2(IMAGE_WIDTH)-1:0] x_pixel_out
);

    // --- 내부 신호 선언 ---
    logic [DATA_WIDTH-1:0] dc_out, airlight_r, airlight_g, airlight_b, t_out;
    logic de_dc, de_te;
    logic [$clog2(IMAGE_WIDTH)-1:0] x_dc, x_te;
    logic airlight_done;

    // --- 2. Airlight 저장을 위한 레지스터 (피드백 루프) ---
    logic [DATA_WIDTH-1:0] airlight_r_reg, airlight_g_reg, airlight_b_reg;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // 첫 프레임의 Airlight를 위한 경험적인 초기값
            airlight_r_reg <= 8'd220;
            airlight_g_reg <= 8'd220;
            airlight_b_reg <= 8'd220;
        end else if (airlight_done) begin // airlight_A가 계산을 마쳤을 때!
            airlight_r_reg <= airlight_r; // 계산된 새 Airlight 값을 저장
            airlight_g_reg <= airlight_g;
            airlight_b_reg <= airlight_b;
        end
        // done 신호가 없으면 이전 값을 그대로 유지
    end

    // --- 3. 원본 데이터 동기화를 위한 지연 라인 (쉬프트 레지스터) ---
    // 전체 파이프라인의 총 지연 시간
    localparam TOTAL_LATENCY = DC_LATENCY + TE_LATENCY;
    logic [15:0] pixel_888_delayed [0:TOTAL_LATENCY-1];
    logic [$clog2(IMAGE_HEIGHT)-1:0] y_pixel_delayed [0:DC_LATENCY-1]; // y_pixel은 airlight_A까지만 지연

    always_ff @(posedge clk) begin
        if (rst) begin
            pixel_888_delayed <= '{default:'0};
            y_pixel_delayed   <= '{default:'0};
        end else if (DE) begin
            pixel_888_delayed[0] <= pixel_in_888;
            for (int i=0; i<TOTAL_LATENCY-1; i++) pixel_888_delayed[i+1] <= pixel_888_delayed[i];

            y_pixel_delayed[0] <= y_pixel;
            for (int i=0; i<DC_LATENCY-1; i++) y_pixel_delayed[i+1] <= y_pixel_delayed[i];
        end
    end

    DarkChannel#(
        .DATA_DEPTH(IMAGE_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) U_DarkChannel (
        .clk(clk),
        .rst(rst),

        //input port
        .pixel_in_888(pixel_in_888),
        .DE(DE),
        .x_pixel(x_pixel),

        //output port
        .dark_channel_out(dc_out),  // dark channel 결과값
        .DE_out(de_dc),  // 결과 데이터 유효 신호
        .x_pixel_out(x_dc)
    );
    
    airlight_A#(
        .IMAGE_WIDTH (IMAGE_WIDTH),
        .IMAGE_HEIGHT(IMAGE_HEIGHT),
        .DATA_WIDTH  (DATA_WIDTH)
    ) U_Airlight (
        .clk(clk),
        .rst(rst),

        //input port
        .DE(de_dc),
        .x_pixel(x_dc),
        .y_pixel(y_pixel_delayed[DC_LATENCY-1]), // 지연된 y_pixel
        .pixel_in_888(pixel_888_delayed[DC_LATENCY-1]), // 지연된 원본 픽셀
        .dark_channel_in(dc_out),

        //output port
        .airlight_r_out(airlight_r),
        .airlight_g_out(airlight_g),
        .airlight_b_out(airlight_b),
        .airlight_done(airlight_done)
    ); 
    
    TransmissionEstimate#(
        .DATA_DEPTH(IMAGE_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) U_Transmission_Estimate(
        .clk(clk),
        .rst(rst),

        //input port
        .DE(de_dc),
        .x_pixel(x_dc),
        .dark_channel_in(dc_out),  // 8비트 dark channel
        .airlight_r_in(airlight_r_reg),  // 프레임 내내 고정된 Airlight R
        .airlight_g_in(airlight_g_reg),
        .airlight_b_in(airlight_b_reg),

        //output port
        .t_out(t_out),
        .DE_out(de_te),
        .x_pixel_out(x_te)
    );
    
    fog_removal_cal#(
        .DATA_DEPTH(IMAGE_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .DIVIDER_LATENCY(37)
    ) U_Recover (
        .clk(clk),
        .rst(rst),

        //input port
        .DE(de_te),
        .x_pixel(x_te),
        .pixel_in_888(pixel_888_delayed[TOTAL_LATENCY-1]),
        .airlight_r(airlight_r_reg),
        .airlight_g(airlight_g_reg),
        .airlight_b(airlight_b_reg),
        .tx_data(t_out),  // guided filter에서 나온 값

        //output port
        .removal_data(removal_data),
        .DE_out(DE_out),
        .x_pixel_out(x_pixel_out)
    );

endmodule
