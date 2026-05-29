`timescale 1ns / 1ps
// ============================================================
// Synchronous Parameterized FIFO
// Parameters : DATA_WIDTH, FIFO_DEPTH, ALMOST_FULL_THRESH,
//              ALMOST_EMPTY_THRESH
// ============================================================

module sync_fifo #(
    parameter DATA_WIDTH         = 32,
    parameter FIFO_DEPTH         = 16,
    parameter ALMOST_FULL_THRESH  = FIFO_DEPTH - 2,
    parameter ALMOST_EMPTY_THRESH = 2
)(
    input  wire                  clk,
    input  wire                  rst_n,        // active low reset

    // Write port
    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] din,

    // Read port
    input  wire                  rd_en,
    output reg  [DATA_WIDTH-1:0] dout,

    // Status flags
    output wire                  full,
    output wire                  empty,
    output wire                  almost_full,
    output wire                  almost_empty,
    output wire [$clog2(FIFO_DEPTH):0] fifo_count  // occupancy
);

    // --------------------------------------------------------
    // Local parameters
    // --------------------------------------------------------
    localparam ADDR_WIDTH = $clog2(FIFO_DEPTH);

    // --------------------------------------------------------
    // Memory array
    // --------------------------------------------------------
    reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];

    // --------------------------------------------------------
    // Pointers — extra bit for full/empty distinction
    // --------------------------------------------------------
    reg [ADDR_WIDTH:0] wr_ptr;
    reg [ADDR_WIDTH:0] rd_ptr;

    // --------------------------------------------------------
    // Occupancy count
    // --------------------------------------------------------
    assign fifo_count = wr_ptr - rd_ptr;

    // --------------------------------------------------------
    // Status flags
    // --------------------------------------------------------
    assign full         = (fifo_count == FIFO_DEPTH);
    assign empty        = (fifo_count == 0);
    assign almost_full  = (fifo_count >= ALMOST_FULL_THRESH);
    assign almost_empty = (fifo_count <= ALMOST_EMPTY_THRESH);

    // --------------------------------------------------------
    // Write logic — with overflow protection
    // --------------------------------------------------------
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            for (i = 0; i < FIFO_DEPTH; i = i + 1)
                mem[i] <= 0;
        end else begin
            if (wr_en && !full) begin
                mem[wr_ptr[ADDR_WIDTH-1:0]] <= din;
                wr_ptr <= wr_ptr + 1;
            end
        end
    end

    // --------------------------------------------------------
    // Read logic — with underflow protection
    // --------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
            dout   <= 0;
        end else begin
            if (rd_en && !empty) begin
                dout   <= mem[rd_ptr[ADDR_WIDTH-1:0]];
                rd_ptr <= rd_ptr + 1;
            end
        end
    end

endmodule