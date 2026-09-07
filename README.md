# RISC-V Pipelined CPU

5-Stage Pipelined RV32I Processor in SystemVerilog

## Requirements
- **QuestaSim / ModelSim** (Intel FPGA Edition or standard) for simulation
- **Intel Quartus Prime** (Lite Edition 20.1+ or 24.1+) for FPGA synthesis
- **xPack RISC-V GCC Toolchain** (`riscv-none-elf-gcc`) with Python 3 for C program compilation

## Structure
- `RTL/` — Pipelined CPU core (Fetch, Decode, Execute, Memory, Writeback)
- `Testbench/` — Verification testbenches (ISA compliance suite & C application runner)
- `Debug/tests/` — Precompiled RISC-V architectural test vectors (`.hex`)
- `program.c` — Fibonacci reference program (`fib(19)`)
- `program2.c` — Pipeline hazard verification suite (Load-use, branch conditions, data hazards)
- `compile.bat` — Automated build script to compile C sources into memory hex files
- `run.do` — ModelSim/Questa simulation runner

## Compiling C Programs
Compile C source code into machine code hex images using the xPack GCC toolchain:
```bat
compile.bat
```

Script workflow:
1. Assembles minimal reset startup vector (`startup.s` initializes `sp = 1024` and calls `main`)
2. Links with bare-metal linker script (`linker.ld`) at base address `0x0` with `-O1`
3. Converts ELF binary to raw binary (`riscv-none-elf-objcopy`)
4. Converts little-endian 32-bit words into memory hex format (`.hex`)

Output:
```
Compiling program.c -> program.hex...
[OK] program.hex ready
Compiling program2.c -> program2.hex...
[OK] program2.hex ready

All programs built successfully.
```

## Running Simulation
```tcl
do run.do <mode>
```

Modes:
- `0` = Both (default)
- `1` = ISA Tests
- `2` = C Programs

## Verification & Testing

### 1. RV32I Architectural Compliance Suite
Automated regression suite executing 38 formal compliance test vectors covering all base integer instructions:

```
# PASS:    rv32ui-p-add.hex
# PASS:    rv32ui-p-addi.hex
# ...
# PASS:    rv32ui-p-xor.hex
# PASS:    rv32ui-p-xori.hex
# ==============================
#   38/38 passed
# ==============================
```

### 2. C Program Execution
Executes bare-metal C applications compiled with GCC:

```
# Running program.hex ...
# Registers: x1=8, x2=1024, x3=0, x10=4181, x11=0
# Return value (x10 / a0) = 4181 (0x00001055)
# RESULT: [PASS] fib(19) == 4181
# 
# Running program2.hex ...
# Registers: x1=8, x2=1024, x3=0, x10=1, x11=0
# Return value (x10 / a0) = 1 (0x00000001)
# RESULT: [PASS] program2 passed all hazard tests!
```

## Synthesis & FPGA Implementation
The processor was synthesized and analyzed using **Intel Quartus Prime Lite** targeting an **Intel Cyclone IV E** FPGA (`EP4CE115F29C7`):

| Parameter | Measured Value | Details / Conditions |
|---|---|---|
| **Target Device** | Intel Cyclone IV E (`EP4CE115F29C7`) | Reference evaluation board |
| **Max Frequency ($F_{\max}$)** | **86.63 MHz** | Worst-case corner (Slow 1200mV 85°C model) |
| **Nominal Frequency** | **94.43 MHz** | Typical condition (Slow 1200mV 0°C model) |
| **Logic Utilization** | ~18.5k Logic Elements | Distributed register implementation |

## Notes
- **5-Stage Pipeline**: Implements Fetch (IF), Decode (ID), Execute (EX), Memory (MEM), and Writeback (WB) stages.
- **Hazard Handling**:
  - Hardware load-use hazard detection unit stalling Fetch and Decode.
  - Full data forwarding networks (EX $\rightarrow$ EX, MEM $\rightarrow$ EX).
  - Branch and jump resolution in Execute stage triggering pipeline flush.
- **Architectural Trade-off**: The MEM stage utilizes combinational reads as a design trade-off to provide single-cycle data availability to Writeback without requiring additional load-delay stall cycles. Because Cyclone IV dedicated block RAM (M9K) requires synchronous clocked reads, data memory is inferred as distributed register storage (~9.0k registers), resulting in higher logic element utilization in exchange for simpler pipeline control.
