// ************************************************************** 
// COPYRIGHT, Xi'an XDU Radio-frequency IC Co.,Ltd 
// All rights reserved. 
// 
// IP LIB INDEX : IP lib index just sa UTOPIA_B 
// IP Name      : OPTIM
//
// File name    : rst.v
// Module name  : RST
// Full name    : Reset Control Unit 
// 
// Author       : panwanqiang
// Email        :  
// Data         : 2013/04/28
// Version      : V1.0 
// 
// Abstract     : 
// Called by    : RFID_TOP
// 
// Modification history 
// ---------------------------------------- 
//
// $Log$ 
// 
// ************************************************************** 

`timescale 1ns/1ns
`define UDLY #5

module RST(
                //inputs
                clk_50m,
                rd_data,
                rst_n,
                
                //output
                sys_rst
            );
            
    //inputs
    input            clk_50m;
    input            rd_data;
    input            rst_n;
                     
                     
    output           sys_rst;
                     
    
    //regs
    reg              sys_rst;
    reg    [12:0]    low_cnt;
    reg              cnt_en;
    reg              din_buf_a;
    reg              din_buf_b;
    
    //wires
    wire             neg_pulse;
    wire             pos_pulse;
    wire             cnt_clk;
    
    
    always @(posedge clk_50m or negedge rst_n)
    begin
        if(!rst_n)
            din_buf_a<=`UDLY 1'b1;
        else if(rd_data)
            din_buf_a<=`UDLY 1'b1;
        else
            din_buf_a<=`UDLY 1'b0;
    end
    
    
    always @(negedge clk_50m or negedge rst_n)
    begin
        if(!rst_n)
            din_buf_b<=`UDLY 1'b1;
        else if(din_buf_a)
            din_buf_b<=`UDLY 1'b1;
        else
            din_buf_b<=`UDLY 1'b0;
    end
    
    
    assign neg_pulse=~din_buf_a&din_buf_b;
    assign pos_pulse=din_buf_a&~din_buf_b;
    
    
    always @(posedge neg_pulse or posedge pos_pulse or negedge rst_n)
    begin
        if(!rst_n)
            cnt_en<=`UDLY 1'b0;
        else if(neg_pulse)
            cnt_en<=`UDLY 1'b1;
        else
            cnt_en<=`UDLY 1'b0;
    end    
    
    assign cnt_clk=clk_50m&cnt_en;    
    
    always @(posedge cnt_clk or posedge pos_pulse or negedge rst_n)
    begin
        if(!rst_n)
            low_cnt<=`UDLY 13'd0;
        else if(pos_pulse)
            low_cnt<=`UDLY 13'd0;
        else if(low_cnt==13'd5001)
            low_cnt<=`UDLY 13'd0;
        else
            low_cnt<=`UDLY low_cnt+1'b1;
    end
    
    always @(negedge cnt_clk or negedge rst_n)
    begin
        if(!rst_n)
            sys_rst<=`UDLY 1'b0;
        else if(low_cnt==13'd5000)
            sys_rst<=`UDLY 1'b1;
        else
            sys_rst<=`UDLY 1'b0;
    end
	 
endmodule
            