module reg_file (
    input  logic        clock,
    input  logic        reset_active_low,

    input  logic [4:0]  source_reg1_address,
    output logic [31:0] source_reg1_data,

    input  logic [4:0]  source_reg2_address,
    output logic [31:0] source_reg2_data,

    input  logic [4:0]  destination_reg_address,
    input  logic [31:0] destination_reg_data,
    input  logic        write_enable
);

    logic [31:0] registers [0:31];

    always_ff @(posedge clock) begin
        if (!reset_active_low) begin
            integer i;
            for (i = 0; i < 32; i++)
                registers[i] <= 32'b0;
        end else if (write_enable && destination_reg_address != 5'b0) begin
            registers[destination_reg_address] <= destination_reg_data;
        end
    end

    assign source_reg1_data = (source_reg1_address == 5'b0) ? 32'b0 : registers[source_reg1_address];
    assign source_reg2_data = (source_reg2_address == 5'b0) ? 32'b0 : registers[source_reg2_address];

endmodule