import riscv_pkg::*;
module EXECUTE(
    input  logic [31:0] register_data1, register_data2, immediate, curr_address,
    input  instr_type inst_info,
    output logic flush,
    output logic [31:0] result, next_address
);

assign flush = (next_address != curr_address + 4);

always_comb begin
    result = 32'b0;
    next_address = curr_address + 4;

    case (inst_info)
        INSTR_ADD:   result = register_data1 + register_data2;
        INSTR_SUB:   result = register_data1 - register_data2;
        INSTR_AND:   result = register_data1 & register_data2;
        INSTR_OR:    result = register_data1 | register_data2;
        INSTR_XOR:   result = register_data1 ^ register_data2;
        INSTR_ADDI:  result = register_data1 + immediate;
        INSTR_ANDI:  result = register_data1 & immediate;
        INSTR_ORI:   result = register_data1 | immediate;
        INSTR_XORI:  result = register_data1 ^ immediate;
        INSTR_AUIPC: result = curr_address + immediate;
        INSTR_LUI:   result = immediate;
        INSTR_SLLI:  result = register_data1 << immediate[4:0];
        INSTR_SRLI:  result = register_data1 >> immediate[4:0];
        INSTR_SLL:   result = register_data1 << register_data2[4:0];
        INSTR_SRL:   result = register_data1 >> register_data2[4:0];
        INSTR_SRAI:  result =  $signed(register_data1) >>> immediate[4:0];
        INSTR_SLTI:  result = ($signed(register_data1) < $signed(immediate)) ? 32'd1 : 32'd0;
        INSTR_SRA:   result =  $signed(register_data1) >>> register_data2[4:0];
        INSTR_SLT:   result = ($signed(register_data1) < $signed(register_data2)) ? 32'd1 : 32'd0;
        INSTR_SLTU:  result = (register_data1 < register_data2) ? 32'd1 : 32'd0;
        INSTR_SLTIU: result = (register_data1 < immediate)      ? 32'd1 : 32'd0;

        INSTR_LW, INSTR_LH, INSTR_LHU, INSTR_LB, INSTR_LBU:  result = register_data1 + immediate;
        INSTR_SW, INSTR_SH, INSTR_SB:                        result = register_data1 + immediate;

        INSTR_JAL:  begin
            result       = curr_address + 4;
            next_address = curr_address + immediate;
        end
        INSTR_JALR: begin
            result       = curr_address + 4;
            next_address = (register_data1 + immediate) & ~32'd1;
        end

        INSTR_BEQ:  if (register_data1 == register_data2)                   next_address = curr_address + immediate;
        INSTR_BNE:  if (register_data1 != register_data2)                   next_address = curr_address + immediate;
        INSTR_BLT:  if ($signed(register_data1) <  $signed(register_data2)) next_address = curr_address + immediate;
        INSTR_BGE:  if ($signed(register_data1) >= $signed(register_data2)) next_address = curr_address + immediate;
        INSTR_BLTU: if (register_data1 <  register_data2)                   next_address = curr_address + immediate;
        INSTR_BGEU: if (register_data1 >= register_data2)                   next_address = curr_address + immediate;

    endcase
end

endmodule