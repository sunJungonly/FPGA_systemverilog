module buzzer_variable_freq (
    input  logic        clk,        // 100MHz
    input  logic        enable,
    input  logic [19:0] freq,       // Hz
    output logic        buzzer_out
);

    logic [31:0] counter;
    logic [31:0] period;
    logic [31:0] high_time;

    always_comb begin
        if (freq != 0) begin
            period    = 100_000_000 / freq;           // 전체 주기
            high_time = (period * 70) / 100;          // 70% 구간
        end else begin
            period    = 0;
            high_time = 0;
        end
    end

    always_ff @(posedge clk) begin
        if (!enable || freq == 0) begin
            buzzer_out <= 0;
            counter    <= 0;
        end else begin
            if (counter >= period - 1)
                counter <= 0;
            else
                counter <= counter + 1;

            buzzer_out <= (counter < high_time);
        end
    end

endmodule