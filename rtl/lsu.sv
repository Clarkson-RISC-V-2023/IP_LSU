`timescale 1ns/1ps
module lsu #(
    // Parameters
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 1024,
    parameter NUM_MEM_BLOCKS = 4,
    parameter ADDRESS_SPACE = 4096, // DEPTH * NUM_MEM_BLOCKS
    parameter NUM_DATA_TYPES = 6,
    parameter GPIO_A_ADDR = 12'hEF0,
    parameter GPIO_B_ADDR = 12'hEF4
)(
    // Inputs
    input wire clk,
    input wire [$clog2(ADDRESS_SPACE)-1:0] addr_in,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire WE_in,
    input wire [$clog2(NUM_DATA_TYPES)-1:0] dtypes_in,
    input wire reset_n,
 
    // Outputs
    output reg [DATA_WIDTH-1:0] data_out,

    // In Outs
    output reg [DATA_WIDTH-1:0] gpioA_out,
    output reg [DATA_WIDTH-1:0] gpioB_out
);
    // Defining the different DTYPES
    `define BYTE               3'b000
    `define HALF_WORD          3'b001
    `define FULL_WORD          3'b010
    `define BYTE_UNSIGNED      3'b011
    `define HALF_WORD_UNSIGNED 3'b100


    // Signal which controls the 4 memory block write enables
    reg [DATA_WIDTH-1:0] data_input_internal;
    reg [DATA_WIDTH-1:0] data_output_internal;
    reg [NUM_MEM_BLOCKS-1:0] memory_bank_we;
    wire [DATA_WIDTH-1:0] data_output_ram_internal;

    // Instatiating the RAM
    ram #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH),
        .NUM_OF_MEM_BLOCKS(NUM_MEM_BLOCKS),
        .ADDRESS_SPACE(ADDRESS_SPACE)
    ) ram_ip (
        .clk(clk),
        .addr_i(addr_in),
        .wr_data_i(data_input_internal),
        .mem_block_en_i(memory_bank_we),
        .wr_en_i(WE_in),
        .rd_data_o(data_output_ram_internal)
    );

    //Reset Logic
    always @(*) begin
        if(!reset_n) begin
            data_out <= '0;
        end else begin
            data_out <= data_output_internal;
        end
    end

    // Determining When to Write to GPIO
    always_ff @(posedge clk) begin
        if(!reset_n) begin
            gpioA_out <= '0;
            gpioB_out <= '0;
        end else begin
            if(WE_in) begin
            case(addr_in)
                GPIO_A_ADDR: gpioA_out <= data_in;
                GPIO_B_ADDR: gpioB_out <= data_in;
            endcase
        end
        end
    end

    // Determining which membanks to write to and how to write to them
    wire [$clog2(NUM_MEM_BLOCKS)-1:0] membank_number;
    assign membank_number = addr_in[1:0];
    always @(membank_number, dtypes_in, data_output_ram_internal, data_in) begin
        case(dtypes_in)
            `BYTE               : begin
                // Setting the Write Enable Correctly
                memory_bank_we[((membank_number+0)%4)] <= 1'b1;
                memory_bank_we[((membank_number+1)%4)] <= 1'b0;
                memory_bank_we[((membank_number+2)%4)] <= 1'b0;
                memory_bank_we[((membank_number+3)%4)] <= 1'b0;

                // Writing the Data Correctly
                data_input_internal[((membank_number+0)%4)*8+:8] <= data_in[7:0];
                data_input_internal[((membank_number+1)%4)*8+:8] <= 8'd0;
                data_input_internal[((membank_number+2)%4)*8+:8] <= 8'd0;
                data_input_internal[((membank_number+3)%4)*8+:8] <= 8'd0;

                // Reading the Data Correctly
                data_output_internal[0+:8]           <= data_output_ram_internal[((membank_number+0)%4)*8+:8];
                data_output_internal[DATA_WIDTH-1:8] <= {24{data_output_ram_internal[(((membank_number+0)%4)*8) + 7]}};
            end
            `HALF_WORD          : begin
                // Setting the Write Enable Correctly
                memory_bank_we[((membank_number+0)%4)] <= 1'b1;
                memory_bank_we[((membank_number+1)%4)] <= 1'b1;
                memory_bank_we[((membank_number+2)%4)] <= 1'b0;
                memory_bank_we[((membank_number+3)%4)] <= 1'b0;

                // Writing the Data Correctly
                data_input_internal[((membank_number+0)%4)*8+:8] <= data_in[7:0];
                data_input_internal[((membank_number+1)%4)*8+:8] <= data_in[15:8];
                data_input_internal[((membank_number+2)%4)*8+:8] <= 8'd0;
                data_input_internal[((membank_number+3)%4)*8+:8] <= 8'd0;

                // Reading the Data Correctly
                data_output_internal[0+:8]          <= data_output_ram_internal[((membank_number+0)%4)*8+:8];
                data_output_internal[8+:8]          <= data_output_ram_internal[((membank_number+1)%4)*8+:8];
                data_output_internal[DATA_WIDTH-1:16] <= {16{data_output_ram_internal[(((membank_number+1)%4)*8) + 7]}};
            end
            `FULL_WORD          : begin
                // Setting the Write Enable Correctly
                memory_bank_we <= 4'b1111;

                // Writing the Data Correctly
                data_input_internal[((membank_number+0)%4)*8+:8] <= data_in[7:0];
                data_input_internal[((membank_number+1)%4)*8+:8] <= data_in[15:8];
                data_input_internal[((membank_number+2)%4)*8+:8] <= data_in[23:16];
                data_input_internal[((membank_number+3)%4)*8+:8] <= data_in[31:24];

                // Reading the Data Correctly
                data_output_internal[0+:8]          <= data_output_ram_internal[((membank_number+0)%4)*8+:8];
                data_output_internal[8+:8]          <= data_output_ram_internal[((membank_number+1)%4)*8+:8];
                data_output_internal[16+:8]         <= data_output_ram_internal[((membank_number+2)%4)*8+:8];
                data_output_internal[24+:8]         <= data_output_ram_internal[((membank_number+3)%4)*8+:8];
            end
            `BYTE_UNSIGNED      : begin
                // Setting the Write Enable Correctly
                memory_bank_we[((membank_number+0)%4)] <= 1'b1;
                memory_bank_we[((membank_number+1)%4)] <= 1'b0;
                memory_bank_we[((membank_number+2)%4)] <= 1'b0;
                memory_bank_we[((membank_number+3)%4)] <= 1'b0;

                // Writing the Data Correctly
                data_input_internal[((membank_number+0)%4)*8+:8] <= data_in[7:0];
                data_input_internal[((membank_number+1)%4)*8+:8] <= 8'd0;
                data_input_internal[((membank_number+2)%4)*8+:8] <= 8'd0;
                data_input_internal[((membank_number+3)%4)*8+:8] <= 8'd0;

                // Reading the Data Correctly
                data_output_internal[0+:8]           <= data_output_ram_internal[((membank_number+0)%4)*8+:8];
                data_output_internal[DATA_WIDTH-1:8] <= '0;
            end
            `HALF_WORD_UNSIGNED : begin
                // Setting the Write Enable Correctly
                memory_bank_we[((membank_number+0)%4)] <= 1'b1;
                memory_bank_we[((membank_number+1)%4)] <= 1'b1;
                memory_bank_we[((membank_number+2)%4)] <= 1'b0;
                memory_bank_we[((membank_number+3)%4)] <= 1'b0;

                // Writing the Data Correctly
                data_input_internal[((membank_number+0)%4)*8+:8] <= data_in[7:0];
                data_input_internal[((membank_number+1)%4)*8+:8] <= data_in[15:8];
                data_input_internal[((membank_number+2)%4)*8+:8] <= 8'd0;
                data_input_internal[((membank_number+3)%4)*8+:8] <= 8'd0;

                // Reading the Data Correctly
                data_output_internal[0+:8]          <= data_output_ram_internal[((membank_number+0)%4)*8+:8];
                data_output_internal[8+:8]          <= data_output_ram_internal[((membank_number+1)%4)*8+:8];
                data_output_internal[DATA_WIDTH-1:16] <= '0;
            end
            default             : begin
                // Setting the Write Enable Correctly
                memory_bank_we[((membank_number+0)%4)] <= 1'b0;
                memory_bank_we[((membank_number+1)%4)] <= 1'b0;
                memory_bank_we[((membank_number+2)%4)] <= 1'b0;
                memory_bank_we[((membank_number+3)%4)] <= 1'b0;

                // Writing the Data Correctly
                data_input_internal[((membank_number+0)%4)*8+:8] <= 8'd0;
                data_input_internal[((membank_number+1)%4)*8+:8] <= 8'd0;
                data_input_internal[((membank_number+2)%4)*8+:8] <= 8'd0;
                data_input_internal[((membank_number+3)%4)*8+:8] <= 8'd0;

                // Reading the Data Correctly
                data_output_internal[DATA_WIDTH-1:0] <= '0;
            end
        endcase   
    end
endmodule