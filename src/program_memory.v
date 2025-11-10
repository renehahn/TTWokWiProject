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
// Default Program (16 instructions):
//   Demonstrates a more complex cell manipulation program
//   Address | Instruction | Description
//   --------|-------------|------------
//   0       | +3          | cell[0] = 3
//   1       | [           | Loop while cell[0] != 0:
//   2       | >           |   Move to cell[1]
//   3       | +1          |   cell[1]++
//   4       | <           |   Move back to cell[0]
//   5       | -1          |   cell[0]--
//   6       | ]           | Jump to addr 1 if cell[0] != 0
//   7       | >           | Move to cell[1] (result)
//   8       | [           | Loop while cell[1] != 0:
//   9       | >           |   Move to cell[2]
//   10      | +1          |   cell[2]++
//   11      | <           |   Move back to cell[1]
//   12      | -1          |   cell[1]--
//   13      | ]           | Jump to addr 8 if cell[1] != 0
//   14      | >           | Move to cell[2]
//   15      | .           | Output cell[2] (result: 0x03)
//
//   Result: cell[0]=0, cell[1]=0, cell[2]=3, outputs 0x03 from cell[2]
//
// Parameters:
//   DATA_W: Instruction width in bits (default 8)
//   DEPTH:  Number of memory locations (default 16, must be power of 2)
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
    parameter integer DEPTH  = 16
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
                // Demo: Nested loop copying cell[0] → cell[1] → cell[2]
                4'd0:  rom_data = 8'b010_00011;  // +3       cell[0] = 3
                4'd1:  rom_data = 8'b110_00101;  // [ +5     JZ forward 5 (to addr 6) if cell[0]==0
                4'd2:  rom_data = 8'b000_00001;  // >        move to cell[1]
                4'd3:  rom_data = 8'b010_00001;  // +1       cell[1]++
                4'd4:  rom_data = 8'b001_00001;  // <        move back to cell[0]
                4'd5:  rom_data = 8'b011_00001;  // -1       cell[0]--
                4'd6:  rom_data = 8'b111_11011;  // ] -5     JNZ back -5 (to addr 1) if cell[0]!=0
                4'd7:  rom_data = 8'b000_00001;  // >        move to cell[1]
                4'd8:  rom_data = 8'b110_00101;  // [ +5     JZ forward 5 (to addr 13) if cell[1]==0
                4'd9:  rom_data = 8'b000_00001;  // >        move to cell[2]
                4'd10: rom_data = 8'b010_00001;  // +1       cell[2]++
                4'd11: rom_data = 8'b001_00001;  // <        move back to cell[1]
                4'd12: rom_data = 8'b011_00001;  // -1       cell[1]--
                4'd13: rom_data = 8'b111_11011;  // ] -5     JNZ back -5 (to addr 8) if cell[1]!=0
                4'd14: rom_data = 8'b000_00001;  // >        move to cell[2]
                4'd15: rom_data = 8'b100_00000;  // .        output cell[2] (should be 0x03)
                // Note: After loops, cell[0]=0, cell[1]=0, cell[2]=3
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
