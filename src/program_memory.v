//=============================================================================
// program_memory.v - TinyBF Program Memory (Instruction Storage)
//=============================================================================
// Project:     TinyBF - Tiny Tapeout Sky 25B Brainfuck ASIC CPU
// Author:      René Hahn
// Date:        2025-11-10
// Version:     1.0
//
// Description:
//   Synchronous dual-port RAM for Brainfuck program instructions
//   Write-first semantics (simultaneous read/write returns new data)
//   1-cycle read latency
//
// Parameters:
//   DATA_W: Instruction width in bits (default 8)
//   DEPTH:  Number of memory locations (default 16, must be power of 2)
//
// Interfaces:
//   clk_i:   System clock
//   rst_i:   Active-low reset (unused, lint_off applied)
//   wen_i:   Write enable
//   waddr_i: Write address
//   wdata_i: Write data
//   ren_i:   Read enable
//   raddr_i: Read address
//   rdata_o: Read data (valid 1 cycle after ren_i assertion)

`timescale 1ns/1ps
module program_memory #(
    parameter integer DATA_W = 8,
    parameter integer DEPTH  = 16
) (
    input  wire                      clk_i,
    /* verilator lint_off UNUSEDSIGNAL */
    input  wire                      rst_i,  // Unused: Memory initialized via initial block
    /* verilator lint_on UNUSEDSIGNAL */
    // Write port
    input  wire                      wen_i,
    input  wire [$clog2(DEPTH)-1:0]  waddr_i,
    input  wire [DATA_W-1:0]         wdata_i,
    // Read port
    input  wire                      ren_i,
    input  wire [$clog2(DEPTH)-1:0]  raddr_i,
    output reg  [DATA_W-1:0]         rdata_o
);

    // Memory storage array
    reg [DATA_W-1:0] mem [0:DEPTH-1];

    // Initialize memory to zero
    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1) begin
            mem[i] = {DATA_W{1'b0}};
        end
    end

    // Synchronous write and read with write-first behavior
    always @(posedge clk_i) begin
        // Write operation
        if (wen_i) begin
            mem[waddr_i] <= wdata_i;
        end

        // Read operation with write-first semantics
        if (ren_i) begin
            if (wen_i && (waddr_i == raddr_i)) begin
                // Write-first: return the data being written
                rdata_o <= wdata_i;
            end else begin
                // Normal read from memory
                rdata_o <= mem[raddr_i];
            end
        end
        // Note: If ren_i is low, rdata_o retains its previous value
    end

endmodule
