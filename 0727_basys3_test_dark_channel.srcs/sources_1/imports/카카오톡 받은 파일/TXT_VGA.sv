`timescale 1ns / 1ps

module TXT_VGA (
    input  logic               clk,
    input  logic               reset,
    input  logic        [ 9:0] x_pixel,
    input  logic        [ 9:0] y_pixel,
    input  logic        [ 9:0] txt_x_pixel,  // from game fsm
    input  logic        [ 9:0] txt_y_pixel,  // "
    input  logic        [ 2:0] scale,
    input  logic        [ 3:0] txt_mode,
    input  logic        [ 1:0] txt_stage,
    input  logic               score_stage,
    input  logic signed [12:0] score,
    output logic        [ 1:0] txt_out,
    output logic               txt_done,
    output logic               tick_1s
);

    logic [95:0] char_buf_flat;
    logic [95:0] char_buf_stage1;
    logic [95:0] char_buf_stage2;
    logic [95:0] char_buf_stage3;
    logic [95:0] char_buf_stage4;

    txt U_txt (
        .clk(clk),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .txt_x_pixel(txt_x_pixel),
        .txt_y_pixel(txt_y_pixel),
        .scale(scale),
        .leftup(leftup),
        .char_buf_flat(char_buf_flat),
        .char_buf_stage1(char_buf_stage1),
        .char_buf_stage2(char_buf_stage2),
        .char_buf_stage3(char_buf_stage3),
        .char_buf_stage4(char_buf_stage4),
        .txt_out(txt_out)
    );

    clk_gen_1s U_CLK_DIV (
        .clk  (clk),
        .reset(reset),
        .tick (tick_1s)
    );

    txt_fsm U_txt_FSM (
        .clk(clk),
        .reset(reset),
        .tick(tick_1s),
        .state(txt_mode),
        .stage(txt_stage),
        .score_stage(score_stage),
        .score(score),
        .txt_done(txt_done),
        .char_buf_flat(char_buf_flat),
        .char_buf_stage1(char_buf_stage1),
        .char_buf_stage2(char_buf_stage2),
        .char_buf_stage3(char_buf_stage3),
        .char_buf_stage4(char_buf_stage4),
        .leftup(leftup)
    );

endmodule

module txt (
    input  logic        clk,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic [ 9:0] txt_x_pixel,
    input  logic [ 9:0] txt_y_pixel,
    input  logic [ 2:0] scale,
    input  logic        leftup,
    input  logic [95:0] char_buf_flat,
    input  logic [95:0] char_buf_stage1,
    input  logic [95:0] char_buf_stage2,
    input  logic [95:0] char_buf_stage3,
    input  logic [95:0] char_buf_stage4,
    output logic [ 1:0] txt_out
);

    logic [7:0] font_rom[0 : (256*8)-1];

    initial begin
        // " " (ASCII 32) 
        font_rom[256] = 8'b00000000;
        font_rom[257] = 8'b00000000;
        font_rom[258] = 8'b00000000;
        font_rom[259] = 8'b00000000;
        font_rom[260] = 8'b00000000;
        font_rom[261] = 8'b00000000;
        font_rom[262] = 8'b00000000;
        font_rom[263] = 8'b00000000;

        // 문자 '0' (ASCII 0x30 = 48)
        font_rom[384] = 8'b00111100;  // 48 * 8 + 0
        font_rom[385] = 8'b01000010;  // 48 * 8 + 1
        font_rom[386] = 8'b01000010;  // 48 * 8 + 2
        font_rom[387] = 8'b01000010;  // 48 * 8 + 3
        font_rom[388] = 8'b01000010;  // 48 * 8 + 4
        font_rom[389] = 8'b01000010;  // 48 * 8 + 5
        font_rom[390] = 8'b00111100;  // 48 * 8 + 6
        font_rom[391] = 8'b00000000;  // 48 * 8 + 7

        // "1" (ASCII 49)
        font_rom[392] = 8'b00011000;
        font_rom[393] = 8'b00001000;
        font_rom[394] = 8'b00001000;
        font_rom[395] = 8'b00001000;
        font_rom[396] = 8'b00001000;
        font_rom[397] = 8'b00001000;
        font_rom[398] = 8'b01111110;
        font_rom[399] = 8'b00000000;

        // "2" (ASCII 50)
        font_rom[400] = 8'b01111100;
        font_rom[401] = 8'b10000010;
        font_rom[402] = 8'b00000010;
        font_rom[403] = 8'b00011100;
        font_rom[404] = 8'b00100000;
        font_rom[405] = 8'b01000000;
        font_rom[406] = 8'b11111110;
        font_rom[407] = 8'b00000000;

        // "3" (ASCII 51)
        font_rom[408] = 8'b01111100;
        font_rom[409] = 8'b10000010;
        font_rom[410] = 8'b00000010;
        font_rom[411] = 8'b00111100;
        font_rom[412] = 8'b00000010;
        font_rom[413] = 8'b10000010;
        font_rom[414] = 8'b01111100;
        font_rom[415] = 8'b00000000;

        // "4" (ASCII 52)
        font_rom[416] = 8'b00000100;
        font_rom[417] = 8'b00001100;
        font_rom[418] = 8'b00010100;
        font_rom[419] = 8'b00100100;
        font_rom[420] = 8'b01000100;
        font_rom[421] = 8'b11111110;
        font_rom[422] = 8'b00000100;
        font_rom[423] = 8'b00000100;

        // "5" (ASCII 53)
        font_rom[424] = 8'b11111110;
        font_rom[425] = 8'b10000000;
        font_rom[426] = 8'b10000000;
        font_rom[427] = 8'b11111100;
        font_rom[428] = 8'b00000010;
        font_rom[429] = 8'b10000010;
        font_rom[430] = 8'b01111100;
        font_rom[431] = 8'b00000000;

        // "R" (ASCII 82)
        font_rom[656] = 8'b01111100;
        font_rom[657] = 8'b01100110;
        font_rom[658] = 8'b01100110;
        font_rom[659] = 8'b01111100;
        font_rom[660] = 8'b01111000;
        font_rom[661] = 8'b01101100;
        font_rom[662] = 8'b01100110;
        font_rom[663] = 8'b00000000;

        // "E" (ASCII 69)
        font_rom[552] = 8'b01111110;
        font_rom[553] = 8'b01111110;
        font_rom[554] = 8'b01100000;
        font_rom[555] = 8'b01111110;
        font_rom[556] = 8'b01100000;
        font_rom[557] = 8'b01111110;
        font_rom[558] = 8'b01111110;
        font_rom[559] = 8'b00000000;

        // "A" (ASCII 65)
        font_rom[520] = 8'b00011000;
        font_rom[521] = 8'b00111100;
        font_rom[522] = 8'b01100110;
        font_rom[523] = 8'b01111110;
        font_rom[524] = 8'b01111110;
        font_rom[525] = 8'b01100110;
        font_rom[526] = 8'b01100110;
        font_rom[527] = 8'b00000000;

        // "D" (ASCII 68)
        font_rom[544] = 8'b11111000;
        font_rom[545] = 8'b10000100;
        font_rom[546] = 8'b10000010;
        font_rom[547] = 8'b10000010;
        font_rom[548] = 8'b10000010;
        font_rom[549] = 8'b10000100;
        font_rom[550] = 8'b11111000;
        font_rom[551] = 8'b00000000;

        // "Y" (ASCII 89)
        font_rom[712] = 8'b10000010;
        font_rom[713] = 8'b10000010;
        font_rom[714] = 8'b01000100;
        font_rom[715] = 8'b00111000;
        font_rom[716] = 8'b00010000;
        font_rom[717] = 8'b00010000;
        font_rom[718] = 8'b00010000;
        font_rom[719] = 8'b00010000;

        // 문자 'P' (ASCII 0x50 = 80)
        font_rom[640] = 8'b01111100;  // 80 * 8 + 0
        font_rom[641] = 8'b01111110;  // 80 * 8 + 1
        font_rom[642] = 8'b01100110;  // 80 * 8 + 2
        font_rom[643] = 8'b01111100;  // 80 * 8 + 3
        font_rom[644] = 8'b01111000;  // 80 * 8 + 4
        font_rom[645] = 8'b01100000;  // 80 * 8 + 5
        font_rom[646] = 8'b01100000;  // 80 * 8 + 6
        font_rom[647] = 8'b00000000;  // 80 * 8 + 7

        // 문자 'S' (ASCII 0x53 = 83)
        font_rom[664] = 8'b00111110;  // 83 * 8 + 0
        font_rom[665] = 8'b01111110;  // 83 * 8 + 1
        font_rom[666] = 8'b01100000;  // 83 * 8 + 2
        font_rom[667] = 8'b00011100;  // 83 * 8 + 3
        font_rom[668] = 8'b00000110;  // 83 * 8 + 4
        font_rom[669] = 8'b01111110;  // 83 * 8 + 5
        font_rom[670] = 8'b01111100;  // 83 * 8 + 6
        font_rom[671] = 8'b00000000;  // 83 * 8 + 7

        // "F"
        font_rom[560] = 8'b01111110;
        font_rom[561] = 8'b01111110;
        font_rom[562] = 8'b01100000;
        font_rom[563] = 8'b01111110;
        font_rom[564] = 8'b01111110;
        font_rom[565] = 8'b01100000;
        font_rom[566] = 8'b01100000;
        font_rom[567] = 8'b00000000;

        // "I"
        font_rom[584] = 8'b01111110;
        font_rom[585] = 8'b01111110;
        font_rom[586] = 8'b00011000;
        font_rom[587] = 8'b00011000;
        font_rom[588] = 8'b00011000;
        font_rom[589] = 8'b01111110;
        font_rom[590] = 8'b01111110;
        font_rom[591] = 8'b00000000;

        // "L"
        font_rom[608] = 8'b01100000;
        font_rom[609] = 8'b01100000;
        font_rom[610] = 8'b01100000;
        font_rom[611] = 8'b01100000;
        font_rom[612] = 8'b01100000;
        font_rom[613] = 8'b01111110;
        font_rom[614] = 8'b01111110;
        font_rom[615] = 8'b00000000;

        // 'H' (ASCII 72)
        font_rom[576] = 8'b01100110;
        font_rom[577] = 8'b01100110;
        font_rom[578] = 8'b01111110;
        font_rom[579] = 8'b01111110;
        font_rom[580] = 8'b01100110;
        font_rom[581] = 8'b01100110;
        font_rom[582] = 8'b01100110;
        font_rom[583] = 8'b00000000;

        // 'O' (ASCII 79)
        font_rom[632] = 8'b00111100;
        font_rom[633] = 8'b01111110;
        font_rom[634] = 8'b01100110;
        font_rom[635] = 8'b01100110;
        font_rom[636] = 8'b01100110;
        font_rom[637] = 8'b01111110;
        font_rom[638] = 8'b00111100;
        font_rom[639] = 8'b00000000;

        // 'N' (ASCII 78)
        font_rom[624] = 8'b01100110;
        font_rom[625] = 8'b01100110;
        font_rom[626] = 8'b01110110;
        font_rom[627] = 8'b01111110;
        font_rom[628] = 8'b01101110;
        font_rom[629] = 8'b01100110;
        font_rom[630] = 8'b01100110;
        font_rom[631] = 8'b00000000;

        // 'W' (ASCII 87)
        font_rom[696] = 8'b11000110;
        font_rom[697] = 8'b11000110;
        font_rom[698] = 8'b11010110;
        font_rom[699] = 8'b11010110;
        font_rom[700] = 8'b11111110;
        font_rom[701] = 8'b11101110;
        font_rom[702] = 8'b10000010;
        font_rom[703] = 8'b00000000;

        // "G" (ASCII 71)
        font_rom[568] = 8'b00111100;
        font_rom[569] = 8'b01111110;
        font_rom[570] = 8'b11100000;
        font_rom[571] = 8'b11000000;
        font_rom[572] = 8'b11001110;
        font_rom[573] = 8'b11000110;
        font_rom[574] = 8'b01111110;
        font_rom[575] = 8'b00111100;

        // "T" (ASCII 84)
        font_rom[672] = 8'b01111110;
        font_rom[673] = 8'b01111110;
        font_rom[674] = 8'b00011000;
        font_rom[675] = 8'b00011000;
        font_rom[676] = 8'b00011000;
        font_rom[677] = 8'b00011000;
        font_rom[678] = 8'b00011000;
        font_rom[679] = 8'b00011000;

        // "C" (ASCII 67)
        font_rom[536] = 8'b00111100;
        font_rom[537] = 8'b01110010;
        font_rom[538] = 8'b01100000;
        font_rom[539] = 8'b01100000;
        font_rom[540] = 8'b01100000;
        font_rom[541] = 8'b01110010;
        font_rom[542] = 8'b00111110;
        font_rom[543] = 8'b00000000;

        // "6" (ASCII 54)
        font_rom[432] = 8'b00111100;
        font_rom[433] = 8'b01000010;
        font_rom[434] = 8'b10000000;
        font_rom[435] = 8'b11111100;
        font_rom[436] = 8'b10000010;
        font_rom[437] = 8'b10000010;
        font_rom[438] = 8'b01000010;
        font_rom[439] = 8'b00111100;

        // "7" (ASCII 55)
        font_rom[440] = 8'b11111110;
        font_rom[441] = 8'b00000010;
        font_rom[442] = 8'b00000100;
        font_rom[443] = 8'b00001000;
        font_rom[444] = 8'b00010000;
        font_rom[445] = 8'b00100000;
        font_rom[446] = 8'b01000000;
        font_rom[447] = 8'b10000000;

        // "8" (ASCII 56)
        font_rom[448] = 8'b00111100;
        font_rom[449] = 8'b01000010;
        font_rom[450] = 8'b01000010;
        font_rom[451] = 8'b00111100;
        font_rom[452] = 8'b01000010;
        font_rom[453] = 8'b01000010;
        font_rom[454] = 8'b01000010;
        font_rom[455] = 8'b00111100;

        // "9" (ASCII 57)
        font_rom[456] = 8'b00111100;
        font_rom[457] = 8'b01000010;
        font_rom[458] = 8'b01000010;
        font_rom[459] = 8'b00111110;
        font_rom[460] = 8'b00000010;
        font_rom[461] = 8'b00000010;
        font_rom[462] = 8'b01000010;
        font_rom[463] = 8'b00111100;

        // 문자 '!'
        font_rom[264] = 8'b00011000;  // 위에서 아래로 느낌표 막대기
        font_rom[265] = 8'b00011000;
        font_rom[266] = 8'b00011000;
        font_rom[267] = 8'b00011000;
        font_rom[268] = 8'b00011000;
        font_rom[269] = 8'b00000000;
        font_rom[270] = 8'b00011000;  // 아래 점
        font_rom[271] = 8'b00000000;

        // ":" (ASCII 58)
        font_rom[464] = 8'b00000000;
        font_rom[465] = 8'b00000000;
        font_rom[466] = 8'b00011000;
        font_rom[467] = 8'b00011000;
        font_rom[468] = 8'b00000000;
        font_rom[469] = 8'b00011000;
        font_rom[470] = 8'b00011000;
        font_rom[471] = 8'b00000000;

        // "." (ASCII 46)
        font_rom[368] = 8'b00000000;
        font_rom[369] = 8'b00000000;
        font_rom[370] = 8'b00000000;
        font_rom[371] = 8'b00000000;
        font_rom[372] = 8'b00000000;
        font_rom[373] = 8'b00000000;
        font_rom[374] = 8'b00011000;
        font_rom[375] = 8'b00011000;
    end

    logic [8:0] X_MAX, Y_MAX, START_X, START_Y;

    assign X_MAX = 320;
    assign Y_MAX = 240;
    assign START_X = leftup ? 32 : 32;  // (X_MAX - (몇글자 * width픽셀/1글자당 * SCALE)) / 2
    assign START_Y = leftup ? 40 : Y_MAX - 32;
    localparam START_STAGE_X = 520;
    localparam START_STAGE_Y = 40;
    parameter CHAR_WIDTH = 8;
    parameter STAGE_WIDTH = 8;
    parameter CHAR_HEIGHT = 8;
    parameter NUM_CHARS = 12;
    parameter SCALE = 6;
    parameter SCALE2 = 4;

    logic in_char_block;
    logic in_stage_block1, in_stage_block2, in_stage_block3, in_stage_block4;
    logic [2:0] row_in_char;  // 0~7
    logic [6:0] col_in_char;  // 0~7
    logic [2:0] row_in_stage1;  // 0~7
    logic [2:0] row_in_stage2;  // 0~7
    logic [2:0] row_in_stage3;  // 0~7
    logic [2:0] row_in_stage4;  // 0~7
    logic [6:0] col_in_stage;  // 0~7
    logic [7:0] font_row_data;
    logic font_bit, is_border_pixel;
    logic [7:0] font_row_stage1;
    logic [7:0] font_row_stage2;
    logic [7:0] font_row_stage3;
    logic [7:0] font_row_stage4;

    logic       font_bit_stage1;
    logic       font_bit_stage2;
    logic       font_bit_stage3;
    logic       font_bit_stage4;

    logic [7:0] char_buf        [0:11];
    logic [7:0] stage_buf1      [0:11];
    logic [7:0] stage_buf2      [0:11];
    logic [7:0] stage_buf3      [0:11];
    logic [7:0] stage_buf4      [0:11];
    assign {char_buf[11], char_buf[10], char_buf[9], char_buf[8], char_buf[7], char_buf[6], char_buf[5], char_buf[4], char_buf[3], char_buf[2], char_buf[1], char_buf[0]} = char_buf_flat;
    // stage
    localparam STAGE1_X_PRE = START_STAGE_X;
    localparam STAGE1_X_NEXT = START_STAGE_X + NUM_CHARS * CHAR_WIDTH;
    localparam STAGE1_Y_PRE = START_STAGE_Y;
    localparam STAGE1_Y_NEXT = START_STAGE_Y + CHAR_HEIGHT;

    localparam STAGE2_X_PRE = START_STAGE_X;
    localparam STAGE2_X_NEXT = START_STAGE_X + NUM_CHARS * CHAR_WIDTH;
    localparam STAGE2_Y_PRE = 2 * START_STAGE_Y;
    localparam STAGE2_Y_NEXT = 2 * START_STAGE_Y + CHAR_HEIGHT;

    localparam STAGE3_X_PRE = START_STAGE_X;
    localparam STAGE3_X_NEXT = START_STAGE_X + NUM_CHARS * CHAR_WIDTH;
    localparam STAGE3_Y_PRE = 3 * START_STAGE_Y;
    localparam STAGE3_Y_NEXT = 3 * START_STAGE_Y + CHAR_HEIGHT;

    localparam STAGE4_X_PRE = START_STAGE_X;
    localparam STAGE4_X_NEXT = START_STAGE_X + NUM_CHARS * CHAR_WIDTH;
    localparam STAGE4_Y_PRE = 4 * START_STAGE_Y;
    localparam STAGE4_Y_NEXT = 4 * START_STAGE_Y + CHAR_HEIGHT;

    assign {
        stage_buf1[11], 
        stage_buf1[10], 
        stage_buf1[9], 
        stage_buf1[8], 
        stage_buf1[7], 
        stage_buf1[6], 
        stage_buf1[5], 
        stage_buf1[4], 
        stage_buf1[3], 
        stage_buf1[2], 
        stage_buf1[1], 
        stage_buf1[0]
        } = char_buf_stage1;

    assign {
        stage_buf2[11], 
        stage_buf2[10], 
        stage_buf2[9], 
        stage_buf2[8], 
        stage_buf2[7], 
        stage_buf2[6], 
        stage_buf2[5], 
        stage_buf2[4], 
        stage_buf2[3], 
        stage_buf2[2], 
        stage_buf2[1], 
        stage_buf2[0]
        } = char_buf_stage2;

    assign {
        stage_buf3[11], 
        stage_buf3[10], 
        stage_buf3[9], 
        stage_buf3[8], 
        stage_buf3[7], 
        stage_buf3[6], 
        stage_buf3[5], 
        stage_buf3[4], 
        stage_buf3[3], 
        stage_buf3[2], 
        stage_buf3[1], 
        stage_buf3[0]
        } = char_buf_stage3;

    assign {
        stage_buf4[11], 
        stage_buf4[10], 
        stage_buf4[9], 
        stage_buf4[8], 
        stage_buf4[7], 
        stage_buf4[6], 
        stage_buf4[5], 
        stage_buf4[4], 
        stage_buf4[3], 
        stage_buf4[2], 
        stage_buf4[1], 
        stage_buf4[0]
        } = char_buf_stage4;
    logic [3:0] char_idx, stage_idx1, stage_idx2, stage_idx3, stage_idx4;
    logic [7:0] char_out, stage_out1, stage_out2, stage_out3, stage_out4;
    logic [9:0] scaled_x, scaled_y;

    assign scaled_x = x_pixel / scale;
    assign scaled_y = y_pixel / scale;
    logic [9:0] OFFSET_X, OFFSET_Y;
    assign OFFSET_X = CHAR_WIDTH * scale * NUM_CHARS / 2;
    assign OFFSET_Y = CHAR_WIDTH * scale / 2;

    // -------------------------------
    // 현재 위치가 문자 블록 안인지 판별
    // -------------------------------
    assign in_char_block = leftup ?
        (x_pixel >= START_X) && (x_pixel < START_X + NUM_CHARS * CHAR_WIDTH*SCALE - 2) &&
        (y_pixel >= START_Y) && (y_pixel < START_Y + CHAR_HEIGHT*SCALE - 4) :
        (x_pixel >= txt_x_pixel - OFFSET_X) && (x_pixel < txt_x_pixel + OFFSET_X) &&
        (y_pixel >= txt_y_pixel - OFFSET_Y - 12) && (y_pixel < txt_y_pixel + OFFSET_Y - 12);

    assign in_stage_block1 = ((x_pixel >= STAGE1_X_PRE) & (x_pixel < STAGE1_X_NEXT)) & ((y_pixel >= STAGE1_Y_PRE) & (y_pixel < STAGE1_Y_NEXT));
    assign in_stage_block2 = ((x_pixel >= STAGE2_X_PRE) & (x_pixel < STAGE2_X_NEXT)) & ((y_pixel >= STAGE2_Y_PRE) & (y_pixel < STAGE2_Y_NEXT));
    assign in_stage_block3 = ((x_pixel >= STAGE3_X_PRE) & (x_pixel < STAGE3_X_NEXT)) & ((y_pixel >= STAGE3_Y_PRE) & (y_pixel < STAGE3_Y_NEXT));
    assign in_stage_block4 = ((x_pixel >= STAGE4_X_PRE) & (x_pixel < STAGE4_X_NEXT)) & ((y_pixel >= STAGE4_Y_PRE) & (y_pixel < STAGE4_Y_NEXT));


    always_comb begin
        // 기본값
        row_in_char = 0;
        col_in_char = 0;
        char_idx    = 0;
        char_out    = 8'd32;

        row_in_stage1 = 0;
        row_in_stage2 = 0;
        row_in_stage3 = 0;
        row_in_stage4 = 0;
        col_in_stage = 0;
        stage_idx1    = 0;
        stage_idx2    = 0;
        stage_idx3    = 0;
        stage_idx4    = 0;

        stage_out1    = 8'd32;
        stage_out2    = 8'd32;
        stage_out3    = 8'd32;
        stage_out4    = 8'd32;

        if (in_char_block) begin
            row_in_char = leftup ? ((y_pixel - START_Y) / scale)  : ((y_pixel - (txt_y_pixel - OFFSET_Y - 12)) / scale);
            col_in_char = leftup ? ((x_pixel - START_X) / scale)  : ((x_pixel - (txt_x_pixel - OFFSET_X)) / scale);

            char_idx = col_in_char / CHAR_WIDTH;  // 0~4 중 해당 글자 인덱스
            char_out = char_buf[char_idx];  // 해당 문자 선택
            col_in_char = col_in_char % CHAR_WIDTH;  // 해당 문자 내에서의 열
        end
        // stage 1
        if (in_stage_block1) begin
            row_in_stage1 = y_pixel - STAGE1_Y_PRE;
            col_in_stage = x_pixel - STAGE1_X_PRE;

            stage_idx1    = col_in_stage / STAGE_WIDTH;  // 0~4 중 해당 글자 인덱스
            stage_out1 = stage_buf1[stage_idx1];  //해당 문자 선택
            col_in_stage = col_in_stage % STAGE_WIDTH;  // 해당 문자 내에서의 열
        end
        // stage 2
        if (in_stage_block2) begin
            row_in_stage2 = y_pixel - STAGE2_Y_PRE;
            col_in_stage = x_pixel - STAGE2_X_PRE;

            stage_idx2 = col_in_stage / STAGE_WIDTH;  // 0~4 ?? ??? ???? ??????
            stage_out2 = stage_buf2[stage_idx2];  // ??? ???? ????
            col_in_stage = col_in_stage % STAGE_WIDTH;  // ??? ???? ???????? ??
        end
        // stage 3
        if (in_stage_block3) begin
            row_in_stage3 = y_pixel - STAGE3_Y_PRE;
            col_in_stage = x_pixel - STAGE3_X_PRE;

            stage_idx3 = col_in_stage / STAGE_WIDTH;  // 0~4 ?? ??? ???? ??????
            stage_out3 = stage_buf3[stage_idx3];  // ??? ???? ????
            col_in_stage = col_in_stage % STAGE_WIDTH;  // ??? ???? ???????? ??
        end
        // stage 4
        if (in_stage_block4) begin
            row_in_stage4 = y_pixel - STAGE4_Y_PRE;
            col_in_stage = x_pixel - STAGE4_X_PRE;

            stage_idx4 = col_in_stage / STAGE_WIDTH;  // 0~4 ?? ??? ???? ??????
            stage_out4 = stage_buf4[stage_idx4];  // ??? ???? ????
            col_in_stage = col_in_stage % STAGE_WIDTH;  // ??? ???? ???????? ??
        end
    end
    // -------------------------------
    // font_rom에서 해당 문자 라인 데이터 읽기
    // -------------------------------
    always_ff @(posedge clk) begin
        if (in_char_block) font_row_data <= font_rom[{char_out, row_in_char}];
        else font_row_data <= 8'h00;

        if (in_stage_block1)
            font_row_stage1 <= font_rom[{stage_out1, row_in_stage1}];
        else font_row_stage1 <= 8'h00;

        if (in_stage_block2)
            font_row_stage2 <= font_rom[{stage_out2, row_in_stage2}];
        else font_row_stage2 <= 8'h00;

        if (in_stage_block3)
            font_row_stage3 <= font_rom[{stage_out3, row_in_stage3}];
        else font_row_stage3 <= 8'h00;

        if (in_stage_block4)
            font_row_stage4 <= font_rom[{stage_out4, row_in_stage4}];
        else font_row_stage4 <= 8'h00;
    end

    assign font_bit = font_row_data[7-col_in_char];
    assign font_bit_stage1 = font_row_stage1[7-col_in_stage];
    assign font_bit_stage2 = font_row_stage2[7-col_in_stage];
    assign font_bit_stage3 = font_row_stage3[7-col_in_stage];
    assign font_bit_stage4 = font_row_stage4[7-col_in_stage];

    logic [31:0] font_row_data_center, font_row_data_up, font_row_data_down;

    always_ff @(posedge clk) begin
        if (in_char_block) begin
            font_row_data_center <= font_rom[char_out*8+row_in_char];
            font_row_data_up     <= (row_in_char > 0) ? font_rom[char_out*8+row_in_char-1] : 8'd0;
            font_row_data_down   <= (row_in_char < 7) ? font_rom[char_out*8+row_in_char+1] : 8'd0;
        end
    end

    always_comb begin
        is_border_pixel = 0;
        if (!font_bit) begin
            if (
            (col_in_char > 0 && font_row_data_center[7 - (col_in_char - 1)]) ||
            (row_in_char > 0 && font_row_data_up[7 - col_in_char]) ||
            (row_in_char > 0 && col_in_char > 0   && font_row_data_up[7 - (col_in_char - 1)])
        ) begin
                is_border_pixel = 1;
            end
        end
    end

    // -------------------------------
    // RGB 출력 설정
    // -------------------------------
    logic [1:0] txt_stage_out;
    logic [1:0] txt_main_out;

    // stage_text 영역 처리 (항상 고정 위치에 있음)
    assign txt_stage_out = ((in_stage_block1 & font_bit_stage1) | (in_stage_block2 & font_bit_stage2) | (in_stage_block3 & font_bit_stage3) | (in_stage_block4 & font_bit_stage4)) ? 2'b1 : 2'b0;


    // main_text 영역 처리 (state에 따라 문자가 바뀜)
    always_comb begin
        txt_main_out = 2'd0;
        if (in_char_block && font_bit)
            txt_main_out = 2'd1;  // 필요할 때만 출력됨
        else if (in_char_block && is_border_pixel) txt_main_out = 2'd2;
    end

    // 최종 txt_out은 우선순위에 따라 결정
    assign txt_out = (txt_main_out != 2'd0) ? txt_main_out : txt_stage_out;

endmodule

module txt_fsm (
    input logic clk,
    input logic reset,
    input logic tick,
    input logic [3:0] state,
    input logic [1:0] stage,
    input logic score_stage,
    input logic signed [12:0] score,
    output logic txt_done,
    output logic [95:0] char_buf_flat,
    output logic [95:0] char_buf_stage1,
    output logic [95:0] char_buf_stage2,
    output logic [95:0] char_buf_stage3,
    output logic [95:0] char_buf_stage4,
    output logic leftup
);

    logic [7:0] char_buf  [0:11];
    logic [7:0] stage_buf1[0:11];
    logic [7:0] stage_buf2[0:11];
    logic [7:0] stage_buf3[0:11];
    logic [7:0] stage_buf4[0:11];

    assign char_buf_flat = {
        char_buf[11],
        char_buf[10],
        char_buf[9],
        char_buf[8],
        char_buf[7],
        char_buf[6],
        char_buf[5],
        char_buf[4],
        char_buf[3],
        char_buf[2],
        char_buf[1],
        char_buf[0]
    };

    assign char_buf_stage1 = {
        stage_buf1[11],
        stage_buf1[10],
        stage_buf1[9],
        stage_buf1[8],
        stage_buf1[7],
        stage_buf1[6],
        stage_buf1[5],
        stage_buf1[4],
        stage_buf1[3],
        stage_buf1[2],
        stage_buf1[1],
        stage_buf1[0]
    };

    assign char_buf_stage2 = {
        stage_buf2[11],
        stage_buf2[10],
        stage_buf2[9],
        stage_buf2[8],
        stage_buf2[7],
        stage_buf2[6],
        stage_buf2[5],
        stage_buf2[4],
        stage_buf2[3],
        stage_buf2[2],
        stage_buf2[1],
        stage_buf2[0]
    };

    assign char_buf_stage3 = {
        stage_buf3[11],
        stage_buf3[10],
        stage_buf3[9],
        stage_buf3[8],
        stage_buf3[7],
        stage_buf3[6],
        stage_buf3[5],
        stage_buf3[4],
        stage_buf3[3],
        stage_buf3[2],
        stage_buf3[1],
        stage_buf3[0]
    };

    assign char_buf_stage4 = {
        stage_buf4[11],
        stage_buf4[10],
        stage_buf4[9],
        stage_buf4[8],
        stage_buf4[7],
        stage_buf4[6],
        stage_buf4[5],
        stage_buf4[4],
        stage_buf4[3],
        stage_buf4[2],
        stage_buf4[1],
        stage_buf4[0]
    };

    typedef enum logic [3:0] {
        S_IDLE = 4'd0,
        S_SPACE = 4'd1,
        S_START = 4'd5,
        S_PASS = 4'd6,
        S_FAIL = 4'd7,
        S_SCORE = 4'd8,
        S_SCORE_FINAL = 4'd9
    } state_t;

    logic tick_1s;

    logic [2:0] cnt5;
    logic [1:0] cnt3;

    logic [3:0] v, w, x, y, z;
    logic [3:0] a, b, c, d, e;
    logic signed [12:0] abs_score;
    logic minus;

    assign abs_score = (score < 0) ? -score : score;
    assign minus = (score < 0);
    assign v = 0;
    assign w = abs_score / 1000 % 10;
    assign x = abs_score / 100 % 10;
    assign y = abs_score / 10 % 10;
    assign z = abs_score % 10;

    assign a = (score_stage) ? v : 0;
    assign b = (score_stage) ? w : 0;
    assign c = (score_stage) ? x : 0;
    assign d = (score_stage) ? y : 0;
    assign e = (score_stage) ? z : 0;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            stage_buf1[0]  <= " ";
            stage_buf1[1]  <= " ";
            stage_buf1[2]  <= " ";
            stage_buf1[3]  <= " ";
            stage_buf1[4]  <= " ";
            stage_buf1[5]  <= " ";
            stage_buf1[6]  <= " ";
            stage_buf1[7]  <= " ";
            stage_buf1[8]  <= " ";
            stage_buf1[9]  <= " ";
            stage_buf1[10] <= " ";
            stage_buf1[11] <= " ";

            stage_buf2[0]  <= " ";
            stage_buf2[1]  <= " ";
            stage_buf2[2]  <= " ";
            stage_buf2[3]  <= " ";
            stage_buf2[4]  <= " ";
            stage_buf2[5]  <= " ";
            stage_buf2[6]  <= " ";
            stage_buf2[7]  <= " ";
            stage_buf2[8]  <= " ";
            stage_buf2[9]  <= " ";
            stage_buf2[10] <= " ";
            stage_buf2[11] <= " ";

            stage_buf3[0]  <= " ";
            stage_buf3[1]  <= " ";
            stage_buf3[2]  <= " ";
            stage_buf3[3]  <= " ";
            stage_buf3[4]  <= " ";
            stage_buf3[5]  <= " ";
            stage_buf3[6]  <= " ";
            stage_buf3[7]  <= " ";
            stage_buf3[8]  <= " ";
            stage_buf3[9]  <= " ";
            stage_buf3[10] <= " ";
            stage_buf3[11] <= " ";

            stage_buf4[0]  <= " ";
            stage_buf4[1]  <= " ";
            stage_buf4[2]  <= " ";
            stage_buf4[3]  <= " ";
            stage_buf4[4]  <= " ";
            stage_buf4[5]  <= " ";
            stage_buf4[6]  <= " ";
            stage_buf4[7]  <= " ";
            stage_buf4[8]  <= " ";
            stage_buf4[9]  <= " ";
            stage_buf4[10] <= " ";
            stage_buf4[11] <= " ";
        end else
            case (stage)
                2'b00: begin
                    stage_buf1[0] <= "S";
                    stage_buf1[1] <= "T";
                    stage_buf1[2] <= "A";
                    stage_buf1[3] <= "G";
                    stage_buf1[4] <= "E";
                    stage_buf1[5] <= "1";
                    stage_buf1[6] <= ":";
                    case (a)
                        0: stage_buf1[7] <= "0";
                        1: stage_buf1[7] <= "1";
                        2: stage_buf1[7] <= "2";
                        3: stage_buf1[7] <= "3";
                        4: stage_buf1[7] <= "4";
                        5: stage_buf1[7] <= "5";
                        6: stage_buf1[7] <= "6";
                        7: stage_buf1[7] <= "7";
                        8: stage_buf1[7] <= "8";
                        9: stage_buf1[7] <= "9";
                        default: stage_buf1[7] <= " ";
                    endcase
                    case (b)
                        0: stage_buf1[8] <= "0";
                        1: stage_buf1[8] <= "1";
                        2: stage_buf1[8] <= "2";
                        3: stage_buf1[8] <= "3";
                        4: stage_buf1[8] <= "4";
                        5: stage_buf1[8] <= "5";
                        6: stage_buf1[8] <= "6";
                        7: stage_buf1[8] <= "7";
                        8: stage_buf1[8] <= "8";
                        9: stage_buf1[8] <= "9";
                        default: stage_buf1[8] <= " ";
                    endcase
                    case (c)
                        0: stage_buf1[9] <= "0";
                        1: stage_buf1[9] <= "1";
                        2: stage_buf1[9] <= "2";
                        3: stage_buf1[9] <= "3";
                        4: stage_buf1[9] <= "4";
                        5: stage_buf1[9] <= "5";
                        6: stage_buf1[9] <= "6";
                        7: stage_buf1[9] <= "7";
                        8: stage_buf1[9] <= "8";
                        9: stage_buf1[9] <= "9";
                        default: stage_buf1[9] <= " ";
                    endcase
                    case (d)
                        0: stage_buf1[10] <= "0";
                        1: stage_buf1[10] <= "1";
                        2: stage_buf1[10] <= "2";
                        3: stage_buf1[10] <= "3";
                        4: stage_buf1[10] <= "4";
                        5: stage_buf1[10] <= "5";
                        6: stage_buf1[10] <= "6";
                        7: stage_buf1[10] <= "7";
                        8: stage_buf1[10] <= "8";
                        9: stage_buf1[10] <= "9";
                        default: stage_buf1[10] <= " ";
                    endcase
                    case (e)
                        0: stage_buf1[11] <= "0";
                        1: stage_buf1[11] <= "1";
                        2: stage_buf1[11] <= "2";
                        3: stage_buf1[11] <= "3";
                        4: stage_buf1[11] <= "4";
                        5: stage_buf1[11] <= "5";
                        6: stage_buf1[11] <= "6";
                        7: stage_buf1[11] <= "7";
                        8: stage_buf1[11] <= "8";
                        9: stage_buf1[11] <= "9";
                        default: stage_buf1[11] <= " ";
                    endcase
                end

                2'b01: begin
                    stage_buf2[0] <= "S";
                    stage_buf2[1] <= "T";
                    stage_buf2[2] <= "A";
                    stage_buf2[3] <= "G";
                    stage_buf2[4] <= "E";
                    stage_buf2[5] <= "2";
                    stage_buf2[6] <= ":";
                    case (a)
                        0: stage_buf2[7] <= "0";
                        1: stage_buf2[7] <= "1";
                        2: stage_buf2[7] <= "2";
                        3: stage_buf2[7] <= "3";
                        4: stage_buf2[7] <= "4";
                        5: stage_buf2[7] <= "5";
                        6: stage_buf2[7] <= "6";
                        7: stage_buf2[7] <= "7";
                        8: stage_buf2[7] <= "8";
                        9: stage_buf2[7] <= "9";
                        default: stage_buf2[7] <= " ";
                    endcase
                    case (b)
                        0: stage_buf2[8] <= "0";
                        1: stage_buf2[8] <= "1";
                        2: stage_buf2[8] <= "2";
                        3: stage_buf2[8] <= "3";
                        4: stage_buf2[8] <= "4";
                        5: stage_buf2[8] <= "5";
                        6: stage_buf2[8] <= "6";
                        7: stage_buf2[8] <= "7";
                        8: stage_buf2[8] <= "8";
                        9: stage_buf2[8] <= "9";
                        default: stage_buf2[8] <= " ";
                    endcase
                    case (c)
                        0: stage_buf2[9] <= "0";
                        1: stage_buf2[9] <= "1";
                        2: stage_buf2[9] <= "2";
                        3: stage_buf2[9] <= "3";
                        4: stage_buf2[9] <= "4";
                        5: stage_buf2[9] <= "5";
                        6: stage_buf2[9] <= "6";
                        7: stage_buf2[9] <= "7";
                        8: stage_buf2[9] <= "8";
                        9: stage_buf2[9] <= "9";
                        default: stage_buf2[9] <= " ";
                    endcase
                    case (d)
                        0: stage_buf2[10] <= "0";
                        1: stage_buf2[10] <= "1";
                        2: stage_buf2[10] <= "2";
                        3: stage_buf2[10] <= "3";
                        4: stage_buf2[10] <= "4";
                        5: stage_buf2[10] <= "5";
                        6: stage_buf2[10] <= "6";
                        7: stage_buf2[10] <= "7";
                        8: stage_buf2[10] <= "8";
                        9: stage_buf2[10] <= "9";
                        default: stage_buf2[10] <= " ";
                    endcase
                    case (e)
                        0: stage_buf2[11] <= "0";
                        1: stage_buf2[11] <= "1";
                        2: stage_buf2[11] <= "2";
                        3: stage_buf2[11] <= "3";
                        4: stage_buf2[11] <= "4";
                        5: stage_buf2[11] <= "5";
                        6: stage_buf2[11] <= "6";
                        7: stage_buf2[11] <= "7";
                        8: stage_buf2[11] <= "8";
                        9: stage_buf2[11] <= "9";
                        default: stage_buf2[11] <= " ";
                    endcase
                end

                2'b10: begin
                    stage_buf3[0] <= "S";
                    stage_buf3[1] <= "T";
                    stage_buf3[2] <= "A";
                    stage_buf3[3] <= "G";
                    stage_buf3[4] <= "E";
                    stage_buf3[5] <= "3";
                    stage_buf3[6] <= ":";
                    case (a)
                        0: stage_buf3[7] <= "0";
                        1: stage_buf3[7] <= "1";
                        2: stage_buf3[7] <= "2";
                        3: stage_buf3[7] <= "3";
                        4: stage_buf3[7] <= "4";
                        5: stage_buf3[7] <= "5";
                        6: stage_buf3[7] <= "6";
                        7: stage_buf3[7] <= "7";
                        8: stage_buf3[7] <= "8";
                        9: stage_buf3[7] <= "9";
                        default: stage_buf3[7] <= " ";
                    endcase
                    case (b)
                        0: stage_buf3[8] <= "0";
                        1: stage_buf3[8] <= "1";
                        2: stage_buf3[8] <= "2";
                        3: stage_buf3[8] <= "3";
                        4: stage_buf3[8] <= "4";
                        5: stage_buf3[8] <= "5";
                        6: stage_buf3[8] <= "6";
                        7: stage_buf3[8] <= "7";
                        8: stage_buf3[8] <= "8";
                        9: stage_buf3[8] <= "9";
                        default: stage_buf3[8] <= " ";
                    endcase
                    case (c)
                        0: stage_buf3[9] <= "0";
                        1: stage_buf3[9] <= "1";
                        2: stage_buf3[9] <= "2";
                        3: stage_buf3[9] <= "3";
                        4: stage_buf3[9] <= "4";
                        5: stage_buf3[9] <= "5";
                        6: stage_buf3[9] <= "6";
                        7: stage_buf3[9] <= "7";
                        8: stage_buf3[9] <= "8";
                        9: stage_buf3[9] <= "9";
                        default: stage_buf3[9] <= " ";
                    endcase
                    case (d)
                        0: stage_buf3[10] <= "0";
                        1: stage_buf3[10] <= "1";
                        2: stage_buf3[10] <= "2";
                        3: stage_buf3[10] <= "3";
                        4: stage_buf3[10] <= "4";
                        5: stage_buf3[10] <= "5";
                        6: stage_buf3[10] <= "6";
                        7: stage_buf3[10] <= "7";
                        8: stage_buf3[10] <= "8";
                        9: stage_buf3[10] <= "9";
                        default: stage_buf3[10] <= " ";
                    endcase
                    case (e)
                        0: stage_buf3[11] <= "0";
                        1: stage_buf3[11] <= "1";
                        2: stage_buf3[11] <= "2";
                        3: stage_buf3[11] <= "3";
                        4: stage_buf3[11] <= "4";
                        5: stage_buf3[11] <= "5";
                        6: stage_buf3[11] <= "6";
                        7: stage_buf3[11] <= "7";
                        8: stage_buf3[11] <= "8";
                        9: stage_buf3[11] <= "9";
                        default: stage_buf3[11] <= " ";
                    endcase
                end

                2'b11: begin
                    stage_buf4[0] <= "S";
                    stage_buf4[1] <= "T";
                    stage_buf4[2] <= "A";
                    stage_buf4[3] <= "G";
                    stage_buf4[4] <= "E";
                    stage_buf4[5] <= "4";
                    stage_buf4[6] <= ":";
                    case (a)
                        0: stage_buf4[7] <= "0";
                        1: stage_buf4[7] <= "1";
                        2: stage_buf4[7] <= "2";
                        3: stage_buf4[7] <= "3";
                        4: stage_buf4[7] <= "4";
                        5: stage_buf4[7] <= "5";
                        6: stage_buf4[7] <= "6";
                        7: stage_buf4[7] <= "7";
                        8: stage_buf4[7] <= "8";
                        9: stage_buf4[7] <= "9";
                        default: stage_buf4[7] <= " ";
                    endcase
                    case (b)
                        0: stage_buf4[8] <= "0";
                        1: stage_buf4[8] <= "1";
                        2: stage_buf4[8] <= "2";
                        3: stage_buf4[8] <= "3";
                        4: stage_buf4[8] <= "4";
                        5: stage_buf4[8] <= "5";
                        6: stage_buf4[8] <= "6";
                        7: stage_buf4[8] <= "7";
                        8: stage_buf4[8] <= "8";
                        9: stage_buf4[8] <= "9";
                        default: stage_buf4[8] <= " ";
                    endcase
                    case (c)
                        0: stage_buf4[9] <= "0";
                        1: stage_buf4[9] <= "1";
                        2: stage_buf4[9] <= "2";
                        3: stage_buf4[9] <= "3";
                        4: stage_buf4[9] <= "4";
                        5: stage_buf4[9] <= "5";
                        6: stage_buf4[9] <= "6";
                        7: stage_buf4[9] <= "7";
                        8: stage_buf4[9] <= "8";
                        9: stage_buf4[9] <= "9";
                        default: stage_buf4[9] <= " ";
                    endcase
                    case (d)
                        0: stage_buf4[10] <= "0";
                        1: stage_buf4[10] <= "1";
                        2: stage_buf4[10] <= "2";
                        3: stage_buf4[10] <= "3";
                        4: stage_buf4[10] <= "4";
                        5: stage_buf4[10] <= "5";
                        6: stage_buf4[10] <= "6";
                        7: stage_buf4[10] <= "7";
                        8: stage_buf4[10] <= "8";
                        9: stage_buf4[10] <= "9";
                        default: stage_buf4[10] <= " ";
                    endcase
                    case (e)
                        0: stage_buf4[11] <= "0";
                        1: stage_buf4[11] <= "1";
                        2: stage_buf4[11] <= "2";
                        3: stage_buf4[11] <= "3";
                        4: stage_buf4[11] <= "4";
                        5: stage_buf4[11] <= "5";
                        6: stage_buf4[11] <= "6";
                        7: stage_buf4[11] <= "7";
                        8: stage_buf4[11] <= "8";
                        9: stage_buf4[11] <= "9";
                        default: stage_buf4[11] <= " ";
                    endcase
                end
            endcase
    end


    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            cnt5 <= 3'd5;
            cnt3 <= 2'd3;
            leftup <= 0;
            char_buf[0] <= " ";
            char_buf[1] <= " ";
            char_buf[2] <= " ";
            char_buf[3] <= " ";
            char_buf[4] <= " ";
            char_buf[5] <= " ";
            char_buf[6] <= " ";
            char_buf[7] <= " ";
            char_buf[8] <= " ";
            char_buf[9] <= " ";
            char_buf[10] <= " ";
            char_buf[11] <= " ";
        end else begin
            txt_done <= 0;
            leftup   <= 0;
            case (state)
                S_IDLE: begin
                    cnt5 <= 3'd5;
                    cnt3 <= 2'd3;
                    leftup <= 0;
                    char_buf[0] <= "H";
                    char_buf[1] <= "O";
                    char_buf[2] <= "L";
                    char_buf[3] <= "E";
                    char_buf[4] <= " ";
                    char_buf[5] <= "I";
                    char_buf[6] <= "N";
                    char_buf[7] <= " ";
                    char_buf[8] <= "W";
                    char_buf[9] <= "A";
                    char_buf[10] <= "L";
                    char_buf[11] <= "L";
                end
                S_SPACE: begin
                    cnt5 <= 3'd5;
                    cnt3 <= 2'd3;
                    leftup <= 0;
                    char_buf[0] <= " ";
                    char_buf[1] <= " ";
                    char_buf[2] <= " ";
                    char_buf[3] <= " ";
                    char_buf[4] <= " ";
                    char_buf[5] <= " ";
                    char_buf[6] <= " ";
                    char_buf[7] <= " ";
                    char_buf[8] <= " ";
                    char_buf[9] <= " ";
                    char_buf[10] <= " ";
                    char_buf[11] <= " ";
                end
                S_START: begin
                    cnt5 <= 3'd5;
                    cnt3 <= 2'd3;
                    if (tick) begin
                        leftup <= 1;
                        case (cnt5)
                            3'd5: char_buf[0] <= "5";
                            3'd4: char_buf[0] <= "4";
                            3'd3: char_buf[0] <= "3";
                            3'd2: char_buf[0] <= "2";
                            3'd1: char_buf[0] <= "1";
                            3'd0: char_buf[0] <= "0";
                            default: char_buf[0] <= " ";
                        endcase
                        char_buf[1]  <= " ";
                        char_buf[2]  <= " ";
                        char_buf[3]  <= " ";
                        char_buf[4]  <= " ";
                        char_buf[5]  <= " ";
                        char_buf[6]  <= " ";
                        char_buf[7]  <= " ";
                        char_buf[8]  <= " ";
                        char_buf[9]  <= " ";
                        char_buf[10] <= " ";
                        char_buf[11] <= " ";
                        if (cnt5 != 3'd0) cnt5 <= cnt5 - 1;
                        else begin
                            cnt5 <= 3'd0;
                            txt_done <= 1;
                        end
                    end else begin
                        // 1초 사이가 아닐 때는, 이전에 저장된 char_buf 그대로 유지
                        cnt5 <= cnt5;
                        cnt3 <= 2'd3;
                        leftup <= 1;
                        char_buf[0] <= char_buf[0];
                        char_buf[1] <= char_buf[1];
                        char_buf[2] <= char_buf[2];
                        char_buf[3] <= char_buf[3];
                        char_buf[4] <= char_buf[4];
                        char_buf[5] <= char_buf[5];
                        char_buf[6] <= char_buf[6];
                        char_buf[7] <= char_buf[7];
                        char_buf[8] <= char_buf[8];
                        char_buf[9] <= char_buf[9];
                        char_buf[10] <= char_buf[10];
                        char_buf[11] <= char_buf[11];
                    end
                end
                S_PASS: begin
                    cnt5   <= 3'd5;
                    cnt3   <= 2'd3;
                    leftup <= 0;
                    if (tick) begin
                        char_buf[0]  <= " ";
                        char_buf[1]  <= " ";
                        char_buf[2]  <= " ";
                        char_buf[3]  <= " ";
                        char_buf[4]  <= "P";
                        char_buf[5]  <= "A";
                        char_buf[6]  <= "S";
                        char_buf[7]  <= "S";
                        char_buf[8]  <= "!";
                        char_buf[9]  <= " ";
                        char_buf[10] <= " ";
                        char_buf[11] <= " ";
                        if (cnt5 != 3'd0) cnt5 <= cnt5 - 1;
                        else begin
                            cnt5 <= 3'd0;
                        end
                    end
                end
                S_FAIL: begin
                    cnt5 <= 3'd5;
                    cnt3 <= 2'd3;
                    leftup <= 0;
                    char_buf[0] <= " ";
                    char_buf[1] <= " ";
                    char_buf[2] <= " ";
                    char_buf[3] <= " ";
                    char_buf[4] <= "F";
                    char_buf[5] <= "A";
                    char_buf[6] <= "I";
                    char_buf[7] <= "L";
                    char_buf[8] <= "!";
                    char_buf[9] <= " ";
                    char_buf[10] <= " ";
                    char_buf[11] <= " ";
                end
                S_SCORE: begin
                    cnt5 <= 3'd5;
                    cnt3 <= 2'd3;
                    leftup <= 0;
                    char_buf[0] <= "S";
                    char_buf[1] <= "C";
                    char_buf[2] <= "O";
                    char_buf[3] <= "R";
                    char_buf[4] <= "E";
                    char_buf[5] <= ":";
                    char_buf[6] <= " ";
                    case (v)
                        0: char_buf[7] <= "0";
                        1: char_buf[7] <= "1";
                        2: char_buf[7] <= "2";
                        3: char_buf[7] <= "3";
                        4: char_buf[7] <= "4";
                        5: char_buf[7] <= "5";
                        6: char_buf[7] <= "6";
                        7: char_buf[7] <= "7";
                        8: char_buf[7] <= "8";
                        9: char_buf[7] <= "9";
                        default: char_buf[7] <= " ";
                    endcase
                    case (w)
                        0: char_buf[8] <= "0";
                        1: char_buf[8] <= "1";
                        2: char_buf[8] <= "2";
                        3: char_buf[8] <= "3";
                        4: char_buf[8] <= "4";
                        5: char_buf[8] <= "5";
                        6: char_buf[8] <= "6";
                        7: char_buf[8] <= "7";
                        8: char_buf[8] <= "8";
                        9: char_buf[8] <= "9";
                        default: char_buf[8] <= " ";
                    endcase
                    case (x)
                        0: char_buf[9] <= "0";
                        1: char_buf[9] <= "1";
                        2: char_buf[9] <= "2";
                        3: char_buf[9] <= "3";
                        4: char_buf[9] <= "4";
                        5: char_buf[9] <= "5";
                        6: char_buf[9] <= "6";
                        7: char_buf[9] <= "7";
                        8: char_buf[9] <= "8";
                        9: char_buf[9] <= "9";
                        default: char_buf[9] <= " ";
                    endcase
                    case (y)
                        0: char_buf[10] <= "0";
                        1: char_buf[10] <= "1";
                        2: char_buf[10] <= "2";
                        3: char_buf[10] <= "3";
                        4: char_buf[10] <= "4";
                        5: char_buf[10] <= "5";
                        6: char_buf[10] <= "6";
                        7: char_buf[10] <= "7";
                        8: char_buf[10] <= "8";
                        9: char_buf[10] <= "9";
                        default: char_buf[10] <= " ";
                    endcase
                    case (z)
                        0: char_buf[11] <= "0";
                        1: char_buf[11] <= "1";
                        2: char_buf[11] <= "2";
                        3: char_buf[11] <= "3";
                        4: char_buf[11] <= "4";
                        5: char_buf[11] <= "5";
                        6: char_buf[11] <= "6";
                        7: char_buf[11] <= "7";
                        8: char_buf[11] <= "8";
                        9: char_buf[11] <= "9";
                        default: char_buf[11] <= " ";
                    endcase
                end
                S_SCORE_FINAL: begin
                    cnt5 <= 3'd5;
                    cnt3 <= 2'd3;
                    leftup <= 0;
                    char_buf[0] <= " ";
                    char_buf[1] <= "F";
                    char_buf[2] <= "I";
                    char_buf[3] <= "N";
                    char_buf[4] <= "A";
                    char_buf[5] <= "L";
                    char_buf[6] <= ":";
                    char_buf[7] <= " ";
                    case (x)
                        0: char_buf[8] <= "0";
                        1: char_buf[8] <= "1";
                        2: char_buf[8] <= "2";
                        3: char_buf[8] <= "3";
                        4: char_buf[8] <= "4";
                        5: char_buf[8] <= "5";
                        6: char_buf[8] <= "6";
                        7: char_buf[8] <= "7";
                        8: char_buf[8] <= "8";
                        9: char_buf[8] <= "9";
                        default: char_buf[8] <= " ";
                    endcase
                    case (y)
                        0: char_buf[9] <= "0";
                        1: char_buf[9] <= "1";
                        2: char_buf[9] <= "2";
                        3: char_buf[9] <= "3";
                        4: char_buf[9] <= "4";
                        5: char_buf[9] <= "5";
                        6: char_buf[9] <= "6";
                        7: char_buf[9] <= "7";
                        8: char_buf[9] <= "8";
                        9: char_buf[9] <= "9";
                        default: char_buf[9] <= " ";
                    endcase
                    case (z)
                        0: char_buf[10] <= "0";
                        1: char_buf[10] <= "1";
                        2: char_buf[10] <= "2";
                        3: char_buf[10] <= "3";
                        4: char_buf[10] <= "4";
                        5: char_buf[10] <= "5";
                        6: char_buf[10] <= "6";
                        7: char_buf[10] <= "7";
                        8: char_buf[10] <= "8";
                        9: char_buf[10] <= "9";
                        default: char_buf[10] <= " ";
                    endcase
                    char_buf[11] <= " ";
                end
                default: begin
                    cnt5 <= 3'd5;
                    cnt3 <= 2'd3;
                    char_buf[0] <= " ";
                    char_buf[1] <= " ";
                    char_buf[2] <= " ";
                    char_buf[3] <= " ";
                    char_buf[4] <= " ";
                    char_buf[5] <= " ";
                    char_buf[6] <= " ";
                    char_buf[7] <= " ";
                    char_buf[8] <= " ";
                    char_buf[9] <= " ";
                    char_buf[10] <= " ";
                    char_buf[11] <= " ";
                end
            endcase
        end
    end

endmodule

module clk_gen_1s (
    input  logic clk,
    input  logic reset,
    output logic tick
);
    logic [$clog2(100_000_000) - 1:0] counter;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            tick <= 0;
            counter <= 0;
        end else begin
            if (counter == 100_000_000 - 1) begin
                tick <= 1;
                counter <= 0;
            end else begin
                tick <= 0;
                counter <= counter + 1;
            end
        end
    end

endmodule
