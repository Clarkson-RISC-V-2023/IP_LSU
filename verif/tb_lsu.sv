`timescale 1ns/1ps
module tb_lsu #(
    parameter ADDRESS_SPACE = 4096,
    parameter DATA_WIDTH = 32,
    parameter NUM_DATA_TYPES = 6
)(
    // EMPTY
);
    // MACROS
    `define BYTE               3'b000
    `define HALF_WORD          3'b001
    `define FULL_WORD          3'b010
    `define BYTE_UNSIGNED      3'b011
    `define HALF_WORD_UNSIGNED 3'b100

    // SIGNALS
    reg clk;
    reg [$clog2(ADDRESS_SPACE)-1:0] addr;
    reg [DATA_WIDTH-1:0] data_in;
    reg we_in;
    reg [$clog2(NUM_DATA_TYPES)-1:0] dtypes;
    reg reset_n;
    reg [DATA_WIDTH-1:0] data_out;

    // Instatiating the LSU
    lsu #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDRESS_SPACE(ADDRESS_SPACE),
        .NUM_DATA_TYPES(NUM_DATA_TYPES)
    ) lsu_dut (
        .clk(clk),
        .addr_in(addr),
        .data_in(data_in),
        .WE_in(we_in),
        .dtypes_in(dtypes),
        .reset_n(reset_n),
        .data_out(data_out)
    );

    // Functions
    task write_data(input [11:0] addr_input, input [31:0] data_input, input [2:0]  dtypes_input);
        begin
            #5
            addr = addr_input;
            data_in = data_input;
            dtypes = dtypes_input;
            we_in = 1'b1;
            #15
            we_in = 1'b0;
        end
    endtask

    task read_data(input [11:0] addr_input, input [2:0] dtypes_input);
        begin
            #5
            addr = addr_input;
            data_in = '0;
            dtypes = dtypes_input;
            we_in = 1'b0;
            #15
            we_in = 1'b0;
        end
    endtask

    // Setting a 50 MHz clock
    always #10 clk= ~clk;

    // Testing the device
    initial begin
        $dumpfile("tb_lsu.vcd");
        $dumpvars(0, tb_lsu);
        // Setting Initial Conditions (For Clk and Reset)
        clk = 1'b0;
        reset_n = 1'b0;

        // Setting Initial Conditions (For input signals)
        addr = '0;
        data_in = '0;
        we_in = 1'b0;
        dtypes = `FULL_WORD;

        // Waiting 100 ns, then negating reset
        #100 reset_n = 1'b1;

        // Waiting 100 ns, then writing a full word to addr 10
        #100
        write_data(12'h000, 32'hABCDEF00, `FULL_WORD);
        write_data(12'h004, 32'h00000010, `FULL_WORD);
        write_data(12'h008, 32'hA0000F12, `FULL_WORD);
        write_data(12'h00C, 32'hC0000B00, `FULL_WORD);
        #100
        read_data(12'h000, `FULL_WORD);
        read_data(12'h004, `FULL_WORD);
        read_data(12'h008, `FULL_WORD);
        read_data(12'h00C, `FULL_WORD);
        #100 $finish;
    end
endmodule;