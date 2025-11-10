//=============================================================================
// bf_board.v - TinyBF Tiny Tapeout Board-Level Interface
//=============================================================================
// Project:     TinyBF - Tiny Tapeout Sky 25B Brainfuck ASIC CPU
// Author:      René Hahn
// Date:        2025-11-10
// Version:     1.0
//
// Description:
//   Tiny Tapeout board interface for TinyBF Brainfuck CPU
//   Maps Tiny Tapeout standard I/O pins to bf_top module interface
//   Program is pre-loaded in program_memory.v (no external programming)
//
// Pin Mapping:
//   Dedicated Inputs (ui_in):
//     ui[0]:     UART RX serial input (for Brainfuck ',' input command)
//     ui[1]:     Start execution (pulse high to begin from PC=0)
//     ui[2]:     Halt execution (pulse high to stop)
//     ui[7:3]:   Unused
//
//   Bidirectional I/O (uio) - All outputs:
//     uio[2:0]:  Data pointer [2:0] (3-bit tape address)
//     uio[7:3]:  Current cell value [4:0] (lower 5 bits)
//
//   Dedicated Outputs (uo_out):
//     uo[0]:     UART TX serial output (for Brainfuck '.' output command)
//     uo[1]:     CPU busy status (high when executing)
//     uo[4:2]:   Program counter [2:0]
//     uo[5]:     Unused (was PC[3])
//     uo[7:6]:   Current cell value [6:5] (upper 2 bits)
//=============================================================================

`default_nettype none

module tt_um_rh_bf_top (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    //=========================================================================
    // Parameters - REDUCED FOR AREA OPTIMIZATION
    //=========================================================================
    localparam ADDR_W = 3;              // 8 program memory locations (reduced from 16)
    localparam TAPE_ADDR_W = 3;         // 8 tape cells
    localparam CLK_FREQ = 50000000;     // 50 MHz system clock
    localparam BAUD_RATE = 38400;       // UART baud rate (reduced from 115200)

    //=========================================================================
    // Internal Signals
    //=========================================================================
    wire [2:0] pc;              // Program counter (3-bit, reduced from 4-bit)
    wire [2:0] dp;              // Data pointer
    wire [7:0] cell_data;       // Current cell value
    wire       cpu_busy;        // CPU busy status

    //=========================================================================
    // Bidirectional I/O Control
    //=========================================================================
    // All bidirectional pins configured as outputs for debug visibility
    assign uio_oe = 8'b11111111;

    //=========================================================================
    // Bidirectional I/O Output Assignment
    //=========================================================================
    assign uio_out[2:0] = dp;              // Data pointer [2:0] (full 3-bit tape address)
    assign uio_out[7:3] = cell_data[4:0];  // Current cell value [4:0] (lower 5 bits)

    //=========================================================================
    // Dedicated Output Assignment
    //=========================================================================
    assign uo_out[1]   = cpu_busy;         // CPU busy status
    assign uo_out[4:2] = pc;               // Program counter [2:0] (3-bit, reduced from 4-bit)
    assign uo_out[5]   = 1'b0;             // Unused (was pc[3])
    assign uo_out[7:6] = cell_data[6:5];   // Current cell value [6:5] (upper 2 bits)

    //=========================================================================
    // BF Top Module Instantiation
    //=========================================================================
    bf_top #(
        .ADDR_W      (ADDR_W),
        .TAPE_ADDR_W (TAPE_ADDR_W),
        .CLK_FREQ    (CLK_FREQ),
        .BAUD_RATE   (BAUD_RATE)
    ) u_bf_core (
        // Clock and reset
        .clk_i         (clk),
        .rst_i         (rst_n),        // Active-low reset
        
        // UART interface
        .uart_rx_i     (ui_in[0]),     // UART RX from ui[0]
        .uart_tx_o     (uo_out[0]),    // UART TX to uo[0]
        
        // CPU control
        .start_i       (ui_in[1]),     // Start execution from ui[1]
        .halt_i        (ui_in[2]),     // Halt execution from ui[2]
        
        // Debug outputs
        .pc_o          (pc),           // Program counter to uo[4:2]
        .dp_o          (dp),           // Data pointer to uio[2:0]
        .cell_data_o   (cell_data),    // Cell data to uio[7:3] and uo[7:6]
        .cpu_busy_o    (cpu_busy)      // CPU busy to uo[1]
    );

    //=========================================================================
    // Unused Signal Suppression
    //=========================================================================
    wire _unused = &{ena, ui_in[7:3], uio_in[7:0], cell_data[7], 1'b0};

endmodule

`default_nettype wire
