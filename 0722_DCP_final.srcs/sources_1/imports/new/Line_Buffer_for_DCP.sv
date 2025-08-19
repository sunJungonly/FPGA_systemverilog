`timescale 1ns / 1ps
module Line_Buffer_for_DCP #(
    parameter IMAGE_WIDTH = 320,
    parameter DATA_WIDTH  = 8,
    parameter NUM_ROWS    = 15
) (
    input logic clk,
    input logic rst,

    input logic [         DATA_WIDTH-1:0] pixel_in,  // rdata from frambuffer
    input logic                           DE,
    input logic [$clog2(IMAGE_WIDTH)-1:0] x_pixel,

    output logic [         DATA_WIDTH-1:0] row_data_out[NUM_ROWS-1:0],
    output logic                           DE_out,
    output logic [$clog2(IMAGE_WIDTH)-1:0] x_pixel_out
);

    // logic [DATA_WIDTH-1:0] ram_chain_out [NUM_ROWS-2:0]; // 14개 라인버퍼
    // logic [DATA_WIDTH-1:0] row_data_out_reg [NUM_ROWS-1:0]; // 0:NUM_ROWS-1 이거 아닌가

    // assign row_data_out = row_data_out_reg;

    // logic DE_d1;
    // logic [$clog2(IMAGE_WIDTH)-1:0] x_pixel_d1;
    // logic [1:0] counter;

    // always_ff @( posedge clk or posedge rst) begin
    //     if(rst)begin
    //         for(int j = 0; j < NUM_ROWS; j = j + 1)begin
    //             row_data_out_reg[j] <= 0;
    //         end
    //         counter <= 0;
    //         DE_out <= 0;
    //     end
    //     else if(x_pixel != x_pixel_d1)begin
    //         counter <= 0;
    //         DE_out <= 0;
    //     end
    //     else begin
    //         counter <= counter + 1;
    //         if(counter == 2)begin
    //             counter <= 0;
    //             DE_out <= 1;
    //             row_data_out_reg[0] <= pixel_in;
    //             for(int j = 1; j < NUM_ROWS; j = j + 1)begin
    //                 row_data_out_reg[j] <= ram_chain_out[j-1];
    //             end
    //         end
    //     end
    // end

    // always_ff @(posedge clk or posedge rst) begin
    //     if(rst) begin
    //         DE_d1 <= 1'b0;
    //         x_pixel_d1 <= '0;
    //     end else begin
    //         DE_d1 <= DE;
    //         x_pixel_d1 <= x_pixel;
    //     end
    // end

    // genvar i;
    // generate
    //     for(i = 0; i < NUM_ROWS - 1; i = i + 1)begin
    //         data_mem #(
    //             .DATA_WIDTH(DATA_WIDTH),
    //             .WORD_WIDTH(IMAGE_WIDTH)
    //         ) line_buffer_ram_dcp (
    //             .clk(clk),
    //             .rst(rst),
    //             .wen(counter == 2),
    //             .waddr(x_pixel),
    //             .wdata((i==0) ? pixel_in : ram_chain_out[i-1]),
    //             .ren(1'b1),
    //             .raddr(x_pixel),
    //             .rdata(ram_chain_out[i])
    //         );
    //     end
    // endgenerate

    // // 최종적으로 지연된 제어 신호를 출력에 할당
    // // assign DE_out      = DE_d1;
    // assign x_pixel_out = x_pixel_d1;
    // RAM 체인의 출력을 담을 와이어 배열
    logic [DATA_WIDTH-1:0] ram_chain_out[NUM_ROWS-2:0];

    // --- 상태 추적을 위한 새로운 로직 ---

    // 1. 라인의 끝을 감지하는 신호
    logic end_of_line;
    assign end_of_line = DE && (x_pixel == IMAGE_WIDTH - 1);

    // 2. 채워진 라인의 수를 세는 카운터
    logic [$clog2(NUM_ROWS)-1:0] lines_filled_count;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            lines_filled_count <= 0;
        end else if (end_of_line) begin
            // 카운터가 NUM_ROWS - 1에 도달하면 더 이상 증가하지 않음
            if (lines_filled_count < NUM_ROWS - 1) begin
                lines_filled_count <= lines_filled_count + 1;
            end
        end
    end

    // 3. 커널이 완전히 준비되었는지 나타내는 신호
    logic kernel_ready;
    assign kernel_ready = (lines_filled_count == NUM_ROWS - 1);

    // --- 데이터 경로 구성 ---

    // 레지스터에 들어가기 전의 커널 데이터 (조합 논리)
    logic [DATA_WIDTH-1:0] kernel_data_unreg[NUM_ROWS-1:0];

    // 첫 번째 행은 현재 입력 픽셀
    assign kernel_data_unreg[0] = pixel_in;
    // 나머지 행은 RAM 체인의 출력
    for (genvar k = 0; k < NUM_ROWS - 1; k = k + 1) begin
        assign kernel_data_unreg[k+1] = ram_chain_out[k];
    end

    // --- 최종 출력 레지스터 (데이터 및 제어 신호 동기화) ---
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            DE_out <= 1'b0;
            x_pixel_out <= '0;
            for (int j = 0; j < NUM_ROWS; j = j + 1) begin
                row_data_out[j] <= '0;
            end
        end else begin
            // 4. DE_out 로직 수정: 입력이 유효하고(DE) 커널이 준비되었을 때(kernel_ready)만 활성화
            DE_out <= DE && kernel_ready;

            // 입력 DE가 활성화될 때만 출력 데이터와 좌표를 업데이트
            if (DE) begin
                x_pixel_out <= x_pixel;
                for (int j = 0; j < NUM_ROWS; j = j + 1) begin
                    row_data_out[j] <= kernel_data_unreg[j];
                end
            end
        end
    end

    // --- RAM 인스턴스 생성 ---
    genvar i;
    generate
        for (i = 0; i < NUM_ROWS - 1; i = i + 1) begin : line_buffer_gen
            data_mem #(
                .DATA_WIDTH(DATA_WIDTH),
                .WORD_WIDTH(IMAGE_WIDTH)
            ) line_buffer_ram_dcp (
                .clk(clk),
                .rst(rst),
                .wen(DE), // 5. wen 수정: 유효한 픽셀이 들어오면 항상 RAM에 쓰기
                .waddr(x_pixel),
                .wdata((i == 0) ? pixel_in : ram_chain_out[i-1]),
                .ren(1'b1),  // 항상 읽기 활성화
                .raddr(x_pixel),
                .rdata(ram_chain_out[i])
            );
        end
    endgenerate
endmodule


module data_mem #(
    parameter DATA_WIDTH = 24,
    parameter WORD_WIDTH = 320,
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

    // integer i;

    logic [DATA_WIDTH-1:0] ram[0:WORD_WIDTH-1];

    reg [DATA_WIDTH-1:0] rdata_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            rdata_reg <= 0; // 리셋 시 출력 레지스터를 0으로 초기화
        end else begin
            // 쓰기 동작
            if (wen) begin
                ram[waddr] <= wdata;
            end

            rdata_reg <= ram[raddr];
        end
    end

    assign rdata = rdata_reg;

endmodule
