![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

# TinyBF - Brainfuck CPU for Tiny Tapeout

TinyBF is a complete hardware implementation of a Brainfuck interpreter designed for ASIC fabrication through Tiny Tapeout. The design fits within a single tile and includes a full CPU with UART I/O capabilities.

## Features

- **Complete Brainfuck interpreter** with all 8 commands plus optimized instruction encoding
- **11-state FSM CPU core** with one-hot encoding
- **16×8-bit program memory** for storing compiled Brainfuck programs
- **8×8-bit tape memory** (data cells) for program execution
- **Full UART subsystem** (TX/RX) at 115200 baud for I/O operations
- **Optimized instruction set** with 5-bit arguments for compact programs
- **Debug outputs** for program counter, data pointer, and cell values

## Quick Start

1. **Power on**: Release reset (`rst_n` high)
2. **Start execution**: Pulse `START` input (`ui[1]`)
3. **Monitor via UART**: Connect to `UART_TX` (`uo[0]`) at 115200 baud
4. **Debug**: Observe PC on `uo[5:2]`, DP on `uio[2:0]`, cell value on `{uo[7:6], uio[7:3]}`

## Documentation

- **[Detailed documentation](docs/info.md)** - Complete project description, architecture, and usage guide
- **[Pin assignments](info.yaml)** - Full pinout configuration

## Pin Mapping

### Inputs
- `ui[0]` - UART RX (serial input for `,` command)
- `ui[1]` - START (begin execution)
- `ui[2]` - HALT (stop execution)

### Outputs  
- `uo[0]` - UART TX (serial output for `.` command)
- `uo[1]` - CPU_BUSY (execution status)
- `uo[5:2]` - Program Counter [3:0]
- `uo[7:6]` - Cell Value [6:5]

### Bidirectional (all outputs)
- `uio[2:0]` - Data Pointer [2:0]
- `uio[7:3]` - Cell Value [4:0]

## Current Status

This version includes a pre-loaded test program that exercises all 8 Brainfuck opcodes. The program is loaded into memory automatically during the reset.

**Test Program Flow:**
1. Initialize cells with values using `+` and `-`
2. Navigate tape using `>` and `<`
3. Output a byte via UART using `.`
4. Wait for input via UART using `,`
5. Demonstrate conditional jumps using `[` (JZ) and `]` (JNZ)
6. End with HALT instruction

**Startup Sequence:**
- On power-up/reset, the CPU waits 16 clock cycles while program memory initializes
- After initialization, pulse START to begin execution
- The program demonstrates cell arithmetic, data pointer movement, UART I/O, and loop control

Future enhancements will include UART-based dynamic program loading.

## What is Tiny Tapeout?

Tiny Tapeout is an educational project that aims to make it easier and cheaper than ever to get your digital and analog designs manufactured on a real chip.

To learn more and get started, visit https://tinytapeout.com.

## Resources

- [FAQ](https://tinytapeout.com/faq/)
- [Digital design lessons](https://tinytapeout.com/digital_design/)
- [Learn how semiconductors work](https://tinytapeout.com/siliwiz/)
- [Join the community](https://tinytapeout.com/discord)
- [Build your design locally](https://www.tinytapeout.com/guides/local-hardening/)

## Author

René Hahn - 2025
