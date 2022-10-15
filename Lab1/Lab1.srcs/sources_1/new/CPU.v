`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/15/2022 04:27:24 PM
// Design Name: 
// Module Name: CPU
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


module CPU#(
    parameter DATA_SIZE = 16,
    parameter ADDRESS_LENGTH = 12
    )(input clock

    );
    
    register R[5:0]();
    
    ALU alu();   
    wire [DATA_SIZE-1:0] mem_out;
    wire [ADDRESS_LENGTH-1:0] mem_address;
    wire [DATA_SIZE-1:0] mem_in;
    wire write_enable;
    memory mem(mem_address,mem_in,mem_out,write_enable,clock);

    wire [DATA_SIZE-1:0] PC_out,PC_next;
    wire [ADDRESS_LENGTH-1:0] PC_address;
    wire [DATA_SIZE-1:0] instruction;
    
    register PC(PC_out,PC_next,,clock);
    fetch_unit FU(PC_out,mem_out,PC_address,instruction);
endmodule
