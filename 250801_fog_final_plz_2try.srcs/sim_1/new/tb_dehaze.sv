`timescale 1ns / 1ps

module tb_divide();
    logic clk;
    logic pclk;
    logic reset;
    logic rst;
    logic rclk;

    logic DE;
    logic [9:0] x_pixel;  // 라인 내 현재 픽셀 좌표 
    logic [9:0] y_pixel;
    logic [9:0] x_pixel_out;  // 라인 내 현재 픽셀 좌표 
    logic [9:0] y_pixel_out;
    
    logic h_sync;
    logic v_sync;
    logic h_sync_out;
    logic v_sync_out;

    logic DE_out;  // 결과 데이터 유효 신호

    logic [31:0] pixel_mem[640*480-1:0];
    logic [$clog2(480*640)-1:0] read_idx;

    //input port
    logic [7:0] red_port;
    logic [7:0] green_port;
    logic [7:0] blue_port;
    // logic [                     7:0] red_port_out;
    // logic [                     7:0] green_port_out;
    // logic [                     7:0] blue_port_out;
    // logic       debug_DE_out;
    logic [7:0] final_r;
    logic [7:0] final_g;
    logic [7:0] final_b;

    fog_removal_top dut(.*);

    VGA_Controller dut1 (.*);
    
    always #4 clk = ~clk;

    integer fd, fw;
    initial begin
        fd = $fopen("C:/final_DCP/0803_test/test16.hex", "r");
        fd = $fopen("C:/final_DCP/image_dehaze-master/image/KKU/16.hex", "r");
        fw = $fopen("C:/final_DCP/0803_test/sim_test.hex","w");
        if (fd == 0) begin
            $display("파일 열기 실패");
            $finish;
        end
        for (int i = 0; i < 640*480-1; i++) begin
            $fscanf(fd, "%h\n", pixel_mem[i]);
        end
        $fclose(fd);
        
        clk = 0;
        pclk = 0;
        reset = 1;
        read_idx = 0;
        rst = 1;
        #10 rst = 0;
        reset =0; 
    end
    assign {red_port, green_port, blue_port} = (DE) ? pixel_mem[read_idx] : 24'b0;

    always @(posedge pclk) begin

        if (DE) begin
            read_idx <= read_idx + 1;
            
        end

        if (DE_out) begin
            $fwrite(fw, "%h%h%h\n", final_r, final_g, final_b);
        end

        // if (debug_DE_out) begin
        //     $fwrite(fw, "%h%h%h\n", red_port_out, green_port_out, blue_port_out);
        // end

        if (read_idx >= 480*640-1) begin
            $fclose(fw);
            $display("시뮬레이션 완료");
            $finish;
        end
        
    end
endmodule
