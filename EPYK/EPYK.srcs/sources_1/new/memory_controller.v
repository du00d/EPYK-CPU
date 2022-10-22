`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/15/2022 06:07:36 PM
// Design Name: 
// Module Name: memory_controller
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


module memory_controller#(
    parameter DATA_SIZE = 16,
    parameter ADDRESS_LENGTH = 12
    )(
    input op, //0==1011, 1=1100 (write)(0) / (read)(1)
    input enable,//do or not
    input [DATA_SIZE-1:0] R_out_adress,
    input [DATA_SIZE-1:0] R_out_data,
    input [DATA_SIZE-1:0] mem_out,
    
    output [DATA_SIZE-1:0] R_in_data,
    output [DATA_SIZE-1:0] mem_in,
    output write_reg,
    output write_mem,
    
    output [ADDRESS_LENGTH-1:0] mem_address
    );
    assign write_mem = enable&(!op);
    assign write_reg = enable&op;
    assign mem_in = R_out_data;
    assign R_in_data = mem_out;
    assign mem_address = R_out_adress;
//    always@(*)
//        case(op)
//         endcase
            
endmodule
