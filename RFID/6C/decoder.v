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

module DECODER(
                //inputs
                clk_1_92m,
                rst_n,
                dec_en,
                din,
                cmd_end,
                Tpri_10,
                
                //outputs
                delimiter,
                pie_clk,
                pie_data,
                TRcal,
                CRC_FLG,
                dec_done
            );

    //inputs
    input             clk_1_92m;
    input             rst_n;
    input             dec_en;
    input             din;
    input             cmd_end;
    input    [8:0]    Tpri_10;
    
    //outputs
    output            delimiter;
    output            pie_clk;
    output            pie_data;
    output   [9:0]    TRcal;
    output            CRC_FLG;
    output            dec_done;
    
    //regs
    reg               pie_clk_en;
    reg               pie_data;
    reg               CRC_FLG;
    reg               dec_done;
    reg      [9:0]    TRcal;
    reg      [9:0]    RTcal;
    //reg               delimiter;    
    ////////////////////////////
    reg      [2:0]    data_cnt;
    reg      [9:0]    symbol_cnt;
    reg               din_buf_a;
    reg               din_buf_b;
    reg               din_buf_c;    
    reg               cnt_en_a;
    reg               cnt_en_b;
    reg               dec_err;
    
    //wires   
    wire              dec_clk;
    wire              cnt_en;
    wire              cnt_clk;
    wire              delimiter;
    wire              pos_pulse;
    wire              rst_pulse;
    wire              dec_rst;
    wire     [8:0]    pivot;
    
    //********************************************************//
    
    assign dec_clk=clk_1_92m&dec_en;
    
    assign dec_rst=rst_n&~(dec_done|dec_err);
    
    //Sampling din to din_buf_a.    
    always @(posedge dec_clk or negedge rst_n)
    begin
        if(!rst_n)
            din_buf_a<=`UDLY 1'b1;
        else
            din_buf_a<=`UDLY din;
    end
    
    //Sampling din_buf_a to din_buf_b.    
    always @(negedge dec_clk or negedge rst_n)
    begin
        if(!rst_n)
            din_buf_b<=`UDLY 1'b1;
        else
            din_buf_b<=`UDLY din_buf_a;
    end
    
    //Sampling din_buf_b to din_buf_c.    
    always @(posedge dec_clk or negedge rst_n)
    begin
        if(!rst_n)
            din_buf_c<=`UDLY 1'b1;
        else
            din_buf_c<=`UDLY din_buf_b;
    end
    
    //Generate pos_pulse and rst_pulse.
    assign pos_pulse=din_buf_a&(~din_buf_b);
    
    assign rst_pulse=din_buf_b&(~din_buf_c); 
    
    //Remove burrs resulting from dec_done.
    always @(negedge dec_clk or negedge rst_n)
    begin
        if(!rst_n)
            cnt_en_b<=`UDLY 1'b0;
        else
            cnt_en_b<=`UDLY cnt_en_a;
    end
    
    assign cnt_en=cnt_en_a|cnt_en_b;
    
    assign cnt_clk=dec_clk&cnt_en;
    
    //Count for a symbol.
    always @(negedge cnt_clk or posedge rst_pulse or negedge rst_n)
    begin
        if(!rst_n)
            symbol_cnt<=`UDLY 10'd1;
        else if(rst_pulse)
            symbol_cnt<=`UDLY 10'd1;
        else
            symbol_cnt<=`UDLY symbol_cnt+1'b1;            
    end
    
    //Generate a pulse when error.
    always @(posedge cnt_clk or negedge rst_n)
    begin
        if(!rst_n)
            dec_err<=`UDLY 1'b0;
        else if(symbol_cnt==10'd750)
            dec_err<=`UDLY 1'b1;
        else
            dec_err<=`UDLY 1'b0;
    end 
       
    //Generate a pulse when detecting a valid delimiter.
    assign delimiter=~din_buf_a&din_buf_b&~data_cnt[0]&~data_cnt[1]&~data_cnt[2];
    /*always @(posedge pos_pulse or posedge rst_pulse or negedge rst_n)
    begin
        if(!rst_n)
            delimiter<=`UDLY 1'b0;
        else if(rst_pulse)
            delimiter<=`UDLY 1'b0;
        else if(data_cnt==3'b0)
            delimiter<=`UDLY 1'b1;
        else
            delimiter<=`UDLY 1'b0;
    end*/
    
    //Control decoding the data region.
    always @(posedge delimiter or negedge dec_done or negedge rst_n)
    begin
        if(!rst_n)
            cnt_en_a<=`UDLY 1'b0;
        else if(delimiter)
            cnt_en_a<=`UDLY 1'b1;
        else
            cnt_en_a<=`UDLY 1'b0;
    end
    
    //Get the value of RTcal
    always @(posedge pos_pulse or negedge rst_n)
    begin
        if(!rst_n)
            RTcal<=`UDLY 10'd0;
        else if(data_cnt==3'd2)
            RTcal<=`UDLY symbol_cnt;
        else
            RTcal<=`UDLY RTcal;        
    end
    
    //Get the value of TRcal
    always @(posedge pos_pulse or negedge rst_n)
    begin
        if(!rst_n)
            TRcal<=`UDLY 10'd0;
        else if(data_cnt==3'd3&&symbol_cnt>RTcal)
            TRcal<=`UDLY symbol_cnt;
        else
            TRcal<=`UDLY TRcal;  
    end
    
    //Denote the current command is Query.
    always @(posedge pos_pulse or negedge dec_rst)
    begin
        if(!dec_rst)
            CRC_FLG<=`UDLY 1'b0;
        else if(data_cnt==3'd3&&symbol_cnt>RTcal)
            CRC_FLG<=`UDLY 1'b1;
        else
            CRC_FLG<=`UDLY CRC_FLG;
    end
    
    //Get the value of pivot.
    assign pivot=RTcal[9:1];
    
    //Get the value of pie_data
    always @(posedge pos_pulse or negedge rst_n)
    begin
        if(!rst_n)
            pie_data<=`UDLY 1'b0;
        else if(data_cnt==3'd3)
            if(symbol_cnt>RTcal)
                pie_data<=`UDLY 1'b0;
            else if(symbol_cnt>pivot)
                pie_data<=`UDLY 1'b1;
            else
                pie_data<=`UDLY 1'b0;                 
        else if(data_cnt==3'd4)
            if(symbol_cnt<pivot)
                pie_data<=`UDLY 1'b0;
            else
                pie_data<=`UDLY 1'b1;
        else
            pie_data<=`UDLY 1'b0;      
    end 
    
    //Enable the output of pie_clk.
    always @(posedge pos_pulse or negedge dec_rst)
    begin
        if(~dec_rst)
            pie_clk_en<=`UDLY 1'b0;
        else if(data_cnt==3'd3)
            if(symbol_cnt>RTcal)
                pie_clk_en<=`UDLY 1'b0;
            else
                pie_clk_en<=`UDLY 1'b1;
        else if(data_cnt==3'd4)
            pie_clk_en<=`UDLY 1'b1;
        else 
            pie_clk_en<=`UDLY 1'b0;
    end
     
    assign pie_clk=rst_pulse&pie_clk_en;
    
    assign cnt_pulse=(~data_cnt[2]|data_cnt[1]|data_cnt[0])&pos_pulse;//data_cnt!=3'd4
    
    //Count for the number of PIE symbol.
    always @(negedge cnt_pulse or negedge dec_rst)
    begin
        if(!dec_rst)
            data_cnt<=`UDLY 3'b0;
        else
            data_cnt<=`UDLY data_cnt+1;
    end
    
    //Generate dec_done.
    always @(posedge cnt_clk or negedge rst_n)
    begin
        if(!rst_n)
            dec_done<=`UDLY 1'b0;
        else if(data_cnt==3'd4)
            if(cmd_end)
                if(RTcal>Tpri_10) 
                    if(symbol_cnt==RTcal-Tpri_10)
                        dec_done<=`UDLY 1'b1;
                    else
                        dec_done<=`UDLY 1'b0;
                else
                    dec_done<=`UDLY 1'b1;
            else
                dec_done<=`UDLY 1'b0;
        else
            dec_done<=`UDLY 1'b0;
    end
    
endmodule