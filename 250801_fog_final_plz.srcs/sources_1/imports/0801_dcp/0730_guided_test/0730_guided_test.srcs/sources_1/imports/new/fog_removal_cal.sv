`timescale 1ns / 1ps

// recover output rgb value가 일정 간격마다 0이 나오는 듯
// 테스트벤치 문제인지 진짜 문제인지 파악해봐야함
// 이것만 봤을 땐 영상 테스트에서 봤던 줄 그어진 거랑 비슷한듯
// 뭐랑 뭐를 나누는 지 봐야할 듯

// 나누는 거
// 

module fog_removal_cal #(
    parameter DATA_DEPTH = 320,
    parameter DATA_WIDTH = 8
    // parameter DIVIDER_LATENCY = 18
) (
    input logic clk,
    input logic rst,
    input logic pclk,
    input logic DE,
    input logic [$clog2(DATA_DEPTH)-1:0] x_pixel,
    input logic [23:0] pixel_in_888,
    input logic [DATA_WIDTH-1:0] airlight_r,
    input logic [DATA_WIDTH-1:0] airlight_g,
    input logic [DATA_WIDTH-1:0] airlight_b,
    input logic [DATA_WIDTH - 1:0] tx_data,  // guided filter에서 나온 값

    output logic [        DATA_WIDTH-1:0] final_r,
    output logic [        DATA_WIDTH-1:0] final_g,
    output logic [        DATA_WIDTH-1:0] final_b,
    output logic                          DE_out
    // output logic [$clog2(DATA_DEPTH)-1:0] x_pixel_out
);
    localparam DIVIDER_WIDTH = DATA_WIDTH * 2;

    logic [DATA_WIDTH - 1:0] r_8bit;
    logic [DATA_WIDTH - 1:0] g_8bit;
    logic [DATA_WIDTH - 1:0] b_8bit;

    logic [DATA_WIDTH-1:0] airlight_r_signed;
    logic [DATA_WIDTH-1:0] airlight_g_signed;
    logic [DATA_WIDTH-1:0] airlight_b_signed;
    // 원본
    assign r_8bit = {pixel_in_888[23:16]};
    assign g_8bit = {pixel_in_888[15:8]};
    assign b_8bit = {pixel_in_888[7:0]};

    assign airlight_r_signed = airlight_r;
    assign airlight_g_signed = airlight_g;
    assign airlight_b_signed = airlight_b;

    parameter   tx_min   =   8'd78;//=0.1 * 2^8 하한값 t0=0.1로 설정한 것을 8비트 고정 소수점으로 나타냄
    logic [DATA_WIDTH - 1 : 0] tx_value;


    // --- Stage 1: J = ((I-A)*2^8 + A*t) 계산 ---
    logic  [DATA_WIDTH - 1:0] value_tem_r, value_tem_g, value_tem_b;  // 비트 폭 재계산 필요
    // logic  [DIVIDER_WIDTH:0] value_tem_r, value_tem_g, value_tem_b;  // 비트 폭 재계산 필요
    logic [$clog2(DATA_DEPTH)-1:0] x_pixel_s1;
    logic DE_s1;
    // --- Stage 2: 나눗셈 IP 연결 ---
    logic  [DIVIDER_WIDTH - 1:0] removal_data_r_int, removal_data_g_int, removal_data_b_int;
    logic  [7:0] removal_data_r_frac, removal_data_g_frac, removal_data_b_frac;
    logic r_valid_out, g_valid_out, b_valid_out;


    logic signed [8:0] result_integer_r, result_integer_g, result_integer_b;
    logic signed_tem_r, signed_tem_g, signed_tem_b;
    always_ff @(posedge pclk or posedge rst) begin
        if (rst) begin
            value_tem_r <= '0;
            value_tem_g <= '0;
            value_tem_b <= '0;
            x_pixel_s1 <= '0;
            DE_s1 <= 0;
            signed_tem_r <= 0;
            signed_tem_g <= 0;
            signed_tem_b <= 0;
            tx_value <= 0;
        end else begin
            if (DE) begin
                tx_value = (tx_data < tx_min) ? tx_min : tx_data;
                value_tem_r <= ($signed({r_8bit} - {airlight_r_signed}) < 0) ? ~({r_8bit} - {airlight_r_signed}) + 1 : ({r_8bit} - {airlight_r_signed}); //* ((16'h0100 - {8'b0, tx_value})) )>> 8)  + ({airlight_r_signed});
                value_tem_g <= ($signed({g_8bit} - {airlight_g_signed}) < 0) ? ~({g_8bit} - {airlight_g_signed}) + 1 : ({g_8bit} - {airlight_g_signed}); //* ((16'h0100 - {8'b0, tx_value})) )>> 8)  + ({airlight_g_signed});
                value_tem_b <= ($signed({b_8bit} - {airlight_b_signed}) < 0) ? ~({b_8bit} - {airlight_b_signed}) + 1 : ({b_8bit} - {airlight_b_signed}); //* ((16'h0100 - {8'b0, tx_value})) )>> 8)  + ({airlight_b_signed});
                signed_tem_r <= ($signed({r_8bit} - {airlight_r_signed}) < 0) ? 1 : 0; 
                signed_tem_g <= ($signed({g_8bit} - {airlight_g_signed}) < 0) ? 1 : 0; 
                signed_tem_b <= ($signed({b_8bit} - {airlight_b_signed}) < 0) ? 1 : 0; 
            end
            DE_s1 <= DE;
            x_pixel_s1 <= x_pixel;
        end
    end
    shift_divider_pipelined #(
        .DATA_WIDTH(24), //18비트
        .FRAC_BITS (8)
    ) u_div_r (
        .clk(pclk),
        .rst(rst),

        // 분자(Dividend) 입력
        .divided_in_tdata ({8'b0, value_tem_r, 8'b0}),
        .divided_in_tvalid(DE_s1),
        .divided_in_tready(),

        // 분모(Divisor) 입력
        .divisor_in_tdata ({16'b0, tx_value}),
        .divisor_in_tvalid(DE_s1),

        // 결과(Quotient) 출력
        .quotient_integer_out (removal_data_r_int),
        .quotient_fractional_out(removal_data_r_frac), // not used
        .remainder_out_tdata(),
        .quotient_out_tvalid (r_valid_out) // not used
    );

    shift_divider_pipelined #(
        .DATA_WIDTH(24),
        .FRAC_BITS (8)
    ) u_div_g (
        .clk(pclk),
        .rst(rst),

        // 분자(Dividend) 입력
        .divided_in_tdata ({8'b0, value_tem_g, 8'b0}),
        .divided_in_tvalid(DE_s1),
        .divided_in_tready(),

        // 분모(Divisor) 입력
        .divisor_in_tdata ({16'b0, tx_value}),
        .divisor_in_tvalid(DE_s1),

        // 결과(Quotient) 출력
        .quotient_integer_out (removal_data_g_int),
        .quotient_fractional_out(removal_data_g_frac), // not used
        .remainder_out_tdata(),
        .quotient_out_tvalid (g_valid_out) // not used
    );

    shift_divider_pipelined #(
        .DATA_WIDTH(24),
        .FRAC_BITS (8)
    ) u_div_b (
        .clk(pclk),
        .rst(rst),

        // 분자(Dividend) 입력
        .divided_in_tdata ({8'b0, value_tem_b, 8'b0}),
        .divided_in_tvalid(DE_s1),
        .divided_in_tready(),

        // 분모(Divisor) 입력
        .divisor_in_tdata ({16'b0, tx_value}),
        .divisor_in_tvalid(DE_s1),

        // 결과(Quotient) 출력
        .quotient_integer_out (removal_data_b_int),
        .quotient_fractional_out(removal_data_b_frac), // not used
        .remainder_out_tdata(),
        .quotient_out_tvalid (b_valid_out) // not used
    );


    localparam DELAY = 34; // 분배기 지연시간(25) + Mux/Demux 로직 지연(약 4)

    logic       DE_pipe     [0:DELAY-1];

    always_ff @(posedge pclk or posedge rst) begin 
        if (rst) begin
            for (int k = 0; k < DELAY; k++) begin

                DE_pipe[k]      <= 0;
            end
        end else begin
            DE_pipe[0]      <= DE;
            for (int k = 1; k < DELAY; k++) begin
                DE_pipe[k]      <= DE_pipe[k-1];
            end
        end
    end

    assign DE_out = DE_pipe[DELAY-1];

    // --- 최종 출력 할당 ---

    // 나눗셈 결과의 "정수부"를 추출합니다. 
    // assign result_integer_r = ((removal_data_r_int + airlight_r_signed) > 8'd255) ? 8'd255 : (removal_data_r_int + airlight_r_signed);
    // assign result_integer_g = ((removal_data_g_int + airlight_g_signed) > 8'd255) ? 8'd255 : (removal_data_g_int + airlight_g_signed);
    // assign result_integer_b = ((removal_data_b_int + airlight_b_signed) > 8'd255) ? 8'd255 : (removal_data_b_int + airlight_b_signed);

    // assign result_integer_r = (removal_data_r_int >> 8) + $signed(airlight_r_signed);
    // assign result_integer_b = (removal_data_g_int >> 8) + $signed(airlight_b_signed);
    // assign result_integer_g = (removal_data_b_int >> 8) + $signed(airlight_g_signed);


    assign result_integer_r = (signed_tem_r) ? $signed(~(removal_data_r_int) + 1) + $signed(airlight_r_signed) : ((removal_data_r_int >> 8)) + $signed(airlight_r_signed);
    assign result_integer_b = (signed_tem_g) ? $signed(~(removal_data_g_int) + 1) + $signed(airlight_b_signed) : ((removal_data_g_int >> 8)) + $signed(airlight_b_signed);
    assign result_integer_g = (signed_tem_b) ? $signed(~(removal_data_b_int) + 1) + $signed(airlight_g_signed) : ((removal_data_b_int >> 8)) + $signed(airlight_g_signed);
    // 포화 로직 적용
    always_comb begin
        if (r_valid_out) begin
            final_r =  (result_integer_r > 255) ? 255 : (result_integer_r < 0) ? 0 : result_integer_r;
            final_g =  (result_integer_g > 255) ? 255 : (result_integer_g < 0) ? 0 : result_integer_g;
            final_b =  (result_integer_b > 255) ? 255 : (result_integer_b < 0) ? 0 : result_integer_b;  
        end
        else begin
            final_r = 0;
            final_g = 0;
            final_b = 0;
        end
    end

endmodule