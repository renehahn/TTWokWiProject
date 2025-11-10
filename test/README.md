# Testbench for TinyBF Brainfuck CPU

This is a minimal testbench for the TinyBF Brainfuck CPU project. It uses [cocotb](https://docs.cocotb.org/en/stable/) to drive the DUT and verify basic functionality.
See below to get started or for more information, check the [website](https://tinytapeout.com/hdl/testing/).

## What this tests

The testbench performs a minimal sanity check:
- Instantiates the `tt_um_rh_bf_top` module (TinyBF board wrapper)
- Applies reset and waits for initialization
- Verifies outputs are responsive (not in X/Z state)

This is a **dummy test** to ensure the design compiles and instantiates correctly for CI/CD.

For comprehensive testing, see the advanced test suite in `/tb/` directory.

## Setting up

The Makefile is already configured with all necessary source files from `../src/`:
- `bf_board.v` - Tiny Tapeout board wrapper
- `bf_top.v` - TinyBF CPU top level
- `control_unit.v` - CPU core FSM
- `program_memory.v` - Instruction memory with default program
- `tape_memory.v` - Data tape memory
- `uart_rx.v` / `uart_tx.v` - UART I/O
- `baud_gen.v` - Baud rate generator
- `reset_sync.v` - Reset synchronizer

## How to run

To run the RTL simulation:

```sh
make -B
```

To run gatelevel simulation, first harden your project and copy `../runs/wokwi/results/final/verilog/gl/{your_module_name}.v` to `gate_level_netlist.v`.

Then run:

```sh
make -B GATES=yes
```

## How to view the VCD file

Using GTKWave
```sh
gtkwave tb.vcd tb.gtkw
```

Using Surfer
```sh
surfer tb.vcd
```
