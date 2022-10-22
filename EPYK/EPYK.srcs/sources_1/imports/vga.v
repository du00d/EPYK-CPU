`timescale 1ns / 1ps

// Generate HS, VS signals from pixel clock.
// hcounter & vcounter are the index of the current pixel 
// origin (0, 0) at top-left corner of the screen
// valid display range for hcounter: [0, 640)
// valid display range for vcounter: [0, 480)
module vga_controller_640_60 (pixel_clk,HS,VS,hcounter,vcounter,blank);

	input pixel_clk;
	output HS, VS, blank;
	output [10:0] hcounter, vcounter;

	parameter HMAX = 800; // maximum value for the horizontal pixel counter
	parameter VMAX = 525; // maximum value for the vertical pixel counter
	parameter HLINES = 640; // total number of visible columns
	parameter HFP = 648; // value for the horizontal counter where front porch ends
	parameter HSP = 744; // value for the horizontal counter where the synch pulse ends
	parameter VLINES = 480; // total number of visible lines
	parameter VFP = 482; // value for the vertical counter where the front porch ends
	parameter VSP = 484; // value for the vertical counter where the synch pulse ends
	parameter SPP = 0;


	wire video_enable;
	reg HS,VS,blank;
	reg [10:0] hcounter,vcounter;

	always@(posedge pixel_clk)begin
		blank <= ~video_enable; 
	end

	always@(posedge pixel_clk)begin
		if (hcounter == HMAX) hcounter <= 0;
		else hcounter <= hcounter + 1;
	end

	always@(posedge pixel_clk)begin
		if(hcounter == HMAX) begin
			if(vcounter == VMAX) vcounter <= 0;
			else vcounter <= vcounter + 1; 
		end
	end

	always@(posedge pixel_clk)begin
		if(hcounter >= HFP && hcounter < HSP) HS <= SPP;
		else HS <= ~SPP; 
	end

	always@(posedge pixel_clk)begin
		if(vcounter >= VFP && vcounter < VSP) VS <= SPP;
		else VS <= ~SPP; 
	end

	assign video_enable = (hcounter < HLINES && vcounter < VLINES) ? 1'b1 : 1'b0;

endmodule
module map4(input [15:0] digits,
            output wire [7*4-1:0] hexies);
    genvar i;
    for(i=0;i<4;i=i+1) begin
        map map0(digits[(i+1)*4-1:i*4],hexies[(i+1)*7-1:i*7]);
    end
endmodule



module map(
    input [3:0] digit,
    output reg [6:0] hex
    );
    always@(*)begin
    case(digit)
    0: hex = 7'h30;
    1: hex = 7'h31;
    2: hex = 7'h32;
    3: hex = 7'h33;
    4: hex = 7'h34;
    5: hex = 7'h35;
    6: hex = 7'h36;
    7: hex = 7'h37;
    8: hex = 7'h38;
    9: hex = 7'h39;
    10: hex = 7'h41; 
    11: hex = 7'h42;
    12: hex = 7'h43;
    13: hex = 7'h44;
    14: hex = 7'h45;
    15: hex = 7'h46;
    endcase
    end
endmodule
module hex7seg(
    input wire [3:0] x,
    output reg [6:0] out
);
always @(*)
begin
case(x)
0:   out = 7'b0000001;
1:   out = 7'b1000111;
2:   out = 7'b0010010;
3:   out = 7'b0000110;
4:   out = 7'b1001100;
5:   out = 7'b0100100;
6:   out = 7'b0100010;
7:   out = 7'b0001111;
8:   out = 7'b0000000;
9:   out = 7'b1000100;
'hA: out = 7'b0001000;
'hB: out = 7'b1100000;
'hC: out = 7'b0110001;
'hD: out = 7'b1000010;
'hE: out = 7'b0110000;
'hF: out = 7'b01110000;


default out = 7'b0000001;
endcase
end
endmodule
// top module that instantiate the VGA controller and generate images
module top(
    input wire CLK100MHZ,
    input wire res,
    input wire user_clock,
    input wire continue,
    output reg [3:0] VGA_R,
    output reg [3:0] VGA_G,
    output reg [3:0] VGA_B,
    output wire VGA_HS,
    output wire VGA_VS,
    output wire [15:0] PC_out,
    output wire [6:0] LED_out,
    output wire [7:0] AN,
    output wire DP
    );

reg pclk_div_cnt;
reg pixel_clk;
wire [10:0] vga_hcnt, vga_vcnt;
wire vga_blank;

// Clock divider. Generate 25MHz pixel_clk from 100MHz clock.
always @(posedge CLK100MHZ) begin
    pclk_div_cnt <= !pclk_div_cnt;
    if (pclk_div_cnt == 1'b1) pixel_clk <= !pixel_clk;
end



// Instantiate VGA controller
vga_controller_640_60 vga_controller(
    .pixel_clk(pixel_clk),
    .HS(VGA_HS),
    .VS(VGA_VS),
    .hcounter(vga_hcnt),
    .vcounter(vga_vcnt),
    .blank(vga_blank)
);

reg [10:0] addr;
wire [7:0] data;
wire [16*6-1:0] R;
CPU_wrapper epyc(CLK100MHZ, user_clock, res, continue, PC_out, R);

// Generate figure to be displayed
// Decide the color for the current pixel at index (hcnt, vcnt).
// This example displays an white square at the center of the screen with a colored checkerboard background.
font_rom(pixel_clk, addr, data);

wire [7*4-1:0] hexiesR0; 
wire [7*4-1:0] hexiesR1;
wire [7*4-1:0] hexiesR2; 
wire [7*4-1:0] hexiesR3; 
wire [7*4-1:0] hexiesR4; 
wire [7*4-1:0] hexiesR5; 
 
wire [7*4-1:0] pcouts; 


map4 R0 (R[15:0], hexiesR0);
map4 R1 (R[31:16], hexiesR1);
map4 R2 (R[47:32], hexiesR2);
map4 R3 (R[63:48], hexiesR3);
map4 R4 (R[79:64], hexiesR4);
map4 R5 (R[95:80], hexiesR5);
map4 PC (PC_out, pcouts);

hex7seg SEGMENT(pcouts[3:0], LED_out);
assign AN = 8'b11111110;
assign DP = 1;



always @(*) begin

    
    // Set pixels to black during Sync. Failure to do so will result in dimmed colors or black screens.
    if (vga_blank) begin 
        VGA_R = 0;
        VGA_G = 0;
        VGA_B = 0;
    end
    else begin  // Image to be displayed
        // Default values for the checkerboard background
        VGA_R = 8'b11111111;
        VGA_G = 8'b11111111;
        VGA_B = 8'b11111111;
        if ((vga_hcnt >= 50 && vga_hcnt <= 58 ) &&
        	(vga_vcnt >= 50 && vga_vcnt <= 66)) begin
        	addr[10:4] = 7'h52;
        	addr[3:0] = vga_vcnt - 50;
        	//addr[vga_vcnt - 50;
			if (data[58-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        
        if ((vga_hcnt >= 60 && vga_hcnt <= 68 ) &&
        	(vga_vcnt >= 50 && vga_vcnt <= 66)) begin
        	addr[10:4] = 7'h30;
        	addr[3:0] = vga_vcnt - 50;
        	//addr[vga_vcnt - 50;
			if (data[68-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        
        if ((vga_hcnt >= 70 && vga_hcnt <= 78 ) &&
        	(vga_vcnt >= 50 && vga_vcnt <= 66)) begin
        	addr[10:4] = 7'h3a;
        	addr[3:0] = vga_vcnt - 50;
        	//addr[vga_vcnt - 50;
			if (data[78-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        
        if ((vga_hcnt >= 80 && vga_hcnt <= 88 ) &&
        	(vga_vcnt >= 50 && vga_vcnt <= 66)) begin
        	addr[10:4] = 7'h30;
        	addr[3:0] = vga_vcnt - 50;
        	//addr[vga_vcnt - 50;
			if (data[88-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        
         if ((vga_hcnt >= 90 && vga_hcnt <= 98 ) &&
        	(vga_vcnt >= 50 && vga_vcnt <= 66)) begin
        	addr[10:4] = 7'h78;
        	addr[3:0] = vga_vcnt - 50;
        	//addr[vga_vcnt - 50;
			if (data[98-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
         // r0 input
         if ((vga_hcnt >= 100 && vga_hcnt <=108 ) &&
        	(vga_vcnt >= 50 && vga_vcnt <= 66)) begin
        	addr[10:4] = hexiesR0[7*1-1:0];
        	addr[3:0] = vga_vcnt - 50;
        	//addr[vga_vcnt - 50;
			if (data[108-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        if ((vga_hcnt >= 110 && vga_hcnt <=118 ) &&
        	(vga_vcnt >= 50 && vga_vcnt <= 66)) begin
        	addr[10:4] = hexiesR0[7*2-1:1*7];
        	addr[3:0] = vga_vcnt - 50;
        	//addr[vga_vcnt - 50;
			if (data[118-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        
         if ((vga_hcnt >= 120 && vga_hcnt <=128 ) &&
        	(vga_vcnt >= 50 && vga_vcnt <= 66)) begin
        	addr[10:4] = hexiesR0[7*3-1:2*7];
        	addr[3:0] = vga_vcnt - 50;
        	//addr[vga_vcnt - 50;
			if (data[128-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        if ((vga_hcnt >= 130 && vga_hcnt <=138 ) &&
        	(vga_vcnt >= 50 && vga_vcnt <= 66)) begin
        	addr[10:4] = hexiesR0[7*4-1:3*7];
        	addr[3:0] = vga_vcnt - 50;
        	//addr[vga_vcnt - 50;
			if (data[138-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        
        
        
        // R1
        
        
         if ((vga_hcnt >= 50 && vga_hcnt <= 58 ) &&
        	(vga_vcnt >= 70 && vga_vcnt <= 86)) begin
        	addr[10:4] = 7'h52;
        	addr[3:0] = vga_vcnt - 70;
        	//addr[vga_vcnt - 50;
			if (data[58-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
      
        if ((vga_hcnt >= 60 && vga_hcnt <= 68 ) &&
        	(vga_vcnt >= 70 && vga_vcnt <= 86)) begin
        	addr[10:4] = 7'h31;
        	addr[3:0] = vga_vcnt - 70;
        	//addr[vga_vcnt - 50;
			if (data[68-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
       if ((vga_hcnt >= 70 && vga_hcnt <= 78 ) &&
        	(vga_vcnt >= 70 && vga_vcnt <= 86)) begin
        	addr[10:4] = 7'h3a;
        	addr[3:0] = vga_vcnt - 70;
        	//addr[vga_vcnt - 50;
			if (data[78-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        
        if ((vga_hcnt >= 80 && vga_hcnt <= 88 ) &&
        	(vga_vcnt >= 70 && vga_vcnt <= 86)) begin
        	addr[10:4] = 7'h30;
        	addr[3:0] = vga_vcnt - 70;
        	//addr[vga_vcnt - 50;
			if (data[88-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        
         if ((vga_hcnt >= 90 && vga_hcnt <= 98 ) &&
        	(vga_vcnt >= 70 && vga_vcnt <= 86)) begin
        	addr[10:4] = 7'h78;
        	addr[3:0] = vga_vcnt - 70;
        	//addr[vga_vcnt - 50;
			if (data[98-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
         // r1 input
         if ((vga_hcnt >= 100 && vga_hcnt <=108 ) &&
        	(vga_vcnt >= 70 && vga_vcnt <= 86)) begin
        	addr[10:4] = hexiesR1[7*1-1:0];
        	addr[3:0] = vga_vcnt - 70;
        	//addr[vga_vcnt - 50;
			if (data[108-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        if ((vga_hcnt >= 110 && vga_hcnt <=118 ) &&
        	(vga_vcnt >= 70 && vga_vcnt <= 86)) begin
        	addr[10:4] = hexiesR1[7*2-1:1*7];
        	addr[3:0] = vga_vcnt - 70;
        	//addr[vga_vcnt - 50;
			if (data[118-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        
         if ((vga_hcnt >= 120 && vga_hcnt <=128 ) &&
        	(vga_vcnt >= 70 && vga_vcnt <= 86)) begin
        	addr[10:4] = hexiesR1[7*3-1:2*7];
        	addr[3:0] = vga_vcnt - 70;
        	//addr[vga_vcnt - 50;
			if (data[128-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        if ((vga_hcnt >= 130 && vga_hcnt <=138 ) &&
        	(vga_vcnt >= 70 && vga_vcnt <= 86)) begin
        	addr[10:4] = hexiesR1[7*4-1:3*7];
        	addr[3:0] = vga_vcnt - 70;
        	//addr[vga_vcnt - 50;
			if (data[138-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end       
        // R2
        
         if ((vga_hcnt >= 50 && vga_hcnt <= 58 ) &&
        	(vga_vcnt >= 90 && vga_vcnt <= 106)) begin
        	addr[10:4] = 7'h52;
        	addr[3:0] = vga_vcnt - 90;
        	
			if (data[58-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        
        if ((vga_hcnt >= 60 && vga_hcnt <= 68 ) &&
        	(vga_vcnt >= 90 && vga_vcnt <= 106)) begin
        	addr[10:4] = 7'h32;
        	addr[3:0] = vga_vcnt - 90;
        	//addr[vga_vcnt - 50;
			if (data[68-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end

        if ((vga_hcnt >= 70 && vga_hcnt <= 78 ) &&
        	(vga_vcnt >= 90 && vga_vcnt <= 106)) begin
        	addr[10:4] = 7'h3a;
        	addr[3:0] = vga_vcnt - 90;
        	//addr[vga_vcnt - 50;
			if (data[78-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        
        if ((vga_hcnt >= 80 && vga_hcnt <= 88 ) &&
        	(vga_vcnt >= 90 && vga_vcnt <= 106)) begin
        	addr[10:4] = 7'h30;
        	addr[3:0] = vga_vcnt - 90;
        	//addr[vga_vcnt - 50;
			if (data[88-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        
         if ((vga_hcnt >= 90 && vga_hcnt <= 98 ) &&
        	(vga_vcnt >= 90 && vga_vcnt <= 106)) begin
        	addr[10:4] = 7'h78;
        	addr[3:0] = vga_vcnt - 90;
        	//addr[vga_vcnt - 50;
			if (data[98-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
         // r1 input
         if ((vga_hcnt >= 100 && vga_hcnt <=108 ) &&
        	(vga_vcnt >= 90 && vga_vcnt <= 106)) begin
        	addr[10:4] = hexiesR2[7*1-1:0];
        	addr[3:0] = vga_vcnt - 90;
        	//addr[vga_vcnt - 50;
			if (data[108-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        if ((vga_hcnt >= 110 && vga_hcnt <=118 ) &&
        	(vga_vcnt >= 90 && vga_vcnt <= 106)) begin
        	addr[10:4] = hexiesR2[7*2-1:1*7];
        	addr[3:0] = vga_vcnt - 90;
        	//addr[vga_vcnt - 50;
			if (data[118-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        
         if ((vga_hcnt >= 120 && vga_hcnt <=128 ) &&
        	(vga_vcnt >= 90 && vga_vcnt <= 106)) begin
        	addr[10:4] = hexiesR2[7*3-1:2*7];
        	addr[3:0] = vga_vcnt - 90;
        	//addr[vga_vcnt - 50;
			if (data[128-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        if ((vga_hcnt >= 130 && vga_hcnt <=138 ) &&
        	(vga_vcnt >= 90 && vga_vcnt <= 106)) begin
        	addr[10:4] = hexiesR2[7*4-1:3*7];
        	addr[3:0] = vga_vcnt - 90;
        	//addr[vga_vcnt - 50;
			if (data[138-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end              
         // R3
        
         if ((vga_hcnt >= 50 && vga_hcnt <= 58 ) &&
        	(vga_vcnt >= 110 && vga_vcnt <= 126)) begin
        	addr[10:4] = 7'h52;
        	addr[3:0] = vga_vcnt - 110;
        	//addr[vga_vcnt - 50;
			if (data[58-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        
        if ((vga_hcnt >= 60 && vga_hcnt <= 68 ) &&
        	(vga_vcnt >= 110 && vga_vcnt <= 126)) begin
        	addr[10:4] = 7'h33;
        	addr[3:0] = vga_vcnt - 110;
        	//addr[vga_vcnt - 50;
			if (data[68-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        if ((vga_hcnt >= 70 && vga_hcnt <= 78 ) &&
        	(vga_vcnt >= 110 && vga_vcnt <= 126)) begin
        	addr[10:4] = 7'h3a;
        	addr[3:0] = vga_vcnt - 110;
        	//addr[vga_vcnt - 50;
			if (data[78-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        
        if ((vga_hcnt >= 80 && vga_hcnt <= 88 ) &&
        	(vga_vcnt >= 110 && vga_vcnt <= 126)) begin
        	addr[10:4] = 7'h30;
        	addr[3:0] = vga_vcnt - 110;
        	//addr[vga_vcnt - 50;
			if (data[88-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        
         if ((vga_hcnt >= 90 && vga_hcnt <= 98 ) &&
        	(vga_vcnt >= 110 && vga_vcnt <= 126)) begin
        	addr[10:4] = 7'h78;
        	addr[3:0] = vga_vcnt - 110;
        	//addr[vga_vcnt - 50;
			if (data[98-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
         // r1 input
         if ((vga_hcnt >= 100 && vga_hcnt <=108 ) &&
        	(vga_vcnt >= 110 && vga_vcnt <= 126)) begin
        	addr[10:4] = hexiesR3[7*1-1:0];
        	addr[3:0] = vga_vcnt - 110;
        	//addr[vga_vcnt - 50;
			if (data[108-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        if ((vga_hcnt >= 110 && vga_hcnt <=118 ) &&
        	(vga_vcnt >= 110 && vga_vcnt <= 126)) begin
        	addr[10:4] = hexiesR3[7*2-1:1*7];
        	addr[3:0] = vga_vcnt - 110;
        	//addr[vga_vcnt - 50;
			if (data[118-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        
         if ((vga_hcnt >= 120 && vga_hcnt <=128 ) &&
        	(vga_vcnt >= 110 && vga_vcnt <= 126)) begin
        	addr[10:4] = hexiesR3[7*3-1:2*7];
        	addr[3:0] = vga_vcnt - 110;
        	//addr[vga_vcnt - 50;
			if (data[128-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        if ((vga_hcnt >= 130 && vga_hcnt <=138 ) &&
        	(vga_vcnt >= 110 && vga_vcnt <= 126)) begin
        	addr[10:4] = hexiesR3[7*4-1:3*7];
        	addr[3:0] = vga_vcnt - 110;
        	//addr[vga_vcnt - 50;
			if (data[138-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end                  
        
        
        // R4
        
         if ((vga_hcnt >= 50 && vga_hcnt <= 58 ) &&
        	(vga_vcnt >= 130 && vga_vcnt <= 146)) begin
        	addr[10:4] = 7'h52;
        	addr[3:0] = vga_vcnt - 130;
        	//addr[vga_vcnt - 50;
			if (data[58-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        
        if ((vga_hcnt >= 60 && vga_hcnt <= 68 ) &&
        	(vga_vcnt >= 130 && vga_vcnt <= 146)) begin
        	addr[10:4] = 7'h34;
        	addr[3:0] = vga_vcnt - 130;
        	//addr[vga_vcnt - 50;
			if (data[68-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        
         if ((vga_hcnt >= 70 && vga_hcnt <= 78 ) &&
        	(vga_vcnt >= 130 && vga_vcnt <= 146)) begin
        	addr[10:4] = 7'h3a;
        	addr[3:0] = vga_vcnt - 130;
        	//addr[vga_vcnt - 50;
			if (data[78-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        
        if ((vga_hcnt >= 80 && vga_hcnt <= 88 ) &&
        	(vga_vcnt >= 130 && vga_vcnt <= 146)) begin
        	addr[10:4] = 7'h30;
        	addr[3:0] = vga_vcnt - 130;
        	//addr[vga_vcnt - 50;
			if (data[88-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        
         if ((vga_hcnt >= 90 && vga_hcnt <= 98 ) &&
        	(vga_vcnt >= 130 && vga_vcnt <= 146)) begin
        	addr[10:4] = 7'h78;
        	addr[3:0] = vga_vcnt - 130;
        	//addr[vga_vcnt - 50;
			if (data[98-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
         // r4 input
         if ((vga_hcnt >= 100 && vga_hcnt <=108 ) &&
        	(vga_vcnt >= 130 && vga_vcnt <= 146)) begin
        	addr[10:4] = hexiesR4[7*1-1:0];
        	addr[3:0] = vga_vcnt - 130;
        	//addr[vga_vcnt - 50;
			if (data[108-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        if ((vga_hcnt >= 110 && vga_hcnt <=118 ) &&
        	(vga_vcnt >= 130 && vga_vcnt <= 146)) begin
        	addr[10:4] = hexiesR4[7*2-1:1*7];
        	addr[3:0] = vga_vcnt - 130;
        	//addr[vga_vcnt - 50;
			if (data[118-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        
         if ((vga_hcnt >= 120 && vga_hcnt <=128 ) &&
        	(vga_vcnt >= 130 && vga_vcnt <= 146)) begin
        	addr[10:4] = hexiesR4[7*3-1:2*7];
        	addr[3:0] = vga_vcnt - 130;
        	//addr[vga_vcnt - 50;
			if (data[128-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        if ((vga_hcnt >= 130 && vga_hcnt <=138 ) &&
        	(vga_vcnt >= 130 && vga_vcnt <= 146)) begin
        	addr[10:4] = hexiesR4[7*4-1:3*7];
        	addr[3:0] = vga_vcnt - 130;
        	//addr[vga_vcnt - 50;
			if (data[138-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end          
        
         // R5
        
         if ((vga_hcnt >= 50 && vga_hcnt <= 58 ) &&
        	(vga_vcnt >= 150 && vga_vcnt <= 166)) begin
        	addr[10:4] = 7'h52;
        	addr[3:0] = vga_vcnt - 150;
        	//addr[vga_vcnt - 50;
			if (data[58-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        
        if ((vga_hcnt >= 60 && vga_hcnt <= 68 ) &&
        	(vga_vcnt >= 150 && vga_vcnt <= 166)) begin
        	addr[10:4] = 7'h35;
        	addr[3:0] = vga_vcnt - 150;
        	//addr[vga_vcnt - 50;
			if (data[68-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
         if ((vga_hcnt >= 70 && vga_hcnt <= 78 ) &&
        	(vga_vcnt >= 150 && vga_vcnt <= 166)) begin
        	addr[10:4] = 7'h3a;
        	addr[3:0] = vga_vcnt - 150;
        	//addr[vga_vcnt - 50;
			if (data[78-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        
        if ((vga_hcnt >= 80 && vga_hcnt <= 88 ) &&
        	(vga_vcnt >= 150 && vga_vcnt <= 166)) begin
        	addr[10:4] = 7'h30;
        	addr[3:0] = vga_vcnt - 150;
        	//addr[vga_vcnt - 50;
			if (data[88-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        
         if ((vga_hcnt >= 90 && vga_hcnt <= 98 ) &&
        	(vga_vcnt >= 150 && vga_vcnt <= 166)) begin
        	addr[10:4] = 7'h78;
        	addr[3:0] = vga_vcnt - 150;
        	//addr[vga_vcnt - 50;
			if (data[98-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
         // r5 input
         if ((vga_hcnt >= 100 && vga_hcnt <=108 ) &&
        	(vga_vcnt >= 150 && vga_vcnt <= 166)) begin
        	addr[10:4] = hexiesR5[7*1-1:0];
        	addr[3:0] = vga_vcnt - 150;
        	//addr[vga_vcnt - 50;
			if (data[108-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        if ((vga_hcnt >= 110 && vga_hcnt <=118 ) &&
        	(vga_vcnt >= 150 && vga_vcnt <= 166)) begin
        	addr[10:4] = hexiesR5[7*2-1:1*7];
        	addr[3:0] = vga_vcnt - 150;
        	//addr[vga_vcnt - 50;
			if (data[118-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        
         if ((vga_hcnt >= 120 && vga_hcnt <=128 ) &&
        	(vga_vcnt >= 150 && vga_vcnt <= 166)) begin
        	addr[10:4] = hexiesR5[7*3-1:2*7];
        	addr[3:0] = vga_vcnt - 150;
        	//addr[vga_vcnt - 50;
			if (data[128-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        if ((vga_hcnt >= 130 && vga_hcnt <=138 ) &&
        	(vga_vcnt >= 150 && vga_vcnt <= 166)) begin
        	addr[10:4] = hexiesR5[7*4-1:3*7];
        	addr[3:0] = vga_vcnt - 150;
        	//addr[vga_vcnt - 50;
			if (data[138-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end                  
        // PC
        
         if ((vga_hcnt >= 50 && vga_hcnt <= 58 ) &&
        	(vga_vcnt >= 170 && vga_vcnt <= 186)) begin
        	addr[10:4] = 7'h50;
        	addr[3:0] = vga_vcnt - 170;
        	//addr[vga_vcnt - 50;
			if (data[58-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        
        if ((vga_hcnt >= 60 && vga_hcnt <= 68 ) &&
        	(vga_vcnt >= 170 && vga_vcnt <= 186)) begin
        	addr[10:4] = 7'h43;
        	addr[3:0] = vga_vcnt - 170;
        	//addr[vga_vcnt - 50;
			if (data[68-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        
        
         if ((vga_hcnt >= 70 && vga_hcnt <= 78 ) &&
        	(vga_vcnt >= 170 && vga_vcnt <= 186)) begin
        	addr[10:4] = 7'h3a;
        	addr[3:0] = vga_vcnt - 170;
        	//addr[vga_vcnt - 50;
			if (data[78-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        
        if ((vga_hcnt >= 80 && vga_hcnt <= 88 ) &&
        	(vga_vcnt >= 170 && vga_vcnt <= 186)) begin
        	addr[10:4] = 7'h30;
        	addr[3:0] = vga_vcnt - 170;
        	//addr[vga_vcnt - 50;
			if (data[88-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        
         if ((vga_hcnt >= 90 && vga_hcnt <= 98 ) &&
        	(vga_vcnt >= 170 && vga_vcnt <= 186)) begin
        	addr[10:4] = 7'h78;
        	addr[3:0] = vga_vcnt - 170;
        	//addr[vga_vcnt - 50;
			if (data[98-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
         // pc input
         if ((vga_hcnt >= 100 && vga_hcnt <=108 ) &&
        	(vga_vcnt >= 170 && vga_vcnt <= 186)) begin
        	addr[10:4] = pcouts[7*1-1:0];
        	addr[3:0] = vga_vcnt - 170;
        	//addr[vga_vcnt - 50;
			if (data[108-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        if ((vga_hcnt >= 110 && vga_hcnt <=118 ) &&
        	(vga_vcnt >= 170 && vga_vcnt <= 186)) begin
        	addr[10:4] = pcouts[7*2-1:1*7];
        	addr[3:0] = vga_vcnt - 170;
        	//addr[vga_vcnt - 50;
			if (data[118-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        
         if ((vga_hcnt >= 120 && vga_hcnt <=128 ) &&
        	(vga_vcnt >= 170 && vga_vcnt <= 186)) begin
        	addr[10:4] = pcouts[7*3-1:2*7];
        	addr[3:0] = vga_vcnt - 170;
        	//addr[vga_vcnt - 50;
			if (data[128-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end
        if ((vga_hcnt >= 130 && vga_hcnt <=138 ) &&
        	(vga_vcnt >= 170 && vga_vcnt <= 186)) begin
        	addr[10:4] = pcouts[7*4-1:3*7];
        	addr[3:0] = vga_vcnt - 170;
        	//addr[vga_vcnt - 50;
			if (data[138-vga_hcnt] == 1) begin
			VGA_R = 4'h0;
			VGA_G = 4'h0;
			VGA_B = 4'h0;
			end
			else begin
			VGA_R = 4'hf;
			VGA_G = 4'hf;
			VGA_B = 4'hf;
			end
        end        
    end
end

endmodule
