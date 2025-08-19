// `timescale 1ns / 1ps

// module tb_divide();
//     logic clk;
//     logic pclk;
//     logic reset;
//     logic rst;
//     logic rclk;

//     logic DE;
//     logic [9:0] x_pixel;  // 라인 내 현재 픽셀 좌표 
//     logic [9:0] y_pixel;
//     logic [9:0] x_pixel_out;  // 라인 내 현재 픽셀 좌표 
//     logic [9:0] y_pixel_out;

//     logic h_sync;
//     logic v_sync;
//     logic h_sync_out;
//     logic v_sync_out;

//     logic DE_out;  // 결과 데이터 유효 신호

//     logic [31:0] pixel_mem[640*480-1:0];
//     logic [$clog2(480*640)-1:0] read_idx;

//     //input port
//     logic [7:0] red_port;
//     logic [7:0] green_port;
//     logic [7:0] blue_port;
//     logic [                     7:0] red_port_out;
//     logic [                     7:0] green_port_out;
//     logic [                     7:0] blue_port_out;
//     logic       debug_DE_out;
//     logic [7:0] final_r;
//     logic [7:0] final_g;
//     logic [7:0] final_b;

//     fog_removal_top dut(.*);

//     VGA_Controller dut1 (.*);

//     always #4 clk = ~clk;

//     integer fd, fw, fw2;
//     initial begin
//         fd = $fopen("C:/final_DCP/0803_test/test16.hex", "r");
//         fw = $fopen("C:/final_DCP/0803_test/sim_test16.hex","w");
//         // fw2 = $fopen("C:/Users/kccistc/trans_image.hex","w");
//         if (fd == 0) begin
//             $display("파일 열기 실패");
//             $finish;
//         end
//         for (int i = 0; i < 640*480-1; i++) begin
//             $fscanf(fd, "%h\n", pixel_mem[i]);
//         end
//         $fclose(fd);

//         clk = 0;
//         pclk = 0;
//         reset = 1;
//         read_idx = 0;
//         rst = 1;
//         #10 rst = 0;
//         reset =0; 
//     end
//     assign {red_port, green_port, blue_port} = (DE) ? pixel_mem[read_idx] : 24'b0;

//     always @(posedge pclk) begin

//         if (DE) begin
//             read_idx <= read_idx + 1;

//         end

//         if (DE_out) begin
//             $fwrite(fw, "%h%h%h\n", final_r, final_g, final_b);
//         end

//         // if (debug_DE_out) begin
//         //     $fwrite(fw2, "%h%h%h\n", red_port_out, green_port_out, blue_port_out);
//         // end

//         if (read_idx >= 480*640-1) begin
//             $fclose(fw);
//             // $fclose(fw2);
//             $display("시뮬레이션 완료");
//             $finish;
//         end

//     end
// endmodule


