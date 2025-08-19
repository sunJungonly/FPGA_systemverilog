`timescale 1ns / 1ps

module game_state_fsm (
    input logic clk,
    input logic pclk,
    input logic reset,
    input logic btnU,
    input logic btnD,
    input logic DE,
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,
    input logic h_sync,
    input logic v_sync,
    input logic chroma,  // 초록이면 1 아니면 0으로 변경함
    input logic sobel,
    input logic in_polygon,
    input logic valid,
    input logic tick_1s,
    input logic [3:0] median_red,
    input logic [3:0] median_grn,
    input logic [3:0] median_blu,
    output logic enable,
    output logic [2:0] pattern_num,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port,
    output logic frame_stop,
    output logic [1:0] sound_option,
    output logic signed [12:0] score,
    input logic txt_done,
    input logic [1:0] txt_out,
    output logic [3:0] txt_mode,
    output logic [9:0] txt_x_pixel,
    output logic [9:0] txt_y_pixel,
    output logic [2:0] scale,  //1~6
    output logic score_stage
);

    // pattern_num 01234
    // enable tick 줘야됨
    // 그럼 valid 받아서 점수 판별

    /*
    txt mode
    IDLE(HOLE IN WALL)
    5초(5초) - STAGE마다
    SCORE - 점수 계산하고
    SCORE_FINAL - 마지막 점수/400
    
    S_IDLE   = 4'd0,
    S_SPACE  = 4'd1,
    S_START  = 4'd5,
    S_PASS   = 4'd6,
    S_FAIL   = 4'd7,
    S_SCORE  = 4'd8,
    S_SCORE_FINAL  = 4'd9
    */
    localparam btn_x1 = 300, btn_x2 = 340, btn_y1 = 260, btn_y2 = 300; // y좌표 차이 40 / 1frame당 1칸 / 1.33초
    localparam time_bar_x1 = 20, time_bar_x2 = 80, time_bar_y1 = 15, time_bar_y2 = 465; // y좌표 차이 450

    logic btn_in, btn_edge;
    logic [9:0] btn_bottom_reg, btn_bottom_next;
    assign btn_in = (x_pixel > btn_x1 && x_pixel < btn_x2 && y_pixel > btn_y1 && y_pixel < btn_y2);
    assign btn_edge = ((x_pixel == btn_x1 || x_pixel == btn_x2) && y_pixel >= btn_y1 && y_pixel <= btn_y2) || ((y_pixel == btn_y1 || y_pixel == btn_y2) && x_pixel >= btn_x1 && x_pixel <= btn_x2);

    logic time_bar_in, time_bar_edge;
    logic [9:0] time_bar_upper_reg, time_bar_upper_next;
    assign time_bar_in = (x_pixel > time_bar_x1 && x_pixel < time_bar_x2 && y_pixel > time_bar_y1 && y_pixel < time_bar_y2);
    assign time_bar_edge = ((x_pixel == time_bar_x1-1 || x_pixel == time_bar_x2+1 || x_pixel == time_bar_x1 || x_pixel == time_bar_x2) && y_pixel >= time_bar_y1 && y_pixel <= time_bar_y2) ||
                            ((y_pixel == time_bar_y1-1 || y_pixel == time_bar_y2+1 || y_pixel == time_bar_y1 || y_pixel == time_bar_y2) && x_pixel >= time_bar_x1 && x_pixel <= time_bar_x2);

    logic [2:0] sec_cnt_reg, sec_cnt_next;
    logic [2:0] score_cnt_reg, score_cnt_next;
    logic [$clog2(640*320)-1:0]
        advantage_reg,
        advantage_next,
        penalty_reg,
        penalty_next; // advantage는 득점용 카운터이지만, 크기가 크므로 무언가를 셀 때 범용적으로 사용하고 있음.
    logic v_sync_falling, v_sync_rising, v_sync_reg;
    logic [3:0] red_reg, red_next, grn_reg, grn_next, blu_reg, blu_next;
    logic enable_reg, enable_next;
    logic [3:0] txt_mode_reg, txt_mode_next;
    logic frame_stop_reg, frame_stop_next;
    logic signed [12:0] score_reg, score_next;
    logic signed [15:0] total_score_reg, total_score_next;
    logic [2:0] pattern_num_next, pattern_num_reg;
    logic [1:0] sound_option_reg, sound_option_next;
    logic [$clog2(500_000_000)-1:0] clk_cnt_reg, clk_cnt_next;
    logic [9:0] txt_x_pixel_reg, txt_x_pixel_next;
    logic [9:0] txt_y_pixel_reg, txt_y_pixel_next;
    logic [2:0] scale_reg, scale_next;
    logic score_stage_reg, score_stage_next;

    logic chroma_area_top_set_reg, chroma_area_top_set_next;
    logic chroma_area_bottom_set_reg, chroma_area_bottom_set_next;
    logic chroma_area_left_set_reg, chroma_area_left_set_next;
    logic chroma_area_right_set_reg, chroma_area_right_set_next;
    logic [$clog2(640)-1:0]
        chroma_area_top_cnt_reg,
        chroma_area_top_cnt_next,
        chroma_area_bottom_cnt_reg,
        chroma_area_bottom_cnt_next;
    logic [$clog2(480)-1:0]
        chroma_area_left_cnt_reg,
        chroma_area_left_cnt_next,
        chroma_area_right_cnt_reg,
        chroma_area_right_cnt_next;
    logic [9:0]
        chroma_area_top_reg,
        chroma_area_top_next,
        chroma_area_bottom_reg,
        chroma_area_bottom_next;
    logic [9:0]
        chroma_area_left_reg,
        chroma_area_left_next,
        chroma_area_right_reg,
        chroma_area_right_next;
    logic [1:0]
        chroma_area_top_cnt_continue_reg,
        chroma_area_top_cnt_continue_next,
        chroma_area_bottom_cnt_continue_reg,
        chroma_area_bottom_cnt_continue_next,
        chroma_area_left_cnt_continue_reg,
        chroma_area_left_cnt_continue_next,
        chroma_area_right_cnt_continue_reg,
        chroma_area_right_cnt_continue_next;

    logic chroma_in, chroma_edge;
    assign chroma_in = (x_pixel > chroma_area_left_reg && x_pixel < chroma_area_right_reg && y_pixel > chroma_area_top_reg && y_pixel < chroma_area_bottom_reg);
    assign chroma_edge = ((x_pixel == chroma_area_left_reg || x_pixel == chroma_area_right_reg || x_pixel == chroma_area_left_reg || x_pixel == chroma_area_right_reg) && y_pixel >= chroma_area_top_reg && y_pixel <= chroma_area_bottom_reg) ||
                            ((y_pixel == chroma_area_top_reg || y_pixel == chroma_area_bottom_reg || y_pixel == chroma_area_top_reg || y_pixel == chroma_area_bottom_reg) && x_pixel >= chroma_area_left_reg && x_pixel <= chroma_area_right_reg);

    assign enable = enable_reg;
    assign txt_mode = txt_mode_reg;
    assign v_sync_rising = (v_sync_reg != v_sync) && (v_sync_reg == 0);
    assign v_sync_falling = (v_sync_reg != v_sync) && (v_sync_reg == 1);
    assign {red_port, green_port, blue_port} = !DE? 12'h000 : {red_reg, grn_reg, blu_reg};
    assign frame_stop = frame_stop_reg;
    assign score = score_reg;
    assign pattern_num = pattern_num_reg;
    assign sound_option = sound_option_reg;
    assign txt_x_pixel = txt_x_pixel_reg;
    assign txt_y_pixel = txt_y_pixel_reg;
    assign scale = scale_reg;
    assign score_stage = score_stage_reg;

    typedef enum logic [3:0] {
        IDLE,               // 초기 화면
        WAIT_PERSON,        // 사람 기다림
        LOAD_PATTERN,       // PATTERN 불러오기
        WAIT_PATTERN,       // VALID 대기
        SHOW_PATTERN,       // PATTERN 5초
        CAL_PHASE_0,        // SCORE 계산해주기
        CAL_PHASE_1,        // SCORE 계산해주기
        SHOW_SCORE_0,       // 득점 보여주기
        SHOW_SCORE_1,       // 실점 보여주기
        SHOW_SCORE_2,       // 점수 보여주기(움직임)
        SHOW_PASS_FAIL,     // PASS,FAIL 보여주기
        FINAL_SCORE,        // 총점수 보여주기
        SET_CHROMA_AREA_0,  // Chromakey 천 영역 감지
        SET_CHROMA_AREA_1   // Chromakey 천 영역 감지
    } state_game;
    state_game state, state_next;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            v_sync_reg                          <= 0;
            state                               <= IDLE;
            enable_reg                          <= 0;
            score_cnt_reg                       <= 3'd0;
            pattern_num_reg                     <= 0;
            red_reg                             <= 0;
            grn_reg                             <= 0;
            blu_reg                             <= 0;
            score_reg                           <= 0;
            txt_mode_reg                        <= 1;  // blank
            frame_stop_reg                      <= 0;
            advantage_reg                       <= 0;
            penalty_reg                         <= 0;
            sec_cnt_reg                         <= 0;
            btn_bottom_reg                      <= 300 << 1;  // 2frame당 1칸
            time_bar_upper_reg                  <= 15;  // 1frame당 4칸
            sound_option_reg                    <= 0;
            clk_cnt_reg                         <= 0;
            chroma_area_top_set_reg             <= 0;
            chroma_area_bottom_set_reg          <= 0;
            chroma_area_left_set_reg            <= 0;
            chroma_area_right_set_reg           <= 0;
            chroma_area_top_cnt_reg             <= 0;
            chroma_area_bottom_cnt_reg          <= 0;
            chroma_area_left_cnt_reg            <= 0;
            chroma_area_right_cnt_reg           <= 0;
            chroma_area_top_reg                 <= 0;
            chroma_area_bottom_reg              <= 480;
            chroma_area_left_reg                <= 0;
            chroma_area_right_reg               <= 640;
            chroma_area_top_cnt_continue_reg    <= 0;
            chroma_area_bottom_cnt_continue_reg <= 0;
            chroma_area_left_cnt_continue_reg   <= 0;
            chroma_area_right_cnt_continue_reg  <= 0;
            txt_x_pixel_reg                     <= 320;
            txt_y_pixel_reg                     <= 240;
            scale_reg                           <= 6;
            score_stage_reg                     <= 0;
            total_score_reg                     <= 0;
        end else begin
            v_sync_reg <= v_sync;
            state <= state_next;
            enable_reg <= enable_next;
            score_cnt_reg <= score_cnt_next;
            pattern_num_reg <= pattern_num_next;
            red_reg <= red_next;
            grn_reg <= grn_next;
            blu_reg <= blu_next;
            score_reg <= score_next;
            txt_mode_reg <= txt_mode_next;
            frame_stop_reg <= frame_stop_next;
            advantage_reg <= advantage_next;
            penalty_reg <= penalty_next;
            sec_cnt_reg <= sec_cnt_next;
            btn_bottom_reg <= btn_bottom_next;
            time_bar_upper_reg <= time_bar_upper_next;
            sound_option_reg <= sound_option_next;
            clk_cnt_reg <= clk_cnt_next;
            chroma_area_top_set_reg <= chroma_area_top_set_next;
            chroma_area_bottom_set_reg <= chroma_area_bottom_set_next;
            chroma_area_left_set_reg <= chroma_area_left_set_next;
            chroma_area_right_set_reg <= chroma_area_right_set_next;
            chroma_area_top_cnt_reg <= chroma_area_top_cnt_next;
            chroma_area_bottom_cnt_reg <= chroma_area_bottom_cnt_next;
            chroma_area_left_cnt_reg <= chroma_area_left_cnt_next;
            chroma_area_right_cnt_reg <= chroma_area_right_cnt_next;
            chroma_area_top_reg <= chroma_area_top_next;
            chroma_area_bottom_reg <= chroma_area_bottom_next;
            chroma_area_left_reg <= chroma_area_left_next;
            chroma_area_right_reg <= chroma_area_right_next;
            chroma_area_top_cnt_continue_reg    <=chroma_area_top_cnt_continue_next;
            chroma_area_bottom_cnt_continue_reg <=chroma_area_bottom_cnt_continue_next;
            chroma_area_left_cnt_continue_reg   <=chroma_area_left_cnt_continue_next;
            chroma_area_right_cnt_continue_reg  <=chroma_area_right_cnt_continue_next;
            txt_x_pixel_reg <= txt_x_pixel_next;
            txt_y_pixel_reg <= txt_y_pixel_next;
            scale_reg <= scale_next;
            score_stage_reg <= score_stage_next;
            total_score_reg <= total_score_next;
        end
    end

    always_comb begin
        state_next = state;
        enable_next = 0;
        score_cnt_next = score_cnt_reg;
        pattern_num_next = pattern_num_reg;
        red_next = red_reg;
        grn_next = grn_reg;
        blu_next = blu_reg;
        score_next = score_reg;
        txt_mode_next = txt_mode_reg;
        frame_stop_next = frame_stop_reg;
        advantage_next = advantage_reg;
        penalty_next = penalty_reg;
        sec_cnt_next = sec_cnt_reg;
        btn_bottom_next = btn_bottom_reg;
        time_bar_upper_next = time_bar_upper_reg;
        sound_option_next = 0;
        clk_cnt_next = clk_cnt_reg;
        chroma_area_top_set_next = chroma_area_top_set_reg;
        chroma_area_bottom_set_next = chroma_area_bottom_set_reg;
        chroma_area_left_set_next = chroma_area_left_set_reg;
        chroma_area_right_set_next = chroma_area_right_set_reg;
        chroma_area_top_cnt_next = chroma_area_top_cnt_reg;
        chroma_area_bottom_cnt_next = chroma_area_bottom_cnt_reg;
        chroma_area_left_cnt_next = chroma_area_left_cnt_reg;
        chroma_area_right_cnt_next = chroma_area_right_cnt_reg;
        chroma_area_top_next = chroma_area_top_reg;
        chroma_area_bottom_next = chroma_area_bottom_reg;
        chroma_area_left_next = chroma_area_left_reg;
        chroma_area_right_next = chroma_area_right_reg;
        chroma_area_top_cnt_continue_next = chroma_area_top_cnt_continue_reg;
        chroma_area_bottom_cnt_continue_next = chroma_area_bottom_cnt_continue_reg;
        chroma_area_left_cnt_continue_next = chroma_area_left_cnt_continue_reg;
        chroma_area_right_cnt_continue_next = chroma_area_right_cnt_continue_reg;
        txt_x_pixel_next = txt_x_pixel_reg;
        txt_y_pixel_next = txt_y_pixel_reg;
        scale_next = scale_reg;
        score_stage_next = score_stage_reg;
        total_score_next = total_score_reg;
        case (state)
            IDLE: begin
                txt_mode_next    = 4'd0;
                pattern_num_next = 0;
                score_cnt_next   = 0;
                advantage_next = 0;
                penalty_next = 0;
                total_score_next = 0;
                score_stage_next =0;
                if (txt_out[1]) begin
                    {red_next, grn_next, blu_next} = 12'h000;  // 검정 태두리
                end else if (txt_out[0]) begin
                    {red_next, grn_next, blu_next} = 12'hFFF;  // 하양 문자
                end else begin
                    {red_next, grn_next, blu_next} = {
                        median_red, median_grn, median_blu
                    };
                end
                if (btnU) state_next = WAIT_PERSON;
                if (btnD) begin
                    state_next                           = SET_CHROMA_AREA_0;
                    chroma_area_top_set_next             = 0;
                    chroma_area_bottom_set_next          = 0;
                    chroma_area_left_set_next            = 0;
                    chroma_area_right_set_next           = 0;
                    chroma_area_top_cnt_next             = 0;
                    chroma_area_bottom_cnt_next          = 0;
                    chroma_area_left_cnt_next            = 0;
                    chroma_area_right_cnt_next           = 0;
                    chroma_area_top_next                 = 0;
                    chroma_area_bottom_next              = 480;
                    chroma_area_left_next                = 0;
                    chroma_area_right_next               = 640;
                    chroma_area_top_cnt_continue_next    = 0;
                    chroma_area_bottom_cnt_continue_next = 0;
                    chroma_area_left_cnt_continue_next   = 0;
                    chroma_area_right_cnt_continue_next  = 0;
                end
            end
            WAIT_PERSON: begin
                txt_mode_next    = 4'd0;
                pattern_num_next = 0;
                score_cnt_next   = 0;
                penalty_next = 0;
                total_score_next = 0;
                score_stage_next = 0;
                if (txt_out[1]) begin
                    {red_next, grn_next, blu_next} = 12'h000;  // 검정 태두리
                end else if (txt_out[0]) begin
                    {red_next, grn_next, blu_next} = 12'hFFF;  // 하양 문자
                end else if (btn_in) begin
                    if (y_pixel > btn_bottom_reg[9:1]) begin
                        {red_next, grn_next, blu_next} = 12'hF00;
                    end else begin
                        {red_next, grn_next, blu_next} = {
                            median_red, median_grn, median_blu
                        };  // 배경색 (기본값)
                    end
                end else begin
                    if (btn_edge) begin
                        {red_next, grn_next, blu_next} = 12'h000;
                    end else begin
                        {red_next, grn_next, blu_next} = {
                            median_red, median_grn, median_blu
                        };  // 배경색 (기본값)
                    end
                end
                if (btn_in && pclk) begin
                    if (!chroma) advantage_next = advantage_reg + 1;
                    if ((x_pixel == btn_x2-1) && (y_pixel == btn_y2-1)) begin
                        advantage_next = 0;
                        if (advantage_reg[17:4] > 50) begin
                            if (btn_bottom_reg == 260 << 1) begin
                                btn_bottom_next = 300;
                                state_next = LOAD_PATTERN;
                                txt_mode_next = 1;
                            end else begin
                                btn_bottom_next = btn_bottom_reg - 1;
                            end
                        end else begin
                            if (btn_bottom_reg == 300 << 1) begin
                                btn_bottom_next = btn_bottom_reg;
                            end else begin
                                btn_bottom_next = btn_bottom_reg + 1;
                            end
                        end
                    end
                end
            end
            LOAD_PATTERN: begin
                if (score_cnt_reg == 7) begin
                    state_next = FINAL_SCORE;
                    txt_mode_next = 4'd9;
                end else begin
                    state_next  = WAIT_PATTERN;
                    enable_next = 1;
                end
            end
            WAIT_PATTERN: begin
                if (valid) begin
                    state_next    = SHOW_PATTERN;
                    txt_mode_next = 4'd5;
                    frame_stop_next = 0;
                end
            end
            SHOW_PATTERN: begin
                if (txt_out[1]) begin
                    {red_next, grn_next, blu_next} = 12'h000;  // 검정 태두리
                end else if (txt_out[0]) begin
                    {red_next, grn_next, blu_next} = 12'hFFF;  // 하양 문자
                end else if (time_bar_edge) begin
                    {red_next, grn_next, blu_next} = 12'h000;
                end else if (time_bar_in) begin
                    if (y_pixel > time_bar_upper_reg) begin
                        case (1)
                            (time_bar_upper_reg < 60):
                            {red_next, grn_next, blu_next} = 12'h0F0;
                            (time_bar_upper_reg < 105):
                            {red_next, grn_next, blu_next} = 12'h4F0;
                            (time_bar_upper_reg < 150):
                            {red_next, grn_next, blu_next} = 12'h8F0;
                            (time_bar_upper_reg < 195):
                            {red_next, grn_next, blu_next} = 12'hCF0;
                            (time_bar_upper_reg < 240):
                            {red_next, grn_next, blu_next} = 12'hFF0;
                            (time_bar_upper_reg < 285):
                            {red_next, grn_next, blu_next} = 12'hFC0;
                            (time_bar_upper_reg < 330):
                            {red_next, grn_next, blu_next} = 12'hF80;
                            (time_bar_upper_reg < 375):
                            {red_next, grn_next, blu_next} = 12'hF40;
                            (time_bar_upper_reg < 420):
                            {red_next, grn_next, blu_next} = 12'hF20;
                            default: {red_next, grn_next, blu_next} = 12'hF00;
                        endcase
                    end else begin
                        {red_next, grn_next, blu_next} = 12'hFFF;
                    end
                end else begin
                    if (!chroma_in) begin
                        {red_next, grn_next, blu_next} = 12'hFF0;
                    end else if (in_polygon) begin
                        {red_next, grn_next, blu_next} = (chroma) ? 12'h0AF : {median_red, median_grn, median_blu};
                    end else begin
                        {red_next, grn_next, blu_next} = (chroma) ? 12'hFF0 : 12'hF00 ;
                    end
                end
                if ((x_pixel == 640-1) && (y_pixel == 480-1) && pclk) begin // time_bar 450칸, 1칸당 1frame, 1초당 30frame
                    if (time_bar_upper_reg == 465) begin
                        time_bar_upper_next = 15;
                        frame_stop_next     = 1;
                        state_next          = CAL_PHASE_0;
                    end else begin
                        time_bar_upper_next = time_bar_upper_reg + 1;
                    end
                end
            end
            CAL_PHASE_0: begin
                if (in_polygon) begin
                    {red_next, grn_next, blu_next} = (chroma) ? 12'h0AF : {median_red, median_grn, median_blu};
                end else begin
                    {red_next, grn_next, blu_next} = (chroma) ? 12'hFF0 : 12'hF00 ;
                end
                if (x_pixel == 1 && y_pixel == 1) begin
                    state_next = CAL_PHASE_1;
                    advantage_next = 0;
                    penalty_next = 0;
                end
            end
            CAL_PHASE_1: begin
                if (DE && pclk) begin
                    if (in_polygon) begin
                        if (chroma) begin
                            {red_next, grn_next, blu_next} = 12'h0AF;
                        end else begin
                            {red_next, grn_next, blu_next} = {
                                median_red, median_grn, median_blu
                            };
                            advantage_next = advantage_reg + 1;
                        end
                    end else begin
                        if (!chroma_in || chroma) begin
                            {red_next, grn_next, blu_next} = 12'hFF0;
                        end else begin
                            {red_next, grn_next, blu_next} = 12'hF00;
                            penalty_next = penalty_reg + 1;
                        end
                    end
                end
                if ( (x_pixel == 640 - 2) && (y_pixel == 480 - 2) && pclk) begin  // 640 & 480 = 307_200 / 307_200 >> 6 =  4_800 // -4800 ~ 4800
                    score_next = advantage_reg[17:6];
                    state_next = SHOW_SCORE_0;
                    txt_mode_next = 4'd8;
                    sec_cnt_next = 0;
                end
            end
            SHOW_SCORE_0: begin
                if (txt_out[1]) begin
                    {red_next, grn_next, blu_next} = 12'h000;  // 검정 태두리
                end else if (txt_out[0]) begin
                    {red_next, grn_next, blu_next} = 12'hFFF;  // 하양 문자
                end else if (!chroma_in) begin
                    {red_next, grn_next, blu_next} = 12'hFF0;
                end else if (clk_cnt_reg[24]) begin
                    if (in_polygon) begin
                        if (!chroma) begin
                            if (sobel) {red_next, grn_next, blu_next} = 12'h0F0;
                            else {red_next, grn_next, blu_next} = 12'h8F8;
                        end else begin
                            {red_next, grn_next, blu_next} = 12'hFFF;
                        end
                    end else begin
                        if (!chroma) begin
                            if (sobel) {red_next, grn_next, blu_next} = 12'hF00;
                            else {red_next, grn_next, blu_next} = 12'hF88;
                        end else begin
                            {red_next, grn_next, blu_next} = 12'hFF0;
                        end
                    end
                end else begin
                    if (in_polygon) begin
                        if (!chroma) begin
                            if (sobel) {red_next, grn_next, blu_next} = 12'h8F8;
                            else {red_next, grn_next, blu_next} = 12'h0F0;
                        end else begin
                            {red_next, grn_next, blu_next} = 12'hFFF;
                        end
                    end else begin
                        if (!chroma) begin
                            if (sobel) {red_next, grn_next, blu_next} = 12'hF00;
                            else {red_next, grn_next, blu_next} = 12'hF88;
                        end else begin
                            {red_next, grn_next, blu_next} = 12'hFF0;
                        end
                    end
                end
                if (clk_cnt_reg == 250_000_000 - 1) begin
                    clk_cnt_next    = 0;
                    frame_stop_next = 1;
                    state_next      = SHOW_SCORE_1;
                    score_next      = penalty_reg[17:6];
                end else begin
                    clk_cnt_next = clk_cnt_reg + 1;
                end
            end
            SHOW_SCORE_1: begin
                if (txt_out[1]) begin
                    {red_next, grn_next, blu_next} = 12'h000;  // 검정 태두리
                end else if (txt_out[0]) begin
                    {red_next, grn_next, blu_next} = 12'hFFF;  // 하양 문자
                end else if (!chroma_in) begin
                    {red_next, grn_next, blu_next} = 12'hFF0;
                end else if (clk_cnt_reg[24]) begin
                    if (in_polygon) begin
                        if (!chroma) begin
                            if (sobel) {red_next, grn_next, blu_next} = 12'h0F0;
                            else {red_next, grn_next, blu_next} = 12'h8F8;
                        end else begin
                            {red_next, grn_next, blu_next} = 12'hFFF;
                        end
                    end else begin
                        if (!chroma) begin
                            if (sobel) {red_next, grn_next, blu_next} = 12'hF00;
                            else {red_next, grn_next, blu_next} = 12'hF88;
                        end else begin
                            {red_next, grn_next, blu_next} = 12'hFF0;
                        end
                    end
                end else begin
                    if (in_polygon) begin
                        if (!chroma) begin
                            if (sobel) {red_next, grn_next, blu_next} = 12'h0F0;
                            else {red_next, grn_next, blu_next} = 12'h8F8;
                        end else begin
                            {red_next, grn_next, blu_next} = 12'hFFF;
                        end
                    end else begin
                        if (!chroma) begin
                            if (sobel) {red_next, grn_next, blu_next} = 12'hF88;
                            else {red_next, grn_next, blu_next} = 12'hF00;
                        end else begin
                            {red_next, grn_next, blu_next} = 12'hFF0;
                        end
                    end
                end
                if (clk_cnt_reg == 250_000_000 - 1) begin
                    clk_cnt_next = 0;
                    frame_stop_next = 1;
                    state_next = SHOW_SCORE_2;
                    score_next = advantage_reg[17:6] - penalty_reg[17:6];
                    total_score_next = total_score_reg + (advantage_reg[17:6]) - (penalty_reg[17:6]);
                end else begin
                    clk_cnt_next = clk_cnt_reg + 1;
                end
            end
            SHOW_SCORE_2: begin
                if (txt_out[1]) begin
                    {red_next, grn_next, blu_next} = 12'h000;  // 검정 태두리
                end else if (txt_out[0]) begin
                    {red_next, grn_next, blu_next} = 12'hFFF;  // 하양 문자
                end else begin
                    if (in_polygon) begin
                        if (!chroma) begin
                            if (sobel) {red_next, grn_next, blu_next} = 12'h0F0;
                            else {red_next, grn_next, blu_next} = 12'h8F8;
                        end else begin
                            {red_next, grn_next, blu_next} = 12'hFFF;
                        end
                    end else begin
                        if (!chroma) begin
                            if (sobel) {red_next, grn_next, blu_next} = 12'hF00;
                            else {red_next, grn_next, blu_next} = 12'hF88;
                        end else begin
                            {red_next, grn_next, blu_next} = 12'hFF0;
                        end
                    end
                end
                if (x_pixel == 1 && y_pixel == 1) begin
                    if (txt_x_pixel_reg == 568) begin
                        scale_next = 3'd1;
                        if (txt_y_pixel_reg == 52 + (pattern_num_reg * 40) ) begin
                            txt_x_pixel_next = 10'd320;
                            txt_y_pixel_next = 10'd240;
                            scale_next = 3'd6;
                            score_stage_next = 1;
                            if (score_reg >= 300) begin  // 조절 필요
                                state_next  = SHOW_PASS_FAIL; // 원래 IDLE인데 test용으로 계속 넘어가게 임시로 해둠
                                txt_mode_next = 4'd6;
                                sound_option_next = 2'b01;
                            end else begin
                                state_next = SHOW_PASS_FAIL;
                                txt_mode_next = 4'd7;
                                sound_option_next = 2'b10;
                            end
                        end else begin
                            if (pattern_num_reg > 4) begin
                                txt_y_pixel_next = txt_y_pixel_reg + 1;
                            end else begin
                                txt_y_pixel_next = txt_y_pixel_reg - 1;
                            end
                            txt_mode_next = 4'd8;
                        end
                    end else if (txt_x_pixel_reg == 10'd361) begin
                        scale_next = 3'd6;
                        txt_x_pixel_next = txt_x_pixel_reg + 1;
                    end else if (txt_x_pixel_reg == 10'd402) begin
                        scale_next = 3'd5;
                        txt_x_pixel_next = txt_x_pixel_reg + 1;
                    end else if (txt_x_pixel_reg == 10'd443) begin
                        scale_next = 3'd4;
                        txt_x_pixel_next = txt_x_pixel_reg + 1;
                    end else if (txt_x_pixel_reg == 10'd484) begin
                        scale_next = 3'd3;
                        txt_x_pixel_next = txt_x_pixel_reg + 1;
                    end else if (txt_x_pixel_reg == 10'd525) begin
                        scale_next = 3'd2;
                        txt_x_pixel_next = txt_x_pixel_reg + 1;
                    end else begin
                        txt_x_pixel_next = txt_x_pixel_reg + 1;
                        txt_mode_next = 4'd8;
                    end
                end
            end
            SHOW_PASS_FAIL: begin
                if (txt_out[1]) begin
                    {red_next, grn_next, blu_next} = 12'h000;  // 검정 태두리
                end else if (txt_out[0]) begin
                    {red_next, grn_next, blu_next} = 12'hFFF;  // 하양 문자
                end else begin
                    if (in_polygon) begin
                        if (!chroma) begin
                            if (sobel) {red_next, grn_next, blu_next} = 12'h0F0;
                            else {red_next, grn_next, blu_next} = 12'h8F8;
                        end else begin
                            {red_next, grn_next, blu_next} = 12'hFFF;
                        end
                    end else begin
                        if (!chroma) begin
                            if (sobel) {red_next, grn_next, blu_next} = 12'hF00;
                            else {red_next, grn_next, blu_next} = 12'hF88;
                        end else begin
                            {red_next, grn_next, blu_next} = 12'hFF0;
                        end
                    end
                end
                if (clk_cnt_reg == 300_000_000 - 1) begin
                    clk_cnt_next    = 0;
                    frame_stop_next = 1;
                    txt_mode_next   = 4'd1;
                    advantage_next = 0;
                    penalty_next = 0;
                    score_stage_next = 0;
                    if (score_reg >= 300) begin  // 조절 필요
                        pattern_num_next = pattern_num_reg + 1;
                        score_cnt_next = score_cnt_reg + 1;
                        state_next = LOAD_PATTERN;
                    end else begin
                        pattern_num_next = 0;
                        score_cnt_next = 0;
                        state_next = FINAL_SCORE;
                    end
                end else begin
                    clk_cnt_next = clk_cnt_reg + 1;
                end
            end
            FINAL_SCORE: begin  // 400점 만점 몇점인지 띄우기
                txt_mode_next = 4'd9;
                if (txt_out[1]) begin
                    {red_next, grn_next, blu_next} = 12'h000;  // 검정 태두리
                end else if (txt_out[0]) begin
                    {red_next, grn_next, blu_next} = 12'hFFF;  // 하양 문자
                end else begin
                    {red_next, grn_next, blu_next} = {
                        median_red, median_grn, median_blu
                    };
                end
                if (btnU) begin
                    state_next       = IDLE;
                    pattern_num_next = 0;
                end
            end
            SET_CHROMA_AREA_0: begin
                if ((x_pixel == 1) && (y_pixel == 1)) begin
                    state_next = SET_CHROMA_AREA_1;
                    advantage_next = advantage_reg + 1;
                    chroma_area_top_cnt_next    = 0;
                    chroma_area_bottom_cnt_next = 0;
                    chroma_area_left_cnt_next   = 0;
                    chroma_area_right_cnt_next  = 0;
                end
                if (advantage_reg == 320) begin
                    state_next = IDLE;
                    advantage_next = 0;
                end
                if (chroma_area_top_set_reg && chroma_area_bottom_set_reg && chroma_area_left_set_reg && chroma_area_right_set_reg)begin
                    state_next = IDLE;
                    advantage_next = 0;
                end
            end
            SET_CHROMA_AREA_1: begin
                if (pclk) begin
                    if ( (y_pixel == chroma_area_top_reg) || (y_pixel == chroma_area_bottom_reg) || (x_pixel == chroma_area_left_reg)|| (x_pixel == chroma_area_right_reg)) begin
                        {red_next, grn_next, blu_next} = 12'hFFF;
                    end else begin
                        {red_next, grn_next, blu_next} = {
                            median_red, median_grn, median_blu
                        };
                    end
                    if ((y_pixel == (advantage_reg)) && chroma) begin
                        chroma_area_top_cnt_next = chroma_area_top_cnt_reg + 1;
                    end
                    if ((y_pixel == (480 - advantage_reg)) && chroma) begin
                        chroma_area_bottom_cnt_next = chroma_area_bottom_cnt_reg+1;
                    end
                    if ((x_pixel == (advantage_reg)) && chroma) begin
                        chroma_area_left_cnt_next = chroma_area_left_cnt_reg + 1;
                    end
                    if ((x_pixel == (640 - advantage_reg)) && chroma) begin
                        chroma_area_right_cnt_next = chroma_area_right_cnt_reg + 1;
                    end
                    if (!chroma_area_top_set_reg) begin
                        if (chroma_area_top_cnt_reg > 200) begin
                            if (chroma_area_top_cnt_continue_reg == 3) begin
                                chroma_area_top_set_next = 1;
                                chroma_area_top_cnt_continue_next = 0;
                            end else begin
                                chroma_area_top_cnt_continue_next =  chroma_area_top_cnt_continue_reg +1;
                            end
                        end
                        chroma_area_top_next = advantage_reg + 2;
                    end
                    if (!chroma_area_bottom_set_reg) begin
                        if (chroma_area_bottom_cnt_reg > 200) begin
                            if (chroma_area_bottom_cnt_continue_reg == 0) begin
                                chroma_area_bottom_set_next = 1;
                                chroma_area_bottom_cnt_continue_next = 0;
                            end else begin
                                chroma_area_bottom_cnt_continue_next =  chroma_area_bottom_cnt_continue_reg +1;
                            end
                        end
                        chroma_area_bottom_next = 480 - advantage_reg - 2;
                    end
                    if (!chroma_area_left_set_reg) begin
                        if (chroma_area_left_cnt_reg > 300) begin
                            if (chroma_area_left_cnt_continue_reg == 3) begin
                                chroma_area_left_set_next = 1;
                                chroma_area_left_cnt_continue_next = 0;
                            end else begin
                                chroma_area_left_cnt_continue_next =  chroma_area_left_cnt_continue_reg +1;
                            end
                        end
                        chroma_area_left_next = advantage_reg + 2;
                    end
                    if (!chroma_area_right_set_reg) begin
                        if (chroma_area_right_cnt_reg > 300) begin
                            if (chroma_area_right_cnt_continue_reg == 3) begin
                                chroma_area_right_set_next = 1;
                                chroma_area_right_cnt_continue_next = 0;
                            end else begin
                                chroma_area_right_cnt_continue_next =  chroma_area_right_cnt_continue_reg +1;
                            end
                        end
                        chroma_area_right_next = 640 - advantage_reg - 2;
                    end
                    if ((x_pixel == 640 - 1) && (y_pixel == 480 - 1)) begin
                        state_next = SET_CHROMA_AREA_0;
                    end
                end
            end
        endcase
    end

endmodule
