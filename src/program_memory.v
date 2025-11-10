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
//   Pre-loaded with test program
//   Write-first semantics (simultaneous read/write returns new data)
//   1-cycle read latency
//
// Initialization:
//   On reset, automatically loads a test program that exercises all 8 opcodes
//   Initialization takes DEPTH clock cycles (16 cycles for default config)
//
// Parameters:
//   DATA_W: Instruction width in bits (default 8)
//   DEPTH:  Number of memory locations (default 16, must be power of 2)
//
// Interfaces:
//   clk_i:   System clock
//   rst_i:   Active-low reset - triggers program initialization
//   wen_i:   Write enable (only effective after initialization completes)
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
    input  wire                      rst_i,  // Active-low reset for memory initialization
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

    // ROM-like initialization function for synthesizable default program
    // Returns the test program instruction for given address
    // SIMPLIFIED: 8 instructions only (reduced to save area)
    function [DATA_W-1:0] get_default_program;
        input [$clog2(DEPTH)-1:0] addr;
        begin
            case (addr)
                3'd0:  get_default_program = 8'b010_00101;  // + by 5   (cell[0] = 5)
                3'd1:  get_default_program = 8'b100_00000;  // .        (output cell[0])
                3'd2:  get_default_program = 8'b000_00001;  // >        (move to cell[1])
                3'd3:  get_default_program = 8'b010_00011;  // + by 3   (cell[1] = 3)
                3'd4:  get_default_program = 8'b100_00000;  // .        (output cell[1])
                3'd5:  get_default_program = 8'b111_11011;  // JNZ -5   (jump back if cell[1]!=0)
                3'd6:  get_default_program = 8'b101_00000;  // ,        (input to cell[1])
                default: get_default_program = 8'h00;       // HALT (addresses 7)
            endcase
        end
    endfunction

    // Memory initialization state machine
    reg init_done;
    reg [$clog2(DEPTH)-1:0] init_addr;

    // Synchronous reset, initialization, and write operations
    always @(posedge clk_i or negedge rst_i) begin
        if (!rst_i) begin
            init_done <= 1'b0;
            init_addr <= {$clog2(DEPTH){1'b0}};
        end else begin
            if (!init_done) begin
                // Priority: Initialization (blocks external writes)
                mem[init_addr] <= get_default_program(init_addr);
                if (init_addr == DEPTH - 1) begin
                    init_done <= 1'b1;
                end else begin
                    init_addr <= init_addr + 1'b1;
                end
            end else if (wen_i) begin
                // Only allow external writes after initialization completes
                mem[waddr_i] <= wdata_i;
            end
        end
    end

    // Synchronous read with write-first behavior
    always @(posedge clk_i or negedge rst_i) begin
        if (!rst_i) begin
            rdata_o <= {DATA_W{1'b0}};
        end else begin
            // Read operation with write-first semantics
            if (ren_i) begin
                if (wen_i && init_done && (waddr_i == raddr_i)) begin
                    // Write-first: return the data being written
                    rdata_o <= wdata_i;
                end else begin
                    // Normal read from memory
                    rdata_o <= mem[raddr_i];
                end
            end
            // Note: If ren_i is low, rdata_o retains its previous value
        end
    end

endmodule
