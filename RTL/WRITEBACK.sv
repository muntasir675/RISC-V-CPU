module WRITEBACK(
    input  logic        clock,
    input  logic        nreset,
    input  logic [4:0]  rs1_addr,
    input  logic [4:0]  rs2_addr,
    input  logic [4:0]  rd_addr,
    input  logic [31:0] rd_data,
    input  logic        rd_write_enable,
    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data
);

logic [31:0] register [0:31];

assign rs1_data =
    (rs1_addr == 5'd0) ? 32'b0 :
    (rd_write_enable && (rd_addr != 5'd0) && (rd_addr == rs1_addr)) ? rd_data :
    register[rs1_addr];

assign rs2_data =
    (rs2_addr == 5'd0) ? 32'b0 :
    (rd_write_enable && (rd_addr != 5'd0) && (rd_addr == rs2_addr)) ? rd_data :
    register[rs2_addr];

always_ff @(posedge clock or negedge nreset) begin
    if (!nreset) begin
        for (integer i = 0; i < 32; i = i + 1) register[i] <= 32'h0;
    end else if (rd_write_enable && (rd_addr != 5'd0)) begin
        register[rd_addr] <= rd_data;
    end
end

endmodule
