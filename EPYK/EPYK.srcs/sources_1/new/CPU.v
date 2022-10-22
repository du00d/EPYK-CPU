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

module topCPU#(
    parameter DATA_SIZE = 16,
    parameter ADDRESS_LENGTH = 12,
    parameter MEM_INIT_FILE = ""
    )(input sys_clock,user_clock,reset,continue,
      output [DATA_SIZE-1:0] PC_out/*,*/
      /*output [DATA_SIZE*6-1:0] R_allout*/);
      
      reg fake_clock;
      
      always@(posedge sys_clock)
        fake_clock <= user_clock;
      
    CPU epyc(fake_clock,reset,continue,PC_out,/*R_allout*/);
    defparam epyc.MEM_INIT_FILE="C:/Users/bupochen/EC551/Lab1/meminit.txt"; 
endmodule
module CPU_wrapper#(
    parameter DATA_SIZE = 16,
    parameter ADDRESS_LENGTH = 12,
    parameter MEM_INIT_FILE = ""
    )(input sys_clock,user_clock,reset,continue,
      output [DATA_SIZE-1:0] PC_out,
      output [DATA_SIZE*6-1:0] R_allout);
      
      reg fake_clock;
      
      always@(posedge sys_clock)
        fake_clock <= user_clock;
      
    CPU epyc(fake_clock,reset,continue,PC_out,R_allout);
    defparam epyc.MEM_INIT_FILE="X:/EC551/Lab1/meminit.txt"; 
endmodule
module CPU#(
    parameter DATA_SIZE = 16,
    parameter ADDRESS_LENGTH = 12,
    parameter MEM_INIT_FILE = ""
    )(input clock,reset,continue,
      output [DATA_SIZE-1:0] PC_out,
      output [DATA_SIZE*6-1:0] R_allout
    );
    wire [2:0] reg_select1,reg_select2;
    wire [DATA_SIZE-1:0] reg_in1,reg_in2,reg_out1,reg_out2;
    wire write_enable1,write_enable2;
    register_file registers(reg_select1,reg_in1,write_enable1,reg_out1,reg_select2,write_enable2,reg_in2,reg_out2,reset,clock,R_allout);
    
    wire [DATA_SIZE-1:0] A,B,C;
    wire [1:0] ALUOp;
    ALU alu(A,B,ALUOp,C);   
    wire [DATA_SIZE-1:0] mem_out,
                         mem_in;
    wire [ADDRESS_LENGTH-1:0] mem_address;
    wire write_enable_mem;
    wire [DATA_SIZE-1:0] fetch_out;
    wire [ADDRESS_LENGTH-1:0] PC_address;
    memory mem(mem_address,PC_address,mem_in,mem_out,fetch_out,write_enable_mem,clock,reset);
    defparam mem.MEM_INIT_FILE = MEM_INIT_FILE;
    
    wire [DATA_SIZE-1:0] PC_next;
    wire [DATA_SIZE-1:0] instruction;
    wire PC_enable;
    register #(.RESET_VAL(31)) PC(PC_out,PC_next,reset,PC_enable,clock);
    fetch_unit FU(PC_out,fetch_out,PC_address,instruction);
    
    wire mcu_op,mcu_en;
    wire [DATA_SIZE-1:0] r_in_data,r_out_data,r_out_address;
    memory_controller MCU(mcu_op,mcu_en,r_out_address,r_out_data,mem_out,r_in_data,mem_in,,write_enable_mem,mem_address);
    
    reg cmp_reg;
    wire cmp_next;
    always@(posedge clock)
        cmp_reg=cmp_next;
    
    control controller(instruction,reg_select1,reg_select2,reg_out1,reg_out2,mcu_op,mcu_en,r_in_data,r_out_data,r_out_address,write_enable1,write_enable2,reg_in1,reg_in2,
        PC_out,PC_next,PC_enable,
        A,B,ALUOp,C,
        cmp_reg,cmp_next,
        continue);
endmodule

