`timescale 1ns/1ps

import riscv_pkg::*;

module tb_riscv;

    localparam TOHOST_ADDR = 32'h0000_1000;
    localparam CLK_HALF    = 5;
    localparam TIMEOUT_CYC = 20_000;

    logic clk;
    logic rst_n;
    int   trace_fd;
    int   cycle_count;
    int   instret_count;
    bit   trace_enable;
    bit   dump_enable;

    riscv_single_cycle dut (
        .clk   (clk),
        .rst_n (rst_n)
    );

    initial clk = 0;
    always #CLK_HALF clk = ~clk;

    function automatic bit instruction_retired;
        instruction_retired = !$isunknown(dut.instruction) && dut.instruction != 32'h0000_0000;
    endfunction

    function automatic string trace_message;
        trace_message = $sformatf(
            "CYC=%0d PC=%0d INSTR=0x%08h OPC=0x%02h(%s) F3=0x%0h F7=0x%02h INST=%s TYPE=%0d(%s) RD=%0d RS1=%0d RS2=%0d REGW=%0d ASRC=%0d BT=%0d ALU=%0d(%s) IMM=%0d A=%0d B=%0d RES=%0d RDATA=%0d X1=%0d X2=%0d X3=%0d",
            cycle_count,
            dut.program_counter,
            dut.instruction,
            dut.opcode, opcode_name(dut.opcode),
            dut.funct3,
            dut.funct7,
            instr_name(dut.opcode, dut.funct3, dut.funct7),
            dut.instruction_type, instruction_type_name(dut.instruction_type),
            dut.destination_reg_address,
            dut.source_reg1_address,
            dut.source_reg2_address,
            dut.reg_write,
            dut.alu_src,
            dut.take_branch,
            dut.alu_ctrl, alu_name(dut.alu_ctrl),
            $signed(dut.immediate),
            $signed(dut.alu_a),
            $signed(dut.alu_b),
            $signed(dut.alu_result),
            $signed(dut.destination_reg_data),
            $signed(dut.u_rf.registers[1]),
            $signed(dut.u_rf.registers[2]),
            $signed(dut.u_rf.registers[3])
        );
    endfunction

    task automatic finish_test;
        if (trace_fd != 0)
            $fclose(trace_fd);
        $finish;
    endtask

    function automatic string opcode_name(input logic [6:0] opcode);
        case (opcode)
            7'b0110011: opcode_name = "OP";
            7'b0010011: opcode_name = "OP_IMM";
            7'b0000011: opcode_name = "LOAD";
            7'b0100011: opcode_name = "STORE";
            7'b1100011: opcode_name = "BRANCH";
            7'b1101111: opcode_name = "JAL";
            7'b1100111: opcode_name = "JALR";
            7'b0110111: opcode_name = "LUI";
            7'b0010111: opcode_name = "AUIPC";
            7'b1110011: opcode_name = "SYSTEM";
            default:    opcode_name = "UNKNOWN";
        endcase
    endfunction

    function automatic string alu_name(input alu_operation_t alu_ctrl);
        case (alu_ctrl)
            ALU_ADD:  alu_name = "ALU_ADD";
            ALU_SUB:  alu_name = "ALU_SUB";
            ALU_AND:  alu_name = "ALU_AND";
            ALU_OR:   alu_name = "ALU_OR";
            ALU_XOR:  alu_name = "ALU_XOR";
            ALU_SLT:  alu_name = "ALU_SLT";
            ALU_SLTU: alu_name = "ALU_SLTU";
            ALU_SLL:  alu_name = "ALU_SLL";
            ALU_SRL:  alu_name = "ALU_SRL";
            ALU_SRA:  alu_name = "ALU_SRA";
            default:  alu_name = "ALU_?";
        endcase
    endfunction

    function automatic string instruction_type_name(input instruction_type_t instruction_type);
        case (instruction_type)
            INST_ALU:    instruction_type_name = "ALU";
            INST_LOAD:   instruction_type_name = "LOAD";
            INST_STORE:  instruction_type_name = "STORE";
            INST_BRANCH: instruction_type_name = "BRANCH";
            INST_JAL:    instruction_type_name = "JAL";
            INST_JALR:   instruction_type_name = "JALR";
            INST_LUI:    instruction_type_name = "LUI";
            INST_AUIPC:  instruction_type_name = "AUIPC";
            default:     instruction_type_name = "TYPE?";
        endcase
    endfunction

    function automatic string instr_name(
        input logic [6:0] opcode,
        input logic [2:0] funct3,
        input logic [6:0] funct7
    );
        case (opcode)
            7'b0110011: begin
                case (funct3)
                    3'b000: instr_name = funct7[5] ? "SUB" : "ADD";
                    3'b001: instr_name = "SLL";
                    3'b010: instr_name = "SLT";
                    3'b011: instr_name = "SLTU";
                    3'b100: instr_name = "XOR";
                    3'b101: instr_name = funct7[5] ? "SRA" : "SRL";
                    3'b110: instr_name = "OR";
                    3'b111: instr_name = "AND";
                    default: instr_name = "OP?";
                endcase
            end
            7'b0010011: begin
                case (funct3)
                    3'b000: instr_name = "ADDI";
                    3'b001: instr_name = "SLLI";
                    3'b010: instr_name = "SLTI";
                    3'b011: instr_name = "SLTIU";
                    3'b100: instr_name = "XORI";
                    3'b101: instr_name = funct7[5] ? "SRAI" : "SRLI";
                    3'b110: instr_name = "ORI";
                    3'b111: instr_name = "ANDI";
                    default: instr_name = "OPIMM?";
                endcase
            end
            7'b0000011: begin
                case (funct3)
                    3'b000: instr_name = "LB";
                    3'b001: instr_name = "LH";
                    3'b010: instr_name = "LW";
                    3'b100: instr_name = "LBU";
                    3'b101: instr_name = "LHU";
                    default: instr_name = "LOAD?";
                endcase
            end
            7'b0100011: begin
                case (funct3)
                    3'b000: instr_name = "SB";
                    3'b001: instr_name = "SH";
                    3'b010: instr_name = "SW";
                    default: instr_name = "STORE?";
                endcase
            end
            7'b1100011: begin
                case (funct3)
                    3'b000: instr_name = "BEQ";
                    3'b001: instr_name = "BNE";
                    3'b100: instr_name = "BLT";
                    3'b101: instr_name = "BGE";
                    3'b110: instr_name = "BLTU";
                    3'b111: instr_name = "BGEU";
                    default: instr_name = "BRANCH?";
                endcase
            end
            7'b1101111: instr_name = "JAL";
            7'b1100111: instr_name = "JALR";
            7'b0110111: instr_name = "LUI";
            7'b0010111: instr_name = "AUIPC";
            7'b1110011: instr_name = "SYSTEM";
            default:    instr_name = "UNKNOWN";
        endcase
    endfunction

    task automatic trace_line;
        string line;
        begin
            line = trace_message();
            $display("%s", line);

            if (trace_fd != 0)
                $fdisplay(trace_fd, "%s", line);
        end
    endtask

    task automatic report_bench;
        real cpi;
        begin
            if (instret_count != 0)
                cpi = real'(cycle_count) / real'(instret_count);
            else
                cpi = 0.0;

            $display("BENCH cycles=%0d instret=%0d cpi=%0.6f",
                     cycle_count, instret_count, cpi);
        end
    endtask

    task automatic report_result(
        input logic [31:0] status_value,
        input bit          allow_unexpected_value
    );
        begin
            report_bench();

            if (status_value == 32'd1)
                $display("PASS");
            else if (allow_unexpected_value && !status_value[0])
                $display("FAIL (unexpected gp=0x%08h)", status_value);
            else
                $display("FAIL (test case %0d)", status_value >> 1);

            finish_test();
        end
    endtask

    initial begin
        trace_enable  = $test$plusargs("trace");
        dump_enable   = $test$plusargs("dumpwaves");
        trace_fd      = 0;
        cycle_count   = 0;
        instret_count = 0;

        if (trace_enable)
            $display("TRACE enabled");

        if (dump_enable) begin
            $display("VCD dump enabled");
            $dumpfile("Debug/sim/dump.vcd");
            $dumpvars(0, tb_riscv.dut);
        end
    end

    initial begin
        rst_n = 1'b0;
        @(posedge clk); #1;
        @(posedge clk); #1;
        rst_n = 1'b1;
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            cycle_count   <= 0;
            instret_count <= 0;
        end else begin
            cycle_count <= cycle_count + 1;
            if (instruction_retired())
                instret_count <= instret_count + 1;
            if (trace_enable)
                trace_line();
        end
    end

    always @(posedge clk) begin
        if (rst_n && dut.mem_write && dut.alu_result == TOHOST_ADDR) begin
            report_result(dut.source_reg2_data, 1'b0);
        end
    end

    always @(posedge clk) begin
        automatic logic [31:0] gp;
        gp = dut.u_rf.registers[3];

        if (rst_n && gp != 32'd0 && dut.instruction == 32'h0000_0000)
            report_result(gp, 1'b1);
    end

    initial begin
        repeat (TIMEOUT_CYC) @(posedge clk);
        report_bench();
        $display("TIMEOUT at PC=0x%08h, gp=0x%08h",
                 dut.program_counter, dut.u_rf.registers[3]);
        finish_test();
    end

endmodule
