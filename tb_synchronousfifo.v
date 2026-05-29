`timescale 1ns / 1ps
// ============================================================
// Testbench for sync_fifo
// Covers : reset, sequential write/read, simultaneous wr+rd,
//          overflow attempt, underflow attempt, almost flags
// ============================================================

module sync_fifo_tb;

    // --------------------------------------------------------
    // Parameters — match or override DUT params here
    // --------------------------------------------------------
    parameter DATA_WIDTH         = 32;
    parameter FIFO_DEPTH         = 16;
    parameter ALMOST_FULL_THRESH  = FIFO_DEPTH - 2;
    parameter ALMOST_EMPTY_THRESH = 2;
    parameter CLK_PERIOD         = 10; // 10ns = 100MHz

    // --------------------------------------------------------
    // DUT signals
    // --------------------------------------------------------
    reg                    clk;
    reg                    rst_n;
    reg                    wr_en;
    reg                    rd_en;
    reg  [DATA_WIDTH-1:0]  din;
    wire [DATA_WIDTH-1:0]  dout;
    wire                   full;
    wire                   empty;
    wire                   almost_full;
    wire                   almost_empty;
    wire [$clog2(FIFO_DEPTH):0] fifo_count;

    // --------------------------------------------------------
    // DUT instantiation
    // --------------------------------------------------------
    sync_fifo #(
        .DATA_WIDTH         (DATA_WIDTH),
        .FIFO_DEPTH         (FIFO_DEPTH),
        .ALMOST_FULL_THRESH  (ALMOST_FULL_THRESH),
        .ALMOST_EMPTY_THRESH (ALMOST_EMPTY_THRESH)
    ) dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .wr_en        (wr_en),
        .din          (din),
        .rd_en        (rd_en),
        .dout         (dout),
        .full         (full),
        .empty        (empty),
        .almost_full  (almost_full),
        .almost_empty (almost_empty),
        .fifo_count   (fifo_count)
    );

    // --------------------------------------------------------
    // Clock generation
    // --------------------------------------------------------
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // --------------------------------------------------------
    // Task : write one word
    // --------------------------------------------------------
    task write_fifo;
        input [DATA_WIDTH-1:0] data;
        begin
            @(posedge clk);
            wr_en = 1;
            din   = data;
            @(posedge clk);
            wr_en = 0;
        end
    endtask

    // --------------------------------------------------------
    // Task : read one word
    // --------------------------------------------------------
    task read_fifo;
        begin
            @(posedge clk);
            rd_en = 1;
            @(posedge clk);
            rd_en = 0;
            $display("[READ] dout = 0x%08X | empty=%b fifo_count=%0d",
                      dout, empty, fifo_count);
        end
    endtask

    // --------------------------------------------------------
    // Main stimulus
    // --------------------------------------------------------
    integer k;

    initial begin
        // Init
        rst_n = 0; wr_en = 0; rd_en = 0; din = 0;
        repeat(4) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        // ---- Test 1 : Fill FIFO completely ----
        $display("\n=== TEST 1 : Fill FIFO ===");
        for (k = 1; k <= FIFO_DEPTH; k = k + 1) begin
            write_fifo(k * 32'hA5A5_0000 + k);
            $display("[WRITE] din=0x%08X | full=%b fifo_count=%0d",
                      din, full, fifo_count);
        end

        // ---- Test 2 : Overflow attempt ----
        $display("\n=== TEST 2 : Overflow attempt (should be blocked) ===");
        write_fifo(32'hDEAD_BEEF);
        $display("[OVERFLOW] full=%b fifo_count=%0d", full, fifo_count);

        // ---- Test 3 : Drain FIFO completely ----
        $display("\n=== TEST 3 : Drain FIFO ===");
        for (k = 0; k < FIFO_DEPTH; k = k + 1)
            read_fifo();

        // ---- Test 4 : Underflow attempt ----
        $display("\n=== TEST 4 : Underflow attempt (should be blocked) ===");
        read_fifo();
        $display("[UNDERFLOW] empty=%b fifo_count=%0d", empty, fifo_count);

        // ---- Test 5 : Simultaneous read + write ----
        $display("\n=== TEST 5 : Simultaneous RD+WR ===");
        write_fifo(32'hCAFE_BABE);
        @(posedge clk);
        wr_en = 1; rd_en = 1;
        din   = 32'h1234_5678;
        @(posedge clk);
        wr_en = 0; rd_en = 0;
        $display("[SIMUL] dout=0x%08X fifo_count=%0d", dout, fifo_count);

        // ---- Test 6 : Almost full / almost empty flags ----
        $display("\n=== TEST 6 : Almost flags ===");
        // fill to almost full
        for (k = 0; k < ALMOST_FULL_THRESH; k = k + 1)
            write_fifo(k);
        $display("[ALMOST_FULL]  almost_full=%b  fifo_count=%0d",
                  almost_full, fifo_count);
        // drain to almost empty
        for (k = 0; k < ALMOST_FULL_THRESH - ALMOST_EMPTY_THRESH + 1; k = k + 1)
            read_fifo();
        $display("[ALMOST_EMPTY] almost_empty=%b fifo_count=%0d",
                  almost_empty, fifo_count);

        $display("\n=== ALL TESTS DONE ===");
        #20;
        $finish;
    end

    // --------------------------------------------------------
    // Waveform dump — works in ModelSim & iverilog
    // --------------------------------------------------------
    initial begin
        $dumpfile("sync_fifo.vcd");
        $dumpvars(0, sync_fifo_tb);
    end

endmodule