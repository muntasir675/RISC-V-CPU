import riscv_pkg::*;
module DECODE(
    input  logic [31:0] instruction,
    output instr_type inst_info,
    output logic [31:0] immediate,
    output logic enable
);

always_comb begin
    case (instruction[6:0])
        7'b0110011: begin // arithmetic register
            case (instruction[14:12])
                3'b000: inst_info = instruction[30] ? SUB : ADD;
                3'b001: inst_info = SLL;
                3'b010: inst_info = SLT;
                3'b011: inst_info = SLTU;
                3'b100: inst_info = XOR;
                3'b101: inst_info = instruction[30] ? SRA : SRL;
                3'b110: inst_info = OR;
                3'b111: inst_info = AND;
                default: inst_info = UNKNOWN;
            endcase
        end
        7'b0010011: begin // arithmetic immediate
            case (instruction[14:12])
                3'b000: inst_info = ADDI;
                3'b001: inst_info = SLLI;
                3'b010: inst_info = SLTI;
                3'b011: inst_info = SLTIU;
                3'b100: inst_info = XORI;
                3'b101: inst_info = instruction[30] ? SRAI : SRLI;
                3'b110: inst_info = ORI;
                3'b111: inst_info = ANDI;
                default: inst_info = UNKNOWN;
            endcase
        end
        7'b0000011: begin // load
            case (instruction[14:12])
                3'b000: inst_info = LB;
                3'b001: inst_info = LH;
                3'b010: inst_info = LW;
                3'b100: inst_info = LBU;
                3'b101: inst_info = LHU;
                default: inst_info = UNKNOWN;
            endcase
        end
        7'b0100011: begin // store
            case (instruction[14:12])
                3'b000: inst_info = SB;
                3'b001: inst_info = SH;
                3'b010: inst_info = SW;
                default: inst_info = UNKNOWN;
            endcase
        end
        7'b1100011: begin // branch
            case (instruction[14:12])
                3'b000: inst_info = BEQ;
                3'b001: inst_info = BNE;
                3'b100: inst_info = BLT;
                3'b101: inst_info = BGE;
                3'b110: inst_info = BLTU;
                3'b111: inst_info = BGEU;
                default: inst_info = UNKNOWN;
            endcase
        end
        7'b1101111: inst_info = JAL;
        7'b1100111: inst_info = JALR;
        7'b0110111: inst_info = LUI;
        7'b0010111: inst_info = AUIPC;
        7'b1110011: inst_info = (instruction == 32'h00000073) ? ECALL : UNKNOWN;
        default:    inst_info = UNKNOWN;
    endcase
end

// immediate value assign
always_comb begin
    case (inst_info)
        ADDI, SLTI, SLTIU,XORI, ORI, ANDI,SLLI, SRLI, SRAI,LB, LH, LW, LBU, LHU,JALR:
            immediate = {{20{instruction[31]}}, instruction[31:20]};
        SB, SH, SW:
            immediate = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
        BEQ, BNE, BLT, BGE, BLTU, BGEU:
            immediate = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
        LUI, AUIPC:
            immediate = {instruction[31:12], 12'b0};
        JAL:
            immediate = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
        default:
            immediate = 32'b0;
    endcase
end

// enable write to register
always_comb begin
    case (inst_info)
        ADD, SUB, AND, OR, XOR,
        SLL, SRL, SRA, SLT, SLTU,
        ADDI, ANDI, ORI, XORI,
        SLLI, SRLI, SRAI, SLTI, SLTIU,
        LB, LH, LW, LBU, LHU,
        JAL, JALR, LUI, AUIPC:
            enable = 1'b1;
        default:
            enable = 1'b0;
    endcase
end

endmodule
