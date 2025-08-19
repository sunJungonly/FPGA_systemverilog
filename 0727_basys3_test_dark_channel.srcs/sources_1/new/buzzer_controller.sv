module buzzer_controller (
    input  logic clk,
    input  logic reset,
    input  logic play_pass,  // PASS 효과음 재생 트리거 (1 클럭)
    input  logic play_fail,  // FAIL 효과음 재생 트리거 (1 클럭)
    output logic buzzer_out  // 부저 신호
);

    typedef enum logic [1:0] {
        IDLE,
        PLAY_PASS,
        PLAY_FAIL
    } state_t;

    state_t state;

    logic [19:0] freq;
    logic enable;
    logic [31:0] timer;
    logic [3:0] note_idx;

    // PASS 멜로디
    localparam [19:0] PASS_NOTES[0:5] = '{523, 659, 784, 1047, 784, 1047};
    localparam integer PASS_DURATIONS[0:5] = '{
        10_000_000,
        10_000_000,
        10_000_000,
        20_000_000,
        10_000_000,
        30_000_000
    };

    // FAIL 멜로디
    localparam [19:0] FAIL_NOTES[0:4] = '{440, 370, 440, 370, 440};
    localparam integer FAIL_DURATIONS[0:4] = '{
        30_000_000,
        10_000_000,
        30_000_000,
        10_000_000,
        40_000_000
    };

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
        end else begin
            // 기존 상태 전이 로직
            if (play_pass) state <= PLAY_PASS;
            else if (play_fail) state <= PLAY_FAIL;
            else if (state != IDLE && timer == 0) begin
                if ((state == PLAY_PASS && note_idx == 5) ||
                (state == PLAY_FAIL && note_idx == 4))
                    state <= IDLE;
            end
        end
    end

    always_ff @(posedge clk) begin
        case (state)
            IDLE: begin
                timer    <= 0;
                note_idx <= 0;
                enable   <= 0;
                freq     <= 0;
            end

            PLAY_PASS: begin
                enable <= 1;
                freq   <= PASS_NOTES[note_idx];
                if (timer == 0) begin
                    timer <= PASS_DURATIONS[note_idx];
                    note_idx <= note_idx + 1;
                end else begin
                    timer <= timer - 1;
                end
            end

            PLAY_FAIL: begin
                enable <= 1;
                freq   <= FAIL_NOTES[note_idx];
                if (timer == 0) begin
                    timer <= FAIL_DURATIONS[note_idx];
                    note_idx <= note_idx + 1;
                end else begin
                    timer <= timer - 1;
                end
            end
        endcase
    end

    // 부저 출력 모듈 (70% duty)
    buzzer_variable_freq buz (
        .clk(clk),
        .enable(enable),
        .freq(freq),
        .buzzer_out(buzzer_out)
    );

endmodule
