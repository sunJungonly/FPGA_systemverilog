`timescale 1ns / 1ps

module Line_Buffer_for_DCP #(
    parameter IMAGE_WIDTH = 640,
    parameter DATA_WIDTH  = 8,
    parameter NUM_ROWS    = 15
) (
    input logic clk,
    input logic rst,
    input logic pclk,

    input logic [         DATA_WIDTH-1:0] pixel_in,  // rdata from frambuffer
    input logic                           DE,
    input logic                           h_sync,
    input logic                           v_sync,
    input logic [$clog2(IMAGE_WIDTH)-1:0] x_pixel,
    input logic [                    9:0] y_pixel,

    output logic [         DATA_WIDTH-1:0] row_data_out[NUM_ROWS-1:0],
    output logic                           DE_out
);

    logic [DATA_WIDTH-1:0] ram_chain_out[0:NUM_ROWS-2];  // 14개 라인버퍼
    logic [DATA_WIDTH-1:0] row_data_out_reg[0:NUM_ROWS-1];

    assign row_data_out = row_data_out_reg;

    logic DE_d1;
    logic [$clog2(IMAGE_WIDTH)-1:0] x_pixel_d1;
    logic counter;

    always_ff @(posedge pclk or posedge rst) begin
        if (rst) begin
            for (int j = 0; j < NUM_ROWS; j = j + 1) begin
                row_data_out_reg[j] <= 0;
            end
        end else begin
                for (int j = 0; j < NUM_ROWS; j = j + 1) begin
                    if (y_pixel < 14) begin
                        if (j < y_pixel) begin
                            row_data_out_reg[j] <= (j == 0) ? pixel_in : ram_chain_out[j-1];
                        end else if (j == y_pixel) begin
                            row_data_out_reg[j] <= pixel_in;
                        end else begin
                            row_data_out_reg[j] <= 8'hFF;  // dummy
                        end
                    end else begin
                        row_data_out_reg[j] <= (j == 0) ? pixel_in : ram_chain_out[j-1];
                    end
                end
        end
    end

    always_ff @(posedge pclk or posedge rst) begin
        if (rst) begin
            DE_d1 <= 1'b0;
            x_pixel_d1 <= '0;
        end else begin
            DE_d1 <= DE;
            x_pixel_d1 <= x_pixel;
        end
    end

    logic [9:0] x_pixel_ram;
    assign x_pixel_ram = x_pixel >= 640 ? 639 : x_pixel;

    genvar i;
    generate
        for (i = 0; i < NUM_ROWS - 1; i = i + 1) begin
            data_mem #(
                .DATA_WIDTH(DATA_WIDTH),
                .WORD_WIDTH(IMAGE_WIDTH)
            ) line_buffer_ram_dcp (
                .clk(clk),
                .pclk(pclk),
                .rst(rst),
                .wen((DE)),  // DE는 고려 필요  && DE
                .waddr(x_pixel_ram),
                .wdata((x_pixel >= 639) ? 8'hFF : (i==0) ? pixel_in : ram_chain_out[i-1]),
                .ren((DE && pclk)),
                .raddr((x_pixel_ram <= 0) ? '0 : x_pixel_ram -1 ),
                .rdata(ram_chain_out[i])
            );
        end
    endgenerate
    // 최종적으로 지연된 제어 신호를 출력에 할당
    // assign DE_out      = DE_d1;
    assign DE_out = DE_d1;  // && (y_pixel >= 14)

endmodule

module data_mem #(
    parameter DATA_WIDTH = 24,
    parameter WORD_WIDTH = 640,
    parameter ADDR_WIDTH = $clog2(WORD_WIDTH)
) (
    input  logic                  wen,
    input  logic                  ren,
    input  logic                  clk,
    input  logic                  pclk,
    input  logic                  rst,
    input  logic [ADDR_WIDTH-1:0] waddr,
    input  logic [ADDR_WIDTH-1:0] raddr,
    input  logic [DATA_WIDTH-1:0] wdata,
    output logic [DATA_WIDTH-1:0] rdata
);

    // integer i;

    logic [DATA_WIDTH-1:0] ram[WORD_WIDTH-1:0];

    always_ff @(posedge pclk) begin
        // 쓰기 동작
        if (wen) begin
            ram[waddr] <= wdata;
        end
    end

    always_ff @(posedge clk) begin
        if (ren) begin
            rdata <= ram[raddr];
        end
    end

endmodule
