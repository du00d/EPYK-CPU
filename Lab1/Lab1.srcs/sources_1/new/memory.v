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
    input [ADDRESS_LENGTH-1:0] fetch_address,
    input [DATA_SIZE-1:0] data_in,
    output [DATA_SIZE-1:0] data_out1,
    output [DATA_SIZE-1:0] data_out2,
    input write,
          clock,
          reset
    );
    reg [DATA_SIZE-1:0] mem [2 ** ADDRESS_LENGTH -1 : 0];
    assign data_out1 = mem[address];
    assign data_out2 = mem[fetch_address];
//    assign data_out = (read)? mem[address] : {(DATA_SIZE){1'bz}};
    integer i;
    always@(posedge clock) begin
        if(reset) begin
//            for(i=0;i<2**ADDRESS_LENGTH-1;i=i+1)
//                mem[i]=0;
                //program starts at 0b11111
        end
        else if(write)
            mem[address] = data_in;
    end
endmodule
