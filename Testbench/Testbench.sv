`timescale 1ns/1ps
import riscv_pkg::*;
module Testbench;

logic clock;
logic nreset;

always #5 clock = ~clock;
wire [31:0] x3 = u_cpu.u_writeback.registers[3];
wire [31:0] debug_out;
wire ecall;

initial begin
    clock = 0;
    nreset = 0;
end

CPU #(.PROGRAM_HEX("Debug/tests/rv32ui-p-add.hex")) u_cpu (
    .clock       (clock),
    .nreset      (nreset),
    .debug_out   (debug_out),
    .ecall_fired (ecall)
);

// initial begin
//     wait(nreset == 1);
//     forever @(posedge clock) begin
//         if (u_cpu.curr_address_d2 >= 515 && u_cpu.curr_address_d2 <= 555) begin
//             $display("[DBG t=%0t] EX_PC:%0d | EX_inst:%s (d2=0x%h, rd=%0d) | MEM_inst:%s (d3=0x%h, rd=%0d) | WB_inst:%s (d4=0x%h, rd=%0d)",
//                 $time,
//                 u_cpu.curr_address_d2,
//                 u_cpu.inst_info_d1.name(), u_cpu.instruction_d2, u_cpu.instruction_d2[11:7],
//                 u_cpu.inst_info_d2.name(), u_cpu.instruction_d3, u_cpu.instruction_d3[11:7],
//                 u_cpu.inst_info_d3.name(), u_cpu.instruction_d4, u_cpu.instruction_d4[11:7]);
//             $display("         DEC_inst:%s (d1=0x%h, rs1=%0d, rs2=%0d) | stall=%0b | mem_rd_data=0x%h | res_d1=0x%h",
//                 u_cpu.inst_info.name(), u_cpu.instruction_d1, u_cpu.instruction_d1[19:15], u_cpu.instruction_d1[24:20],
//                 u_cpu.stall, u_cpu.read_data, u_cpu.result_d1);
//             $display("         EX_in_val1=0x%h (%0d) | EX_in_val2=0x%h (%0d) | EX_res=0x%h",
//                 u_cpu.u_execute.register_data1, $signed(u_cpu.u_execute.register_data1),
//                 u_cpu.u_execute.register_data2, $signed(u_cpu.u_execute.register_data2),
//                 u_cpu.u_execute.result);
//         end
//         if (u_cpu.u_memory.inst_info == ECALL) begin
//             $display("ECALL fired at time %0t", $time);
//         end
//     end
// end

initial begin
    automatic string tests[] = '{
        "rv32ui-p-add.hex",   "rv32ui-p-addi.hex",  "rv32ui-p-and.hex",
        "rv32ui-p-andi.hex",  "rv32ui-p-auipc.hex", "rv32ui-p-beq.hex",
        "rv32ui-p-bge.hex",   "rv32ui-p-bgeu.hex",  "rv32ui-p-blt.hex",
        "rv32ui-p-bltu.hex",  "rv32ui-p-bne.hex",   "rv32ui-p-jal.hex",
        "rv32ui-p-jalr.hex",  "rv32ui-p-lb.hex",    "rv32ui-p-lbu.hex",
        "rv32ui-p-lh.hex",    "rv32ui-p-lhu.hex",   "rv32ui-p-lui.hex",
        "rv32ui-p-lw.hex",    "rv32ui-p-or.hex",    "rv32ui-p-ori.hex",
        "rv32ui-p-sb.hex",    "rv32ui-p-sh.hex",    "rv32ui-p-simple.hex",
        "rv32ui-p-sll.hex",   "rv32ui-p-slli.hex",  "rv32ui-p-slt.hex",
        "rv32ui-p-slti.hex",  "rv32ui-p-sltiu.hex", "rv32ui-p-sltu.hex",
        "rv32ui-p-sra.hex",   "rv32ui-p-srai.hex",  "rv32ui-p-srl.hex",
        "rv32ui-p-srli.hex",  "rv32ui-p-sub.hex",   "rv32ui-p-sw.hex",
        "rv32ui-p-xor.hex",   "rv32ui-p-xori.hex"
    };
    automatic int passed = 0, failed = 0;

    foreach (tests[i]) begin
        $readmemh({"Debug/tests/", tests[i]}, u_cpu.u_fetch.instruction_memory);
        nreset = 0; 
        repeat(4) @(posedge clock); 
        nreset = 1;

        fork
            begin
                @(posedge ecall);
            end
            begin
                repeat(2000) @(posedge clock);
            end
        join_any
        disable fork;

        if (ecall && x3 == 1) begin
            $display("PASS:    %s", tests[i]);
            passed++;
        end else begin
            $display("FAIL:    %s  (gp=%0d, ecall=%0b)", tests[i], x3, ecall);
            failed++;
        end
    end

    $display("==============================");
    $display("  %0d/%0d passed", passed, passed+failed);
    $display("==============================");
    $stop;
end


endmodule