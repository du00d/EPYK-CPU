`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/15/2022 05:02:55 PM
// Design Name: 
// Module Name: fetch_unit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fetch_unit#(parameter DATA_SIZE = 16,
    parameter ADDRESS_LENGTH = 12
    )(
    input [DATA_SIZE-1:0] PC_out ,
    input [DATA_SIZE-1:0] mem_out,
    output [ADDRESS_LENGTH-1:0] address,
    output [DATA_SIZE-1:0] instruction
    );
    
    assign instruction = mem_out;
    assign address = PC_out[ADDRESS_LENGTH-1:0];
    
endmodule
