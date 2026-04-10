import riscv_pkg::*;

module control_unit (
    input  logic [6:0]  opcode,
    input  logic [2:0]  funct3,
    input  logic        funct7_5,

    output logic        reg_write,
    output logic        mem_read,
    output logic        mem_write,
    output logic        mem_to_reg,
    output logic        alu_src,
    output immediate_select_t imm_sel,
    output alu_operation_t    alu_ctrl,
    output instruction_type_t instruction_type,
    output logic [2:0]  mem_size
);
    assign mem_size = funct3;

    always_comb begin

        reg_write  = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 1'b0;
        alu_src    = 1'b0;
        imm_sel    = IMM_I;
        alu_ctrl   = ALU_ADD;
        instruction_type = INST_ALU;

        case (opcode)

            7'b0110011: begin
                reg_write = 1'b1;
                alu_src   = 1'b0;
                case (funct3)
                    3'b000: alu_ctrl = funct7_5 ? ALU_SUB : ALU_ADD;
                    3'b001: alu_ctrl = ALU_SLL;
                    3'b010: alu_ctrl = ALU_SLT;
                    3'b011: alu_ctrl = ALU_SLTU;
                    3'b100: alu_ctrl = ALU_XOR;
                    3'b101: alu_ctrl = funct7_5 ? ALU_SRA : ALU_SRL;
                    3'b110: alu_ctrl = ALU_OR;
                    3'b111: alu_ctrl = ALU_AND;
                    default: alu_ctrl = ALU_ADD;
                endcase
            end

            7'b0010011: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                imm_sel   = IMM_I;
                case (funct3)
                    3'b000: alu_ctrl = ALU_ADD;
                    3'b001: alu_ctrl = ALU_SLL;
                    3'b010: alu_ctrl = ALU_SLT;
                    3'b011: alu_ctrl = ALU_SLTU;
                    3'b100: alu_ctrl = ALU_XOR;
                    3'b101: alu_ctrl = funct7_5 ? ALU_SRA : ALU_SRL;
                    3'b110: alu_ctrl = ALU_OR;
                    3'b111: alu_ctrl = ALU_AND;
                    default: alu_ctrl = ALU_ADD;
                endcase
            end

            7'b0000011: begin
                reg_write  = 1'b1;
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;
                alu_src    = 1'b1;
                imm_sel    = IMM_I;
                alu_ctrl   = ALU_ADD;
                instruction_type = INST_LOAD;
            end

            7'b0100011: begin
                mem_write = 1'b1;
                alu_src   = 1'b1;
                imm_sel   = IMM_S;
                alu_ctrl  = ALU_ADD;
                instruction_type = INST_STORE;
            end

            7'b1100011: begin
                alu_src          = 1'b0;
                imm_sel          = IMM_B;
                instruction_type = INST_BRANCH;

                case (funct3)
                    3'b000: alu_ctrl = ALU_SUB;
                    3'b001: alu_ctrl = ALU_SUB;
                    3'b100: alu_ctrl = ALU_SLT;
                    3'b101: alu_ctrl = ALU_SLT;
                    3'b110: alu_ctrl = ALU_SLTU;
                    3'b111: alu_ctrl = ALU_SLTU;
                    default: alu_ctrl = ALU_SUB;
                endcase
            end

            7'b1101111: begin
                reg_write        = 1'b1;
                imm_sel          = IMM_J;
                instruction_type = INST_JAL;
            end

            7'b1100111: begin
                reg_write        = 1'b1;
                alu_src          = 1'b1;
                imm_sel          = IMM_I;
                alu_ctrl         = ALU_ADD;
                instruction_type = INST_JALR;
            end

            7'b0110111: begin
                reg_write        = 1'b1;
                imm_sel          = IMM_U;
                instruction_type = INST_LUI;
            end

            7'b0010111: begin
                reg_write        = 1'b1;
                alu_src          = 1'b1;
                imm_sel          = IMM_U;
                alu_ctrl         = ALU_ADD;
                instruction_type = INST_AUIPC;
            end

            default: begin

            end

        endcase
    end

endmodule
