`timescale 1ns / 1ps

module SCCB_Master (
    input logic clk,
    input logic reset,
    inout wire sda,  //sccb data
    output logic scl  //sccb clock
);

    logic [15:0] Data;
    logic [ 7:0] addr;
    logic [7:0] w_reg_addr, w_data;
    logic w_start, w_done, w_ack_error;

    OV7670_set U_OV7670_set (
        .clk (clk),
        .addr(addr),
        .dout(Data)
    );

    SCCB_controller U_SCCB_controller (
        .clk     (clk),
        .reset   (reset),
        .reg_addr(Data[15:8]),
        .data    (Data[7:0]),
        .rom_addr(addr),
        .sda     (sda),
        .scl     (scl)
    );

endmodule

module SCCB_controller (
    input  logic       clk,
    input  logic       reset,
    input  logic [7:0] reg_addr,
    input  logic [7:0] data,
    output logic [7:0] rom_addr,
    inout  wire        sda,
    output logic       scl
);

    typedef enum logic [3:0] {
        IDLE,
        START,
        SEND_IP_ADDR,
        SEND_IP_ACK,
        SEND_ADDR,
        SEND_ADDR_ACK,
        SEND_DATA,
        SEND_DATA_ACK,
        STOP,
        FINISHED
    } state_t;



    state_t state, state_next;
    logic o_clk;
    logic scl_en_reg, scl_en_next;
    logic [3:0] i_reg, i_next;
    logic [7:0] ip_addr_reg, ip_addr_next;
    logic [7:0] reg_addr_reg, reg_addr_next;
    logic [7:0] data_reg, data_next;
    logic [7:0] rom_addr_reg, rom_addr_next;
    logic a_reg, a_next;

    logic [6:0] counter_next, counter_reg;
    logic sda_out_reg, sda_out_next, sda_dir_reg, sda_dir_next;
    logic tick;
    logic [9:0] p_counter;
    logic [6:0] stop_counter_reg, stop_counter_next;
    logic [7:0] new_counter_reg, new_counter_next;
    logic scl_en;

    assign scl = scl_en_reg ? o_clk : 1;
    assign sda = (sda_dir_reg) ? sda_out_reg : 1'bz;
    assign rom_addr = rom_addr_reg;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            p_counter        <= 0;
            tick             <= 0;
            o_clk            <= 1'b0;
            counter_reg      <= 0;
            stop_counter_reg <= 0;
            new_counter_reg  <= 0;
            a_reg            <= 0;
            scl_en_reg       <= 0;
            sda_out_reg      <= 0;
            sda_dir_reg      <= 0;
        end else begin
            a_reg            <= a_next;
            scl_en_reg       <= scl_en_next;
            counter_reg      <= counter_next;
            stop_counter_reg <= stop_counter_next;
            new_counter_reg  <= new_counter_next;
            sda_out_reg      <= sda_out_next;
            sda_dir_reg      <= sda_dir_next;
            if (p_counter <= 500 - 1) begin
                tick  <= 0;
                o_clk <= 1'b0;
                if (a_reg) begin
                    p_counter <= 0;
                end else begin
                    p_counter <= p_counter + 1;
                end
                if (p_counter == 250 - 1) begin
                    tick <= 1;
                end
            end else if (p_counter <= 1000 - 1) begin
                tick  <= 0;
                o_clk <= 1'b1;
                if (a_reg) begin
                    p_counter <= 0;
                end else begin
                    p_counter <= p_counter + 1;
                end
                if (p_counter == 1000 - 1) begin
                    p_counter <= 0;
                end
            end
        end
    end

    always_ff @(posedge tick, posedge reset) begin
        if (reset) begin
            ip_addr_reg  <= 8'b0;
            reg_addr_reg <= 8'b0;
            data_reg     <= 8'b0;
            state        <= IDLE;
            i_reg        <= 0;
            rom_addr_reg <= 0;
        end else begin
            ip_addr_reg  <= ip_addr_next;
            reg_addr_reg <= reg_addr_next;
            data_reg     <= data_next;
            state        <= state_next;
            i_reg        <= i_next;
            rom_addr_reg <= rom_addr_next;
        end
    end

    always_comb begin
        ip_addr_next      = ip_addr_reg;
        reg_addr_next     = reg_addr_reg;
        data_next         = data_reg;
        state_next        = state;
        rom_addr_next     = rom_addr_reg;
        counter_next      = counter_reg;
        stop_counter_next = stop_counter_reg;
        new_counter_next  = new_counter_reg;
        a_next            = a_reg;
        i_next            = i_reg;
        scl_en_next       = scl_en_reg;
        sda_out_next      = sda_out_reg;
        sda_dir_next      = sda_dir_reg;
        case (state)
            IDLE: begin
                sda_out_next = 1'b1;
                sda_dir_next = 1'b1;
                i_next       = 0;
                scl_en       = 0;
                a_next       = 0;
                state_next   = START;
            end
            START: begin
                ip_addr_next      = 8'h42;
                reg_addr_next     = reg_addr;
                data_next         = data;
                state_next        = SEND_IP_ADDR;
                stop_counter_next = 0;
                new_counter_next  = 0;
                sda_dir_next      = 1'b1;
                sda_out_next      = 1'b0;
                if (scl) begin
                    counter_next = counter_reg + 1;
                    if (counter_reg == 99) begin
                        a_next = 1;
                    end
                    if (counter_reg == 101) begin
                        scl_en_next = 1;
                    end else begin
                    end
                end else begin
                    counter_next = 0;
                    a_next = 0;
                end
            end
            SEND_IP_ADDR: begin
                sda_dir_next = 1'b1;
                sda_out_next = ip_addr_reg[7];
                ip_addr_next = {ip_addr_reg[6:0], 1'b0};
                i_next       = i_reg + 1;
                if (i_reg == 7) begin
                    state_next = SEND_IP_ACK;
                    i_next = 0;
                    rom_addr_next = rom_addr_reg + 1;
                end
            end
            SEND_IP_ACK: begin
                sda_dir_next = 1'b0;
                state_next   = SEND_ADDR;
            end
            SEND_ADDR: begin
                sda_dir_next  = 1'b1;
                sda_out_next  = reg_addr_reg[7];
                reg_addr_next = {reg_addr_reg[6:0], 1'b0};
                i_next        = i_reg + 1;
                if (i_reg == 7) begin
                    state_next = SEND_ADDR_ACK;
                    i_next = 0;
                end
            end
            SEND_ADDR_ACK: begin
                sda_dir_next = 1'b0;
                state_next   = SEND_DATA;
            end
            SEND_DATA: begin
                sda_dir_next    = 1'b1;
                sda_out_next   = data_reg[7];
                data_next = {data_reg[6:0], 1'b0};
                i_next    = i_reg + 1;
                if (i_reg == 7) begin
                    state_next = SEND_DATA_ACK;
                    i_next = 0;
                end
            end
            SEND_DATA_ACK: begin
                sda_dir_next = 1'b0;
                state_next   = STOP;
            end
            STOP: begin
                sda_out_next = (stop_counter_reg == 100) ? 1 : 0;
                sda_dir_next = 1'b1;
                if (scl) begin
                    if (stop_counter_reg == 100) begin
                        scl_en_next = 0;
                    end else begin
                        stop_counter_next = stop_counter_reg + 1;
                    end
                end
                if (rom_addr == 78) begin
                    state_next = FINISHED;
                end else begin
                    state_next = START;
                end
            end
            FINISHED: begin
                sda_out_next = 1'b1;
                sda_dir_next = 1'b1;
            end
        endcase
    end
endmodule

module OV7670_set (
    input logic clk,
    input logic [7:0] addr,
    output logic [15:0] dout
);

    //FFFF is end of rom, FFF0 is delay
    always @(posedge clk) begin
        case (addr)
            0: dout <= 16'h12_80;  //reset
            1: dout <= 16'hFF_F0;  //delay
            2:
            dout <= 16'h12_14;  // COM7,     set RGB color output and set QVGA
            3: dout <= 16'h11_80;  // CLKRC     internal PLL matches input clock
            4: dout <= 16'h0C_04;  // COM3,     default settings
            5: dout <= 16'h3E_19;  // COM14,    no scaling, normal pclock
            6: dout <= 16'h04_00;  // COM1,     disable CCIR656
            7: dout <= 16'h40_d0;  //COM15,     RGB565, full output range
            8: dout <= 16'h3a_04;  //TSLB       
            9: dout <= 16'h14_18;  //COM9       MAX AGC value x4
            10: dout <= 16'h4F_B3;  //MTX1       
            11: dout <= 16'h50_B3;  //MTX2
            12: dout <= 16'h51_00;  //MTX3
            13: dout <= 16'h52_3d;  //MTX4
            14: dout <= 16'h53_A7;  //MTX5
            15: dout <= 16'h54_E4;  //MTX6
            16: dout <= 16'h58_9E;  //MTXS
            17:
            dout <= 16'h3D_C0; //COM13      sets gamma enable, does not preserve reserved bits, may be wrong?
            18: dout <= 16'h17_15;  //HSTART     start high 8 bits 
            19:
            dout <= 16'h18_03; //HSTOP      stop high 8 bits //these kill the odd colored line
            20: dout <= 16'h32_80;  //91  //HREF       edge offset //
            21: dout <= 16'h19_03;  //VSTART     start high 8 bits
            22: dout <= 16'h1A_7B;  //VSTOP      stop high 8 bits
            23: dout <= 16'h03_00;  // 00 //VREF       vsync edge offset
            24: dout <= 16'h0F_41;  //COM6       reset timings
            25:
            dout <= 16'h1E_00; //MVFP       disable mirror / flip //might have magic value of 03
            26: dout <= 16'h33_0B;  //CHLF       //magic value from the internet
            27: dout <= 16'h3C_78;  //COM12      no HREF when VSYNC low
            28: dout <= 16'h69_00;  //GFIX       fix gain control
            29: dout <= 16'h74_00;  //REG74      Digital gain control
            30:
            dout <= 16'hB0_84; //RSVD       magic value from the internet *required* for good color
            31: dout <= 16'hB1_0c;  //ABLC1
            32: dout <= 16'hB2_0e;  //RSVD       more magic internet values
            33: dout <= 16'hB3_80;  //THL_ST
            //begin mystery scaling numbers
            34: dout <= 16'h70_3a;
            35: dout <= 16'h71_35;
            36: dout <= 16'h72_11;
            37: dout <= 16'h73_f1;
            38: dout <= 16'ha2_02;
            //gamma curve values
            39: dout <= 16'h7a_20;
            40: dout <= 16'h7b_10;
            41: dout <= 16'h7c_1e;
            42: dout <= 16'h7d_35;
            43: dout <= 16'h7e_5a;
            44: dout <= 16'h7f_69;
            45: dout <= 16'h80_76;
            46: dout <= 16'h81_80;
            47: dout <= 16'h82_88;
            48: dout <= 16'h83_8f;
            49: dout <= 16'h84_96;
            50: dout <= 16'h85_a3;
            51: dout <= 16'h86_af;
            52: dout <= 16'h87_c4;
            53: dout <= 16'h88_d7;
            54: dout <= 16'h89_e8;
            //AGC and AEC
            55: dout <= 16'h13_e0;  //COM8, disable AGC / AEC
            56: dout <= 16'h00_00;  //set gain reg to 0 for AGC
            57: dout <= 16'h10_00;  //set ARCJ reg to 0
            58: dout <= 16'h0d_40;  //magic reserved bit for COM4
            59: dout <= 16'h14_18;  //COM9, 4x gain + magic bit
            60: dout <= 16'ha5_05;  // BD50MAX
            61: dout <= 16'hab_07;  //DB60MAX
            62: dout <= 16'h24_95;  //AGC upper limit
            63: dout <= 16'h25_33;  //AGC lower limit
            64: dout <= 16'h26_e3;  //AGC/AEC fast mode op region
            65: dout <= 16'h9f_78;  //HAECC1
            66: dout <= 16'ha0_68;  //HAECC2
            67: dout <= 16'ha1_03;  //magic
            68: dout <= 16'ha6_d8;  //HAECC3
            69: dout <= 16'ha7_d8;  //HAECC4
            70: dout <= 16'ha8_f0;  //HAECC5
            71: dout <= 16'ha9_90;  //HAECC6
            72: dout <= 16'haa_94;  //HAECC7
            73: dout <= 16'h13_e7;  //COM8, enable AGC / AEC
            74: dout <= 16'h69_07;
            75: dout <= 16'h1e_10;  // vflip == 1
            76: dout <= 16'h41_10;  // denoise
            default: dout <= 16'hFF_FF;  //mark end of ROM
        endcase
    end
endmodule

