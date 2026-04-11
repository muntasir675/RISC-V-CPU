module FETCH(
    input logic clock,
    input logic nreset,
    input logic  [31:0] next_address,
    output logic [31:0] instruction
);

logic [31:0] curr_address;
logic [31:0] instruction_memory [0:4000];

initial $readmemh("program.hex", instruction_memory);
assign instruction = instruction_memory[curr_address[31:2]]; // divide by 4

always_ff @(posedge clock or negedge nreset) begin
    if(!nreset) curr_address<=32'b0;
    else        curr_address<=next_address;
end

endmodule