`timescale 1ns / 1ps

module btn_debounce (
    input  clk,
    input  reset,
    input  i_btn,
    output o_btn
);

    // state
    reg [7:0] q_reg, q_next;  //8개의 shift register
    wire btn_debounce;
    reg edge_detector;

    // 1khz clk
    reg [$clog2(100_000)-1:0] counter;
    reg r_1khz;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter <= 0;
            r_1khz  <= 0;
        end else begin
            if (counter == 100000 - 1) begin
                counter <= 0;
                r_1khz  <= 1'b1;
            end else begin  // 1khz 1tick.
                counter = counter +1; // 다음번 count 값은 현재값에 1을 더하라라
                r_1khz <= 1'b0;
            end
        end
    end

    // state logic , shift register
    always @(posedge r_1khz, posedge reset) begin
        if (reset) begin
            q_reg <= 0;
        end else begin
            q_reg <= q_next;
        end
    end

    always @(*) begin // 버튼이 들어오거나, 1khz 주파수가 들어올때만 동작을 하도록 설정정
        // q_reg 현재의 상위 7비트를 다음 하위 7비트에 넣고,
        // 최상에는 i_btn을 넣어라라
        q_next = {i_btn, q_reg[7:1]};  // 8shift의 동작 설명 
    end

    // 8 input AND gate
    assign btn_debounce = &q_reg;  // 8개의 shift register

    // edge_detector
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            edge_detector <= 1'b0;
        end else begin
            edge_detector <= btn_debounce;
        end
    end

    // 최종 출력
    assign o_btn = btn_debounce & (~edge_detector); // 결과값 edge에서 나타난 결과를 반전시켜서 버튼과 and 처리
endmodule
