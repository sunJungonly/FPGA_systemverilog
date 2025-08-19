`timescale 1ns / 1ps


module fog_removal_cal #(
    parameter DATA_DEPTH = 320,
    parameter DATA_WIDTH = 8,
    parameter DIVIDER_LATENCY = 20
) (
    input logic clk,
    input logic rst,

    input logic DE,
    input logic [$clog2(DATA_DEPTH)-1:0] x_pixel,
    input logic [23:0] pixel_in_888,
    input logic [DATA_WIDTH-1:0] airlight_r,
    input logic [DATA_WIDTH-1:0] airlight_g,
    input logic [DATA_WIDTH-1:0] airlight_b,
    input logic [DATA_WIDTH - 1:0] tx_data,  // guided filter에서 나온 값

    output logic [      DATA_WIDTH*3-1:0] removal_data,
    output logic                          DE_out,
    output logic [$clog2(DATA_DEPTH)-1:0] x_pixel_out
);

    logic [DATA_WIDTH - 1:0] r_8bit;
    logic [DATA_WIDTH - 1:0] g_8bit;
    logic [DATA_WIDTH - 1:0] b_8bit;

    assign r_8bit = {pixel_in_888[23:16]};
    assign g_8bit = {pixel_in_888[15:8]};
    assign b_8bit = {pixel_in_888[7:0]};

    parameter   tx_min   =   8'd26;//=0.1 * 2^8 하한값 t0=0.1로 설정한 것을 8비트 고정 소수점으로 나타냄
    logic [DATA_WIDTH : 0] tx_value;
    assign tx_value = tx_data < tx_min ? tx_min : tx_data;


    // --- Stage 1: J = ((I-A)*2^8 + A*t) 계산 ---
    logic signed [DATA_WIDTH*2+1:0]
        value_tem_r, value_tem_g, value_tem_b;  // 비트 폭 재계산 필요
    logic DE_s1;
    logic [8:0] x_pixel_s1;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            value_tem_r <= '0;
            value_tem_g <= '0;
            value_tem_b <= '0;
            DE_s1 <= 1'b0;
            x_pixel_s1 <= '0;
        end else begin
            if (DE) begin
                value_tem_r <= ( (signed'(r_8bit) - signed'(airlight_r)) <<< 8 ) + signed'(airlight_r) * signed'(tx_value);
                value_tem_g <= ( (signed'(g_8bit) - signed'(airlight_g)) <<< 8 ) + signed'(airlight_g) * signed'(tx_value);
                value_tem_b <= ( (signed'(b_8bit) - signed'(airlight_b)) <<< 8 ) + signed'(airlight_b) * signed'(tx_value);
            end
            DE_s1 <= DE;
            x_pixel_s1 <= x_pixel;
        end
    end

    // --- Stage 2: 나눗셈 IP 연결 ---
    logic signed [15:0]
        removal_data_r_raw, removal_data_g_raw, removal_data_b_raw;
    logic r_valid_out, g_valid_out, b_valid_out;

    // IP의 32비트 출력을 받을 임시 wire 선언
    logic [31:0] div_out_r_temp, div_out_g_temp, div_out_b_temp;

    // 각각 RGB 채널 별로 총 3개 IP 사용
    // value_tem_r/g/b (분자), tx_value_d1 (분모, 하한 보정된 t(x))

    // R 채널 Divider
    divider_IP_wrapper u_div_r (
        .reset_rtl_0(rst),
        .sys_clk(clk),

        .divided_in_tdata (value_tem_r),    // signed // input
        .divided_in_tvalid(DE_s1),          // input
        .divided_in_tready(),               // output

        .divisor_in_tdata ($signed({8'd0, tx_value})),  //unsgned     // input
        .divisor_in_tvalid(DE_s1),          // input
        .divisor_in_tready(),               // output

        .divided_out_tdata (div_out_r_temp),   // output
        .divided_out_tvalid(r_valid_out)           // output
    );

    // G 채널 Divider
    divider_IP_wrapper u_div_g (
        .reset_rtl_0(rst),
        .sys_clk(clk),

        .divided_in_tdata (value_tem_g),
        .divided_in_tvalid(DE_s1),
        .divided_in_tready(),

        .divisor_in_tdata (({8'd0, tx_value})),
        .divisor_in_tvalid(DE_s1),
        .divisor_in_tready(),

        .divided_out_tdata (div_out_g_temp),
        .divided_out_tvalid(g_valid_out)
    );

    // B 채널 Divider
    divider_IP_wrapper u_div_b (
        .reset_rtl_0(rst),
        .sys_clk(clk),

        .divided_in_tdata (value_tem_b),
        .divided_in_tvalid(DE_s1),
        .divided_in_tready(),

        .divisor_in_tdata (({8'd0, tx_value})),
        .divisor_in_tvalid(DE_s1),
        .divisor_in_tready(),

        .divided_out_tdata (div_out_b_temp),
        .divided_out_tvalid(b_valid_out)
    );

    // 몫(상위 16비트)을 기존 wire에 할당
    assign removal_data_r_raw = div_out_r_temp[31:16];
    assign removal_data_g_raw = div_out_g_temp[31:16];
    assign removal_data_b_raw = div_out_b_temp[31:16];


    // ---  Stage 3: 제어 신호 동기화 (쉬프트 레지스터 방식)  ---
    logic [DIVIDER_LATENCY-1:0][$clog2(DATA_DEPTH)-1:0] x_pixel_delay;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            x_pixel_delay <= '{default: '0};
        end else if (DE_s1) begin // IP에 데이터가 들어갈 때만 쉬프트!
            x_pixel_delay[0] <= x_pixel_s1;
            for (int i = 0; i < DIVIDER_LATENCY - 1; i = i + 1) begin
                x_pixel_delay[i+1] <= x_pixel_delay[i];
            end
        end
    end

    // --- 최종 출력 할당 ---
    logic [7:0] final_r, final_g, final_b;

    // 포화 로직 적용(음수 값에 대한 대응)
    assign final_r = (removal_data_r_raw < 0) ? 8'd0 : (removal_data_r_raw > 255) ? 8'd255 : removal_data_r_raw[7:0];
    assign final_g = (removal_data_g_raw < 0) ? 8'd0 : (removal_data_g_raw > 255) ? 8'd255 : removal_data_g_raw[7:0];
    assign final_b = (removal_data_b_raw < 0) ? 8'd0 : (removal_data_b_raw > 255) ? 8'd255 : removal_data_b_raw[7:0];

    assign removal_data = {final_r, final_g, final_b};

    assign DE_out      = r_valid_out; // IP의 유효 신호를 최종 유효 신호로 사용
    assign x_pixel_out = x_pixel_delay[DIVIDER_LATENCY-1]; // 지연된 x_pixel 값 출력

endmodule
