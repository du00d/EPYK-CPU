`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/16/2022 12:33:18 AM
// Design Name: 
// Module Name: register_file
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


module register_file#(
    parameter DATA_SIZE = 16)(
    input [2:0] reg_select1,
    input [DATA_SIZE-1:0] reg_in1,
    input write_enable1,
    output [DATA_SIZE-1:0] reg_out1,
    input [2:0] reg_select2,
    input write_enable2,
    input [DATA_SIZE-1:0] reg_in2,
    output [DATA_SIZE-1:0] reg_out2,
    input reset,
    input clock
    );
    wire [5:0][DATA_SIZE-1:0] R_out;
    wire [5:0][DATA_SIZE-1:0] R_in;
    wire [5:0] R_enable;
    wire [2:0] write_select;
    wire anywrite;
//    register R(R_out,R_in,,clock);// [5:0];
    genvar i;
    generate for(i=0;i<6;i=i+1) begin
        register R(R_out[i],R_in[i],reset,R_enable[i],clock);
    end
    endgenerate
    
    assign reg_out1 = R_out[reg_select1];
    assign reg_out2 = R_out[reg_select2];
    assign write_select = (write_enable1)?reg_select1:reg_select2;
    assign anywrite = write_enable1 ^ write_enable2;
    for(i=0;i<6;i=i+1) begin
        assign R_in[i] = (write_enable1)?reg_in1:reg_in2;
    end
    
    genvar j;
    for(j=0;j<6;j=j+1)begin
        assign R_enable[j] = anywrite & (j==write_select);
    end
//assign R_enable[0] = anywrite && write_select==0; 
//assign R_enable[1] = anywrite && write_select==1; 
//assign R_enable[2] = anywrite && write_select==2; 
//assign R_enable[3] = anywrite && write_select==3; 
//assign R_enable[4] = anywrite && write_select==4; 
//assign R_enable[5] = anywrite && write_select==5; 
    
endmodule
