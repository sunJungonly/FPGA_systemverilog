module stab_passthrough_G #(
    // 1280x720@60 default (CEA-861)
    parameter H_ACTIVE = 1280,
    parameter H_FP     = 110,
    parameter H_SYNC   = 40,
    parameter H_BP     = 220,
    parameter V_ACTIVE = 720,
    parameter V_FP     = 5,
    parameter V_SYNC   = 5,
    parameter V_BP     = 20,
    // sync polarity: 1=positive, 0=negative
    parameter HS_POL   = 1,
    parameter VS_POL   = 1
) (
    // Video Clock and Reset
    input wire vid_clk,
    input wire vid_rst_n, // Active-low reset

    // Video Input
    input  wire [23:0] vid_data_in,
    input  wire        vid_active_video_in,
    input  wire        vid_vsync_in,
    input  wire        vid_hsync_in,
    input  wire        vid_vblank_in,
    input  wire        vid_hblank_in,
    input  wire        vid_field_id_in,
    /// debug
    output reg  [23:0] vid_data_real,
    output reg         vid_active_video_real,
    output reg         vid_vsync_real,
    output reg         vid_hsync_real,
    output reg         vid_vblank_real,
    output reg         vid_hblank_real,
    output reg         vid_field_id_real,

    // Video Output
    output      [23:0] vid_data_out,
    output             vid_active_video_out,
    output             vid_vsync_out,
    output             vid_hsync_out,
    output             vid_vblank_out,
    output             vid_hblank_out,
    output             vid_field_id_out,
    output wire [10:0] x_pixel,
    output wire [ 9:0] y_pixel,
    // debug
    output wire [10:0] inter_x_pixel,
    output wire [ 9:0] inter_y_pixel
);

    // 내부 신호 분리
    wire [ 7:0] r_in = vid_data_in[23:16];
    wire [ 7:0] g_in = vid_data_in[8:0];
    wire [ 7:0] b_in = vid_data_in[15:8];

    // 처리 로직: Red와 Blue를 0으로 만들고 Green만 통과
    wire [23:0] processed_data = {r_in, g_in, b_in};  // {R, G, B}

    reg [10:0] x_pixel_reg, x_pixel_next;
    reg [9:0] y_pixel_reg, y_pixel_next;
    assign x_pixel = x_pixel_reg;
    assign y_pixel = y_pixel_reg;

    reg vid_vblank_in_d;
    reg vid_hblank_in_d;
    reg vid_vblank_in_dd;
    reg vid_hblank_in_dd;
    always @(posedge vid_clk) begin
        vid_vblank_in_dd <= vid_vblank_in_d;
        vid_vblank_in_d  <= vid_vblank_in;
        vid_hblank_in_dd <= vid_hblank_in_d;
        vid_hblank_in_d  <= vid_hblank_in;
    end
    wire vfalling;
    wire vrising;
    wire hfalling;
    wire hrising;
    assign vfalling = ~vid_vblank_in_d && vid_vblank_in_dd;
    assign vrising  = vid_vblank_in_d && ~vid_vblank_in_dd;
    assign hfalling = ~vid_hblank_in_d && vid_hblank_in_dd;
    assign hrising  = vid_hblank_in_d && ~vid_hblank_in_dd;
    reg start_of_frame_reg, start_of_frame_next;
    always @(posedge vid_clk) begin
        if (!vid_rst_n) begin
            x_pixel_reg <= 0;
            y_pixel_reg <= 0;
            start_of_frame_reg <= 0;
        end else begin
            x_pixel_reg <= x_pixel_next;
            y_pixel_reg <= y_pixel_next;
            start_of_frame_reg <= start_of_frame_next;
        end
    end

    reg [3:0] state, state_next;

    always @(posedge vid_clk) begin
        if (!vid_rst_n) begin
            state <= 0;
        end else begin
            state <= state_next;
        end
    end


    always @(*) begin
        x_pixel_next = x_pixel_reg;
        y_pixel_next = y_pixel_reg;
        state_next = state;
        start_of_frame_next = 0;
        case (state)
            0: begin  // vblank
                if (vfalling) begin
                    state_next = 1;
                end
            end
            1: begin  // hblank
                if (hfalling) begin
                    state_next = 2;
                    x_pixel_next = 0;
                    y_pixel_next = 0;
                    start_of_frame_next = 1;
                end
            end
            2: begin  // active line
                x_pixel_next = x_pixel_reg + 1;
                if (!vid_active_video_in) begin
                    state_next = 3;
                end
            end
            3: begin  // hblank
                if (x_pixel_reg < 2048 - 2) begin
                    x_pixel_next = x_pixel_reg + 1;
                end
                if (hfalling) begin
                    x_pixel_next = 0;
                    y_pixel_next = y_pixel_reg + 1;
                    if (y_pixel_reg == 1023 - 1) begin
                        state_next = 4;
                    end else begin
                        state_next = 2;
                    end
                end
                if (vfalling) begin
                    state_next = 1;
                end
            end
            4: begin
                if (x_pixel_reg == 2048 - 1) begin
                    x_pixel_next = 0;
                    if (y_pixel_reg < 1024 - 2) begin
                        y_pixel_next = y_pixel_reg + 1;
                    end
                end else begin
                    x_pixel_next = x_pixel_reg + 1;
                end
                if (vfalling) begin
                    state_next = 1;
                end
            end
        endcase
    end
    
endmodule