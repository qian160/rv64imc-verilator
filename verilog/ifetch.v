/*
TODO: cache, branch-predictor?
*/
`include "define.v"
module ifetch (
    input           clock,
    input           reset,
    // control
    input           stall_i,
    input           flush_i,        // donecare
    // from memory
    input  [31:0]   inst_i,
    // from id. branch result
    input           branch_i,
    input  [63:0]   branch_target_i,
    // exception
    input           exception_i,    // from wb
    input           mret_i,         // from id
    input  [63:0]   mtvec_i,        // from csr (RAW?)
    input  [63:0]   mepc_i,         // from csr
    input  [63:0]   mcause_i,       // from csr
    // used by id's jalr
    output          is_compressed_o,
    // fetch
    output [63:0]   pc_o,
    output [31:0]   inst_o
);
    reg [63:0] pc;
    reg [63:0] next_pc;

    assign is_compressed_o = inst_i[1:0] != 2'b11;
    always @*   begin
        // combinational logic for next_pc
        if (reset)
            next_pc = `PMEM_START;
        else if (stall_i)
            next_pc = pc;
        // exception & branch won't both happen, since exception will flush the pipeline
        else if (exception_i)
            next_pc = mtvec_i[0]? // mode
                {mtvec_i[63:2], 2'b0} + (mcause_i << 2):
                {mtvec_i[63:2], 2'b0};
        else if (mret_i)
            next_pc = mepc_i;
        else if (branch_i)
            next_pc = branch_target_i;
        else if (is_compressed_o)
            next_pc = pc + 64'd2;
        else
            next_pc = pc + 64'd4;
    end

    always @(posedge clock) begin
        // sequential logic for pc's update
        pc <= next_pc;
    end

    assign pc_o = pc;
    assign inst_o = inst_i;
endmodule