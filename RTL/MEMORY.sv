import riscv_pkg::*;
module MEMORY(
    input  logic        clock,
    input  logic        nreset,
    input  logic [31:0] address,
    input  logic [31:0] write_data,
    input  instr_type inst_info,
    output logic [31:0] read_data
);

logic [7:0] Storage [0:1023];

always_ff @(posedge clock or negedge nreset) begin
    if(!nreset) begin
        `ifndef SYNTHESIS
         for (integer i = 0; i < 1023; i = i + 1) Storage[i] <= 8'h00;
        `endif
    end
    else begin
        case (inst_info)
            INSTR_SB: Storage[address] <= write_data[7:0];
            INSTR_SH: begin
                Storage[address]   <= write_data[7:0];
                Storage[address+1] <= write_data[15:8];
            end
            INSTR_SW: begin
                Storage[address]   <= write_data[7:0];
                Storage[address+1] <= write_data[15:8];
                Storage[address+2] <= write_data[23:16];
                Storage[address+3] <= write_data[31:24];
            end
            default: begin end
        endcase
    end
end

always_comb begin
    case (inst_info)
        INSTR_LB:  read_data = {{24{Storage[address][7]}}, Storage[address]};
        INSTR_LH:  read_data = {{16{Storage[address+1][7]}}, Storage[address+1], Storage[address]};
        INSTR_LW:  read_data = {Storage[address+3], Storage[address+2], Storage[address+1], Storage[address]};
        INSTR_LBU: read_data = {24'b0, Storage[address]};
        INSTR_LHU: read_data = {16'b0, Storage[address+1], Storage[address]};
        default:   read_data = 32'b0;
    endcase
end

endmodule