module control#(
    parameter DATA_SIZE = 16,
    parameter ADDRESS_LENGTH = 12
    )(input [DATA_SIZE-1:0] instruction,
      output [2:0] Rn,Rm,
      input [DATA_SIZE-1:0] Rn_out,Rm_out,
      output reg mcu_op, mcu_en,
      input [DATA_SIZE-1:0] r_in_data,
      output reg [DATA_SIZE-1:0] r_out_data,r_out_address,
      output reg Rn_write,Rm_write,
      output reg [DATA_SIZE-1:0] Rn_in,Rm_in,
      input [DATA_SIZE-1:0] PC_out,
      output reg [DATA_SIZE-1:0] PC_next,
      output reg PC_enable,
      output reg [DATA_SIZE-1:0] A,
      output reg [DATA_SIZE-1:0] B,
      output reg [1:0] ALUOp,
      input [DATA_SIZE-1:0] C,
      input cmp_reg, output reg cmp_next,
      input continue
      );
    wire [3:0] operation;
    
    assign operation = instruction[15:12];
    assign Rn = instruction[8:6];
    assign Rm = instruction[2:0];
    
    wire div_sign;
    assign div_sign =Rm_out[DATA_SIZE-1];
    reg [DATA_SIZE-1:0] divtmp; 
        
    always@(*) begin
    //default:
    begin
        r_out_address=0;
        mcu_op = 0;
        mcu_en = 0;
        Rn_write=0;
        Rm_write=0;
        Rn_in=0;
        Rm_in=0;
        PC_next = PC_out+1;
        PC_enable=1;
        A=0;
        B=0;
        ALUOp=0;
        r_out_data=0;
        cmp_next= cmp_reg;
    end
    case(operation)
        4'b0000: begin
            if(~continue)
                PC_next = PC_out;
        end
        4'b0001: begin
            Rm_write=1;
            A=Rm_out;
            ALUOp=2'b10;
            Rm_in= C;
        end
        4'b0010 : begin//j
            PC_next=instruction[11:0];
        end
        4'b0011 : begin//jne
            if(~cmp_reg)
                PC_next=instruction[11:0];
        end
        4'b0100 : begin//je
            if(cmp_reg)
                PC_next=instruction[11:0];
        end
        4'b0101 : begin //add
            A=Rn_out;
            B=Rm_out;
            Rn_in=C;
            Rn_write=1;
            ALUOp=2'b00;
        end
        4'b0110 : begin //sub
            A=Rn_out;
            B=Rm_out;
            Rn_in=C;
            Rn_write=1;
            ALUOp=2'b01;
        end
        4'b0111 : begin//xor
            A=Rn_out;
            B=Rm_out;
            Rn_in=C;
            Rn_write=1;
            ALUOp=2'b11;
        end
        4'b1000 : begin //cmp ( subtract, then check for all 0 C
            A=Rn_out;
            B=Rm_out;
            cmp_next=~(|C);
            ALUOp=2'b01;
        end
        4'b1001 : begin //mov Rn,num
            Rn_write=1;
            Rn_in = $signed(instruction[5:0]);
        end
        4'b1010 : begin //mov Rn,Rm
            Rn_write=1;
            Rn_in = Rm_out;
        end
        4'b1011: begin //mov [Rn],Rm
            mcu_op = 0;
            mcu_en = 1;
            Rn_write=0;
            Rm_write=0;
            r_out_address =Rn_out;
            r_out_data=Rm_out;
        end
        4'b1100 : begin //mov Rn,[Rm]
            mcu_op = 1;
            mcu_en = 1;
            Rn_write=1;
            Rm_write=0;
            r_out_address =Rm_out;
            Rn_in=r_in_data;
        end
        4'b1101 : begin //special 1 : SMULT
            Rn_write=1;
            Rn_in=Rn_out*Rm_out;
        end
        4'b1110 : begin //special 2 SDIV
            Rn_write=1;
            divtmp=Rn_out/(div_sign)?(-Rm_out):Rm_out;
            Rn_in=(div_sign)?-divtmp:divtmp;
        end
        4'b1111 : begin //special 3 inc [Rn]
            mcu_op = 0;
            mcu_en = 1;
            r_out_address =Rn_out;
            r_out_data=r_in_data+1;
        end
        
     endcase
     end

    
endmodule
