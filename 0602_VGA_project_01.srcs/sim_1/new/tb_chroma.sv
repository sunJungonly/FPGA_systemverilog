`timescale 1ns / 1ps

module tb_chroma();
    logic [15:0] rgbData;
    logic [9:0] x_pixel;
    logic [9:0] y_pixel;
    logic DE;
    logic [11:0] RGB;

chromakey dut (.*);

initial begin
    // 초기 상태
    DE = 0;
    rgbData = 16'h0000;
    #10;

    // 배경색 (초록 계열) → 크로마키 동작 확인
    DE = 1;
    rgbData = 16'b0000_1111_0010_0000;  // G=15, B=2, R=0
    #20;

    // 전경색 (빨강 계열) → 그대로 출력
    rgbData = 16'b1111_0000_0000_0000;  // R=15
    #20;

    // DE = 0 → 출력 꺼짐
    DE = 0;
    rgbData = 16'hFFFF;
    #20;

    $finish;
end

endmodule
