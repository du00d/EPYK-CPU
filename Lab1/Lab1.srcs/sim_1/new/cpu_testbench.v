`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/20/2022 09:10:31 PM
// Design Name: 
// Module Name: cpu_testbench
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


module cpu_testbench(

    );
    reg clock,reset;
    wire [16-1:0] PC_out;
    wire [16*6-1:0] R_allout;
    CPU cpu(clock,reset,PC_out,R_allout);
    wire [16-1:0] R [5:0];
    assign R[5] = R_allout[16*6-1:16*5];
    assign R[4] = R_allout[16*5-1:16*4];
    assign R[3] = R_allout[16*4-1:16*3];
    assign R[2] = R_allout[16*3-1:16*2];
    assign R[1] = R_allout[16*2-1:16*1];
    assign R[0] = R_allout[16*1-1:16*0];
    
    defparam cpu.MEM_INIT_FILE="X:/EC551/Lab1/meminit.txt";    
    
    initial begin
    clock=0;
    #10 reset=1;
    #10 reset=0;
    #1000 $finish;
    end
    always  #2 clock=~clock; 
endmodule
