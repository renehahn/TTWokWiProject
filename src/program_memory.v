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
//   Character case converter: lowercase → uppercase via UART
//   Demonstrates: Input, arithmetic, conditional, output
//   Address | Instruction | Description
//   --------|-------------|------------
//   0       | ,           | Read character from UART into cell[0]
//   1       | >           | Move to cell[1] (working cell)
//   2       | +10         | cell[1] = 10 (newline character)
//   3       | <           | Back to cell[0]
//   4       | [           | Loop while cell[0] != 0 (not null):
//   5       | -15         | Subtract 15
//   6       | -15         | Subtract 15 (total -30)
//   7       | -2          | Subtract 2 more (total -32: lowercase→uppercase)
//   8       | .           | Output converted character via UART
//   9       | ,           | Read next character
//   10      | ]           | Jump back if cell[0] != 0
//   11      | >           | Move to cell[1]
//   12      | .           | Output newline (10)
//   13-15   | HALT        | Safety: halt at end
//
//   Example: Input "abc" → Output "ABC\n"
//   - Reads characters via UART RX (,)
//   - Converts lowercase to uppercase by subtracting 32 (via -15, -15, -2)
//   - Outputs via UART TX (.)
//   - Ends with newline
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
//=============================================================================

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
                // Demo: UART case converter (lowercase → UPPERCASE)
                // Shows: Input (,), Output (.), Arithmetic (-32 via -15 and -15 and -2), Loops ([])
                4'd0:  rom_data = 8'b101_00000;  // ,        Read character from UART into cell[0]
                4'd1:  rom_data = 8'b000_00001;  // >        Move to cell[1]
                4'd2:  rom_data = 8'b010_01010;  // +10      cell[1] = 10 (newline character)
                4'd3:  rom_data = 8'b001_00001;  // <        Move back to cell[0]
                4'd4:  rom_data = 8'b110_00110;  // [ +6     JZ forward 6 (to addr 10) if cell[0]==0
                4'd5:  rom_data = 8'b011_01111;  // -15      Subtract 15
                4'd6:  rom_data = 8'b011_01111;  // -15      Subtract 15 (total -30, close to -32)
                4'd7:  rom_data = 8'b011_00010;  // -2       Subtract 2 more (total -32)
                4'd8:  rom_data = 8'b100_00000;  // .        Output converted character
                4'd9:  rom_data = 8'b101_00000;  // ,        Read next character
                4'd10: rom_data = 8'b111_11010;  // ] -6     JNZ back -6 (to addr 4) if cell[0]!=0
                4'd11: rom_data = 8'b000_00001;  // >        Move to cell[1] (newline)
                4'd12: rom_data = 8'b100_00000;  // .        Output newline
                4'd13: rom_data = 8'h00;         // HALT     End of program
                4'd14: rom_data = 8'h00;         // HALT
                4'd15: rom_data = 8'h00;         // HALT
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
