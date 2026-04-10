# ── paths ─────────────────────────────────────────────────────────────────────
set test_dir "Debug/tests"
set hex_dest "Testbench/program.hex"
set work_dir "Debug/work"

# ── test list (name + description) ────────────────────────────────────────────
set tests {
    rv32ui_smoke                                "Basic sanity check"
    rv32ui_add                                  "ADD   - register addition"
    rv32ui_add_immediate                        "ADDI  - add immediate"
    rv32ui_subtract                             "SUB   - register subtraction"
    rv32ui_bitwise_and                          "AND   - bitwise and"
    rv32ui_bitwise_and_immediate                "ANDI  - bitwise and immediate"
    rv32ui_bitwise_or                           "OR    - bitwise or"
    rv32ui_bitwise_or_immediate                 "ORI   - bitwise or immediate"
    rv32ui_bitwise_xor                          "XOR   - bitwise xor"
    rv32ui_bitwise_xor_immediate                "XORI  - bitwise xor immediate"
    rv32ui_shift_left_logical                   "SLL   - shift left logical"
    rv32ui_shift_left_logical_immediate         "SLLI  - shift left logical immediate"
    rv32ui_shift_right_logical                  "SRL   - shift right logical"
    rv32ui_shift_right_logical_immediate        "SRLI  - shift right logical immediate"
    rv32ui_shift_right_arithmetic               "SRA   - shift right arithmetic"
    rv32ui_shift_right_arithmetic_immediate     "SRAI  - shift right arithmetic immediate"
    rv32ui_set_less_than                        "SLT   - set less than"
    rv32ui_set_less_than_immediate              "SLTI  - set less than immediate"
    rv32ui_set_less_than_unsigned               "SLTU  - set less than unsigned"
    rv32ui_set_less_than_unsigned_immediate     "SLTIU - set less than unsigned immediate"
    rv32ui_load_upper_immediate                 "LUI   - load upper immediate"
    rv32ui_add_upper_immediate_to_pc            "AUIPC - add upper immediate to PC"
    rv32ui_jump_and_link                        "JAL   - jump and link"
    rv32ui_jump_and_link_register               "JALR  - jump and link register"
    rv32ui_branch_equal                         "BEQ   - branch if equal"
    rv32ui_branch_not_equal                     "BNE   - branch if not equal"
    rv32ui_branch_less_than                     "BLT   - branch if less than"
    rv32ui_branch_greater_or_equal              "BGE   - branch if greater or equal"
    rv32ui_branch_less_than_unsigned            "BLTU  - branch if less than unsigned"
    rv32ui_branch_greater_or_equal_unsigned     "BGEU  - branch if greater or equal unsigned"
    rv32ui_load_word                            "LW    - load word"
    rv32ui_load_halfword                        "LH    - load halfword"
    rv32ui_load_halfword_unsigned               "LHU   - load halfword unsigned"
    rv32ui_load_byte                            "LB    - load byte"
    rv32ui_load_byte_unsigned                   "LBU   - load byte unsigned"
    rv32ui_store_word                           "SW    - store word"
    rv32ui_store_halfword                       "SH    - store halfword"
    rv32ui_store_byte                           "SB    - store byte"
}

