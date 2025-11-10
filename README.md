![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

# TinyBF - Brainfuck CPU for Tiny Tapeout

TinyBF is a complete hardware implementation of a Brainfuck interpreter designed for ASIC fabrication through Tiny Tapeout. The design fits within a single tile and includes a full CPU with UART I/O capabilities and a hardcoded demonstration program.

## Features

- **Complete Brainfuck interpreter** with all 8 commands plus optimized instruction encoding
- **11-state FSM CPU core** with binary encoding for minimal gate count
- **8×8-bit ROM program memory** containing hardcoded demonstration program
- **8×8-bit RAM tape memory** (data cells) for program execution
- **Full UART subsystem** (TX/RX) at 38400 baud for I/O operations
- **Optimized instruction set** with 5-bit arguments for compact programs
- **Debug outputs** for program counter, data pointer, and cell values

## Quick Start

1. **Power on**: Release reset (`rst_n` high) - ROM is immediately ready
2. **Start execution**: Pulse `START` input (`ui[1]`)
3. **Monitor via UART**: Connect to `UART_TX` (`uo[0]`) at 38400 baud
4. **Debug**: Observe PC on `uo[4:2]`, DP on `uio[2:0]`, cell value on `{uo[7:6], uio[7:3]}`

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
- `uo[4:2]` - Program Counter [2:0] (addresses 0-7)
- `uo[5]` - Unused (was PC[3])
- `uo[7:6]` - Cell Value [6:5]

### Bidirectional (all outputs)
- `uio[2:0]` - Data Pointer [2:0]
- `uio[7:3]` - Cell Value [4:0]

## Hardcoded Program

The ROM contains a cell copy loop demonstration:

```brainfuck
+3     cell[0] = 3
[      Loop while cell[0] != 0:
>        Move to cell[1]
+        cell[1]++
<        Move back to cell[0]
-        cell[0]--
]      End loop
.      Output cell[0] (= 0x00)
```

**Result:** Copies value 3 from cell[0] to cell[1], outputs 0x00 via UART.

**Program Flow:**
1. Initialize cell[0] = 3
2. Loop 3 times: increment cell[1], decrement cell[0]
3. After loop: cell[0]=0, cell[1]=3
4. Output cell[0] (0x00) via UART TX


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
