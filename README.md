# RISC-V-CPU

RISC-V processor implementation in SystemVerilog.
Implements a subset of RV32I with both single-cycle and 5-stage pipelined architectures.

## Structure
- `CPU/` — Single-cycle CPU (fetch, decode, execute, memory, writeback)
- `CPU_Pipelined/` — 5-stage pipelined CPU with hazard detection and forwarding
- `program.c` — Fibonacci test (`fib(19)`) compiled to `program.hex` and loaded into the CPU

## Features
- RV32I base integer instruction set
- 5-stage pipeline with hazard detection and data forwarding
- Simulated with ModelSim/Questa
