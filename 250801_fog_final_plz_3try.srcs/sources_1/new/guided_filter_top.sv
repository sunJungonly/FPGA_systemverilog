`timescale 1ns / 1ps

module guided_filter_top (
    input  logic        clk,
    input  logic        rst,
    input  logic [9:0]  x_pixel,
    input  logic [9:0]  y_pixel,
    input  logic        DE,
    input  logic [23:0] guide_pixel_in, // ?   ? ?  미 ?
    input  logic [7:0]  input_pixel_in, // ?  ?   ?
    output logic        DE_out,
    output logic [7:0]  q_i
);

    localparam DATA_WIDTH  = 24;
    localparam WINDOW_SIZE = 15;

    logic [11:0] guide_pixel_gray;

    logic [19:0] i_mul_p, i_mul_p_reg;

    logic [19:0] sum_i;
    logic [15:0] sum_p;
    logic [31:0] sum_ii;
    logic [27:0] sum_ip;

    logic signed [37:0] sum_a;
    logic signed [47:0] sum_b;

    logic signed [19:0] a_k_out;
    logic signed [29:0] b_k_out;

    logic [28:0] window_sum_i;
    logic [32:0] window_sum_ii;
    logic [24:0] window_sum_p;
    logic [36:0] window_sum_ip;

    localparam DELAY = 110; // ?  ?   78
    logic DE_pipe[0:DELAY-1];
    logic [11:0] guide_pixel_gray_pipe[0:DELAY-1];
    logic [ 7:0] input_pixel_in_pipe[0:DELAY-1];

    always_ff @( posedge clk or posedge rst ) begin
        if(rst)begin
            i_mul_p_reg <= 0;
        end
        else begin
            i_mul_p_reg <= guide_pixel_gray_pipe[0] * input_pixel_in_pipe[0];
            i_mul_p     <= i_mul_p_reg;
        end
    end


    always_ff @( posedge clk or posedge rst ) begin
        if(rst)begin
            for(int i =0; i<DELAY; i++)begin
                guide_pixel_gray_pipe[i] <= 0;
                input_pixel_in_pipe[i] <= 0;
            end
        end
        else begin
            guide_pixel_gray_pipe[0] <= guide_pixel_gray;
            input_pixel_in_pipe[0] <= input_pixel_in;
            for(int i=1;i<DELAY;i++)begin
                guide_pixel_gray_pipe[i] <= guide_pixel_gray_pipe[i-1];
                input_pixel_in_pipe[i] <= input_pixel_in_pipe[i-1];
            end
        end
    end

    always_ff @( posedge clk or posedge rst ) begin
        if(rst)begin
            for(int i=0;i<DELAY;i++)begin
                DE_pipe[i] <= 0;
            end
        end
        else begin
            DE_pipe[0] <= DE;
            for(int i=1;i<DELAY;i++)begin
                DE_pipe[i] <= DE_pipe[i-1];
            end
        end
    end

    assign DE_out = DE_pipe[DELAY-1];

    localparam DELAY2 = 88;

    logic [9:0] x_pixel_pipe[0:DELAY2-1];
    logic [9:0] y_pixel_pipe[0:DELAY2-1];

    always_ff @( posedge clk or posedge rst ) begin
        if(rst)begin
            for(int i=0; i<DELAY2;i++)begin
                x_pixel_pipe[i] <= 0;
                y_pixel_pipe[i] <= 0;
            end
        end
        else begin
            x_pixel_pipe[0] <= x_pixel;
            y_pixel_pipe[0] <= y_pixel;
            for(int i=1; i<DELAY2; i++)begin
                x_pixel_pipe[i] <= x_pixel_pipe[i-1];
                y_pixel_pipe[i] <= y_pixel_pipe[i-1];
            end
        end
    end

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
        .SUM_WIDTH(20),
        .SUM_SQ_WIDTH(32)
    ) sum_i_inst(
        .clk(clk),
        .rst(rst),
        .pixel_in(guide_pixel_gray_pipe[2]),
        .DE(DE_pipe[2]),
        .x_pixel(x_pixel_pipe[2]),
        .y_pixel(y_pixel_pipe[2]),
        .mean_out(),
        .mean_sq_out(),
        .valid_out(valid_i),
        .window_sum(window_sum_i),
        .window_sum_sq(window_sum_ii)
    );

    window_sum_calculator #(
        .IMAGE_WIDTH(640),
        .IMAGE_HEIGHT(480),
        .WINDOW_SIZE(15),
        .DATA_WIDTH(8),
        .SUM_WIDTH(16),
        .SUM_SQ_WIDTH()
    ) sum_p_inst(
        .clk(clk),
        .rst(rst),
        .pixel_in(input_pixel_in_pipe[2]),
        .DE(DE_pipe[2]),
        .x_pixel(x_pixel_pipe[2]),
        .y_pixel(y_pixel_pipe[2]),
        .mean_out(),
        .mean_sq_out(), // dummy
        .valid_out(valid_p),
        .window_sum(window_sum_p),
        .window_sum_sq()
    );

    window_sum_calculator #(
        .IMAGE_WIDTH(640),
        .IMAGE_HEIGHT(480),
        .WINDOW_SIZE(15),
        .DATA_WIDTH(20),
        .SUM_WIDTH(28),
        .SUM_SQ_WIDTH()
    ) sum_ip_inst(
        .clk(clk),
        .rst(rst),
        .pixel_in(i_mul_p),
        .DE(DE_pipe[2]),
        .x_pixel(x_pixel_pipe[2]),
        .y_pixel(y_pixel_pipe[2]),
        .mean_out(),
        .mean_sq_out(), // dummy
        .valid_out(valid_ip),
        .window_sum(window_sum_ip),
        .window_sum_sq()
    );

    AB_Calculator #(
        .WINDOW_SIZE(15),
        .DATA_WIDTH(24),
        .SUM_I_WIDTH(28),
        .SUM_II_WIDTH(32),
        .SUM_P_WIDTH(24),
        .SUM_IP_WIDTH(36)
    ) ab_cal_inst(
        .clk(clk),
        .rst(rst),
        .x_pixel(x_pixel_pipe[20]),
        .valid_in(DE_pipe[20]),
        .sum_i(window_sum_i),
        .sum_ii(window_sum_ii),
        .sum_p(window_sum_p),
        .sum_ip(window_sum_ip),
        .a_k_out(a_k_out),
        .b_k_out(b_k_out),
        .valid_out(ab_valid_out)
    );

    window_sum #(
        .IMAGE_WIDTH(640),
        .IMAGE_HEIGHT(480),
        .WINDOW_SIZE(15),
        .DATA_WIDTH(20),
        .SUM_WIDTH(38),
        .SUM_SQ_WIDTH()
    ) sum_a_inst(
        .clk(clk),
        .rst(rst),
        .pixel_in(a_k_out),
        .DE(DE_pipe[87]),
        .x_pixel(x_pixel_pipe[87]), // 75
        .y_pixel(y_pixel_pipe[87]), // 75
        .mean_out(sum_a),
        .mean_sq_out(), // dummy
        .valid_out()
    );

    window_sum #(
        .IMAGE_WIDTH(640),
        .IMAGE_HEIGHT(480),
        .WINDOW_SIZE(15),
        .DATA_WIDTH(30),
        .SUM_WIDTH(48),
        .SUM_SQ_WIDTH()
    ) sum_b_inst(
        .clk(clk),
        .rst(rst),
        .pixel_in(b_k_out),
        .DE(DE_pipe[87]),
        .x_pixel(x_pixel_pipe[87]),
        .y_pixel(y_pixel_pipe[87]),
        .mean_out(sum_b),
        .mean_sq_out(), // dummy
        .valid_out()
    );

    Final_Output_Calculator #(
        .WINDOW_SIZE(15),
        .GRAY_WIDTH(12),
        .AK_WIDTH(38),
        .BK_WIDTH(48)
    ) final_inst(
        .clk(clk),
        .rst(rst),
        .DE(DE_pipe[109]),
        .guide_pixel_gray(guide_pixel_gray_pipe[106]), // guided gray는 2clk delay더 있는거라서
        .mean_a(sum_a),
        .mean_b(sum_b),
        .valid_a(DE_pipe[107]),
        .q_i(q_i),
        .valid_out()
    );

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
        // ?   ? ?  ?  
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
    parameter DATA_WIDTH   = 24,
    parameter SUM_WIDTH = DATA_WIDTH + $clog2(WINDOW_SIZE * WINDOW_SIZE),
    parameter SUM_SQ_WIDTH = DATA_WIDTH*2 + $clog2(WINDOW_SIZE * WINDOW_SIZE)
) (
    input  logic                    clk,
    input  logic                    rst,
    input  logic [DATA_WIDTH-1:0]   pixel_in, // 12bit rgb data
    input  logic                    DE,
    input  logic [9:0]              x_pixel,
    input  logic [9:0]              y_pixel,
    output logic [SUM_WIDTH-1:0]    mean_out, // window ?   결과
    output logic [SUM_SQ_WIDTH-1:0] mean_sq_out, // window ?  곱의 ?   결과
    output logic                    valid_out,
    output logic [SUM_WIDTH+8:0]    window_sum,
    output logic [SUM_SQ_WIDTH:0]   window_sum_sq
);

    localparam N = WINDOW_SIZE * WINDOW_SIZE;
    localparam COL_SUM_WIDTH = DATA_WIDTH + $clog2(WINDOW_SIZE) + 2; // 24 + 4
    localparam COL_SUM_SQ_WIDTH = DATA_WIDTH*2 + $clog2(WINDOW_SIZE);

    logic [9:0] x_pixel_d1, x_pixel_d2, x_pixel_d3;
    logic [9:0] y_pixel_d1, y_pixel_d2;

    localparam DE_DELAY = 20;
    logic DE_pipe[0:DE_DELAY-1];

    always_ff @( posedge clk or posedge rst ) begin
        if(rst)begin
            for(int i=0;i<DE_DELAY;i++)begin
                DE_pipe[i] <= 0;
            end
        end
        else begin
            DE_pipe[0] <= DE;
            for(int i=1;i<DE_DELAY;i++)begin
                DE_pipe[i] <= DE_pipe[i-1];
            end
        end
    end

    always_ff @( posedge clk or posedge rst ) begin
        if(rst)begin
            x_pixel_d1 <= 0; y_pixel_d1 <= 0;
            x_pixel_d2 <= 0; y_pixel_d2 <= 0;
        end
        else begin
            x_pixel_d1 <= x_pixel;
            y_pixel_d1 <= y_pixel;

            x_pixel_d2 <= x_pixel_d1;
            y_pixel_d2 <= y_pixel_d1;

            x_pixel_d3 <= x_pixel_d2;
        end
    end

    // --- 3. ?   ? ?   계산 ---
    logic [COL_SUM_WIDTH+6:0]    col_sum;
    logic [COL_SUM_SQ_WIDTH:0] col_sum_sq;
    logic [DATA_WIDTH-1:0]       col_data_out_reg[0:WINDOW_SIZE-1];
    logic [DATA_WIDTH-1:0]       ram_chain_out [0:WINDOW_SIZE-2]; 
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
        else begin
            counter <= counter + 1;
            if(counter == 2)begin
                for(int j = 0; j < 15; j++)begin
                    if (y_pixel < 14) begin
                        if (j <= y_pixel) begin
                            col_data_out_reg[j] <= (j == 0) ? pixel_in : ram_chain_out[j-1];
                        end else begin
                            col_data_out_reg[j] <= 100; // dummy
                        end
                    end else begin
                        col_data_out_reg[j] <= (j == 0) ? pixel_in : ram_chain_out[j-1];
                    end
                end
            end
        end
    end

    logic [COL_SUM_WIDTH+6:0] temp_sum, temp_sum_reg; // COL_SUM_WIDTH-1
    logic [COL_SUM_SQ_WIDTH:0] temp_sum_sq;
    logic [COL_SUM_SQ_WIDTH:0] sum_square [0:WINDOW_SIZE-1];

    logic [DATA_WIDTH-1:0] oldest_pixel;
    assign oldest_pixel = ram_chain_out[WINDOW_SIZE-2];

    always_ff @( posedge clk or posedge rst ) begin
        if (rst)begin
            col_sum <= 0;
            col_sum_sq <= 0;
            temp_sum <= 0;
            temp_sum_reg <= 0;
            temp_sum_sq <= 0;
            for (int i = 0; i < WINDOW_SIZE; i++) begin
                sum_square[i] <= 0;
            end
        end
        else begin
            if(counter == 2) begin
                // if(y_pixel >= 14)begin
                //     if(DE_pipe[3])begin // de_d1? 
                // if(x_pixel > 0 && y_pixel >= 1 && DE_pipe[3])begin
                //         temp_sum <= temp_sum + col_data_out_reg[0] - oldest_pixel;
                //         temp_sum_sq <= temp_sum_sq + sum_square[0] - (oldest_pixel * oldest_pixel);
                // end
                //         // col_sum <= temp_sum;
                //         // col_sum_sq <= temp_sum_sq;
                //     end
                // end
                // else if(DE_pipe[3])begin
                    // temp_sum_sq <= temp_sum_sq + sum_square[0];

                    temp_sum <= col_data_out_reg[0] + col_data_out_reg[1] + col_data_out_reg[2] + col_data_out_reg[3] + col_data_out_reg[4] + col_data_out_reg[5] + col_data_out_reg[6] + col_data_out_reg[7] + col_data_out_reg[8] + col_data_out_reg[9] + col_data_out_reg[10] + col_data_out_reg[11] + col_data_out_reg[12] + col_data_out_reg[13] + col_data_out_reg[14];
                    temp_sum_sq <= sum_square[0] + sum_square[1] + sum_square[2] + sum_square[3] + sum_square[4] + sum_square[5] + sum_square[6] + sum_square[7] + sum_square[8] + sum_square[9] + sum_square[10] + sum_square[11] + sum_square[12] + sum_square[13] + sum_square[14];

                // end
                // if(x_pixel == 0)begin
                //     temp_sum <= col_data_out_reg[0];
                // end
                temp_sum_reg <= temp_sum;
                col_sum <= temp_sum_reg;
                col_sum_sq <= temp_sum_sq;
                
                for(int i=0;i<WINDOW_SIZE;i++)begin
                    sum_square[i] <= col_data_out_reg[i] * col_data_out_reg[i];
                end
            end
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
                .wen(counter == 2 && DE),
                .waddr(x_pixel_ram),
                .wdata((y_pixel<14 && i>y_pixel) ? 100 : (i==0) ? pixel_in : ram_chain_out[i-1]),
                .ren(DE),
                .raddr(x_pixel_ram),
                .rdata(ram_chain_out[i])
            );
        end
    endgenerate

    // --- 3.  ? ? ?  (Window Sum) 계산 ---
    logic [COL_SUM_WIDTH+6:0]    col_sum_pipeline [0:WINDOW_SIZE-1];
    logic [COL_SUM_SQ_WIDTH:0] col_sum_sq_pipeline [0:WINDOW_SIZE-1];
    // logic [SUM_WIDTH+8:0]        window_sum;
    // logic [SUM_SQ_WIDTH:0]     window_sum_sq;
    logic [1:0] counter1;

    always_ff @(posedge clk or posedge rst) begin
        if(rst)begin
            counter1 <= 0;
            for(int j = 0; j < WINDOW_SIZE; j++)begin
                col_sum_pipeline[j] <= 0;
                col_sum_sq_pipeline[j] <= 0;
            end
        end
        else if (x_pixel != x_pixel_d1) begin
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
    
    localparam COL_DELAY = 4;
    logic [COL_SUM_WIDTH+6:0] col_sum_d[0:COL_DELAY-1];
    logic [COL_SUM_SQ_WIDTH:0] col_sum_sq_d[0:COL_DELAY-1];

    always_ff @( posedge clk or posedge rst ) begin
        if(rst)begin
            for(int i=0; i<COL_DELAY;i++)begin
                col_sum_d[i] <= 0;
                col_sum_sq_d[i] <= 0;
            end
        end
        else begin
            col_sum_d[0] <= col_sum;
            col_sum_sq_d[0] <= col_sum_sq;
            for(int i=1; i<COL_DELAY;i++)begin
                col_sum_d[i] <= col_sum_d[i-1];
                col_sum_sq_d[i] <= col_sum_sq_d[i-1];
            end
        end
    end

    logic [COL_SUM_WIDTH+6:0] oldest_col_sum;
    logic [COL_SUM_SQ_WIDTH:0] oldest_col_sum_sq;
    assign oldest_col_sum = col_sum_pipeline[WINDOW_SIZE-1];
    assign oldest_col_sum_sq = col_sum_sq_pipeline[WINDOW_SIZE-1];

    logic window_valid;

    assign window_valid = (y_pixel_d1 >= WINDOW_SIZE - 1) && (x_pixel > WINDOW_SIZE);

    always_ff @( posedge clk or posedge rst ) begin
        if(rst) begin
            window_sum <= 0;
            window_sum_sq <= 0;
        end
        else if((x_pixel != x_pixel_d1) && (x_pixel > 4 && x_pixel < 658)) begin
            if(x_pixel < 19) begin
                window_sum <= window_sum + col_sum_d[COL_DELAY-1];
                window_sum_sq <= window_sum_sq + col_sum_sq_d[COL_DELAY-1];
            end
            else if(x_pixel > 643) begin
                window_sum <= window_sum - oldest_col_sum;
                window_sum_sq <= window_sum_sq - oldest_col_sum_sq;
            end
            else begin
                window_sum <= window_sum + col_sum_d[COL_DELAY-1] - oldest_col_sum;
                window_sum_sq <= window_sum_sq + col_sum_sq_d[COL_DELAY-1] - oldest_col_sum_sq;
            end
        end
        // else if(x_pixel == 0) begin
        //         // window_sum <= col_sum_d[COL_DELAY-1];
        //         // window_sum_sq <= col_sum_sq_d[COL_DELAY-1];
        //         window_sum <= 0;
        //         window_sum_sq <= 0;
        // end
    end

        // else if((x_pixel != x_pixel_d1))begin
        //     window_sum <= window_sum + col_sum_d[COL_DELAY-1] - oldest_col_sum;
        //     window_sum_sq <= window_sum_sq + col_sum_sq_d[COL_DELAY-1] - oldest_col_sum_sq;
        // end
    
        // else if((x_pixel != x_pixel_d1))begin
        //     if(x_pixel < 19) begin
        //        window_sum <= window_sum + col_sum_d[COL_DELAY-1];
        //        window_sum_sq <= window_sum_sq + col_sum_sq_d[COL_DELAY-1];
        //     end
        //     else begin
        //         window_sum <= window_sum + col_sum_d[COL_DELAY-1] - oldest_col_sum;
        //         window_sum_sq <= window_sum_sq + col_sum_sq_d[COL_DELAY-1] - oldest_col_sum_sq;
        //         if(x_pixel > 645) begin
        //             window_sum <= window_sum - oldest_col_sum;
        //             window_sum_sq <= window_sum_sq - oldest_col_sum_sq;
        //         end
        //     end
        //     oldest_col_sum <= col_sum_pipeline[WINDOW_SIZE-1];
        //     oldest_col_sum_sq <= col_sum_sq_pipeline[WINDOW_SIZE-1];
        //     if(x_pixel == 0) begin
        //         // window_sum <= col_sum_d[COL_DELAY-1];
        //         window_sum <= 0;
        //         // window_sum_sq <= col_sum_sq_d[COL_DELAY-1];
        //         window_sum_sq <= 0;
        //     end
        // end

    logic de_pipe[0:9];
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for(int i=0;i<10;i++)begin
                de_pipe[i] <= 0;
            end
        end
        else begin
            de_pipe[0] <= DE;
            for(int i=1;i<10;i++)begin
                de_pipe[i] <= de_pipe[i-1];
            end
        end
    end

    // localparam MEAN_FRAC_BITS = 18;
    // localparam INV_N = (1 << MEAN_FRAC_BITS) / N;
localparam MEAN_FRAC_BITS = 18;
localparam signed [MEAN_FRAC_BITS:0] INV_N = (1<<MEAN_FRAC_BITS)/N; // 1165

    logic signed [SUM_WIDTH + MEAN_FRAC_BITS - 1:0] mul_result;
    logic signed [SUM_SQ_WIDTH + MEAN_FRAC_BITS - 1:0] mul_sq_result;

    // always_ff @( posedge clk or posedge rst ) begin
    //     if(rst)begin
    //         mul_result <= 0;
    //         mul_sq_result <= 0;
    //         mean_out       <= 0;
    //         mean_sq_out       <= 0;
    //     end
    //     else begin
    //         mul_result <= window_sum * INV_N;
    //         mul_sq_result <= window_sum_sq * INV_N;

    //         mean_out <= mul_result >>> MEAN_FRAC_BITS;
    //         mean_sq_out <= mul_sq_result >>> MEAN_FRAC_BITS;
    //     end
    // end



    always_ff @(posedge clk) begin
        if (!rst) begin
            // ½LSB 라운딩
            mul_result    <= (window_sum    * INV_N) + (1<<(MEAN_FRAC_BITS-1));
            mul_sq_result <= (window_sum_sq * INV_N) + (1<<(MEAN_FRAC_BITS-1));

            mean_out    <= mul_result    >>> MEAN_FRAC_BITS; // >> 도 OK
            mean_sq_out <= mul_sq_result >>> MEAN_FRAC_BITS;
        end
    end

    assign valid_out = de_pipe[9];

endmodule

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
    output logic signed [DATA_WIDTH+6:0] b_k_out, // 29:0
    output logic                         valid_out
);

    localparam N = WINDOW_SIZE * WINDOW_SIZE;

    localparam AK_INT_BITS  = 4;
    localparam AK_FRAC_BITS = 16;
    localparam AK_WIDTH     = AK_INT_BITS + AK_FRAC_BITS;
    localparam DIVIDER_LATENCY = 59;
    localparam AK_CAL_LATENCY = 5 + DIVIDER_LATENCY; // sum ?  ?   ??   a_k 계산 ?  료까 ??    ?  ??  ?   ? (mul/sub + divider)

    // localparam signed [47:0] EPSILON = 1; // ?  본의 VAR_NUM_WIDTH?? 맞춤
    
    // localparam signed [47:0] EPSILON = 1; 
    // localparam signed [47:0] EPSILON = 5062500; // 50625 * 100
    // localparam signed [47:0] EPSILON = 10125000; // 50625 * 100
    localparam signed [47:0] EPSILON = 50625; // 50625 * 100
    // localparam signed [47:0] EPSILON = 50625; // 50625 * 100

    // MUL/SUB 결과 ???   register
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
    logic [40:0] quotient_from_ip_int;
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

    // [?  ?   1] ?  ?  ?   a_k 고정?  ?  ?   값을 ?  ?   wire ?  ?  
    logic [56:0] a_k_fixed_reg;
    // assign a_k_fixed = {quotient_from_ip_int[AK_INT_BITS-1:0], quotient_from_ip_frac};
    assign a_k_fixed_reg = (quotient_from_ip_int << AK_FRAC_BITS) | quotient_from_ip_frac;

    logic signed [56:0] a_k_fixed;
    assign a_k_fixed = signed_divide ? -a_k_fixed_reg : a_k_fixed_reg;

    logic signed [19:0] a_k_pipe[0:2];

    always_ff @( posedge clk, posedge rst) begin
        if (rst) begin
            for(int i=0; i<3; i++)begin
                a_k_pipe[i] <= 0;
            end
        end
        else begin
            if(quotient_valid)begin
                a_k_pipe[0] <= a_k_fixed_reg[19:0];
            end
            for(int i=1; i<3; i++)begin
                a_k_pipe[i] <= a_k_pipe[i-1];
            end
        end
    end

    assign a_k_out = a_k_pipe[2];

    // --- 2. b_k 계산 ---

    // [?  ?   2] a_k 계산  ??  ?  간에 맞춰 sum_i?? sum_p ?  ??  ?  ?  ?   ?  ?  ?  ?  ?  
    logic [SUM_I_WIDTH-1:0] sum_i_pipeline [0:AK_CAL_LATENCY-1];
    logic signed [SUM_P_WIDTH-1:0] sum_p_pipeline [0:AK_CAL_LATENCY-1];

    always_ff @( posedge clk or posedge rst ) begin
        if(rst)begin
             for(int i = 0; i < AK_CAL_LATENCY; i = i + 1)begin
                sum_i_pipeline[i] <= '0;
                sum_p_pipeline[i] <= '0;
            end
        end
        else if(valid_in) begin
            sum_i_pipeline[0] <= sum_i;
            sum_p_pipeline[0] <= sum_p;
            for(int i = 1; i < AK_CAL_LATENCY; i = i + 1)begin
                sum_i_pipeline[i] <= sum_i_pipeline[i-1];
                sum_p_pipeline[i] <= sum_p_pipeline[i-1];
            end
        end
    end

    logic [SUM_I_WIDTH-1:0] sum_i_synced;
    logic signed [SUM_P_WIDTH:0] sum_p_synced;
    assign sum_i_synced = sum_i_pipeline[AK_CAL_LATENCY-1];
    assign sum_p_synced = sum_p_pipeline[AK_CAL_LATENCY-1];

    // b_k_num = (sum_p * 2^16) - (a_k_fixed * sum_i)
    // logic signed [SUM_P_WIDTH + AK_FRAC_BITS :0] b_k_num;
    logic signed [32:0] b_k_num;
    // logic signed [AK_WIDTH + SUM_I_WIDTH - 1:0]  mul_result;
    logic signed [32:0]  mul_result;
    logic valid_delay;

    // logic [31+N : 0] rounded_product; // 캐리 발생 가능성으로 1비트 추가
    // localparam ROUND_CONST = 1 << 15; // 2^15

    // assign rounded_product = (a_k_fixed * sum_i_synced) + ROUND_CONST;
    // assign mul_result = rounded_product >>> 16; // 원래 16
    
    // assign mul_result = a_k_fixed[31:16] * sum_i_synced;

    assign mul_result = a_k_fixed * sum_i_synced;

    logic signed [AK_FRAC_BITS + SUM_P_WIDTH -1 : 0] sum_p_shifted;
    assign sum_p_shifted = $signed(sum_p_synced) << AK_FRAC_BITS;

    always_ff @( posedge clk or posedge rst) begin
        if(rst)begin
            b_k_num <= 0;
            valid_delay <= 0;
        end
        else begin 
            valid_delay <= quotient_valid;
            if(quotient_valid)begin
                b_k_num <= sum_p_shifted - mul_result;
            end
        end
    end

    // // assign b_k_out = b_k_num;
    // // assign b_k_out = b_k_num >>> 18;
    // assign b_k_out = b_k_num >>> 8;
    // assign valid_out = valid_delay;

    // N으로 나누기: 고정소수점 역수 곱 추천(라운딩 포함)
    localparam FRAC = 18;
    localparam signed [FRAC:0] INV_N = (1<<FRAC)/N;   // N=225이면 1165

    logic signed [32+FRAC:0] b_mul;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) b_k_out <= '0;
        else begin
            // b_k_num (Q16 * N) / N  => Q16
            b_mul  <= b_k_num * INV_N + (1<<(FRAC-1)); // round
            b_k_out <= b_mul >>> FRAC;                 // <<< 유지: Q16로 내보내기
        end
    end

endmodule

module Final_Output_Calculator #(
    parameter WINDOW_SIZE   = 15,
    parameter GRAY_WIDTH    = 12,
    parameter AK_WIDTH      = 20,
    parameter BK_WIDTH      = 30
) (
    input  logic                          clk,
    input  logic                          rst,
    input  logic                          DE,
    input  logic [GRAY_WIDTH-1:0]         guide_pixel_gray,
    input  logic signed [AK_WIDTH-1:0]    mean_a,
    input  logic signed [BK_WIDTH-1:0]    mean_b,
    input  logic                          valid_a,
    output logic [7:0]                    q_i,
    output logic                          valid_out
);

    localparam N = WINDOW_SIZE * WINDOW_SIZE;
    localparam AK_FRAC_BITS = 16;
    localparam MUL_Q_WIDTH  = AK_WIDTH + GRAY_WIDTH; // 곱셈 결과?   ?   ?
    localparam MEAN_B_WIDTH = BK_WIDTH;              // ?  ?  ?   ?   ? ?  ?   ?   ?
    
    // ?  ?   ?  ?   ?  ?  ?  ?  ?  ?  
    logic valid_pipeline [2:0];
    always_ff @(posedge clk) begin
        valid_pipeline[0] <= valid_a;
        valid_pipeline[1] <= valid_pipeline[0];
        valid_pipeline[2] <= valid_pipeline[1];
    end

    // ?  ?   mean  ? ?  ?  ?  ?  ?  ?  
    logic signed [AK_WIDTH-1:0] mean_a_d1;
    logic signed [BK_WIDTH-1:0] mean_b_d1;
    always_ff @(posedge clk) begin
        mean_a_d1 <= mean_a;
        mean_b_d1 <= mean_b;
    end

    // --- [?  ?   1] 고정?  ?  ?   ?  ?   로직 ?  ?   ---
    logic signed [AK_WIDTH + GRAY_WIDTH:0]               mul_q_result;
    logic signed [AK_WIDTH + GRAY_WIDTH:0]               mul_q_result_reg;
    logic signed [BK_WIDTH-15:0]                          q_i_final;
    logic signed [BK_WIDTH + 1:0] q_i_final_1;
 
    assign mul_q_result = mean_a * guide_pixel_gray;

    // assign mul_q_result_reg = (mean_a * guide_pixel_gray) >>> AK_FRAC_BITS;

    // assign q_i_final_1 = (mul_q_result >>> AK_FRAC_BITS);
    assign q_i_final_1 = mul_q_result + mean_b;

    localparam ROUND_CONST = 1 << (AK_FRAC_BITS - 1);
    assign q_i_final = (q_i_final_1 + ROUND_CONST) >>> AK_FRAC_BITS;

    assign q_i = (q_i_final < 0) ? 8'd0 : (q_i_final > 255) ? 8'd255 : q_i_final[7:0];
    assign valid_out = valid_pipeline[2];

endmodule

module window_sum #(
    parameter IMAGE_WIDTH  = 640,
    parameter IMAGE_HEIGHT = 480,
    parameter WINDOW_SIZE  = 15,
    parameter DATA_WIDTH   = 24,
    parameter SUM_WIDTH = DATA_WIDTH + $clog2(WINDOW_SIZE * WINDOW_SIZE),
    parameter SUM_SQ_WIDTH = DATA_WIDTH*2 + $clog2(WINDOW_SIZE * WINDOW_SIZE)
) (
    input  logic                    clk,
    input  logic                    rst,
    input  logic signed [DATA_WIDTH-1:0]   pixel_in, // 12bit rgb data
    input  logic                    DE,
    input  logic [9:0]              x_pixel,
    input  logic [9:0]              y_pixel,
    output logic signed [SUM_WIDTH-1:0]    mean_out, // window ?   결과
    output logic signed [SUM_SQ_WIDTH-1:0] mean_sq_out, // window ?  곱의 ?   결과
    output logic                    valid_out // sum_out, sum_sq_out?   ?  ?  ?   ?   1
);

    localparam N = WINDOW_SIZE * WINDOW_SIZE;
    localparam COL_SUM_WIDTH = DATA_WIDTH + $clog2(WINDOW_SIZE) + 2; // 24 + 4
    localparam COL_SUM_SQ_WIDTH = DATA_WIDTH*2 + $clog2(WINDOW_SIZE);

    logic [9:0] x_pixel_d1, x_pixel_d2, x_pixel_d3;
    logic [9:0] y_pixel_d1, y_pixel_d2;

    localparam DE_DELAY = 20;
    logic DE_pipe[0:DE_DELAY-1];

    always_ff @( posedge clk or posedge rst ) begin
        if(rst)begin
            for(int i=0;i<DE_DELAY;i++)begin
                DE_pipe[i] <= 0;
            end
        end
        else begin
            DE_pipe[0] <= DE;
            for(int i=1;i<DE_DELAY;i++)begin
                DE_pipe[i] <= DE_pipe[i-1];
            end
        end
    end

    always_ff @( posedge clk or posedge rst ) begin
        if(rst)begin
            x_pixel_d1 <= 0; y_pixel_d1 <= 0;
            x_pixel_d2 <= 0; y_pixel_d2 <= 0;
        end
        else begin
            x_pixel_d1 <= x_pixel;
            y_pixel_d1 <= y_pixel;

            x_pixel_d2 <= x_pixel_d1;
            y_pixel_d2 <= y_pixel_d1;

            x_pixel_d3 <= x_pixel_d2;
        end
    end

    // --- 3. ?   ? ?   계산 ---
    logic signed [COL_SUM_WIDTH+6:0]    col_sum;
    logic signed [COL_SUM_SQ_WIDTH:0] col_sum_sq;
    logic signed [DATA_WIDTH-1:0]       col_data_out_reg[0:WINDOW_SIZE-1];
    logic signed [DATA_WIDTH-1:0]       ram_chain_out [0:WINDOW_SIZE-2]; 
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
        else begin
            counter <= counter + 1;
            if(counter == 2)begin
                for(int j = 0; j < 15; j++)begin
                    if (y_pixel < 14) begin
                        if (j <= y_pixel) begin
                            col_data_out_reg[j] <= (j == 0) ? pixel_in : ram_chain_out[j-1];
                        end else begin
                            col_data_out_reg[j] <= 120; // dummy
                        end
                    end else begin
                        col_data_out_reg[j] <= (j == 0) ? pixel_in : ram_chain_out[j-1];
                    end
                end
            end
        end
    end

    logic signed [COL_SUM_WIDTH+6:0] temp_sum;
    logic signed [COL_SUM_WIDTH+6:0] temp_sum_reg; // COL_SUM_WIDTH-1
    logic [COL_SUM_SQ_WIDTH:0] temp_sum_sq;
    logic [COL_SUM_SQ_WIDTH:0] sum_square [0:WINDOW_SIZE-1];

    logic signed [DATA_WIDTH-1:0] oldest_pixel;
    assign oldest_pixel = ram_chain_out[WINDOW_SIZE-2];

    always_ff @( posedge clk or posedge rst ) begin
        if (rst)begin
            col_sum <= 0;
            col_sum_sq <= 0;
            temp_sum <= 0;
            temp_sum_reg <= 0;
            temp_sum_sq <= 0;
            for (int i = 0; i < WINDOW_SIZE; i++) begin
                sum_square[i] <= 0;
            end
        end
        else begin
            if(counter == 2) begin
                // if(y_pixel >= 14)begin
                //     if(DE_pipe[3])begin // de_d1? 
                //         temp_sum <= temp_sum + col_data_out_reg[0] - oldest_pixel;
                //         temp_sum_sq <= temp_sum_sq + sum_square[0] - (oldest_pixel * oldest_pixel);

                //         // col_sum <= temp_sum;
                //         // col_sum_sq <= temp_sum_sq;
                //     end
                // end
                // else if(DE_pipe[3])begin
                    temp_sum <= col_data_out_reg[0] + col_data_out_reg[1] + col_data_out_reg[2] + col_data_out_reg[3] + col_data_out_reg[4] + col_data_out_reg[5] + col_data_out_reg[6] + col_data_out_reg[7] + col_data_out_reg[8] + col_data_out_reg[9] + col_data_out_reg[10] + col_data_out_reg[11] + col_data_out_reg[12] + col_data_out_reg[13] + col_data_out_reg[14];
                    // temp_sum_sq <= temp_sum_sq + sum_square[0];
                    temp_sum_sq <= sum_square[0] + sum_square[1] + sum_square[2] + sum_square[3] + sum_square[4] + sum_square[5] + sum_square[6] + sum_square[7] + sum_square[8] + sum_square[9] + sum_square[10] + sum_square[11] + sum_square[12] + sum_square[13] + sum_square[14];
                // end
                // if(x_pixel == 0)begin
                //     temp_sum <= col_data_out_reg[0];
                // end
                temp_sum_reg <= temp_sum;
                col_sum <= temp_sum_reg;
                col_sum_sq <= temp_sum_sq;
                
                for(int i=0;i<WINDOW_SIZE;i++)begin
                    sum_square[i] <= col_data_out_reg[i] * col_data_out_reg[i];
                end
            end
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
                .wen(counter == 2 && DE),
                .waddr(x_pixel_ram),
                .wdata((y_pixel<14 && i>y_pixel) ? 10 : (i==0) ? pixel_in : ram_chain_out[i-1]),
                .ren(DE),
                .raddr(x_pixel_ram),
                .rdata(ram_chain_out[i])
            );
        end
    endgenerate

    // --- 3.  ? ? ?  (Window Sum) 계산 ---
    logic signed [COL_SUM_WIDTH+6:0]    col_sum_pipeline [0:WINDOW_SIZE-1];
    logic signed [COL_SUM_SQ_WIDTH:0] col_sum_sq_pipeline [0:WINDOW_SIZE-1];
    logic signed [SUM_WIDTH+8:0]        window_sum;
    logic signed [SUM_SQ_WIDTH:0]     window_sum_sq;
    logic [1:0] counter1;

    always_ff @(posedge clk or posedge rst) begin
        if(rst)begin
            counter1 <= 0;
            for(int j = 0; j < WINDOW_SIZE; j++)begin
                col_sum_pipeline[j] <= 0;
                col_sum_sq_pipeline[j] <= 0;
            end
        end
        else if (x_pixel != x_pixel_d1) begin
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
    
    localparam COL_DELAY = 4;
    logic signed [COL_SUM_WIDTH+6:0] col_sum_d[0:COL_DELAY-1];
    logic signed [COL_SUM_SQ_WIDTH:0] col_sum_sq_d[0:COL_DELAY-1];

    always_ff @( posedge clk or posedge rst ) begin
        if(rst)begin
            for(int i=0; i<COL_DELAY;i++)begin
                col_sum_d[i] <= 0;
                col_sum_sq_d[i] <= 0;
            end
        end
        else begin
            col_sum_d[0] <= col_sum;
            col_sum_sq_d[0] <= col_sum_sq;
            for(int i=1; i<COL_DELAY;i++)begin
                col_sum_d[i] <= col_sum_d[i-1];
                col_sum_sq_d[i] <= col_sum_sq_d[i-1];
            end
        end
    end

    logic signed [COL_SUM_WIDTH+6:0] oldest_col_sum;
    logic signed [COL_SUM_SQ_WIDTH:0] oldest_col_sum_sq;
    assign oldest_col_sum = col_sum_pipeline[WINDOW_SIZE-1];
    assign oldest_col_sum_sq = col_sum_sq_pipeline[WINDOW_SIZE-1];

    logic window_valid;

    assign window_valid = (y_pixel_d1 >= WINDOW_SIZE - 1) && (x_pixel > WINDOW_SIZE);

    always_ff @( posedge clk or posedge rst ) begin
        if(rst) begin
            window_sum <= 0;
            window_sum_sq <= 0;
        end
        else if((x_pixel != x_pixel_d1) && (x_pixel > 4 && x_pixel < 658)) begin
            if(x_pixel < 19) begin
                window_sum <= window_sum + col_sum_d[COL_DELAY-1];
                window_sum_sq <= window_sum_sq + col_sum_sq_d[COL_DELAY-1];
            end
            else if(x_pixel > 643) begin
                window_sum <= window_sum - oldest_col_sum;
                window_sum_sq <= window_sum_sq - oldest_col_sum_sq;
            end
            else begin
                window_sum <= window_sum + col_sum_d[COL_DELAY-1] - oldest_col_sum;
                window_sum_sq <= window_sum_sq + col_sum_sq_d[COL_DELAY-1] - oldest_col_sum_sq;
            end
        end
        if(x_pixel == 0) begin
            // window_sum <= col_sum_d[COL_DELAY-1];
            window_sum <= 0;
            // window_sum_sq <= col_sum_sq_d[COL_DELAY-1];
            window_sum_sq <= 0;
        end
    end

        // else if((x_pixel != x_pixel_d1))begin
        //     window_sum <= window_sum + col_sum_d[COL_DELAY-1] - oldest_col_sum;
        //     window_sum_sq <= window_sum_sq + col_sum_sq_d[COL_DELAY-1] - oldest_col_sum_sq;
        // end
    
        // else if((x_pixel != x_pixel_d1))begin
        //     if(x_pixel < 19) begin
        //        window_sum <= window_sum + col_sum_d[COL_DELAY-1];
        //        window_sum_sq <= window_sum_sq + col_sum_sq_d[COL_DELAY-1];
        //     end
        //     else begin
        //         window_sum <= window_sum + col_sum_d[COL_DELAY-1] - oldest_col_sum;
        //         window_sum_sq <= window_sum_sq + col_sum_sq_d[COL_DELAY-1] - oldest_col_sum_sq;
        //         if(x_pixel > 645) begin
        //             window_sum <= window_sum - oldest_col_sum;
        //             window_sum_sq <= window_sum_sq - oldest_col_sum_sq;
        //         end
        //     end
        //     oldest_col_sum <= col_sum_pipeline[WINDOW_SIZE-1];
        //     oldest_col_sum_sq <= col_sum_sq_pipeline[WINDOW_SIZE-1];
        //     if(x_pixel == 0) begin
        //         // window_sum <= col_sum_d[COL_DELAY-1];
        //         window_sum <= 0;
        //         // window_sum_sq <= col_sum_sq_d[COL_DELAY-1];
        //         window_sum_sq <= 0;
        //     end
        // end

    logic de_pipe[0:9];
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for(int i=0;i<10;i++)begin
                de_pipe[i] <= 0;
            end
        end
        else begin
            de_pipe[0] <= DE;
            for(int i=1;i<10;i++)begin
                de_pipe[i] <= de_pipe[i-1];
            end
        end
    end

    // localparam MEAN_FRAC_BITS = 18;
    // localparam INV_N = (1 << MEAN_FRAC_BITS) / N;
localparam MEAN_FRAC_BITS = 18;
localparam signed [MEAN_FRAC_BITS:0] INV_N = (1<<MEAN_FRAC_BITS)/N; // 1165

    logic signed [SUM_WIDTH + MEAN_FRAC_BITS - 1:0] mul_result;
    logic signed [SUM_SQ_WIDTH + MEAN_FRAC_BITS - 1:0] mul_sq_result;

    // always_ff @( posedge clk or posedge rst ) begin
    //     if(rst)begin
    //         mul_result <= 0;
    //         mul_sq_result <= 0;
    //         mean_out       <= 0;
    //         mean_sq_out       <= 0;
    //     end
    //     else begin
    //         mul_result <= window_sum * INV_N;
    //         mul_sq_result <= window_sum_sq * INV_N;

    //         mean_out <= mul_result >>> MEAN_FRAC_BITS;
    //         mean_sq_out <= mul_sq_result >>> MEAN_FRAC_BITS;
    //     end
    // end



always_ff @(posedge clk) begin
    if (!rst) begin
        // ½LSB 라운딩
        mul_result    <= (window_sum    * INV_N) + (1<<(MEAN_FRAC_BITS-1));
        mul_sq_result <= (window_sum_sq * INV_N) + (1<<(MEAN_FRAC_BITS-1));

        mean_out    <= mul_result    >>> MEAN_FRAC_BITS; // >> 도 OK
        mean_sq_out <= mul_sq_result >>> MEAN_FRAC_BITS;
    end
end

    assign valid_out = de_pipe[9];
endmodule
