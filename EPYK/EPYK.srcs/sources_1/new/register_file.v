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
    input clock,
    output [DATA_SIZE*6-1:0] R_allout
    );
    wire [DATA_SIZE*6-1:0] R_allin;
//    wire [5:0][DATA_SIZE-1:0] R_out;
//    wire [5:0][DATA_SIZE-1:0] R_in;
    wire [5:0] R_enable;
    wire [2:0] write_select;
    wire anywrite;
//    register R(R_out,R_in,,clock);// [5:0];
    genvar i;
    generate for(i=0;i<6;i=i+1) begin
        register R(R_allout[(i+1)*DATA_SIZE-1:i*DATA_SIZE],R_allin[(i+1)*DATA_SIZE-1:i*DATA_SIZE],reset,R_enable[i],clock);
//        assign R_allout[(i+1)*DATA_SIZE-1:i*DATA_SIZE] = R_out[i];
    end
    endgenerate
    regselect rs1(reg_out1,R_allout,reg_select1);
    regselect rs2(reg_out2,R_allout,reg_select2);
//    assign reg_out1 = R_allout[(reg_select1+1)*DATA_SIZE-1:reg_select1*DATA_SIZE];
//    assign reg_out2 = R_allout[(reg_select2+1)*DATA_SIZE-1:reg_select2*DATA_SIZE
    assign write_select = (write_enable1)?reg_select1:reg_select2;
    assign anywrite = write_enable1 ^ write_enable2;
    for(i=0;i<6;i=i+1) begin
        assign R_allin[(i+1)*DATA_SIZE-1:i*DATA_SIZE] = (write_enable1)?reg_in1:reg_in2;
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
module regselect#(
    parameter DATA_SIZE = 16)(
    output reg [DATA_SIZE-1:0] regout,
    input [DATA_SIZE*6-1:0] regall,
    input [2:0] regselect);
    
    always@(*) begin
        case(regselect)
            0: regout = regall[(0+1)*DATA_SIZE-1:0*DATA_SIZE];
            1: regout = regall[(1+1)*DATA_SIZE-1:1*DATA_SIZE];
            2: regout = regall[(2+1)*DATA_SIZE-1:2*DATA_SIZE];
            3: regout = regall[(3+1)*DATA_SIZE-1:3*DATA_SIZE];
            4: regout = regall[(4+1)*DATA_SIZE-1:4*DATA_SIZE];
            default: regout = regall[(5+1)*DATA_SIZE-1:5*DATA_SIZE];
        endcase
    end
endmodule
