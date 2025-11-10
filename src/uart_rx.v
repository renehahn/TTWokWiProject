//=============================================================================
// uart_rx.v - TinyBF UART Receiver (8N1 Serial Input)
//=============================================================================
// Project:     TinyBF - Tiny Tapeout Sky 25B Brainfuck ASIC CPU
// Author:      René Hahn
// Date:        2025-11-10
// Version:     1.0
//
// Description:
//   Standard 8N1 UART receiver (1 start, 8 data LSB-first, 1 stop)
//   4-state FSM with 3-stage input synchronizer for metastability protection
//   16x oversampling for mid-bit sampling at tick 7 (center of each bit period)
//
// Parameters:
//   None
//
// Interfaces:
//   clk_i:           System clock
//   rst_i:           Active-low reset
//   baud_tick_16x_i: Baud rate tick (16x, from baud_gen)
//   rx_serial_i:     Serial input line
//   rx_data_o:       Received data byte (valid when rx_valid_o high)
//   rx_valid_o:      Data valid pulse (1 cycle)
//   rx_busy_o:       Busy flag (high during reception)

`timescale 1ns/1ps
module uart_rx (
    input  wire        clk_i,          // System clock
    input  wire        rst_i,          // Active-low reset
    input  wire        baud_tick_16x_i,// 16x oversampled baud tick
    input  wire        rx_serial_i,    // Serial input line
    output reg  [7:0]  rx_data_o,      // Received data byte
    output reg         rx_valid_o,     // Data valid pulse (1 cycle)
    output reg         rx_busy_o       // Busy flag
);

    // State encoding
    localparam [1:0] IDLE      = 2'b00;
    localparam [1:0] START_BIT = 2'b01;
    localparam [1:0] DATA_BITS = 2'b10;
    localparam [1:0] STOP_BIT  = 2'b11;

    // Metastability protection: 3-stage synchronizer
    reg [2:0] rx_sync;
    always @(posedge clk_i or negedge rst_i) begin
        if (!rst_i) begin
            rx_sync <= 3'b111;  // Idle high
        end else begin
            rx_sync <= {rx_sync[1:0], rx_serial_i};
        end
    end
    wire rx = rx_sync[2];  // Use final stage

    // Registers
    reg [1:0] state;
    reg [3:0] tick_cnt;     // 0-15 for 16x oversampling
    reg [2:0] bit_cnt;      // 0-7 for data bits
    reg [7:0] shift_reg;    // Shift register for data

    // FSM and datapath
    always @(posedge clk_i or negedge rst_i) begin
        if (!rst_i) begin
            state <= IDLE;
            tick_cnt <= 4'd0;
            bit_cnt <= 3'd0;
            shift_reg <= 8'd0;
            rx_data_o <= 8'd0;
            rx_valid_o <= 1'b0;
            rx_busy_o <= 1'b0;
        end else begin
            // Default: clear valid pulse
            rx_valid_o <= 1'b0;
            
            case (state)
                IDLE: begin
                    rx_busy_o <= 1'b0;
                    tick_cnt <= 4'd0;
                    bit_cnt <= 3'd0;
                    
                    // Detect start bit (falling edge) - ONLY when line is low
                    // and we're at a tick boundary to ensure clean detection
                    if (baud_tick_16x_i && !rx) begin
                        state <= START_BIT;
                        rx_busy_o <= 1'b1;
                        tick_cnt <= 4'd1;  // Start counting from 1
                    end
                end

                START_BIT: begin
                    if (baud_tick_16x_i) begin
                        tick_cnt <= tick_cnt + 1'b1;
                        
                        // Sample at middle of bit (tick 7 of 0-15)
                        if (tick_cnt == 4'd7) begin
                            if (!rx) begin
                                // Valid start bit confirmed
                                // Continue to tick 15, then move to DATA_BITS
                            end else begin
                                // False start bit (glitch), return to idle
                                state <= IDLE;
                                rx_busy_o <= 1'b0;
                            end
                        end else if (tick_cnt == 4'd15) begin
                            // End of start bit period, move to data bits
                            if (!rx || state == START_BIT) begin  // Recheck start bit was valid
                                state <= DATA_BITS;
                                tick_cnt <= 4'd0;
                            end else begin
                                state <= IDLE;
                                rx_busy_o <= 1'b0;
                            end
                        end
                    end
                end

                DATA_BITS: begin
                    if (baud_tick_16x_i) begin
                        tick_cnt <= tick_cnt + 1'b1;
                        
                        // Sample at middle of bit (tick 7 of 0-15)
                        if (tick_cnt == 4'd7) begin
                            // Sample data bit (LSB first)
                            shift_reg <= {rx, shift_reg[7:1]};
                            bit_cnt <= bit_cnt + 1'b1;
                        end else if (tick_cnt == 4'd15) begin
                            // End of bit period
                            tick_cnt <= 4'd0;
                            
                            // Check if all 8 bits received
                            if (bit_cnt == 3'd0) begin  // bit_cnt wraps to 0 after 7→8
                                state <= STOP_BIT;
                            end
                        end
                    end
                end

                STOP_BIT: begin
                    if (baud_tick_16x_i) begin
                        tick_cnt <= tick_cnt + 1'b1;
                        
                        // Sample stop bit at middle (tick 7)
                        if (tick_cnt == 4'd7) begin
                            if (rx) begin
                                // Valid stop bit - output data
                                rx_data_o <= shift_reg;
                                rx_valid_o <= 1'b1;
                            end
                            // Note: On framing error (stop bit low), data is discarded
                        end else if (tick_cnt == 4'd15) begin
                            // End of stop bit period - return to idle
                            state <= IDLE;
                            rx_busy_o <= 1'b0;
                            tick_cnt <= 4'd0;
                        end
                    end
                end

                default: begin
                    state <= IDLE;
                    rx_busy_o <= 1'b0;
                end
            endcase
        end
    end

endmodule
