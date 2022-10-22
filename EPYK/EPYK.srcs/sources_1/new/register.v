`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/15/2022 04:07:14 PM
// Design Name: 
// Module Name: register
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



module register#(parameter SIZE = 16,RESET_VAL=0)(
    output reg [SIZE-1:0] q,
    input [SIZE-1:0] d,
    input reset,
    input enable,
    input clock
    );
    always@(posedge clock)
        if(reset)
            q<=RESET_VAL;
        else
            if(enable)
                q<=d;
endmodule
