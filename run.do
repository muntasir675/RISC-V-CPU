set mode 0
if {[info exists 1]} { set mode $1 }

puts "\n  0 = Both (default)"
puts "  1 = ISA Tests"
puts "  2 = C Programs\n"

if {[file exists work]} { file delete -force work }
vlib work
vmap work work

vlog -sv -quiet RTL/Instructions.sv
vlog -sv -quiet RTL/FETCH.sv
vlog -sv -quiet RTL/DECODE.sv
vlog -sv -quiet RTL/EXECUTE.sv
vlog -sv -quiet RTL/MEMORY.sv
vlog -sv -quiet RTL/WRITEBACK.sv
vlog -sv -quiet RTL/CPU.sv

if {$mode == 1 || $mode == 0} {
    vlog -sv -quiet Testbench/Testbench.sv
    vsim -quiet -t 1ns work.Testbench
    run -all
}

if {$mode == 2 || $mode == 0} {
    vlog -sv -quiet Testbench/Run_program.sv
    vsim -quiet -t 1ns work.Run_program
    run -all
}
