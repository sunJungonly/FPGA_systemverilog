`timescale 1ns/1ps
module tb_guided_filter_vga;

  localparam int W = 640;
  localparam int H = 480;
  localparam int N = W*H;

  // 한 클럭만 사용 (TB 단순화)
  logic clk;
  logic pclk;
  logic rst;



  // VGA 컨트롤러
  logic        DE;
  logic [9:0]  x_pixel, y_pixel;
  logic        h_sync, v_sync;

  VGA_Controller u_vga (
    .clk     (clk),
    .reset   (rst),
    .rclk    (),
    .pclk    (pclk),
    .DE      (DE),
    .x_pixel (x_pixel),
    .y_pixel (y_pixel),
    .h_sync  (h_sync),
    .v_sync  (v_sync)
  );

  // DUT (Guided Filter) - 같은 clk 사용
  logic [23:0] guide_pixel_in;
  logic [7:0]  input_pixel_in;
  logic        DE_out;
  logic [7:0]  q_i;

  guided_filter_top dut (
    .clk            (clk),
    .rst            (rst),
    .x_pixel        (x_pixel),
    .y_pixel        (y_pixel),
    .DE             (DE),
    .guide_pixel_in (guide_pixel_in),
    .input_pixel_in (input_pixel_in),
    .DE_out         (DE_out),
    .q_i            (q_i)
  );

  // 입력 메모리
  logic [23:0] rgb_mem [0:N-1];
  logic [ 7:0] t_mem   [0:N-1];
  logic [$clog2(480*640)-1:0] read_idx;

  integer fd, fs, fw;

    always #4 clk = ~clk;

  initial begin
    guide_pixel_in <= 0;
    input_pixel_in <= 0;
    fd = $fopen("C:/Users/kccistc/Desktop/i_image.hex", "r");
    fs = $fopen("C:/Users/kccistc/Desktop/te_image.hex", "r");
    fw = $fopen("C:/Users/kccistc/Desktop/t_image.hex", "w");
    if (fd == 0) begin
            $display("파일 열기 실패");
            $finish;
        end
        for (int i = 0; i < 640*480-1; i++) begin
            $fscanf(fd, "%h\n", rgb_mem[i]);
        end
        for (int i = 0; i < 640*480-1; i++) begin
            $fscanf(fs, "%h\n", t_mem[i]);
        end
        $fclose(fd);
        $fclose(fs);
        clk = 0;
        rst = 1;
        read_idx = 0;
        #10 rst = 0;
  end

  always @( posedge pclk ) begin
    if(DE)begin
      guide_pixel_in <= rgb_mem[read_idx];
      input_pixel_in <= t_mem[read_idx];
      read_idx <= read_idx + 1;
    end
    if(DE_out)begin
      $fwrite(fw, "%h\n", q_i);
    end
        if (read_idx >= 480*640-1) begin
            $fclose(fw);
            $display("시뮬레이션 완료");
            $finish;
        end

  end

endmodule
