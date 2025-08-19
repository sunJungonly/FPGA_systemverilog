`timescale 1ns / 1ps

module matrix_generate_15X15 #(
    parameter DATA_WIDTH  = 8,
    parameter DATA_DEPTH  = 320,
    parameter KERNEL_SIZE = 3
) (
    input logic clk,
    input logic rst,
    input logic DE,
    input logic h_sync,
    input logic v_sync,
    input logic [8:0] x_pixel,
    input logic [8:0] y_pixel,
    input logic [DATA_WIDTH-1:0] pixel_in,
    output logic DE_out,
    output logic h_sync_out,
    output logic v_sync_out,
    output logic [8:0] x_pixel_out,
    // output logic [8:0] y_pixel_out,
    output logic [DATA_WIDTH-1:0] matrix_p[0:KERNEL_SIZE-1][0:KERNEL_SIZE-1]
);

    // --- 1. 라인 버퍼 ---
    logic [DATA_WIDTH-1:0] row_data_from_lb[0:KERNEL_SIZE-1];
    logic DE_from_lb;
    logic [8:0] x_pixel_from_lb;
    logic [8:0] y_pixel_from_lb;

    // y_pixel도 라인버퍼 딜레이에 동기화 필요 (같은 스테이지에서 같이 딜레이 시켜야 합니다)
    // Line_Buffer_for_DCP 모듈 내에서 y_pixel OUT 신호가 없으면 y_pixel_from_lb 를 따로 파이프라이닝해야 합니다.

    Line_Buffer_for_DCP #(
        .IMAGE_WIDTH(DATA_DEPTH),
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_ROWS(KERNEL_SIZE)
    ) U_Line_Buffer (
        .clk(clk),
        .rst(rst),
        .pixel_in(pixel_in),
        .DE(DE),
        .x_pixel(x_pixel),
        .row_data_out(row_data_from_lb),
        .DE_out(DE_from_lb),
        .x_pixel_out(x_pixel_from_lb)
    );

    // 라인 버퍼의 지연(latency)만큼 y_pixel을 지연시켜 동기화
    // Line_Buffer_for_DCP의 출력은 입력 대비 (NUM_ROWS-1)개의 라인만큼, 
    // 그리고 내부 로직에 따라 약간의 클럭 딜레이가 있을 수 있으나, 여기서는 라인 딜레이만 고려.
    // 하지만, 최종 출력단에서 KERNEL_SIZE만큼 쉬프트가 일어나므로, 그 딜레이에 맞추는 것이 더 정확.
    // 여기서는 최종 출력단의 파이프라인과 동기화.
    
    // --- 2. 제어 신호 및 커널 데이터 준비 상태 관리 ---
    
    // 매트릭스 쉬프트 레지스터의 깊이만큼 제어 신호를 파이프라이닝
    localparam PIPE_DELAY = KERNEL_SIZE; // KERNEL_SIZE-1(쉬프트) + 1(입력 레지스터)
    logic [PIPE_DELAY-1:0] DE_pipe;
    logic [8:0] x_pixel_pipe[PIPE_DELAY-1:0];
    logic [8:0] y_pixel_pipe[PIPE_DELAY-1:0];

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            DE_pipe       <= '{default: 1'b0};
            x_pixel_pipe  <= '{default: '0};
            y_pixel_pipe  <= '{default: '0};
        end else begin
            // 입력단에서 파이프라인 시작
            DE_pipe[0]       <= DE_from_lb;
            x_pixel_pipe[0]  <= x_pixel_from_lb;
            y_pixel_pipe[0]  <= y_pixel; // y_pixel은 라인버퍼를 거치지 않으므로 여기서부터 파이프라인 시작

            for (int i = 0; i < PIPE_DELAY - 1; i++) begin
                DE_pipe[i+1]       <= DE_pipe[i];
                x_pixel_pipe[i+1]  <= x_pixel_pipe[i];
                y_pixel_pipe[i+1]  <= y_pixel_pipe[i];
            end
        end
    end
    
    // 커널 데이터가 처음으로 완전히 채워졌는지 추적하는 카운터
    logic [$clog2(KERNEL_SIZE):0] fill_count;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            fill_count <= '0;
        end else if (DE_from_lb) begin
            if (fill_count < KERNEL_SIZE) begin
                fill_count <= fill_count + 1;
            end
        end
    end

    // 커널 데이터가 준비되었음을 나타내는 신호
    logic kernel_data_ready;
    assign kernel_data_ready = (fill_count >= KERNEL_SIZE);

    // --- 3. 매트릭스 생성 (쉬프트 레지스터) ---
    // [수정] 다중 드라이버 오류를 해결하기 위해 단 하나의 always 블록만 사용
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int r = 0; r < KERNEL_SIZE; r++) begin
                for (int c = 0; c < KERNEL_SIZE; c++) begin
                    matrix_p[r][c] <= '0;
                end
            end
        end else if (DE_from_lb) begin // 라인버퍼에서 유효한 데이터가 나올 때만 쉬프트
            for (int r = 0; r < KERNEL_SIZE; r++) begin
                // 기존 데이터를 왼쪽으로 한 칸씩 쉬프트
                for (int c = 0; c < KERNEL_SIZE - 1; c++) begin
                    matrix_p[r][c] <= matrix_p[r][c+1];
                end
                // 새 데이터를 가장 오른쪽에 로드
                matrix_p[r][KERNEL_SIZE-1] <= row_data_from_lb[r];
            end
        end
    end
    
    // --- 4. 최종 출력 ---
    assign x_pixel_out = x_pixel_pipe[PIPE_DELAY-1];
    assign y_pixel_out = y_pixel_pipe[PIPE_DELAY-1];
    
    // 최종 DE_out은 파이프라인을 통과한 유효신호이고, 커널 데이터가 완전히 준비되었을 때만 활성화
    assign DE_out = DE_pipe[PIPE_DELAY-1] && kernel_data_ready;

endmodule
