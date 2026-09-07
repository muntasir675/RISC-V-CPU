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
        ADD:   result = register_data1 + register_data2;
        SUB:   result = register_data1 - register_data2;
        AND:   result = register_data1 & register_data2;
        OR:    result = register_data1 | register_data2;
        XOR:   result = register_data1 ^ register_data2;
        ADDI:  result = register_data1 + immediate;
        ANDI:  result = register_data1 & immediate;
        ORI:   result = register_data1 | immediate;
        XORI:  result = register_data1 ^ immediate;
        AUIPC: result = curr_address + immediate;
        LUI:   result = immediate;
        SLLI:  result = register_data1 << immediate[4:0];
        SRLI:  result = register_data1 >> immediate[4:0];
        SLL:   result = register_data1 << register_data2[4:0];
        SRL:   result = register_data1 >> register_data2[4:0];
        SRAI:  result =  $signed(register_data1) >>> immediate[4:0];
        SLTI:  result = ($signed(register_data1) < $signed(immediate)) ? 32'd1 : 32'd0;
        SRA:   result =  $signed(register_data1) >>> register_data2[4:0];
        SLT:   result = ($signed(register_data1) < $signed(register_data2)) ? 32'd1 : 32'd0;
        SLTU:  result = (register_data1 < register_data2) ? 32'd1 : 32'd0;
        SLTIU: result = (register_data1 < immediate)      ? 32'd1 : 32'd0;

        LW, LH, LHU, LB, LBU:  result = register_data1 + immediate;
        SW, SH, SB:                        result = register_data1 + immediate;

        JAL:  begin
            result       = curr_address + 4;
            next_address = curr_address + immediate;
        end
        JALR: begin
            result       = curr_address + 4;
            next_address = (register_data1 + immediate) & ~32'd1;
        end

        BEQ:  if (register_data1 == register_data2)                   next_address = curr_address + immediate;
        BNE:  if (register_data1 != register_data2)                   next_address = curr_address + immediate;
        BLT:  if ($signed(register_data1) <  $signed(register_data2)) next_address = curr_address + immediate;
        BGE:  if ($signed(register_data1) >= $signed(register_data2)) next_address = curr_address + immediate;
        BLTU: if (register_data1 <  register_data2)                   next_address = curr_address + immediate;
        BGEU: if (register_data1 >= register_data2)                   next_address = curr_address + immediate;

    endcase
end

endmodule