//=============================================================================
// program_memory.v - TinyBF Program Memory (ROM - Read Only)
//=============================================================================
// Project:     TinyBF - Tiny Tapeout Sky 25B Brainfuck ASIC CPU
// Author:      René Hahn
// Date:        2025-11-10
// Version:     2.0
//
// Description:
//   Pure combinational ROM for Brainfuck program instructions
//   Pre-loaded with demonstration program
//   No write capability - program is fixed at synthesis time
//   1-cycle read latency (registered output)
//
// Default Program (8 instructions):
//   Demonstrates a simple cell copy loop with I/O
//   Address | Instruction | Description
//   --------|-------------|------------
//   0       | +3          | cell[0] = 3
//   1       | [           | Loop while cell[0] != 0:
//   2       | >           |   Move to cell[1]
//   3       | +1          |   cell[1]++
//   4       | <           |   Move back to cell[0]
//   5       | -1          |   cell[0]--
//   6       | ]           | Jump to addr 1 if cell[0] != 0
//   7       | .           | Output cell[0] (result: 0x00 after loop)
//
//   Result: cell[0]=0, cell[1]=3, outputs 0x00 from cell[0]
//
// Parameters:
//   DATA_W: Instruction width in bits (default 8)
//   DEPTH:  Number of memory locations (default 8, must be power of 2)
//
// Interfaces:
//   clk_i:   System clock (used for registered output)
//   rst_i:   Active-low reset
//   ren_i:   Read enable
//   raddr_i: Read address
//   rdata_o: Read data (valid 1 cycle after ren_i assertion)
//
// Note: Write port removed - ROM is not programmable

`timescale 1ns/1ps
module program_memory #(
    parameter integer DATA_W = 8,
    parameter integer DEPTH  = 8
) (
    input  wire                      clk_i,
    input  wire                      rst_i,    // Active-low reset
    // Read port only (write port removed)
    input  wire                      ren_i,
    input  wire [$clog2(DEPTH)-1:0]  raddr_i,
    output reg  [DATA_W-1:0]         rdata_o
);

    // ----------------------------
    // ROM Content (Combinational)
    // ----------------------------
    // Returns the program instruction for given address
    // This is a pure combinational function synthesized to gates
    function [DATA_W-1:0] rom_data;
        input [$clog2(DEPTH)-1:0] addr;
        begin
            case (addr)
                // Demo: Cell copy loop with I/O
                3'd0:  rom_data = 8'b010_00011;  // +3       cell[0] = 3
                3'd1:  rom_data = 8'b110_00101;  // [ +5     JZ forward 5 (to addr 6) if cell[0]==0
                3'd2:  rom_data = 8'b000_00001;  // >        move to cell[1]
                3'd3:  rom_data = 8'b010_00001;  // +1       cell[1]++
                3'd4:  rom_data = 8'b001_00001;  // <        move back to cell[0]
                3'd5:  rom_data = 8'b011_00001;  // -1       cell[0]--
                3'd6:  rom_data = 8'b111_11011;  // ] -5     JNZ back -5 (to addr 1) if cell[0]!=0
                3'd7:  rom_data = 8'b100_00000;  // .        output cell[0] (should be 0x00 after loop)
                // Note: After loop, cell[0]=0, cell[1]=3
                default: rom_data = 8'h00;       // Safety: HALT for unused addresses
            endcase
        end
    endfunction

    // ----------------------------
    // Synchronous Read (1-cycle latency)
    // ----------------------------
    // Registered output for consistent timing with previous RAM implementation
    always @(posedge clk_i or negedge rst_i) begin
        if (!rst_i) begin
            rdata_o <= {DATA_W{1'b0}};
        end else begin
            if (ren_i) begin
                rdata_o <= rom_data(raddr_i);
            end
            // If ren_i is low, rdata_o retains previous value
        end
    end

endmodule
