module branch_unit (
    input  logic [2:0]  funct3,
    input  logic        inst_is_branch,
    input  logic        zero,
    input  logic [31:0] alu_result,

    output logic        take_branch
);

    always_comb begin
        take_branch = 1'b0;

        if (inst_is_branch) begin
            case (funct3)
                3'b000: take_branch = zero;
                3'b001: take_branch = ~zero;
                3'b100: take_branch = alu_result[0];
                3'b101: take_branch = ~alu_result[0];
                3'b110: take_branch = alu_result[0];
                3'b111: take_branch = ~alu_result[0];
                default: take_branch = 1'b0;
            endcase
        end
    end

endmodule
