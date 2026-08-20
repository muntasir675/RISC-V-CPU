# RISC-V-CPU

RISC-V processor implementation in SystemVerilog.
Implements a subset of RV32I with a 5-stage pipelined architecture.

## Structure
- `RTL/` — pipelined CPU RTL (fetch, decode, execute, memory, writeback)
- `Testbench/` — simulation testbenches
- `program.c` — Fibonacci test (`fib(19)`) compiled to `program.hex` and loaded into the CPU

## RV32I Test Suite
The `Debug/tests/` directories contain 37 RV32I compliance test vectors covering the base integer instruction set:
- **Arithmetic:** `add`, `addi`, `sub`, `lui`, `auipc`
- **Logic:** `and`, `andi`, `or`, `ori`, `xor`, `xori`
- **Shifts:** `sll`, `slli`, `srl`, `srli`, `sra`, `srai`
- **Comparison:** `slt`, `slti`, `sltiu`, `sltu`
- **Branches:** `beq`, `bne`, `blt`, `bge`, `bltu`, `bgeu`
- **Jumps:** `jal`, `jalr`
- **Memory:** `lb`, `lbu`, `lh`, `lhu`, `lw`, `sb`, `sh`, `sw`
- **Simple:** A minimal correctness smoke test

## Features
- RV32I base integer instruction set
- 5-stage pipeline with hazard detection and data forwarding
- Simulated with ModelSim/Questa
