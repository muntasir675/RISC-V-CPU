module data_mem #(
    parameter DEPTH = 1024
)(
    input  logic        clock,
    input  logic        read_enable,
    input  logic        write_enable,
    input  logic [31:0] address,
    input  logic [31:0] write_data,
    input  logic [2:0]  byte_count,
    output logic [31:0] read_data
);

    logic [7:0] memory [0:DEPTH-1];

    always_ff @(posedge clock) begin
        if (write_enable) begin
            case (byte_count)
                3'b000: begin // Store Byte
                    memory[address] <= write_data[7:0];
                end
                3'b001: begin // Store Halfword
                    memory[address]   <= write_data[7:0];
                    memory[address+1] <= write_data[15:8];
                end
                3'b010: begin // Store Word
                    memory[address]   <= write_data[7:0];
                    memory[address+1] <= write_data[15:8];
                    memory[address+2] <= write_data[23:16];
                    memory[address+3] <= write_data[31:24];
                end
                default: ;
            endcase
        end
    end

    always_comb begin
        read_data = 32'b0;
        if (read_enable) begin
            case (byte_count)
                3'b000: begin // Load Byte (sign extended)
                    read_data = {{24{memory[address][7]}}, memory[address]};
                end
                3'b001: begin // Load Halfword (sign extended)
                    read_data = {{16{memory[address+1][7]}}, memory[address+1], memory[address]};
                end
                3'b010: begin // Load Word
                    read_data = {memory[address+3], memory[address+2], memory[address+1], memory[address]};
                end
                3'b100: begin // Load Byte Unsigned (zero extended)
                    read_data = {24'b0, memory[address]};
                end
                3'b101: begin // Load Halfword Unsigned (zero extended)
                    read_data = {16'b0, memory[address+1], memory[address]};
                end
                default: read_data = 32'b0;
            endcase
        end
    end

endmodule