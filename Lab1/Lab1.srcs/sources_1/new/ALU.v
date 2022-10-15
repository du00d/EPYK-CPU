`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/15/2022 03:53:30 PM
// Design Name: 
// Module Name: ALU
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


module ALU#(parameter SIZE = 16)(
    input [SIZE-1:0] A,
    input [SIZE-1:0] B,
    input [1:0] ALUOp,
    output reg [SIZE-1:0] C
    );
    always @(*)
        case(ALUOp)
            2'b00:  C=A+B;
            2'b01:  C=A-B;
            2'b10:  C=A+1;
            2'b11:  C=A^B;
        endcase
endmodule
