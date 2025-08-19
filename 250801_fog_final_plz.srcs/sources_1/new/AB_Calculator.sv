module AB_Calculator #(
    parameter WINDOW_SIZE      = 15,
    parameter DATA_WIDTH       = 24,
    parameter SUM_I_WIDTH      = 20,
    parameter SUM_II_WIDTH     = 32,
    parameter SUM_P_WIDTH      = 16,
    parameter SUM_IP_WIDTH     = 28
) (
    input  logic                         clk,
    input  logic                         rst,
    input  logic [9:0]                   x_pixel,
    input  logic                         valid_in,
    input  logic [SUM_I_WIDTH-1:0]       sum_i,
    input  logic [SUM_II_WIDTH-1:0]      sum_ii,
    input  logic [SUM_P_WIDTH-1:0]       sum_p,
    input  logic [SUM_IP_WIDTH-1:0]      sum_ip,
    output logic signed [19:0]           a_k_out,
    output logic signed [DATA_WIDTH+5:0] b_k_out, // 29:0
    output logic                         valid_out
);

    localparam N = WINDOW_SIZE * WINDOW_SIZE;

    localparam AK_INT_BITS  = 4;
    localparam AK_FRAC_BITS = 16;
    localparam AK_WIDTH     = AK_INT_BITS + AK_FRAC_BITS;
    localparam DIVIDER_LATENCY = 59;
    localparam AK_CAL_LATENCY = 2 + DIVIDER_LATENCY; // sum 입력부터 a_k 계산 완료까지의 총 지연시간 (mul/sub + divider)

    localparam signed [47:0] EPSILON = 1; // 원본의 VAR_NUM_WIDTH와 맞춤

    // MUL/SUB 결과 저장 register
    logic [SUM_II_WIDTH + $clog2(N) - 1:0] mul_sumii_n_reg;
    logic [SUM_I_WIDTH*2 - 1:0]            mul_sumi_sumi_reg;
    logic [SUM_IP_WIDTH + $clog2(N) - 1:0] mul_sumip_n_reg;
    logic [SUM_I_WIDTH + SUM_P_WIDTH-1:0]  mul_sumi_sump_reg;

    logic signed [36:0] cov_num_reg;
    logic signed [40:0] var_num_reg;

    logic valid_d1;
    logic [9:0] x_pixel_d1;

    assign divide_valid = valid_d1;
    assign mul_sumii_n_reg   = sum_ii * N;
    assign mul_sumi_sumi_reg = sum_i * sum_i;
    assign mul_sumip_n_reg   = sum_ip * N;
    assign mul_sumi_sump_reg = sum_i * sum_p;

    always_ff @( posedge clk or posedge rst ) begin
        if(rst)begin
            var_num_reg       <= '0;
            cov_num_reg       <= '0;
            valid_d1          <= 0;
            x_pixel_d1        <= 0;
        end
        else begin
            valid_d1 <= valid_in && (x_pixel != x_pixel_d1);
            x_pixel_d1 <= x_pixel;
            if(valid_in) begin
                var_num_reg <= mul_sumii_n_reg - mul_sumi_sumi_reg;
                cov_num_reg <= mul_sumip_n_reg - mul_sumi_sump_reg;
            end
        end
    end

    // --- 1. a_k 계산 ---
    logic signed [36:0] dividend_to_ip;
    logic signed [40:0] divisor_to_ip;

    logic signed_divide;
    
    // a_k = cov / (var + eps)
    // assign dividend_to_ip = $signed(cov_num_reg) <<< AK_FRAC_BITS;
    logic signed [36:0] dividend_reg;
    logic signed [40:0] divisor_reg;

    assign dividend_reg = $signed(cov_num_reg);
    assign divisor_reg  = var_num_reg + EPSILON;

    always_ff @( posedge clk or posedge rst ) begin
        if(rst)begin
            dividend_to_ip <= 0;
            divisor_to_ip  <= 0;
        end
        else begin
            dividend_to_ip <= (dividend_reg < 0) ? ~(cov_num_reg) + 1 : cov_num_reg;
            divisor_to_ip  <= (divisor_reg < 0) ? ~(var_num_reg + EPSILON) + 1 : var_num_reg + EPSILON;
            signed_divide  <= dividend_reg[36] ^ divisor_reg[40];
        end
    end

    // logic [53:0] remainder_from_ip;
    logic signed [40:0] quotient_from_ip_int;
    logic [15:0] quotient_from_ip_frac;
    logic        quotient_valid;

    shift_divider #(
        .DATA_WIDTH(41),
        .FRAC_BITS (16)
    ) divider_ip (
        .clk(clk),
        .rst(rst),
        .divided_in_tdata ({4'b0, dividend_to_ip}),
        .divided_in_tvalid(divide_valid),
        .divided_in_tready(),
        .divisor_in_tdata (divisor_to_ip),
        .divisor_in_tvalid(divide_valid),
        .quotient_integer_out (quotient_from_ip_int),
        .quotient_fractional_out (quotient_from_ip_frac),
        .remainder_out_tdata(),
        .quotient_out_tvalid (quotient_valid)
    );

    // [수정 1] 정확한 a_k 고정소수점 값을 위한 wire 선언
    logic signed [56:0] a_k_fixed;
    // assign a_k_fixed = {quotient_from_ip_int[AK_INT_BITS-1:0], quotient_from_ip_frac};
    assign a_k_fixed = (quotient_from_ip_int << AK_FRAC_BITS) | quotient_from_ip_frac;
    always_ff @( posedge clk, posedge rst) begin : blockName
        if (rst) begin
            a_k_out <= 0;
        end
        else begin
            a_k_out <= a_k_fixed[19:0];
        end
    end

    // --- 2. b_k 계산 ---

    // [수정 2] a_k 계산 지연시간에 맞춰 sum_i와 sum_p를 지연시키는 파이프라인
    logic [SUM_I_WIDTH-1:0] sum_i_pipeline [0:AK_CAL_LATENCY-1];
    logic [SUM_P_WIDTH-1:0] sum_p_pipeline [0:AK_CAL_LATENCY-1];

    always_ff @( posedge clk or posedge rst ) begin
        if(rst)begin
             for(int i = 0; i < AK_CAL_LATENCY; i = i + 1)begin
                sum_i_pipeline[i] <= '0;
                sum_p_pipeline[i] <= '0;
            end
        end
        else if(valid_in) begin // 유효한 sum 값이 들어올 때마다 파이프라인에 적재
            sum_i_pipeline[0] <= sum_i;
            sum_p_pipeline[0] <= sum_p;
            for(int i = 1; i < AK_CAL_LATENCY; i = i + 1)begin
                sum_i_pipeline[i] <= sum_i_pipeline[i-1];
                sum_p_pipeline[i] <= sum_p_pipeline[i-1];
            end
        end
    end

    // 파이프라인을 통과하여 a_k와 타이밍이 동기화된 sum_i, sum_p 값
    logic signed [SUM_I_WIDTH-1:0] sum_i_synced;
    logic signed [SUM_P_WIDTH-1:0] sum_p_synced;
    assign sum_i_synced = sum_i_pipeline[AK_CAL_LATENCY-1];
    assign sum_p_synced = sum_p_pipeline[AK_CAL_LATENCY-1];

    // b_k_num = (sum_p * 2^16) - (a_k_fixed * sum_i)
    // logic signed [SUM_P_WIDTH + AK_FRAC_BITS :0] b_k_num;
    logic signed [32:0] b_k_num;
    // logic signed [AK_WIDTH + SUM_I_WIDTH - 1:0]  mul_result;
    logic signed [32:0]  mul_result;
    logic valid_delay;
    
    assign mul_result = a_k_fixed[31:16] * sum_i_synced;

    always_ff @( posedge clk or posedge rst) begin
        if(rst)begin
            b_k_num <= 0;
            valid_delay <= 0;
        end
        else begin 
            valid_delay <= quotient_valid;
            if(quotient_valid)begin // a_k 계산이 완료된 시점에
                // [수정 1] 올바른 a_k 값과 [수정 2] 동기화된 sum 값으로 연산
                
                b_k_num <= ($signed(sum_p_synced)) - mul_result;
            end
        end
    end

    // b_k = b_k_num / (N * 2^16) 이지만, 하드웨어 친화적으로 (b_k_num / 2^clog2(N)) / 2^16 으로 근사
    assign b_k_out = b_k_num >>> 8;
    assign valid_out = valid_delay;

endmodule
