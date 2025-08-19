`timescale 1ns / 1ps

module guided_filter_top #(
    parameter DATA_WIDTH  = 24,
    parameter WINDOW_SIZE = 15
)(
    input  logic        clk,
    input  logic        rst,
    input  logic [9:0]  x_pixel,
    input  logic [9:0]  y_pixel,
    input  logic        DE,
    input  logic [23:0] guide_pixel_in, // 원본 이미지
    input  logic [7:0]  input_pixel_in, // 전송맵
    output logic        DE_out,
    output logic [7:0]  q_i
);

    logic [11:0] guide_pixel_gray;

    logic [19:0] i_mul_p;
    assign i_mul_p = guide_pixel_gray * input_pixel_in;

    logic [19:0] sum_i;
    logic [15:0] sum_p;
    logic [31:0] sum_ii;
    logic [27:0] sum_ip;

    logic [27:0] sum_a;
    logic [37:0] sum_b;

    logic [19:0] a_k_out;
    logic [29:0] b_k_out;
    
    grayscale_converter gray_inst(
        .red_port(guide_pixel_in[23:16]),
        .green_port(guide_pixel_in[15:8]),
        .blue_port(guide_pixel_in[7:0]),
        .gray_port(guide_pixel_gray)
    );

    window_sum_calculator #(
        .IMAGE_WIDTH(640),
        .IMAGE_HEIGHT(480),
        .WINDOW_SIZE(15),
        .DATA_WIDTH(12),
        .SUM_WIDTH(DATA_WIDTH + $clog2(WINDOW_SIZE * WINDOW_SIZE)),
        .SUM_SQ_WIDTH(DATA_WIDTH*2 + $clog2(WINDOW_SIZE * WINDOW_SIZE)),
        .DUMMY()
    ) sum_i_inst(
        .clk(clk),
        .rst(rst),
        .pixel_in(guide_pixel_gray),
        .DE(DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .sum_out(sum_i),
        .sum_sq_out(sum_ii),
        .valid_out(valid_i)
    );

    window_sum_calculator #(
        .IMAGE_WIDTH(640),
        .IMAGE_HEIGHT(480),
        .WINDOW_SIZE(15),
        .DATA_WIDTH(8),
        .SUM_WIDTH(DATA_WIDTH + $clog2(WINDOW_SIZE * WINDOW_SIZE)),
        .SUM_SQ_WIDTH(DATA_WIDTH*2 + $clog2(WINDOW_SIZE * WINDOW_SIZE)),
        .DUMMY()
    ) sum_p_inst(
        .clk(clk),
        .rst(rst),
        .pixel_in(input_pixel_in),
        .DE(DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .sum_out(sum_p),
        .sum_sq_out(sum_pp), // dummy
        .valid_out(valid_p)
    );

    window_sum_calculator #(
        .IMAGE_WIDTH(640),
        .IMAGE_HEIGHT(480),
        .WINDOW_SIZE(15),
        .DATA_WIDTH(20),
        .SUM_WIDTH(DATA_WIDTH + $clog2(WINDOW_SIZE * WINDOW_SIZE)),
        .SUM_SQ_WIDTH(DATA_WIDTH*2 + $clog2(WINDOW_SIZE * WINDOW_SIZE)),
        .DUMMY()
    ) sum_ip_inst(
        .clk(clk),
        .rst(rst),
        .pixel_in(i_mul_p),
        .DE(DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .sum_out(sum_ip),
        .sum_sq_out(sum_ipip), // dummy
        .valid_out(valid_ip)
    );

    AB_Calculator #(
        .WINDOW_SIZE(15),
        .DATA_WIDTH(24),
        .SUM_I_WIDTH(20),
        .SUM_II_WIDTH(32),
        .SUM_P_WIDTH(16),
        .SUM_IP_WIDTH(28)
    ) ab_cal_inst(
        .clk(clk),
        .rst(rst),
        .valid_in(valid_ip),
        .sum_i(sum_i),
        .sum_ii(sum_ii),
        .sum_p(sum_p),
        .sum_ip(sum_ip),
        .a_k_out(a_k_out),
        .b_k_out(b_k_out),
        .valid_out(ab_valid_out)
    );

    window_sum_calculator #(
        .IMAGE_WIDTH(640),
        .IMAGE_HEIGHT(480),
        .WINDOW_SIZE(15),
        .DATA_WIDTH(20),
        .SUM_WIDTH(DATA_WIDTH + $clog2(WINDOW_SIZE * WINDOW_SIZE)),
        .SUM_SQ_WIDTH(DATA_WIDTH*2 + $clog2(WINDOW_SIZE * WINDOW_SIZE)),
        .DUMMY(0)
    ) sum_a_inst(
        .clk(clk),
        .rst(rst),
        .pixel_in(a_k_out),
        .DE(ab_valid_out),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .sum_out(sum_a),
        .sum_sq_out(), // dummy
        .valid_out(valid_a)
    );

    window_sum_calculator #(
        .IMAGE_WIDTH(640),
        .IMAGE_HEIGHT(480),
        .WINDOW_SIZE(15),
        .DATA_WIDTH(30),
        .SUM_WIDTH(DATA_WIDTH + $clog2(WINDOW_SIZE * WINDOW_SIZE)),
        .SUM_SQ_WIDTH(DATA_WIDTH*2 + $clog2(WINDOW_SIZE * WINDOW_SIZE)),
        .DUMMY(0)
    ) sum_b_inst(
        .clk(clk),
        .rst(rst),
        .pixel_in(b_k_out),
        .DE(ab_valid_out),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .sum_out(sum_b),
        .sum_sq_out(), // dummy
        .valid_out(valid_b)
    );

    Final_Output_Calculator #(
        .WINDOW_SIZE(15),
        .N(225),
        .GRAY_WIDTH(12),
        .AK_WIDTH(20),
        .BK_WIDTH(14),
        .INPUT_LATENCY(122),
        .SUM_A_WIDTH(28),
        .SUM_B_WIDTH(22)
    ) final_inst(
        .clk(clk),
        .rst(rst),
        .DE(DE),
        .guide_pixel_gray(guide_pixel_gray),
        .sum_a(sum_a),
        .sum_b(sum_b),
        .valid_a(valid_a),
        .q_i(q_i),
        .valid_out(DE_out)
    );

endmodule

module data_mem1 #(
    parameter DATA_WIDTH=24, 
    parameter WORD_WIDTH=640,
    parameter ADDR_WIDTH = $clog2(WORD_WIDTH)
) (
    input  logic                  wen,
    input  logic                  ren,
    input  logic                  clk,
    input  logic                  rst,
    input  logic [ADDR_WIDTH-1:0] waddr,
    input  logic [ADDR_WIDTH-1:0] raddr,
    input  logic [DATA_WIDTH-1:0] wdata,
    output logic [DATA_WIDTH-1:0] rdata
);

	logic [DATA_WIDTH-1:0] ram[0:WORD_WIDTH-1];

   always_ff @(posedge clk) begin
        // 쓰기 동작
        if (wen) begin
            ram[waddr] <= wdata;
        end
    end
    
   always_ff @(posedge clk) begin
        if(ren)begin
            rdata <= ram[raddr];
        end
    end

endmodule

module window_sum_calculator #(
    parameter IMAGE_WIDTH  = 640,
    parameter IMAGE_HEIGHT = 480,
    parameter WINDOW_SIZE  = 15,
    parameter DATA_WIDTH   = 16,
    parameter SUM_WIDTH = DATA_WIDTH + $clog2(WINDOW_SIZE * WINDOW_SIZE),
    parameter SUM_SQ_WIDTH = DATA_WIDTH*2 + $clog2(WINDOW_SIZE * WINDOW_SIZE),
    parameter DUMMY = 0
) (
    input  logic                    clk,
    input  logic                    rst,
    input  logic [DATA_WIDTH-1:0]   pixel_in, // 12bit rgb data
    input  logic                    DE,
    input  logic [9:0]              x_pixel,
    input  logic [9:0]              y_pixel,
    output logic [SUM_WIDTH-1:0]    sum_out, // window 합 결과
    output logic [SUM_SQ_WIDTH-1:0] sum_sq_out, // window 제곱의 합 결과
    output logic                    valid_out // sum_out, sum_sq_out이 유효할 때 1
);

    localparam COL_SUM_WIDTH = DATA_WIDTH + $clog2(WINDOW_SIZE);
    localparam COL_SUM_SQ_WIDTH = DATA_WIDTH*2 + $clog2(WINDOW_SIZE);

    logic [9:0] x_pixel_d1, x_pixel_d2, x_pixel_d3;
    logic [9:0] y_pixel_d1, y_pixel_d2;
    logic DE_d1, DE_d2;

    always_ff @( posedge clk or posedge rst ) begin
        if(rst)begin
            x_pixel_d1 <= 0; y_pixel_d1 <= 0; DE_d1 <= 0;
            x_pixel_d2 <= 0; y_pixel_d2 <= 0; DE_d2 <= 0;
        end
        else begin
            x_pixel_d1 <= x_pixel;
            y_pixel_d1 <= y_pixel;
            DE_d1      <= DE;

            x_pixel_d2 <= x_pixel_d1;
            y_pixel_d2 <= y_pixel_d1;
            DE_d2      <= DE_d1;

            x_pixel_d3 <= x_pixel_d2;
        end
    end

    // --- 3. 세로 합 계산 ---
    logic [COL_SUM_WIDTH-1:0]    col_sum;
    logic [COL_SUM_SQ_WIDTH-1:0] col_sum_sq;
    logic [DATA_WIDTH-1:0]       col_data_out_reg[0:WINDOW_SIZE-1];
    logic [DATA_WIDTH-1:0] ram_chain_out [0:WINDOW_SIZE-2]; 
    logic [1:0] counter;

    always_ff @( posedge clk or posedge rst ) begin
        if(rst)begin
            counter <= 0;
            for(int j = 0; j < 15; j++)begin
                col_data_out_reg[j] <= 0;
            end
        end
        else if(x_pixel != x_pixel_d1)begin
            counter <= 0;
        end
        // else begin
        //     counter <= counter + 1;
        //     if(counter == 2)begin
        //         counter <= 0;
        //         col_data_out_reg[0] <= pixel_in;
        //         for(int j = 1; j < 15; j++)begin
        //             col_data_out_reg[j] <= ram_chain_out[j-1];
        //         end
        //     end
        // end
        else begin
            counter <= counter + 1;
            if(counter == 2)begin
                counter <= 0;
                for(int j = 0; j < 15; j++)begin
                    if (y_pixel < 14) begin
                        if (j < y_pixel) begin
                            col_data_out_reg[j] <= (j == 0) ? pixel_in : ram_chain_out[j-1];
                        end else if (j == y_pixel) begin
                            col_data_out_reg[j] <= pixel_in;
                        end else begin
                            col_data_out_reg[j] <= DUMMY; // dummy
                        end
                    end else begin
                        col_data_out_reg[j] <= (j == 0) ? pixel_in : ram_chain_out[j-1];
                    end
                end
            end
        end
    end

    logic [COL_SUM_WIDTH-1:0] temp_sum;
    logic [COL_SUM_SQ_WIDTH-1:0] temp_sum_sq;

    always_comb begin
        temp_sum = 0;
        temp_sum_sq = 0;
        for (int k = 0; k < WINDOW_SIZE; k++) begin
            temp_sum = temp_sum + col_data_out_reg[k];
            temp_sum_sq = temp_sum_sq + (col_data_out_reg[k] * col_data_out_reg[k]);
        end
        if ((y_pixel >= WINDOW_SIZE - 1) && (y_pixel < IMAGE_HEIGHT)) begin
            col_sum = temp_sum;
            col_sum_sq = temp_sum_sq;
        end else begin
            col_sum = 0;
            col_sum_sq = 0;
        end
    end
    
    logic [9:0] x_pixel_ram;
    assign x_pixel_ram = x_pixel >= 640 ? 639 : x_pixel;

    genvar i;
    generate
        for(i = 0; i < WINDOW_SIZE-1; i = i + 1)begin
            data_mem1 # (
                .DATA_WIDTH(DATA_WIDTH),
                .WORD_WIDTH(IMAGE_WIDTH)
            ) line_buffer_ram(
                .clk(clk),
                .rst(rst),
                .wen(counter == 2),
                .waddr(x_pixel_ram),
                .wdata((x_pixel >= 639) ? DUMMY : (i==0) ? pixel_in : ram_chain_out[i-1]),
                .ren(1'b1),
                .raddr(x_pixel_ram),
                .rdata(ram_chain_out[i])
            );
        end
    endgenerate

    // --- 3. 가로 합(Window Sum) 계산 ---
    logic [COL_SUM_WIDTH-1:0]    col_sum_pipeline [0:WINDOW_SIZE-1];
    logic [COL_SUM_SQ_WIDTH-1:0] col_sum_sq_pipeline [0:WINDOW_SIZE-1];
    logic [SUM_WIDTH-1:0]        window_sum;
    logic [SUM_SQ_WIDTH-1:0]     window_sum_sq;
    logic [1:0] counter1;

    always_ff @(posedge clk) begin
        if(rst)begin
            counter1 <= 0;
            for(int j = 0; j < WINDOW_SIZE; j++)begin
                col_sum_pipeline[j] <= 0;
            end
        end
        else if (x_pixel != x_pixel_d1) begin // DE_d1도 고려
            counter1 <= 0;
        end
        else begin
            counter1 <= counter1 + 1;
            if(counter1 == 2)begin
                col_sum_pipeline[0] <= col_sum;
                col_sum_sq_pipeline[0] <= col_sum_sq;
                for(int j = 1; j < WINDOW_SIZE; j++) begin
                    col_sum_pipeline[j] <= col_sum_pipeline[j-1];
                    col_sum_sq_pipeline[j] <= col_sum_sq_pipeline[j-1];
                end
            end
        end
    end

    logic window_valid;
    logic [COL_SUM_WIDTH-1:0] oldest_col_sum;
    logic [COL_SUM_SQ_WIDTH-1:0] oldest_col_sum_sq;

    assign window_valid = (y_pixel_d1 >= WINDOW_SIZE - 1) && (x_pixel > WINDOW_SIZE);
    assign oldest_col_sum = col_sum_pipeline[WINDOW_SIZE-1];
    assign oldest_col_sum_sq = col_sum_sq_pipeline[WINDOW_SIZE-1];

    always_ff @( posedge clk or posedge rst ) begin
        if(rst) begin
            window_sum <= 0;
            window_sum_sq <= 0;
        end
        else if((x_pixel != x_pixel_d1))begin
            if(window_valid)begin
                window_sum <= window_sum + col_sum - oldest_col_sum;
                window_sum_sq <= window_sum_sq + col_sum_sq - oldest_col_sum_sq;
            end
            else if((y_pixel < IMAGE_HEIGHT && x_pixel < IMAGE_WIDTH && x_pixel >= 1)) begin //  && (x_pixel != x_pixel_d1)
                window_sum <= window_sum + col_sum;
                window_sum_sq <= window_sum_sq + col_sum_sq;
            end
            else begin
                window_sum <= 0;
                window_sum_sq <= 0;
            end
        end
    end

    logic [2:0] de_pipe;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) de_pipe <= 3'b0;
        else de_pipe <= {de_pipe[1:0], DE};
    end
    
    logic valid_out_pre;
    assign valid_out_pre = (y_pixel >= WINDOW_SIZE - 1) && (x_pixel >= 1) && (x_pixel <= IMAGE_WIDTH);
    
    // logic valid_out_pipe [0:2];
    // always_ff @(posedge clk or posedge rst) begin
    //     if (rst) begin
    //         valid_out_pipe <= '{default:0};
    //     end else if (de_pipe[0]) begin
    //         valid_out_pipe[0] <= valid_out_pre;
    //         valid_out_pipe[1] <= valid_out_pipe[0];
    //         valid_out_pipe[2] <= valid_out_pipe[1];
    //     end
    // end

    assign sum_out = window_sum;
    assign sum_sq_out = window_sum_sq;
    // assign valid_out = valid_out_pipe[2]; // 최종 지연에 맞춘 valid 신호
    assign valid_out = valid_out_pre;

endmodule

module grayscale_converter (
    input  logic [7:0] red_port,
    input  logic [7:0] green_port,
    input  logic [7:0] blue_port,
    output logic [11:0] gray_port
);

    logic [18:0] gray_full;
    assign gray_full = red_port * 54 + green_port * 183 + blue_port * 19;
    
    assign gray_port = gray_full >> 4;

endmodule

module AB_Calculator #(
    parameter WINDOW_SIZE      = 15,
    parameter DATA_WIDTH       = 24,
    parameter SUM_I_WIDTH      = 32,
    parameter SUM_II_WIDTH     = 56, // 32
    parameter SUM_P_WIDTH      = 16,
    parameter SUM_IP_WIDTH     = 40
) (
    input  logic                         clk,
    input  logic                         rst,
    input  logic                         valid_in,
    input  logic [SUM_I_WIDTH-1:0]       sum_i,
    input  logic [SUM_II_WIDTH-1:0]      sum_ii,
    input  logic [SUM_P_WIDTH-1:0]       sum_p,
    input  logic [SUM_IP_WIDTH-1:0]      sum_ip,
    output logic signed [19:0]           a_k_out,
    output logic signed [DATA_WIDTH+5:0] b_k_out, // 비트 확인 필요 !!
    output logic                         valid_out
);

    localparam N = WINDOW_SIZE * WINDOW_SIZE;
    // localparam FIXED_POINT = N * 1 << 14;

    localparam VAR_NUM_WIDTH    = 48;
    localparam COV_NUM_WIDTH    = 64;
    localparam AK_INT_BITS  = 4;
    localparam AK_FRAC_BITS = 16;
    localparam BK_INT_BITS  = DATA_WIDTH + 2;
    localparam BK_FRAC_BITS = 4;
    localparam AK_WIDTH     = AK_INT_BITS + AK_FRAC_BITS;
    localparam BK_WIDTH     = BK_INT_BITS + BK_FRAC_BITS;
    localparam DIVIDER_LATENCY = 116;
    localparam signed [VAR_NUM_WIDTH-1:0] EPSILON = 1;
    
    // MUL 결과 저장 register
    logic [40-1:0] mul_sumii_n_reg;
    logic [40-1:0] mul_sumi_sumi_reg;
    logic [40-1:0] mul_sumip_n_reg;
    logic [40-1:0] mul_sumi_sump_reg;

    // SUB 결과 저장 register
    logic signed [VAR_NUM_WIDTH-1:0] var_num_reg;
    logic signed [COV_NUM_WIDTH-1:0] cov_num_reg;

    logic valid_d1, valid_d2;

    always_ff @( posedge clk or posedge rst ) begin
        if(rst)begin
            mul_sumii_n_reg    <= '0;
            mul_sumi_sumi_reg <= '0;
            mul_sumip_n_reg    <= '0;
            mul_sumi_sump_reg <= '0;
            var_num_reg         <= '0;
            cov_num_reg         <= '0;
        end
        else if(valid_in)begin
            mul_sumii_n_reg   <= sum_ii * N;
            mul_sumi_sumi_reg <= sum_i * sum_i;
            mul_sumip_n_reg   <= sum_ip * N;
            mul_sumi_sump_reg <= sum_i * sum_p;

            var_num_reg <= mul_sumii_n_reg - mul_sumi_sumi_reg;
            cov_num_reg <= mul_sumip_n_reg - mul_sumi_sump_reg;
        end
    end

    always_ff @( posedge clk or posedge rst ) begin
        if(rst)begin
            valid_d1 <= 0;
            valid_d2 <= 0;
        end
        else begin
            valid_d1 <= valid_in;
            valid_d2 <= valid_d1;
        end
    end

    // 1. a_k 계산

    logic signed [63:0] dividend_to_ip;
    logic signed [47:0] divisor_to_ip;
    
    assign dividend_to_ip = $signed(cov_num_reg) <<< AK_FRAC_BITS;
    assign divisor_to_ip  = var_num_reg + EPSILON;

    logic [63:0] quotient_from_ip;
    logic [63:0] remainder_from_ip;
    logic         quotient_valid;

    shift_divider #(
        .DATA_WIDTH(64),
        .FRAC_BITS (8)
    ) divider_ip (
        .clk(clk),
        .rst(rst),

        // 분자(Dividend) 입력
        .divided_in_tdata (dividend_to_ip),
        .divided_in_tvalid(valid_d2),
        .divided_in_tready(),

        // 분모(Divisor) 입력
        .divisor_in_tdata ({16'b0, divisor_to_ip}),
        .divisor_in_tvalid(valid_d2),

        // 결과(Quotient) 출력
        .quotient_out_tdata (quotient_from_ip), // 몫
        .remainder_out_tdata(remainder_from_ip), // 나머지
        .divided_out_tvalid (quotient_valid)
    );

    // 2. b_k 계산

    logic [SUM_I_WIDTH-1:0] sum_i_delayed [0:2];
    logic [SUM_P_WIDTH-1:0] sum_p_delayed [0:2];

    logic signed [SUM_I_WIDTH-1:0] sum_i_d2;
    logic signed [SUM_I_WIDTH-1:0] sum_p_d2;
    always_ff @( posedge clk ) begin
        sum_i_d2 <= sum_i;
        sum_p_d2 <= sum_p;
    end

    always_ff @( posedge clk or posedge rst ) begin
        if(rst)begin
            
        end
        else if(valid_d2)begin
            sum_i_delayed[0] <= sum_i_d2;
            sum_p_delayed[0] <= sum_p_d2;
            for(int i = 1; i < 3; i = i + 1)begin
                sum_i_delayed[i] <= sum_i_delayed[i-1];
                sum_p_delayed[i] <= sum_p_delayed[i-1];
            end
        end
    end

    logic signed [SUM_P_WIDTH-1:0] sum_p_temp;
    logic signed [SUM_I_WIDTH-1:0] sum_i_temp;

    assign sum_p_temp = sum_p_delayed[2];
    assign sum_i_temp = sum_i_delayed[2];

    logic signed [SUM_P_WIDTH + AK_FRAC_BITS:0] b_k_num;
    assign b_k_num = (sum_p_temp << AK_FRAC_BITS) - ($signed(quotient_from_ip) * sum_i_temp);
    always_ff @( posedge clk or posedge rst) begin
        if(rst)begin
            b_k_out <= 0;
        end
        else if(quotient_valid)begin // a_k 계산 완료
            
            b_k_out <= b_k_num >>> ($clog2(N) + AK_FRAC_BITS);
        end
    end

    assign a_k_out = quotient_from_ip[63:44]; // 4bit 정수부 + 16bit 실수부
    assign valid_out = quotient_valid;

endmodule

module Final_Output_Calculator #(
    parameter WINDOW_SIZE = 15,
    parameter N = WINDOW_SIZE * WINDOW_SIZE,
    parameter GRAY_WIDTH = 12,
    parameter AK_WIDTH = 20,
    parameter BK_WIDTH = 14,
    parameter INPUT_LATENCY = 5,
    parameter SUM_A_WIDTH = AK_WIDTH + $clog2(N),
    parameter SUM_B_WIDTH = BK_WIDTH + $clog2(N) // 14 + 8 = 22
) (
    input  logic                          clk,
    input  logic                          rst,
    input  logic                          DE,
    input  logic [GRAY_WIDTH-1:0]         guide_pixel_gray,
    input  logic signed [SUM_A_WIDTH-1:0] sum_a,
    input  logic signed [SUM_B_WIDTH-1:0] sum_b,
    input  logic                          valid_a,
    output logic [7:0]                    q_i,
    output logic                          valid_out
);

    localparam AK_FRAC_BITS = 16;
    localparam BK_FRAC_BITS = 4;
    localparam MEAN_FRAC_BITS = 18;
    localparam INV_N = (2**MEAN_FRAC_BITS) / N;
    localparam TOTAL_LATENCY = INPUT_LATENCY + 2 + 3; // mean 계산지연(2) + 최종계산지연(3)

    logic [GRAY_WIDTH-1:0] I_pipeline [TOTAL_LATENCY-1:0];
    logic [GRAY_WIDTH-1:0] I_delayed;

    always_ff @(posedge clk) begin
        if (DE) begin // 원본 픽셀이 들어올 때
            I_pipeline[0] <= guide_pixel_gray;
            for (int i = 1; i < TOTAL_LATENCY; i++) begin
                I_pipeline[i] <= I_pipeline[i-1];
            end
        end
    end
    assign I_delayed = I_pipeline[TOTAL_LATENCY-1];
    
    // mean_a, mean_b 계산 2클럭 소요

    logic signed [AK_WIDTH-1:0] mean_a;
    logic signed [BK_WIDTH-1:0] mean_b;

    logic signed [SUM_A_WIDTH + MEAN_FRAC_BITS - 1:0] mul_a_result;
    logic signed [SUM_B_WIDTH + MEAN_FRAC_BITS - 1:0] mul_b_result;

    logic valid_sum_ab_d1, valid_sum_ab_d2;
    always_ff @( posedge clk or posedge rst ) begin
        if(rst)begin
            mul_a_result <= 0;
            mul_b_result <= 0;
            mean_a       <= 0;
            mean_b       <= 0;
            valid_sum_ab_d1  <= 0;
            valid_sum_ab_d2  <= 0;
        end
        else if(valid_a) begin
            mul_a_result <= sum_a * INV_N;
            mul_b_result <= sum_b * INV_N;

            mean_a <= mul_a_result >>> MEAN_FRAC_BITS;
            mean_b <= mul_b_result >>> MEAN_FRAC_BITS;

            valid_sum_ab_d1 <= valid_a;
            valid_sum_ab_d2 <= valid_sum_ab_d1;
        end
        else begin
            valid_sum_ab_d1 <= 0;
            valid_sum_ab_d2 <= 0;
        end
    end

    // 최종 q_i 계산 3클럭 소요

    logic signed [AK_WIDTH-1:0] mean_a_d1, mean_a_d2, mean_a_d3;
    logic signed [BK_WIDTH-1:0] mean_b_d1, mean_b_d2, mean_b_d3;
    logic                       valid_mean_d1, valid_mean_d2, valid_mean_d3;

    always_ff @( posedge clk ) begin
        mean_a_d1     <= mean_a;
        mean_a_d2     <= mean_a_d1;
        mean_a_d3     <= mean_a_d2;
        mean_b_d1     <= mean_b;
        mean_b_d2     <= mean_b_d1;
        mean_b_d3     <= mean_b_d2;
        valid_mean_d1 <= valid_a;
        valid_mean_d2 <= valid_mean_d1;
        valid_mean_d3 <= valid_mean_d2;
    end

    logic signed [AK_WIDTH + GRAY_WIDTH - 1:0]   mul_q_result;
    logic signed [BK_WIDTH + AK_FRAC_BITS - 1:0] mean_b_scaled;
    logic signed [BK_WIDTH + AK_FRAC_BITS - 1:0] add_q_result;
    logic signed [GRAY_WIDTH-1:0]                q_i_final;

    assign mul_q_result  = mean_a_d1 * I_delayed;
    assign mean_b_scaled = mean_b_d1 << (AK_FRAC_BITS - BK_FRAC_BITS);
    assign add_q_result  = (mul_q_result >>> AK_FRAC_BITS) + mean_b_scaled;
    assign q_i_final     = add_q_result >>> (AK_FRAC_BITS - BK_FRAC_BITS);

    // assign q_i = (mean_a * I_delayed) + mean_b;
    assign q_i = q_i_final;
    assign valid_out = valid_mean_d3;

endmodule