# ── compile RTL ───────────────────────────────────────────────────────────────
proc ensure_compiled {} {
    global work_dir

    catch {quit -sim}
    catch {file delete -force -- $work_dir}
    vlib $work_dir
    vmap work $work_dir

    set rtl_sources [lsort [glob -nocomplain RTL/*.sv]]
    set pkg_file ""
    set design_sources {}

    foreach src $rtl_sources {
        if {[string match -nocase "*pkg*.sv" [file tail $src]]} {
            set pkg_file $src
        } else {
            lappend design_sources $src
        }
    }

    if {$pkg_file eq ""} { error "No package file matching RTL/*pkg*.sv found." }

    vlog -sv $pkg_file
    vlog -sv {*}$design_sources Testbench/tb_riscv.sv
}

# ── wave setup (flat labels, no groups) ───────────────────────────────────────
proc setup_waves {} {
    quietly WaveActivateNextPane {} 0

    add wave -noupdate -divider "Testbench"
    add wave -noupdate -label "Clock"                          sim:/tb_riscv/clk
    add wave -noupdate -label "Reset Active Low"               sim:/tb_riscv/rst_n
    add wave -noupdate -radix decimal     -label "Cycle Count" sim:/tb_riscv/cycle_count
    add wave -noupdate -radix decimal     -label "Instruction Retire Count" sim:/tb_riscv/instret_count

    add wave -noupdate -divider "Top Level"
    add wave -noupdate -radix hexadecimal -label "Instruction"            sim:/tb_riscv/dut/instruction
    add wave -noupdate -radix hexadecimal -label "Opcode"                 sim:/tb_riscv/dut/opcode
    add wave -noupdate -radix hexadecimal -label "Funct3"                 sim:/tb_riscv/dut/funct3
    add wave -noupdate -radix hexadecimal -label "Funct7"                 sim:/tb_riscv/dut/funct7
    add wave -noupdate -radix decimal     -label "Immediate"              sim:/tb_riscv/dut/immediate
    add wave -noupdate -label "Register Write Enable"                     sim:/tb_riscv/dut/reg_write
    add wave -noupdate -label "Memory Read Enable"                        sim:/tb_riscv/dut/mem_read
    add wave -noupdate -label "Memory Write Enable"                       sim:/tb_riscv/dut/mem_write
    add wave -noupdate -label "Memory To Register"                        sim:/tb_riscv/dut/mem_to_reg
    add wave -noupdate -label "ALU Use Immediate"                         sim:/tb_riscv/dut/alu_src
    add wave -noupdate -radix hexadecimal -label "ALU Operation"          sim:/tb_riscv/dut/alu_ctrl
    add wave -noupdate -radix hexadecimal -label "Instruction Type"       sim:/tb_riscv/dut/instruction_type
    add wave -noupdate -label "Take Branch"                               sim:/tb_riscv/dut/take_branch
    add wave -noupdate -radix decimal     -label "Destination Register Data" sim:/tb_riscv/dut/destination_reg_data

    add wave -noupdate -divider "Program Counter"
    add wave -noupdate -radix decimal     -label "Next PC"    sim:/tb_riscv/dut/u_pc/next_pc
    add wave -noupdate -radix decimal     -label "PC"         sim:/tb_riscv/dut/u_pc/pc

    add wave -noupdate -divider "Instruction Memory"
    add wave -noupdate -radix decimal     -label "PC"         sim:/tb_riscv/dut/u_imem/pc
    add wave -noupdate -radix hexadecimal -label "Instruction" sim:/tb_riscv/dut/u_imem/instr

    add wave -noupdate -divider "Control Unit"
    add wave -noupdate -radix hexadecimal -label "Opcode"                 sim:/tb_riscv/dut/u_ctrl/opcode
    add wave -noupdate -radix hexadecimal -label "Funct3"                 sim:/tb_riscv/dut/u_ctrl/funct3
    add wave -noupdate -label "Funct7 Bit 5"                              sim:/tb_riscv/dut/u_ctrl/funct7_5
    add wave -noupdate -label "Register Write Enable"                     sim:/tb_riscv/dut/u_ctrl/reg_write
    add wave -noupdate -label "Memory Read Enable"                        sim:/tb_riscv/dut/u_ctrl/mem_read
    add wave -noupdate -label "Memory Write Enable"                       sim:/tb_riscv/dut/u_ctrl/mem_write
    add wave -noupdate -label "Memory To Register"                        sim:/tb_riscv/dut/u_ctrl/mem_to_reg
    add wave -noupdate -label "ALU Use Immediate"                         sim:/tb_riscv/dut/u_ctrl/alu_src
    add wave -noupdate -radix hexadecimal -label "Immediate Type"         sim:/tb_riscv/dut/u_ctrl/imm_sel
    add wave -noupdate -radix hexadecimal -label "ALU Operation"          sim:/tb_riscv/dut/u_ctrl/alu_ctrl
    add wave -noupdate -radix hexadecimal -label "Instruction Type"       sim:/tb_riscv/dut/u_ctrl/instruction_type
    add wave -noupdate -radix hexadecimal -label "Byte Count"             sim:/tb_riscv/dut/u_ctrl/mem_size

    add wave -noupdate -divider "Register File"
    add wave -noupdate -radix decimal     -label "Source Register 1 Address"  sim:/tb_riscv/dut/u_rf/source_reg1_address
    add wave -noupdate -radix decimal     -label "Source Register 1 Data"     sim:/tb_riscv/dut/u_rf/source_reg1_data
    add wave -noupdate -radix decimal     -label "Source Register 2 Address"  sim:/tb_riscv/dut/u_rf/source_reg2_address
    add wave -noupdate -radix decimal     -label "Source Register 2 Data"     sim:/tb_riscv/dut/u_rf/source_reg2_data
    add wave -noupdate -radix decimal     -label "Destination Register Address" sim:/tb_riscv/dut/u_rf/destination_reg_address
    add wave -noupdate -radix decimal     -label "Destination Register Data"  sim:/tb_riscv/dut/u_rf/destination_reg_data
    add wave -noupdate -label "Write Enable"                                  sim:/tb_riscv/dut/u_rf/write_enable
    add wave -noupdate -radix decimal     -label "x1"   sim:/tb_riscv/dut/u_rf/registers(1)
    add wave -noupdate -radix decimal     -label "x2"   sim:/tb_riscv/dut/u_rf/registers(2)
    add wave -noupdate -radix decimal     -label "x3"   sim:/tb_riscv/dut/u_rf/registers(3)
    add wave -noupdate -radix decimal     -label "x4"   sim:/tb_riscv/dut/u_rf/registers(4)
    add wave -noupdate -radix decimal     -label "x5"   sim:/tb_riscv/dut/u_rf/registers(5)

    add wave -noupdate -divider "Immediate Generator"
    add wave -noupdate -radix hexadecimal -label "Instruction"   sim:/tb_riscv/dut/u_immgen/instr
    add wave -noupdate -radix hexadecimal -label "Immediate Type" sim:/tb_riscv/dut/u_immgen/imm_sel
    add wave -noupdate -radix decimal     -label "Immediate Out"  sim:/tb_riscv/dut/u_immgen/imm_out

    add wave -noupdate -divider "ALU"
    add wave -noupdate -radix decimal     -label "Input A"       sim:/tb_riscv/dut/u_alu/a
    add wave -noupdate -radix decimal     -label "Input B"       sim:/tb_riscv/dut/u_alu/b
    add wave -noupdate -radix hexadecimal -label "ALU Operation" sim:/tb_riscv/dut/u_alu/alu_ctrl
    add wave -noupdate -radix decimal     -label "Result"        sim:/tb_riscv/dut/u_alu/result
    add wave -noupdate -label "Zero"                             sim:/tb_riscv/dut/u_alu/zero
    add wave -noupdate -label "Carry"                            sim:/tb_riscv/dut/u_alu/carry

    add wave -noupdate -divider "Branch Unit"
    add wave -noupdate -radix hexadecimal -label "Funct3"        sim:/tb_riscv/dut/u_branch/funct3
    add wave -noupdate -label "Is Branch Instruction"            sim:/tb_riscv/dut/u_branch/inst_is_branch
    add wave -noupdate -label "Zero"                             sim:/tb_riscv/dut/u_branch/zero
    add wave -noupdate -radix decimal     -label "ALU Result"    sim:/tb_riscv/dut/u_branch/alu_result
    add wave -noupdate -label "Take Branch"                      sim:/tb_riscv/dut/u_branch/take_branch

    add wave -noupdate -divider "Data Memory"
    add wave -noupdate -label "Read Enable"                      sim:/tb_riscv/dut/u_dmem/read_enable
    add wave -noupdate -label "Write Enable"                     sim:/tb_riscv/dut/u_dmem/write_enable
    add wave -noupdate -radix hexadecimal -label "Byte Count"    sim:/tb_riscv/dut/u_dmem/byte_count
    add wave -noupdate -radix decimal     -label "Address"       sim:/tb_riscv/dut/u_dmem/address
    add wave -noupdate -radix decimal     -label "Write Data"    sim:/tb_riscv/dut/u_dmem/write_data
    add wave -noupdate -radix decimal     -label "Read Data"     sim:/tb_riscv/dut/u_dmem/read_data

    update
}

# ── run the full test suite ────────────────────────────────────────────────────
proc run_suite {} {
    global tests test_dir hex_dest

    set pass_count 0
    set fail_count 0
    set fail_list {}
    set total_cycles 0
    set total_instret 0
    set bench_lines {}

    file mkdir "Debug/sim"

    foreach {test desc} $tests {
        set src "$test_dir/${test}.hex"
        if {![file exists $src]} {
            puts "SKIP     $test"
            continue
        }

        file copy -force -- $src $hex_dest

        set log "Debug/sim/${test}.log"
        transcript file $log

        vsim -c -voptargs=+acc work.tb_riscv
        onfinish stop
        run -all
        quit -sim

        transcript file "nul"

        set sim_out ""
        catch {
            set fh [open $log r]
            set sim_out [read $fh]
            close $fh
            file delete -force -- $log
        }

        if {[regexp {BENCH cycles=([0-9]+) instret=([0-9]+) cpi=([0-9.]+)} $sim_out -> cycles instret cpi]} {
            set total_cycles  [expr {$total_cycles  + $cycles}]
            set total_instret [expr {$total_instret + $instret}]
            lappend bench_lines [format "%-48s cycles=%-6s instret=%-6s cpi=%s" $test $cycles $instret $cpi]
        }

        if {[string match "*PASS*" $sim_out]} {
            puts [format "PASS     %-48s %s" $test $desc]
            incr pass_count
        } elseif {[string match "*FAIL*" $sim_out]} {
            regexp {FAIL.*} $sim_out fail_msg
            puts [format "FAIL     %-48s %s -- %s" $test $desc $fail_msg]
            incr fail_count
            lappend fail_list $test
        } else {
            puts [format "TIMEOUT  %-48s %s" $test $desc]
            incr fail_count
            lappend fail_list "$test (timeout)"
        }
    }

    set total [expr {$pass_count + $fail_count}]
    puts ""
    puts "========================================================"
    puts "Results: $pass_count / $total passed"
    if {[llength $fail_list] > 0} {
        puts "Failed:"
        foreach f $fail_list { puts "  - $f" }
    }
    puts "========================================================"
    puts ""
    puts "Benchmark:"
    foreach b $bench_lines { puts $b }
    if {$total_cycles > 0 && $total_instret > 0} {
        set total_cpi [expr {double($total_cycles) / double($total_instret)}]
        puts [format "TOTAL                                            cycles=%-6d instret=%-6d cpi=%.6f" \
              $total_cycles $total_instret $total_cpi]
    }
}

# ── run a single test with waveforms ──────────────────────────────────────────
proc run_single {} {
    global tests test_dir hex_dest

    set max [expr {[llength $tests] / 2}]

    puts ""
    puts [format "  %3s   %-48s %s" "#" "Test Name" "What It Tests"]
    puts [format "  %3s   %-48s %s" "---" "------------------------------------------------" "-------------"]

    set index 1
    foreach {name desc} $tests {
        puts [format "  %3d.  %-48s %s" $index $name $desc]
        incr index
    }
    puts ""

    while {1} {
        puts -nonewline "Choose a test (1-$max): "
        flush stdout
        gets stdin choice
        set choice [string trim $choice]
        if {[string is integer -strict $choice] && $choice >= 1 && $choice <= $max} break
        puts "Enter a number from 1 to $max."
    }

    set idx  [expr {($choice - 1) * 2}]
    set test [lindex $tests $idx]
    set desc [lindex $tests [expr {$idx + 1}]]

    set src "$test_dir/${test}.hex"
    if {![file exists $src]} {
        puts "ERROR: hex file not found: $src"
        return
    }

    file copy -force -- $src $hex_dest

    puts ""
    puts "Running: $test"
    puts "         $desc"
    puts ""

    vsim -voptargs=+acc work.tb_riscv
    setup_waves
    onfinish stop
    run -all
    puts ""
    puts "Done."
}

# ── mode selection ─────────────────────────────────────────────────────────────
puts ""
puts "  1.  Run a single test  (with waveforms)"
puts "  2.  Run the full suite (no waveforms, pass/fail summary)"
puts ""

while {1} {
    puts -nonewline "Choose mode (1 or 2): "
    flush stdout
    gets stdin mode
    set mode [string trim $mode]
    if {$mode eq "1" || $mode eq "2"} break
    puts "Enter 1 or 2."
}

ensure_compiled

if {$mode eq "1"} {
    run_single
} else {
    run_suite
}
