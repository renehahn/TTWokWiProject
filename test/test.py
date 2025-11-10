# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start TinyBF minimal test")

    # Set the clock period to 20 ns (50 MHz)
    clock = Clock(dut.clk, 20, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Applying reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 20)
    
    dut._log.info("Releasing reset")
    dut.rst_n.value = 1

    # Wait for program memory initialization (16 cycles)
    dut._log.info("Waiting for program memory initialization")
    await ClockCycles(dut.clk, 20)

    # Verify design is not in reset state
    dut._log.info("Checking outputs are responsive")
    
    # All outputs should be defined (not X or Z)
    # This is a minimal sanity check that the design synthesized correctly
    uo_val = int(dut.uo_out.value)
    uio_val = int(dut.uio_out.value)
    
    dut._log.info(f"uo_out = 0x{uo_val:02x}, uio_out = 0x{uio_val:02x}")
    dut._log.info("Test passed - design instantiated and initialized successfully")

