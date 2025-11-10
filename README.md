![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

# TinyBF - Brainfuck CPU for Tiny Tapeout

TinyBF is a complete hardware implementation of a Brainfuck interpreter designed for ASIC fabrication through Tiny Tapeout. The design fits within a single tile and includes a full CPU with UART I/O capabilities and a hardcoded demonstration program.

## Features

- **Complete Brainfuck interpreter** with all 8 commands plus optimized instruction encoding
- **11-state FSM CPU core** with binary encoding for minimal gate count
- **16×8-bit ROM program memory** containing hardcoded demonstration program
- **8×8-bit RAM tape memory** (data cells) for program execution
- **Full UART subsystem** (TX/RX) at 38400 baud for I/O operations
- **Optimized instruction set** with 5-bit arguments for compact programs
- **Debug outputs** for program counter, data pointer, and cell values

## Quick Start

1. **Power on**: Release reset (`rst_n` high) - ROM is immediately ready
2. **Start execution**: Pulse `START` input (`ui[1]`)
3. **Send input**: Type lowercase letters via UART RX at 38400 baud, end with null (0x00)
4. **Monitor via UART**: Observe uppercase output on `UART_TX` (`uo[0]`)
5. **Debug**: Observe PC on `uo[5:2]`, DP on `uio[2:0]`, cell value on `{uo[7:6], uio[7:3]}`

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
- `uo[5:2]` - Program Counter [3:0] (addresses 0-15)
- `uo[7:6]` - Cell Value [6:5]

### Bidirectional (all outputs)
- `uio[2:0]` - Data Pointer [2:0]
- `uio[7:3]` - Cell Value [4:0]

## Hardcoded Program

The ROM contains a UART case converter demonstration (16 instructions):

```brainfuck
,      Read character from UART into cell[0]
>      Move to cell[1]
+10    cell[1] = 10 (newline character)
<      Back to cell[0]
[      Loop while cell[0] != 0:
-15      Subtract 15
-15      Subtract 15 (total -30)
-2       Subtract 2 (total -32, lowercase→uppercase)
.        Output converted character
,        Read next character
]      End loop
>      Move to cell[1]
.      Output newline (0x0A)
HALT   End of program
```

**Function:** Interactive UART-based case converter that converts lowercase ASCII to uppercase.

**Example Usage:**
- Input: `"abc"` followed by null (0x00)
- Output: `"ABC\n"`
- Conversion: 'a' (0x61) - 32 = 'A' (0x41), 'b' (0x62) - 32 = 'B' (0x42), etc.

**Features Demonstrated:**
1. UART input (`,` command) - reads characters from serial
2. UART output (`.` command) - writes characters to serial
3. Arithmetic operations - subtracts 32 via three decrements (-15, -15, -2)
4. Conditional loops (`[`, `]`) - processes until null terminator
5. Multi-cell usage - cell[0] for data, cell[1] for newline constant


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
