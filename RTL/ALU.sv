import riscv_pkg::*;

module alu (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  alu_operation_t alu_ctrl,

    output logic [31:0] result,
    output logic        zero,
    output logic        carry
);
    logic [32:0] full_result;

    always_comb begin
        full_result = 33'b0;
        result      = 32'b0;

        case (alu_ctrl)

            ALU_ADD: begin

                full_result = {1'b0, a} + {1'b0, b};
                result      = full_result[31:0];
            end

            ALU_SUB: begin

                full_result = {1'b0, a} - {1'b0, b};
                result      = full_result[31:0];
            end

            ALU_AND:  result = a & b;

            ALU_OR:   result = a | b;

            ALU_XOR:  result = a ^ b;

            ALU_SLT: begin

                result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            end

            ALU_SLTU: begin

                result = (a < b) ? 32'd1 : 32'd0;
            end

            ALU_SLL: begin

                result = a << b[4:0];
            end

            ALU_SRL: begin

                result = a >> b[4:0];
            end

            ALU_SRA: begin

                result = $signed(a) >>> b[4:0];
            end

            default: result = 32'b0;
        endcase
    end

    assign zero  = (result == 32'b0);
    assign carry = full_result[32];

endmodule
