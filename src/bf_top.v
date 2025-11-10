//=============================================================================
// bf_top.v - TinyBF CPU Top Level Module
//=============================================================================
// Project:     TinyBF - Tiny Tapeout Sky 25B Brainfuck ASIC CPU
// Author:      René Hahn
// Date:        2025-11-10
// Version:     2.0
//
// Description:
//   Complete Brainfuck interpreter for ASIC implementation
//   Integrates: CPU core, ROM program memory, tape memory, UART (TX/RX), baud generator
//   Program is hardcoded in ROM - no external programming interface
//
// Parameters:
//   ADDR_W:      Program memory address width (default 4 = 16 instructions)
//   TAPE_ADDR_W: Data tape address width (default 3 = 8 cells)
//   CLK_FREQ:    System clock frequency in Hz (default 50MHz)
//   BAUD_RATE:   UART baud rate in bps (default 38400)
// 
// Interfaces:
//   clk_i:        System clock input
//   rst_i:        Asynchronous active-low reset input
//   uart_rx_i:    UART receive line input
//   uart_tx_o:    UART transmit line output    
//   start_i:      Start program execution input (pulse)
//   halt_i:       Halt execution input (pulse)
//   pc_o:         Program counter output (for debugging)
//   dp_o:         Data pointer output (for debugging)
//   cell_data_o:  Current cell value output (for debugging)
//   cpu_busy_o:   CPU busy status output (for debugging)
//=============================================================================

