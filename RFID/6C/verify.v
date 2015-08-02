// ************************************************************** 
// COPYRIGHT, Xi'an XDU Radio-frequency IC Co.,Ltd 
// All rights reserved. 
// 
// IP LIB INDEX : IP lib index just sa UTOPIA_B 
// IP Name      : OPTIM
//
// File name    : decoder.v
// Module name  : DECODER
// Full name    : PIE Decoder Unit 
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

module VERIFY(
                //inputs
                DOUB_BLF,
                rst_n,
                new_cmd,
                ver_pulse,
                handle,
                
                //outputs
                ver_code,
                ver_done
            );

    //inputs
    input              DOUB_BLF;
    input              rst_n;
    input              new_cmd;
    input              ver_pulse;
    input    [15:0]    handle;
                
    //outputs
    output   [7:0]     ver_code;
    output             ver_done;
    
    //regs
    reg      [7:0]     ver_code;
    reg                ver_done;
    ////////
    reg                ver_en;
    reg      [3:0]     ver_cnt;
    
    //wires
    wire               ver_rst;
    wire               ver_clk;
    wire               ver_bit;
    wire               ver_xor0;
    wire               ver_xor1;
    wire               ver_xor2;
    
    assign ver_rst=rst_n&~new_cmd;
    
    always @(posedge ver_pulse or negedge ver_done or negedge rst_n)
    begin
        if(!rst_n)
            ver_en<=`UDLY 1'b0;
        else if(ver_pulse)
            ver_en<=`UDLY 1'b1;
        else
            ver_en<=`UDLY 1'b0;
    end
    
    assign ver_clk=DOUB_BLF&ver_en;
    
    always @(posedge ver_clk or negedge ver_rst)
    begin
        if(!ver_rst)
            ver_cnt<=`UDLY 4'd15;
        else
            ver_cnt<=`UDLY ver_cnt+1'b1;
    end
    
    always @(negedge ver_clk or negedge rst_n)
    begin
        if(!rst_n)
            ver_done<=`UDLY 1'b0;
        else if(ver_cnt==4'd14)
            ver_done<=`UDLY 1'b1;
        else
            ver_done<=`UDLY 1'b0;
    end
    
    assign ver_bit=handle[ver_cnt];
    
    assign ver_xor0=ver_bit^ver_code[7];
    assign ver_xor1=ver_xor0^ver_code[1];
    assign ver_xor2=ver_xor0^ver_code[4];
    
    always @(negedge ver_clk or negedge ver_rst)
    begin
        if(!ver_rst)
            ver_code<=`UDLY 8'hff;
        else
            ver_code<=`UDLY {ver_code[7],ver_code[6],ver_xor2,ver_code[4],ver_code[3],ver_xor1,ver_code[1],ver_xor0};
    end
            
endmodule
                