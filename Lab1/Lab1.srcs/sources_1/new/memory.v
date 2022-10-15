`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Carlton Knox and Po Hao Chen
// EC551
// 12-bit address space
// 16-bit data size
// 
//////////////////////////////////////////////////////////////////////////////////


module memory#(
parameter DATA_SIZE = 16,
parameter ADDRESS_LENGTH = 12
)(
    input [ADDRESS_LENGTH-1:0] address,
    input [DATA_SIZE-1:0] data_in,
    output [DATA_SIZE-1:0] data_out,
    input write,
          clock
    );
    reg [DATA_SIZE-1:0] mem [2 ** ADDRESS_LENGTH -1 : 0];
    
    assign data_out = mem[address];
//    assign data_out = (read)? mem[address] : {(DATA_SIZE){1'bz}};
    always@(posedge clock)
        if(write)
            mem[address] = data_in;
endmodule
