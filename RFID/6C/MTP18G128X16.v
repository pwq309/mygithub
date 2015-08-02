// ************************************************************** 
// COPYRIGHT, Xi'an XDU Radio-frequency IC Co.,Ltd 
// All rights reserved. 
// 
// IP LIB INDEX : IP lib index just sa UTOPIA_B 
// IP Name      : OPTIM
//
// File name    : MTP18G128X16.v
// Module name  : MTP18G128X16
// Full name    : MTP18G128X16 
// 
// Author       : panwanqiang
// Email        : 
// Data         : 2013/04/28
// Version      : V1.0 
// 
// Abstract     : 
// Called by    : OPTIM
// 
// Modification history 
// ---------------------------------------- 
//
// $Log$ 
// 
// ************************************************************** 

`timescale 1ns/1ns
`define UDLY #5

module MTP18G32X16(
                //inputs
                //rst_n,
                DATA_WR,
                FUSEADR,
                FE,
                RECALL,
                SE,
                PROG,
                NVSTR,
                DRT,
                MRGEN,
                MRGSEL,
                
                //outputs
                DBO,
                READY
            );

    //inputs
   // input              rst_n;
    input    [15:0]    DATA_WR;
    input    [4:0]     FUSEADR;
    input              FE;
    input              RECALL;
    input              SE;
    input              PROG;
    input              NVSTR;
    input              DRT;
    input              MRGEN;
    input              MRGSEL;
    
    //outputs
    output   [15:0]    DBO;
    output             READY;
    
    //regs
    reg      [15:0]    DBO;
    reg                READY;
    ////////////////Memory
    reg      [15:0]    mem[31:0];
	 
    integer i;
	 initial
	 
	     begin
            mem[0]<=`UDLY 16'h1234;
            mem[1]<=`UDLY 16'h5678;
            mem[2]<=`UDLY 16'habcd;
            mem[3]<=`UDLY 16'hef00;
            mem[4]<=`UDLY 16'h0000;
            mem[5]<=`UDLY 16'h0000;
            mem[6]<=`UDLY 16'h0000;
            mem[7]<=`UDLY 16'h3014;
            mem[8]<=`UDLY 16'h0000;            
            for(i=9; i<32; i=i+1)
            begin
                mem[i]<=`UDLY 16'h0000;
            end
		  end
	 
    always @(posedge SE )
	 begin
        if(RECALL)
            DBO<=`UDLY mem[FUSEADR];
        else
            DBO<=`UDLY 16'h0000;       
    end
    
    always @(posedge NVSTR  )
	 begin
        if(PROG&FE)
            mem[FUSEADR]<=`UDLY DATA_WR;
        else
            mem[FUSEADR]<=`UDLY mem[FUSEADR];
    end
    
endmodule