`timescale 1ns / 1ps

module tb_divide ();
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

    // CHANGED: 메모리 폭을 16비트(RGB565)로 변경
    logic [15:0] pixel_mem[640*480-1:0];
    logic [$clog2(480*640)-1:0] read_idx;

    //input port
    logic [7:0] red_port;
    logic [7:0] green_port;
    logic [7:0] blue_port;
    logic [7:0] red_port_out;
    logic [7:0] green_port_out;
    logic [7:0] blue_port_out;
    logic debug_DE_out;
    logic [7:0] final_r;
    logic [7:0] final_g;
    logic [7:0] final_b;

    // NEW: RGB565 to RGB888 변환을 위한 중간 신호
    logic [15:0] current_pixel_565;
    logic [7:0] r_from_565;
    logic [7:0] g_from_565;
    logic [7:0] b_from_565;

    fog_removal_top dut (.*);

    VGA_Controller dut1 (.*);

    always #4 clk = ~clk;

    integer fd, fw, fw2;
    initial begin
        // 헥사 파일은 텍스트 파일이므로 메모장으로 편집 가능합니다.
        // 다만, 값들이 16진수 문자(0-9, a-f)와 공백/줄바꿈으로만 이루어져 있는지 확인해야 합니다.
        // fd = $fopen("C:/Users/kccistc/rgb_image.hex", "r");
        // fw = $fopen("C:/Users/kccistc/Final_image.hex","w");
        // fd = $fopen("C:/final_DCP/image_dehaze-master/image/KKU/15.hex", "r");
        // fd = $fopen("C:/final_DCP/image_dehaze-master/image/KKU/16.hex", "r");
        fd = $fopen("C:/final_DCP/image_dehaze-master/image/KKU/19.hex", "r");
        // fd = $fopen("C:/final_DCP/image_dehaze-master/image/KKU/18.hex", "r");
        // fd = $fopen("C:/final_DCP/image_dehaze-master/image/KKU/19.hex", "r");
        fw = $fopen("C:/final_DCP/0803_test/sim_test19.hex", "w");
        fw2 = $fopen("C:/final_DCP/0803_test/trans_image.hex","w");
        if (fd == 0) begin
            $display("파일 열기 실패");
            $finish;
        end

        // CHANGED: for 루프의 종료 조건을 수정하고, $fscanf 형식 지정자를 변경
        // 공백, 탭, 줄바꿈 등 모든 종류의 공백 문자를 건너뛰고 16진수 값을 읽습니다.
        for (int i = 0; i < 640 * 480; i++) begin
            $fscanf(fd, "%h", pixel_mem[i]);
        end
        $fclose(fd);

        clk = 0;
        pclk = 0;
        reset = 1;
        read_idx = 0;
        rst = 1;
        #10 rst = 0;
        reset = 0;
    end

    // CHANGED: pixel_mem에서 읽은 16비트 RGB565 값을 DUT가 요구하는 24비트 RGB888로 변환
    // 1. DE 신호가 유효할 때 메모리에서 16비트 픽셀 값을 읽어옴
    assign current_pixel_565 = (DE) ? pixel_mem[read_idx] : 16'b0;

    // 2. RGB565 포맷에서 각 색상 채널을 분리하고 8비트로 확장
    // R: 5bit -> 8bit. 상위 5비트를 그대로 쓰고, 하위 3비트는 상위 3비트를 복사해서 채움. {R[4:0], R[4:2]}
    // G: 6bit -> 8bit. 상위 6비트를 그대로 쓰고, 하위 2비트는 상위 2비트를 복사해서 채움. {G[5:0], G[5:4]}
    // B: 5bit -> 8bit. 상위 5비트를 그대로 쓰고, 하위 3비트는 상위 3비트를 복사해서 채움. {B[4:0], B[4:2]}
    assign r_from_565 = {current_pixel_565[15:11], current_pixel_565[15:13]};
    assign g_from_565 = {current_pixel_565[10:5], current_pixel_565[10:9]};
    assign b_from_565 = {current_pixel_565[4:0], current_pixel_565[4:2]};

    // 3. 변환된 RGB888 값을 DUT의 입력 포트에 연결
    assign red_port = r_from_565;
    assign green_port = g_from_565;
    assign blue_port = b_from_565;


    always @(posedge pclk) begin
        if (DE) begin
            read_idx <= read_idx + 1;
        end

        if (DE_out) begin
            $fwrite(fw, "%h%h%h\n", final_r, final_g, final_b);
        end

        if (debug_DE_out) begin
            $fwrite(fw2, "%h%h%h\n", red_port_out, green_port_out,
                    blue_port_out);
        end

        // CHANGED: 시뮬레이션 종료 조건을 명확하게 수정
        if (read_idx == 640 * 480) begin
            #1000;  // 마지막 픽셀이 처리될 시간을 약간 더 줌
            $fclose(fw);
            $fclose(fw2);
            $display("시뮬레이션 완료");
            $finish;
        end
    end
endmodule
