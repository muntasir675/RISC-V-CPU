@echo off
setlocal
cd /d "%~dp0"

echo ============================================
echo  RISC-V program build
echo  Working dir: %cd%
echo ============================================

echo.
echo [1/7] Remove previous program.hex
if exist program.hex del /q program.hex

echo [2/7] Generate startup.s
> startup.s (
    echo .global _start
    echo _start:
    echo     li sp, 1024
    echo     jal ra, main
    echo     j .
)

echo [3/7] Generate linker.ld
echo SECTIONS { . = 0x0; .text : { startup.o^(.text^) *^(.text^) } }> linker.ld

echo [4/7] Compile startup.s -^> startup.o
where riscv-none-elf-gcc >nul 2>&1
if errorlevel 1 (
    echo ERROR: riscv-none-elf-gcc not found on PATH
    goto :error
)
riscv-none-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -c startup.s -o startup.o
if errorlevel 1 goto :error

echo [5/7] Link program.elf
riscv-none-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -T linker.ld -O1 -o program.elf startup.o program.c
if errorlevel 1 goto :error

echo [6/7] Convert to program.hex
riscv-none-elf-objcopy -O binary program.elf program.bin
if errorlevel 1 goto :error

> bin2hex.py (
    echo import sys
    echo data = open^('program.bin', 'rb'^).read^()
    echo for i in range^(0, len^(data^), 4^):
    echo     b = data[i:i+4].ljust^(4, b'\x00'^)
    echo     print^('{:02x}{:02x}{:02x}{:02x}'.format^(b[3], b[2], b[1], b[0]^)^)
)
python3 bin2hex.py > program.hex
if errorlevel 1 goto :error

echo [7/7] Clean up temp files
del /q startup.s linker.ld startup.o program.elf program.bin bin2hex.py

echo.
echo Done. program.hex written.
exit /b 0

:error
echo.
echo BUILD FAILED.
exit /b 1