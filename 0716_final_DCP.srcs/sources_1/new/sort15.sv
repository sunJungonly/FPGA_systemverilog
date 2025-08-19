`timescale 1ns / 1ps
module sort15#(
    parameter DATA_WIDTH = 16
)(
    input logic           clk,
    input logic           rst,

    input logic [DATA_WIDTH:0]      data1, 
    input logic [DATA_WIDTH:0]      data2, 
    input logic [DATA_WIDTH:0]      data3,
    input logic [DATA_WIDTH:0]      data4,
    input logic [DATA_WIDTH:0]      data5,
    input logic [DATA_WIDTH:0]      data6,
    input logic [DATA_WIDTH:0]      data7,
    input logic [DATA_WIDTH:0]      data8,
    input logic [DATA_WIDTH:0]      data9,
    input logic [DATA_WIDTH:0]      data10,
    input logic [DATA_WIDTH:0]      data11,
    input logic [DATA_WIDTH:0]      data12,
    input logic [DATA_WIDTH:0]      data13,
    input logic [DATA_WIDTH:0]      data14,
    input logic [DATA_WIDTH:0]      data15,
    
    output logic [DATA_WIDTH:0] min_data
);

//-----------------------------------
//세 수를 크기순으로 정렬
always_ff@(posedge clk or posedge rst)begin
    if(rst)begin
        min_data <= 0;
    end
    else begin
        //최솟값 취득
        min_data <= data1;
        if (data2 < min_data) min_data <= data2;
        if (data3 < min_data) min_data <= data3;
        if (data4 < min_data) min_data <= data4;
        if (data5 < min_data) min_data <= data5;
        if (data6 < min_data) min_data <= data6;
        if (data7 < min_data) min_data <= data7;
        if (data8 < min_data) min_data <= data8;
        if (data9 < min_data) min_data <= data9;
        if (data10 < min_data) min_data <= data10;
        if (data11 < min_data) min_data <= data11;
        if (data12 < min_data) min_data <= data12;
        if (data13 < min_data) min_data <= data13;
        if (data14 < min_data) min_data <= data14;
        if (data15 < min_data) min_data <= data15;
     end
end

endmodule 