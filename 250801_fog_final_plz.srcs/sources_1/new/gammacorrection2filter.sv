module gammacorrection2filter #(
    parameter H_ACTIVE = 1280,
    parameter V_ACTIVE = 720
) (
    // global
    input  logic        aclk,
    input  logic        reset,
    // axis
    input  logic        s_axis_video_tuser,   // Frame start (SOF)
    input  logic        s_axis_video_tvalid,  // Data valid
    input  logic        s_axis_video_tlast,   // End of line
    input  logic [23:0] s_axis_video_tdata,   // RGB data (8:8:8)
    output logic        s_axis_video_tready,  // Ready signal
    // filter
    output logic        user,                 // Frame start output
    output logic        valid,                // Data valid output
    output logic        last,                 // End of line output
    output logic [10:0] x_pixel,              // X coordinate (0 to 1279)
    output logic [ 9:0] y_pixel,              // Y coordinate (0 to 719)
    output logic [ 4:0] red,                  // Red (5 bits)
    output logic [ 5:0] green,                // Green (6 bits)
    output logic [ 4:0] blue,                 // Blue (5 bits)
    output logic [1:0] debug_state,
    output logic [1:0] debug_state_next,
    input  logic        ready                 // Downstream ready
);
    // Direct signal assignments
    logic  [ 4:0] red_reg, red_next;
    logic  [ 5:0] green_reg, green_next; 
    logic  [ 4:0] blue_reg, blue_next; 
    logic  user_reg, user_next; 
    logic  valid_reg, valid_next; 
    logic  last_reg, last_next;


 
    // State machine enum
    localparam IDLE = 0, LINE = 1, DELAY = 2;
    logic [1:0] state, state_next;

    // Pixel coordinate registers
    logic [10:0] x_pixel_reg, x_pixel_next;
    logic [9:0] y_pixel_reg, y_pixel_next;

    // Sequential logic
    
always_ff @(posedge aclk or posedge reset) begin
    if (reset) begin
        state <= IDLE;
        x_pixel_reg <= 0;
        y_pixel_reg <= 0;
        red_reg <= '0;
        green_reg <= '0;
        blue_reg <= '0;
        user_reg <= 0;
        valid_reg <= 0;
        last_reg <= 0;
    end else begin
        state <= state_next;
        x_pixel_reg <= x_pixel_next;
        y_pixel_reg <= y_pixel_next;
        red_reg <= red_next;
        green_reg <= green_next;
        blue_reg <= blue_next;
        user_reg <= user_next;   
        valid_reg <= valid_next; 
        last_reg <= last_next;   
    end
end

    assign x_pixel = x_pixel_reg;
    assign y_pixel = y_pixel_reg;
    assign red = red_reg;  // Extract 5-bit red
    assign green = green_reg;  // Extract 6-bit green
    assign blue = blue_reg;  // Extract 5-bit blue
    assign user = user_reg;  // Pass through SOF
    assign valid = valid_reg;  // Pass through valid
    assign last = last_reg;  // Pass through EOL

    assign debug_state = state;
    assign debug_state_next = state_next;
    
    // Combinational logic for state machine
    always_comb begin
    state_next   = state;
    x_pixel_next = x_pixel_reg;
    y_pixel_next = y_pixel_reg;

    red_next   = red_reg;
    green_next = green_reg;
    blue_next  = blue_reg;

    // 반드시 모든 출력신호 초기화
    user_next  = 0;
    valid_next = 0;
    last_next  = 0;

    s_axis_video_tready = ready; // 기본 ready 유지

    case (state)
        IDLE: begin
            x_pixel_next = 0;
            y_pixel_next = 0;
            red_next = '0;
            green_next = '0;
            blue_next = '0;
            if (s_axis_video_tvalid && ready && s_axis_video_tuser) begin
                state_next   = LINE;
                x_pixel_next = 1;
                user_next    = 1;      // 명확한 첫 프레임 시작 설정
                valid_next   = 1;
                red_next     = s_axis_video_tdata[23:19];
                green_next   = s_axis_video_tdata[15:10];
                blue_next    = s_axis_video_tdata[7:3];
            end
        end

        LINE: begin
            if (s_axis_video_tvalid && ready) begin
                valid_next = 1;
                red_next   = s_axis_video_tdata[23:19];
                green_next = s_axis_video_tdata[15:10];
                blue_next  = s_axis_video_tdata[7:3];

                if (s_axis_video_tlast) begin
                    last_next = 1;  // 라인의 마지막 픽셀 처리
                    x_pixel_next = 0;
                    if (y_pixel_reg == V_ACTIVE - 1) begin
                        state_next = DELAY;
                        y_pixel_next = 0;
                    end else begin
                        y_pixel_next = y_pixel_reg + 1;
                    end
                end else begin
                    x_pixel_next = x_pixel_reg + 1;
                end
            end
        end

        DELAY: begin
            s_axis_video_tready = ready;
            if (s_axis_video_tvalid && ready && s_axis_video_tuser) begin
                state_next   = LINE;
                x_pixel_next = 1;
                user_next    = 1;     // 새 프레임 시작
                valid_next   = 1;
                red_next     = s_axis_video_tdata[23:19];
                green_next   = s_axis_video_tdata[15:10];
                blue_next    = s_axis_video_tdata[7:3];
            end
        end

        default: state_next = IDLE;
    endcase
end
endmodule