`timescale 1ns/1ps
module bf_top #(
    parameter ADDR_W = 4,              // Program address width (16 entries)
    parameter TAPE_ADDR_W = 3,         // Tape address width (8 cells)
    parameter CLK_FREQ = 50000000,     // System clock frequency (Hz)
    parameter BAUD_RATE = 38400        // UART baud rate (reduced from 115200 to save area)
)(
    // Clock and reset
    input  wire                  clk_i,
    input  wire                  rst_i,        // Asynchronous active-low reset
    
    // UART interface
    input  wire                  uart_rx_i,    // UART receive line
    output wire                  uart_tx_o,    // UART transmit line
    
    // CPU control
    input  wire                  start_i,      // Start program execution (pulse)
    input  wire                  halt_i,       // Halt execution (pulse)
    
    // Debug outputs
    output wire [ADDR_W-1:0]     pc_o,         // Program counter
    output wire [TAPE_ADDR_W-1:0] dp_o,        // Data pointer
    output wire [7:0]            cell_data_o,  // Current cell value
    output wire                  cpu_busy_o    // CPU is executing
);

    // Constant widths for instruction and cell data
    localparam INSTR_W = 8;
    localparam CELL_W = 8;

    //========================================================================
    // Internal Signals
    //========================================================================
    
    // Synchronized reset
    wire sync_rst_n;
    
    // Baud rate ticks
    wire tick_1x;        // 1x baud tick for TX
    wire tick_16x;       // 16x oversampled tick for RX
    
    // Program memory interface (ROM - read only)
    wire [ADDR_W-1:0]     prog_raddr;
    wire                  prog_ren;
    wire [INSTR_W-1:0]    prog_rdata;
    
    // Tape memory read interface
    wire [TAPE_ADDR_W-1:0] tape_raddr;
    wire                   tape_ren;
    wire [CELL_W-1:0]      tape_rdata;
    
    // Tape memory write interface
    wire [TAPE_ADDR_W-1:0] tape_waddr;
    wire                   tape_wen;
    wire [CELL_W-1:0]      tape_wdata;
    
    // UART TX interface
    wire [7:0]  tx_data;
    wire        tx_start;
    wire        tx_busy;
    
    // UART RX interface
    wire [7:0]  rx_data;
    wire        rx_valid;
    /* verilator lint_off UNUSEDSIGNAL */
    wire        rx_ready;   // CPU ready to accept RX data (internal handshaking)
    wire        rx_busy;    // UART RX busy (internal status)
    /* verilator lint_on UNUSEDSIGNAL */

    //========================================================================
    // Reset Synchronization
    //========================================================================
    
    reset_sync u_reset_sync (
        .clk_i         (clk_i),
        .async_rst_i   (rst_i),
        .sync_rst_o    (sync_rst_n)
    );

    //========================================================================
    // Baud Rate Generator
    //========================================================================
    // Generates timing ticks for UART:
    //   - tick_16x: 16x oversampled for RX (mid-bit sampling)
    //   - tick_1x: 1x baud rate for TX (bit timing)
    
    baud_gen #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) u_baud_gen (
        .clk_i      (clk_i),
        .rst_i      (sync_rst_n),
        .tick_16x_o (tick_16x),
        .tick_1x_o  (tick_1x)
    );

    //========================================================================
    // UART Transmitter
    //========================================================================
    // 8N1 format: 1 start bit, 8 data bits (LSB first), 1 stop bit
    
    uart_tx u_uart_tx (
        .clk_i        (clk_i),
        .rst_i        (sync_rst_n),
        .baud_tick_i  (tick_1x),
        .tx_start_i   (tx_start),
        .tx_data_i    (tx_data),
        .tx_serial_o  (uart_tx_o),
        .tx_busy_o    (tx_busy)
    );

    //========================================================================
    // UART Receiver
    //========================================================================
    // 8N1 format: 1 start bit, 8 data bits (LSB first), 1 stop bit
    
    uart_rx u_uart_rx (
        .clk_i           (clk_i),
        .rst_i           (sync_rst_n),
        .baud_tick_16x_i (tick_16x),
        .rx_serial_i     (uart_rx_i),
        .rx_data_o       (rx_data),
        .rx_valid_o      (rx_valid),
        .rx_busy_o       (rx_busy)
    );

    //========================================================================
    // Program Memory (ROM - Read Only)
    //========================================================================
    // Stores Brainfuck instructions
    
    program_memory #(
        .DATA_W (INSTR_W),
        .DEPTH  (1 << ADDR_W)
    ) u_prog_mem (
        .clk_i   (clk_i),
        .rst_i   (sync_rst_n),
        .ren_i   (prog_ren),
        .raddr_i (prog_raddr),
        .rdata_o (prog_rdata)
    );

    //========================================================================
    // Tape Memory
    //========================================================================
    // Stores data cells for Brainfuck tape
    
    tape_memory #(
        .CELL_W (CELL_W),
        .DEPTH  (1 << TAPE_ADDR_W)
    ) u_tape_mem (
        .clk_i   (clk_i),
        .rst_i   (sync_rst_n),
        .ren_i   (tape_ren),
        .raddr_i (tape_raddr),
        .rdata_o (tape_rdata),
        .wen_i   (tape_wen),
        .waddr_i (tape_waddr),
        .wdata_i (tape_wdata)
    );

    //========================================================================
    // CPU Core (Control Unit)
    //========================================================================
    
    control_unit #(
        .ADDR_W      (ADDR_W),
        .INSTR_W     (INSTR_W),
        .CELL_W      (CELL_W),
        .TAPE_ADDR_W (TAPE_ADDR_W)
    ) u_cpu (
        .clk_i            (clk_i),
        .rst_i            (sync_rst_n),
        
        // Program memory interface
        .prog_raddr_o     (prog_raddr),
        .prog_ren_o       (prog_ren),
        .prog_rdata_i     (prog_rdata),
        
        // Tape memory read interface
        .tape_addr_r_o    (tape_raddr),
        .tape_ren_o       (tape_ren),
        .tape_rdata_i     (tape_rdata),
        
        // Tape memory write interface
        .tape_addr_w_o    (tape_waddr),
        .tape_wen_o       (tape_wen),
        .tape_wdata_o     (tape_wdata),
        
        // UART TX interface
        .uart_tx_byte_o   (tx_data),
        .uart_tx_start_o  (tx_start),
        .uart_tx_busy_i   (tx_busy),
        
        // UART RX interface
        .uart_rx_byte_i   (rx_data),
        .uart_rx_valid_i  (rx_valid),
        .uart_rx_ready_o  (rx_ready),
        
        // Control
        .start_run_i      (start_i),
        .halt_i           (halt_i),
        
        // Debug outputs
        .pc_out_o         (pc_o),
        .dp_out_o         (dp_o),
        .cell_out_o       (cell_data_o)
    );

    //========================================================================
    // CPU Busy Detection
    //========================================================================
    // Derive busy status from CPU outputs
    // CPU is busy when it's accessing memory or UART
    
    assign cpu_busy_o = prog_ren || tape_ren || tape_wen || tx_start || tx_busy || rx_busy;

endmodule
