package riscv_pkg;

    typedef enum logic [5:0] {
        // R-type arithmetic/logic (reg-reg)
        INSTR_ADD,    // add  rd, rs1, rs2   rd = rs1 + rs2
        INSTR_SUB,    // sub  rd, rs1, rs2   rd = rs1 - rs2
        INSTR_AND,    // and  rd, rs1, rs2   rd = rs1 & rs2
        INSTR_OR,     // or   rd, rs1, rs2   rd = rs1 | rs2
        INSTR_XOR,    // xor  rd, rs1, rs2   rd = rs1 ^ rs2
        INSTR_SLL,    // sll  rd, rs1, rs2   rd = rs1 << rs2[4:0]  (logical left)
        INSTR_SRL,    // srl  rd, rs1, rs2   rd = rs1 >> rs2[4:0]  (logical right)
        INSTR_SRA,    // sra  rd, rs1, rs2   rd = rs1 >>> rs2[4:0] (arithmetic right)
        INSTR_SLT,    // slt  rd, rs1, rs2   rd = (rs1 < rs2 signed) ? 1 : 0
        INSTR_SLTU,   // sltu rd, rs1, rs2   rd = (rs1 < rs2 unsigned) ? 1 : 0

        // I-type arithmetic (reg-immediate)
        INSTR_ADDI,   // addi rd, rs1, imm   rd = rs1 + sext(imm)
        INSTR_ANDI,   // andi rd, rs1, imm   rd = rs1 & sext(imm)
        INSTR_ORI,    // ori  rd, rs1, imm   rd = rs1 | sext(imm)
        INSTR_XORI,   // xori rd, rs1, imm   rd = rs1 ^ sext(imm)
        INSTR_SLLI,   // slli rd, rs1, shamt rd = rs1 << shamt
        INSTR_SRLI,   // srli rd, rs1, shamt rd = rs1 >> shamt  (logical)
        INSTR_SRAI,   // srai rd, rs1, shamt rd = rs1 >>> shamt (arithmetic)
        INSTR_SLTI,   // slti rd, rs1, imm   rd = (rs1 < sext(imm) signed) ? 1 : 0
        INSTR_SLTIU,  // sltiu rd, rs1, imm  rd = (rs1 < sext(imm) unsigned) ? 1 : 0

        // Loads (I-type) — rd = mem[rs1 + sext(imm)]
        INSTR_LW,     // lw  rd, imm(rs1)    load word (4 bytes)
        INSTR_LH,     // lh  rd, imm(rs1)    load halfword (2 bytes, sign-extend)
        INSTR_LHU,    // lhu rd, imm(rs1)    load halfword (2 bytes, zero-extend)
        INSTR_LB,     // lb  rd, imm(rs1)    load byte (sign-extend)
        INSTR_LBU,    // lbu rd, imm(rs1)    load byte (zero-extend)

        // Stores (S-type) — mem[rs1 + sext(imm)] = rs2
        INSTR_SW,     // sw  rs2, imm(rs1)   store word
        INSTR_SH,     // sh  rs2, imm(rs1)   store halfword
        INSTR_SB,     // sb  rs2, imm(rs1)   store byte

        // Branches (B-type) — pc += imm if condition
        INSTR_BEQ,    // beq  rs1, rs2, imm  branch if rs1 == rs2
        INSTR_BNE,    // bne  rs1, rs2, imm  branch if rs1 != rs2
        INSTR_BLT,    // blt  rs1, rs2, imm  branch if rs1 < rs2 (signed)
        INSTR_BGE,    // bge  rs1, rs2, imm  branch if rs1 >= rs2 (signed)
        INSTR_BLTU,   // bltu rs1, rs2, imm  branch if rs1 < rs2 (unsigned)
        INSTR_BGEU,   // bgeu rs1, rs2, imm  branch if rs1 >= rs2 (unsigned)

        // Jumps
        INSTR_JAL,    // jal  rd, imm        rd = pc+4; pc += imm
        INSTR_JALR,   // jalr rd, rs1, imm   rd = pc+4; pc = (rs1+imm) & ~1

        // Upper-immediate
        INSTR_LUI,    // lui  rd, imm        rd = imm[31:12] << 12
        INSTR_AUIPC,  // auipc rd, imm       rd = pc + (imm[31:12] << 12)

        // System
        INSTR_ECALL,  // ecall               trap to environment (syscall)
        INSTR_UNKNOWN // unrecognized instruction
    } instr_type;

endpackage
