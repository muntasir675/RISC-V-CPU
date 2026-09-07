package riscv_pkg;

    typedef enum logic [5:0] {
        // R-type arithmetic/logic (reg-reg)
        ADD,    // add  rd, rs1, rs2   rd = rs1 + rs2
        SUB,    // sub  rd, rs1, rs2   rd = rs1 - rs2
        AND,    // and  rd, rs1, rs2   rd = rs1 & rs2
        OR,     // or   rd, rs1, rs2   rd = rs1 | rs2
        XOR,    // xor  rd, rs1, rs2   rd = rs1 ^ rs2
        SLL,    // sll  rd, rs1, rs2   rd = rs1 << rs2[4:0]  (logical left)
        SRL,    // srl  rd, rs1, rs2   rd = rs1 >> rs2[4:0]  (logical right)
        SRA,    // sra  rd, rs1, rs2   rd = rs1 >>> rs2[4:0] (arithmetic right)
        SLT,    // slt  rd, rs1, rs2   rd = (rs1 < rs2 signed) ? 1 : 0
        SLTU,   // sltu rd, rs1, rs2   rd = (rs1 < rs2 unsigned) ? 1 : 0

        // I-type arithmetic (reg-immediate)
        ADDI,   // addi rd, rs1, imm   rd = rs1 + sext(imm)
        ANDI,   // andi rd, rs1, imm   rd = rs1 & sext(imm)
        ORI,    // ori  rd, rs1, imm   rd = rs1 | sext(imm)
        XORI,   // xori rd, rs1, imm   rd = rs1 ^ sext(imm)
        SLLI,   // slli rd, rs1, shamt rd = rs1 << shamt
        SRLI,   // srli rd, rs1, shamt rd = rs1 >> shamt  (logical)
        SRAI,   // srai rd, rs1, shamt rd = rs1 >>> shamt (arithmetic)
        SLTI,   // slti rd, rs1, imm   rd = (rs1 < sext(imm) signed) ? 1 : 0
        SLTIU,  // sltiu rd, rs1, imm  rd = (rs1 < sext(imm) unsigned) ? 1 : 0

        // Loads (I-type) — rd = mem[rs1 + sext(imm)]
        LW,     // lw  rd, imm(rs1)    load word (4 bytes)
        LH,     // lh  rd, imm(rs1)    load halfword (2 bytes, sign-extend)
        LHU,    // lhu rd, imm(rs1)    load halfword (2 bytes, zero-extend)
        LB,     // lb  rd, imm(rs1)    load byte (sign-extend)
        LBU,    // lbu rd, imm(rs1)    load byte (zero-extend)

        // Stores (S-type) — mem[rs1 + sext(imm)] = rs2
        SW,     // sw  rs2, imm(rs1)   store word
        SH,     // sh  rs2, imm(rs1)   store halfword
        SB,     // sb  rs2, imm(rs1)   store byte

        // Branches (B-type) — pc += imm if condition
        BEQ,    // beq  rs1, rs2, imm  branch if rs1 == rs2
        BNE,    // bne  rs1, rs2, imm  branch if rs1 != rs2
        BLT,    // blt  rs1, rs2, imm  branch if rs1 < rs2 (signed)
        BGE,    // bge  rs1, rs2, imm  branch if rs1 >= rs2 (signed)
        BLTU,   // bltu rs1, rs2, imm  branch if rs1 < rs2 (unsigned)
        BGEU,   // bgeu rs1, rs2, imm  branch if rs1 >= rs2 (unsigned)

        // Jumps
        JAL,    // jal  rd, imm        rd = pc+4; pc += imm
        JALR,   // jalr rd, rs1, imm   rd = pc+4; pc = (rs1+imm) & ~1

        // Upper-immediate
        LUI,    // lui  rd, imm        rd = imm[31:12] << 12
        AUIPC,  // auipc rd, imm       rd = pc + (imm[31:12] << 12)

        // System
        ECALL,  // ecall               trap to environment (syscall)
        UNKNOWN // unrecognized instruction
    } instr_type;

endpackage
