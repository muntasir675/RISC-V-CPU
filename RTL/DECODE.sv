import riscv_pkg::*;
module DECODE(
    input  logic [31:0] instruction,
    output instr_type inst_info,
    output logic [31:0] immediate
);

always_comb begin
    case (instruction[6:0])
        7'b0110011: begin // arithmetic register
            case (instruction[14:12])
                3'b000: inst_info = instruction[30] ? INSTR_SUB : INSTR_ADD;
                3'b001: inst_info = INSTR_SLL;
                3'b010: inst_info = INSTR_SLT;
                3'b011: inst_info = INSTR_SLTU;
                3'b100: inst_info = INSTR_XOR;
                3'b101: inst_info = instruction[30] ? INSTR_SRA : INSTR_SRL;
                3'b110: inst_info = INSTR_OR;
                3'b111: inst_info = INSTR_AND;
                default: inst_info = INSTR_UNKNOWN;
            endcase
        end
        7'b0010011: begin // arithmetic immediate
            case (instruction[14:12])
                3'b000: inst_info = INSTR_ADDI;
                3'b001: inst_info = INSTR_SLLI;
                3'b010: inst_info = INSTR_SLTI;
                3'b011: inst_info = INSTR_SLTIU;
                3'b100: inst_info = INSTR_XORI;
                3'b101: inst_info = instruction[30] ? INSTR_SRAI : INSTR_SRLI;
                3'b110: inst_info = INSTR_ORI;
                3'b111: inst_info = INSTR_ANDI;
                default: inst_info = INSTR_UNKNOWN;
            endcase
        end
        7'b0000011: begin // load
            case (instruction[14:12])
                3'b000: inst_info = INSTR_LB;
                3'b001: inst_info = INSTR_LH;
                3'b010: inst_info = INSTR_LW;
                3'b100: inst_info = INSTR_LBU;
                3'b101: inst_info = INSTR_LHU;
                default: inst_info = INSTR_UNKNOWN;
            endcase
        end
        7'b0100011: begin // store
            case (instruction[14:12])
                3'b000: inst_info = INSTR_SB;
                3'b001: inst_info = INSTR_SH;
                3'b010: inst_info = INSTR_SW;
                default: inst_info = INSTR_UNKNOWN;
            endcase
        end
        7'b1100011: begin // branch
            case (instruction[14:12])
                3'b000: inst_info = INSTR_BEQ;
                3'b001: inst_info = INSTR_BNE;
                3'b100: inst_info = INSTR_BLT;
                3'b101: inst_info = INSTR_BGE;
                3'b110: inst_info = INSTR_BLTU;
                3'b111: inst_info = INSTR_BGEU;
                default: inst_info = INSTR_UNKNOWN;
            endcase
        end
        7'b1101111: inst_info = INSTR_JAL;
        7'b1100111: inst_info = INSTR_JALR;
        7'b0110111: inst_info = INSTR_LUI;
        7'b0010111: inst_info = INSTR_AUIPC;
        7'b1110011: inst_info = (instruction == 32'h00000073) ? INSTR_ECALL : INSTR_UNKNOWN;
        default:    inst_info = INSTR_UNKNOWN;
    endcase
end

// immediate value assign
always_comb begin
    case (inst_info)
        INSTR_ADDI, INSTR_SLTI, INSTR_SLTIU,INSTR_XORI, INSTR_ORI, INSTR_ANDI,INSTR_SLLI, INSTR_SRLI, INSTR_SRAI,INSTR_LB, INSTR_LH, INSTR_LW, INSTR_LBU, INSTR_LHU,INSTR_JALR:
            immediate = {{20{instruction[31]}}, instruction[31:20]};
        INSTR_SB, INSTR_SH, INSTR_SW:
            immediate = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
        INSTR_BEQ, INSTR_BNE, INSTR_BLT, INSTR_BGE, INSTR_BLTU, INSTR_BGEU:
            immediate = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
        INSTR_LUI, INSTR_AUIPC:
            immediate = {instruction[31:12], 12'b0};
        INSTR_JAL:
            immediate = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
        default:
            immediate = 32'b0;
    endcase
end

endmodule
