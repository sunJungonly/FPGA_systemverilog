`timescale 1ns / 1ps
module Line_Buffer_for_DCP #(
    parameter IMAGE_WIDTH = 320,
    parameter DATA_WIDTH  = 12,
    parameter NUM_ROWS    = 15
) (
    input  logic                           clk,
    input  logic                           rst,

    input  logic [DATA_WIDTH-1:0]          pixel_in, // rdata from frambuffer
    input  logic                           DE,
    input  logic [$clog2(IMAGE_WIDTH)-1:0] x_pixel,

    output logic [DATA_WIDTH-1:0]          row_data_out [NUM_ROWS-1:0],
    output logic DE_out,
    output logic [$clog2(IMAGE_WIDTH)-1:0] x_pixel_out
);

    logic [DATA_WIDTH-1:0] ram_chain_out [NUM_ROWS-2:0]; // 14개 라인버퍼
    logic [DATA_WIDTH-1:0] row_data_out_reg [NUM_ROWS-1:0];

    assign row_data_out = row_data_out_reg;

    genvar i;
    generate
        for(i = 0; i < NUM_ROWS - 1; i = i + 1)begin
            data_mem #(
                .DATA_WIDTH(DATA_WIDTH),
                .WORD_WIDTH(IMAGE_WIDTH)
            ) line_buffer_ram_dcp (
                .clk(clk),
                .rst(rst),
                .wen(DE),
                .waddr(x_pixel),
                .wdata((i==0) ? pixel_in : ram_chain_out[i-1]),
                .ren(1'b1),
                .raddr(x_pixel),
                .rdata(ram_chain_out[i])
            );
        end
    endgenerate

    always_ff @( posedge clk or posedge rst ) begin
        if(rst)begin
            for(int j = 0; j < NUM_ROWS; j = j + 1)begin
                row_data_out_reg[j] <= 0;
            end
        end
        else if(DE) begin
            row_data_out_reg[0] <= pixel_in; // 가장 윗 줄은 현재 입력 픽셀
            for(int j = 1; j < NUM_ROWS; j = j + 1)begin
                row_data_out_reg[j] <= ram_chain_out[j-1];
            end
        end
    end

    logic DE_d1;
    logic [$clog2(IMAGE_WIDTH)-1:0] x_pixel_d1;

    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            DE_d1 <= 1'b0;
            x_pixel_d1 <= '0;
        end else begin
            DE_d1 <= DE;
            x_pixel_d1 <= x_pixel;
        end
    end
    
    // 최종적으로 지연된 제어 신호를 출력에 할당
    assign DE_out      = DE_d1;
    assign x_pixel_out = x_pixel_d1;

endmodule


module data_mem #(
    parameter DATA_WIDTH=24, 
    parameter WORD_WIDTH=320,
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

   logic [DATA_WIDTH-1:0] ram[WORD_WIDTH-1:0];

    reg [DATA_WIDTH-1:0] rdata_reg;

   always_ff @(posedge clk) begin
        // 쓰기 동작
        if (wen) begin
            ram[waddr] <= wdata;
        end
        
        rdata_reg <= ram[raddr];
    end
    
    assign rdata = rdata_reg;

endmodule