@echo off
setlocal
cd /d "%~dp0"

call :build program
if errorlevel 1 goto :fail

call :build program2
if errorlevel 1 goto :fail

echo.
echo All programs built successfully.
exit /b 0

:build
set NAME=%1
echo Compiling %NAME%.c -^> %NAME%.hex...

echo .global _start > startup.s
echo _start: >> startup.s
echo     li sp, 1024 >> startup.s
echo     jal ra, main >> startup.s
echo     j . >> startup.s

echo SECTIONS { . = 0x0; .text : { startup.o(.text) *(.text) } } > linker.ld

riscv-none-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -c startup.s -o startup.o
if errorlevel 1 goto :cleanup
riscv-none-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -T linker.ld -O1 -o %NAME%.elf startup.o %NAME%.c
if errorlevel 1 goto :cleanup
riscv-none-elf-objcopy -O binary %NAME%.elf %NAME%.bin
if errorlevel 1 goto :cleanup

python -c "b=open('%NAME%.bin','rb').read(); open('%NAME%.hex','w').write('\n'.join('{:02x}{:02x}{:02x}{:02x}'.format(b[i+3],b[i+2],b[i+1],b[i]) for i in range(0,len(b),4)) + '\n')"

:cleanup
del /q startup.s linker.ld startup.o %NAME%.elf %NAME%.bin 2>nul
if exist %NAME%.hex (
    echo [OK] %NAME%.hex ready
    exit /b 0
) else (
    echo [ERROR] Failed to create %NAME%.hex
    exit /b 1
)

:fail
echo.
echo BUILD FAILED.
exit /b 1