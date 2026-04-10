module instr_mem #(
    parameter DEPTH = 4096
)(
    input  logic [31:0] pc,
    output logic [31:0] instr
);

    logic [31:0] mem [0:DEPTH-1];

    initial $readmemh("Testbench/program.hex", mem);

    assign instr = mem[pc[31:2]];

endmodule