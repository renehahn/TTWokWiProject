<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

TinyBF is a complete hardware implementation of a Brainfuck interpreter designed to fit within the constraints of a single Tiny Tapeout tile. The design is a fully functional CPU with integrated UART I/O, allowing it to execute Brainfuck programs and communicate with external devices.

### Architecture

The system consists of five main components:

1. **Control Unit** - An 11-state finite state machine (FSM) that serves as the CPU core. It fetches instructions, decodes them, and orchestrates all operations including memory access and I/O. The FSM uses one-hot encoding for optimal gate count.

2. **Program Memory** - 16×8-bit synchronous RAM storing up to 16 Brainfuck instructions. Each instruction is encoded as an 8-bit value: 3 bits for the opcode and 5 bits for a signed argument (enabling optimizations like `+5` instead of five separate `+` instructions).

3. **Tape Memory** - 8×8-bit synchronous RAM representing the Brainfuck data tape with 8 cells. This is the working memory where Brainfuck programs manipulate data.

4. **UART Subsystem** - Includes both transmitter and receiver modules operating at 115200 baud. The UART handles Brainfuck's I/O commands: `.` (output) sends bytes via TX, and `,` (input) receives bytes via RX. A baud rate generator provides precise timing.

5. **Reset Synchronizer** - Ensures clean reset propagation across clock domains to prevent metastability issues.

### Instruction Set

TinyBF implements all eight Brainfuck commands plus an optimized instruction encoding:

| Opcode | Command | Description | Argument |
|--------|---------|-------------|----------|
| 000 | `>` | Increment data pointer | Signed offset (-16 to +15) |
| 001 | `<` | Decrement data pointer | Signed offset (-16 to +15) |
| 010 | `+` | Increment cell value | Amount (0 to 31) |
| 011 | `-` | Decrement cell value | Amount (0 to 31) |
| 100 | `.` | Output cell via UART | N/A |
| 101 | `,` | Input from UART to cell | N/A |
| 110 | `[` | Jump forward if zero | PC-relative offset |
| 111 | `]` | Jump backward if non-zero | PC-relative offset |

**Special:** The instruction `0x00` acts as a HALT, cleanly stopping program execution.

The 5-bit argument field enables compact encoding of common patterns. For example, incrementing a cell by 5 requires just one instruction instead of five, reducing both program size and execution time.

### Memory Timing

Both memories use synchronous reads with 1-cycle latency. The control unit explicitly manages this through dedicated wait states: when initiating a read, the FSM transitions through a WAIT state before the data becomes valid, ensuring correct synchronization without combinational paths through memory.

## How to test

### Pin Configuration

**Inputs:**
- `ui[0]` - UART RX: Serial input for Brainfuck `,` command (115200 baud, 8N1)
- `ui[1]` - START: Pulse high to begin program execution from address 0
- `ui[2]` - HALT: Pulse high to stop execution immediately

**Outputs:**
- `uo[0]` - UART TX: Serial output for Brainfuck `.` command (115200 baud, 8N1)
- `uo[1]` - CPU_BUSY: High when CPU is actively executing
- `uo[5:2]` - Program counter bits [3:0]: Current instruction address
- `uo[7:6]` - Cell value bits [6:5]: Upper 2 bits of current cell

**Bidirectional (configured as outputs):**
- `uio[2:0]` - Data pointer [2:0]: Current tape position (0-7)
- `uio[7:3]` - Cell value bits [4:0]: Lower 5 bits of current cell

### Testing Procedure

1. **Power-up and Reset**: Apply power and ensure `rst_n` is asserted low, then released high. The CPU will enter IDLE state.

2. **Load Program**: In this version, programs are pre-loaded into program memory during synthesis. Future versions will support dynamic programming via UART.

3. **Start Execution**: Pulse the START input (`ui[1]`) high for at least one clock cycle. The CPU will begin fetching and executing instructions from address 0.

4. **Monitor Execution**: 
   - Watch `CPU_BUSY` (`uo[1]`) to see when the program is running
   - Observe the program counter on `uo[5:2]` to track instruction flow
   - Monitor the data pointer on `uio[2:0]` and cell value on `{uo[7:6], uio[7:3]}` to see data manipulation

5. **UART Communication**:
   - Connect a UART terminal to `ui[0]` (RX) and `uo[0]` (TX) at 115200 baud, 8N1 format
   - When the program executes a `,` command, it will wait for input on the RX line
   - When the program executes a `.` command, it will transmit the current cell value on the TX line

6. **Program Completion**: The program halts when it executes a `0x00` instruction or when you pulse the HALT input (`ui[2]`).


## External hardware

**Required:**
- UART controller for serial communication
  - Connect TinyBF's TX (`uo[0]`) to converter's RX
  - Connect TinyBF's RX (`ui[0]`) to converter's TX
  - Configure terminal software for 115200 baud, 8 data bits, no parity, 1 stop bit (8N1)

**Optional:**
- Logic analyzer or oscilloscope to monitor debug outputs (program counter, data pointer, cell values)
- Push button for manual START/HALT control
