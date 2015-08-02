// ************************************************************** 
// COPYRIGHT, Xi'an XDU Radio-frequency IC Co.,Ltd 
// All rights reserved. 
// 
// IP LIB INDEX : IP lib index just sa UTOPIA_B 
// IP Name      : the top module_name of this ip, usually, is same  as the small ip classified name just as TOPIA 
//
// File name    : decoder.v
// Module name  : DECODER
// Full name    : TPP Decoder Unit 
// 
// Author       : panwanqaing
// Email        : 
// Data         : 2013/03/07
// Version      : V1.0 
// 
// Abstract     : 
// Called by    : 
// 
// Modification history 
// ---------------------------------------- 
//
// $Log$ 
// 
// ************************************************************** 
`include "./macro.v"
`include "./timescale.v"

module DECODER(
                //inputs
                clk_1_92m,
                DOUB_BLF,
                rst_n,                               
                dec_en,
                din,
                cmd_end, 
                cmd_head,
                head_finish,
                               
                //outputs
                tpp_data,
                tpp_clk,
                delimiter,
                dec_done,
                dec_done3,
                dec_done4,
                dec_done5,
                dec_done6
              );

    //inputs
input              clk_1_92m;
input              DOUB_BLF; 
input              rst_n;
input              dec_en;
input              din;
input              cmd_end;
input   [7:0]      cmd_head;
input              head_finish;

//outputs
output    [1:0]    tpp_data;
output             tpp_clk;
//output    [7:0]    TC_val;
output             delimiter;
output             dec_done;
output             dec_done3;
output             dec_done4;
output             dec_done5;
output             dec_done6;
//output             rst_n_dec;

//regs
reg       [1:0]    tpp_data;                   //to cmd_parse unit
reg                tpp_clk_en;
reg                delimiter; 
reg                din_temp1;
reg                din_temp2;
reg                din_temp3;
reg                dec_gate;              //Determin if the decoder of TPP is implementing.
reg       [8:0]    symbol_cnt;
reg       [1:0]    data_cnt;
reg       [8:0]    TC_val8;
reg       [8:0]    TC_val2;
reg                dec_done;              //to cmd_parse unit
reg                dec_done0;    
reg                dec_done1;             
reg                dec_done2;
reg                dec_done3;             //to cmd_parse unit
reg                dec_done4;
reg                dec_done5;
reg                dec_done6;             //to cmd_parse unit

//wires
wire               dec_clk;
wire               pos_pulse;                                   //Give a pulse when detecting a valid pos-edge.
wire               rst_symbol_cnt;                              //Give a delayed pulse when detecting a valid pos-edge.
wire     [8:0]     pivot1;                                      //The reference time 1.
wire     [8:0]     pivot2;                                      //The reference time 2.
wire     [8:0]     pivot3;                                      //The reference time 3.
                              //Record the time count of the current symbol.
wire               tpp_clk;              //to cmd_parse unit
wire               rst_dec_done;
//wire     [7:0]     TC_val;

wire               symbol_clk;
//wire               del_rst;
//reg    [7:0]       cnt;
//reg                rst_n_dec;
reg                gate_ctrl;

always @(posedge DOUB_BLF or negedge rst_n)
begin
    if(!rst_n)
        gate_ctrl <=#`UDLY 1'b0;
    else if(dec_en)
        gate_ctrl <=#`UDLY 1'b1;
    else
        gate_ctrl <=#`UDLY 1'b0; 
end

assign dec_clk=clk_1_92m&dec_en&gate_ctrl; 

assign rst_dec_done=rst_n&~dec_done;                                //Reset when decoding has done.
                            

//Sample the din and store it to din_temp1.
always @(negedge dec_clk or negedge rst_n)
begin
    if(!rst_n)
        din_temp1<=#`UDLY 1'b1;
    else
        din_temp1<=#`UDLY din;
end 

//Sample the din_temp1 and store it to din_temp2.
always @(posedge dec_clk or negedge rst_n)
begin
    if(!rst_n)
        din_temp2<=#`UDLY 1'b1;
    else
        din_temp2<=#`UDLY din_temp1;
end

//Sample the din_temp2 and store it to din_temp3.
always @(negedge dec_clk or negedge rst_n)
begin
    if(!rst_n)
        din_temp3<=#`UDLY 1'b1;
    else
        din_temp3<=#`UDLY din_temp2;
end

assign pos_pulse=din_temp1&(~din_temp2);                        //Denotes the end of a symbol period.

assign rst_symbol_cnt=din_temp2&(~din_temp3);                   //Denotes the start of a symbol period.   

assign symbol_clk=dec_clk&dec_gate;                             //Clock for decoding the region of TPP.


//Count for the lasting time of a symbol.
always @(posedge symbol_clk or posedge  rst_symbol_cnt or negedge rst_n)
begin
    if(!rst_n)
        symbol_cnt<=#`UDLY 9'd0;
    else if(rst_symbol_cnt)
        symbol_cnt<=#`UDLY 9'd0;
    else
        symbol_cnt<=#`UDLY (symbol_cnt+1'b1);       
end    

//Count for the receiving symbols.    
always @(negedge pos_pulse or negedge rst_dec_done)
begin
    if(!rst_dec_done)
        data_cnt<=#`UDLY 2'd0;
  else if(data_cnt==2'd3)
        data_cnt<=#`UDLY data_cnt;
    else
        data_cnt<=#`UDLY (data_cnt+1'b1);
end

                    

//Generate delimiter when detecting a valid delimiter.
always @(posedge pos_pulse or posedge rst_symbol_cnt or negedge rst_n)
begin
    if(!rst_n)
        delimiter<=#`UDLY 1'b0;
    else if(rst_symbol_cnt)
        delimiter <= #`UDLY 1'b0;    
    else if(data_cnt==2'd0)
        delimiter<=#`UDLY 1'b1;
    
    else
        delimiter<=#`UDLY 1'b0;        
end

//Determin if the decoder of TPP is implementing.
always @(posedge delimiter or posedge dec_done2 or negedge rst_n)
begin
    if(!rst_n)
        dec_gate<=#`UDLY 1'b0;
    else if(dec_done2)    
        dec_gate<=#`UDLY 1'b0;
    else 
        dec_gate<= #`UDLY 1'b1;
        
end

//Get the value of Tcal1.
always @(posedge pos_pulse or negedge rst_n)
begin
    if(!rst_n)
        TC_val8<=#`UDLY 9'd0;
    else if(data_cnt==2'd1)
        TC_val8<=#`UDLY symbol_cnt;
    else
        TC_val8<=#`UDLY TC_val8;
end

//Get the value of Tcal2.
always @(posedge pos_pulse or negedge rst_n)
begin
    if(!rst_n)
        TC_val2<=#`UDLY 9'd0;
    else if(data_cnt==2'd2)
        TC_val2<=#`UDLY symbol_cnt;
    else
        TC_val2<=#`UDLY TC_val2;
end

//assign TC_val={1'b0,TC_val8[8:2]}-TC_val2[8:1];              //Calculate the value of Tc [Tcal1/4 - Tcal2/2].

assign pivot1={1'b0,TC_val8[8:2]}+{1'b0,TC_val2[8:2]};       //pivot1=Tcal1/4+Tcal2/4
assign pivot2=pivot1+{2'b00,TC_val8[8:3]};                   //pivot2=pivot1+Tcal1/8
assign pivot3=pivot2+{2'b00,TC_val8[8:3]};                   //pivot3=pivot2+Tcal1/8

//Output the value of TPP code.
always @(posedge pos_pulse or negedge rst_n)
begin
    if(!rst_n)
        tpp_data<=#`UDLY 2'b00;
    else if(data_cnt==2'd3)
        begin
            if(symbol_cnt<pivot2)
                begin
                    if(symbol_cnt<pivot1)
                        tpp_data<=#`UDLY 2'b00;
                    else
                        tpp_data<=#`UDLY 2'b01;
                end
            else
                begin
                    if(symbol_cnt<pivot3)
                        tpp_data<=#`UDLY 2'b11;
                    else
                        tpp_data<=#`UDLY 2'b10;
                end
        end
    else
        tpp_data<=#`UDLY 2'b00;
end 

//Generate the enable signal of tpp_clk.
always @(posedge pos_pulse or negedge rst_dec_done)
begin
    if(!rst_dec_done)
        tpp_clk_en<=#`UDLY 1'b0;        
    else if(data_cnt==2'd3)
        tpp_clk_en<=#`UDLY 1'b1;
    else
        tpp_clk_en<=#`UDLY 1'b0;
end

//Generate the tpp_clk.
//assign tpp_clk=din_temp3&tpp_clk_en;
assign tpp_clk=rst_symbol_cnt&tpp_clk_en;

//Generate the signal:dec_done.
always @(negedge symbol_clk or negedge rst_n)
begin
    if(!rst_n)
        dec_done<=#`UDLY 1'b0;
    else if(data_cnt==2'd3)
    begin
        if(cmd_end)
            dec_done<=#`UDLY 1'b1;
        else if((cmd_head ==`QUERYREP ||cmd_head==`DISPERSE ||cmd_head == `SHRINK || cmd_head == `NAK)
             && head_finish== 1'b1)
            dec_done <= #`UDLY 1'b1;
        else if(symbol_cnt >9'd200)
            dec_done<= #`UDLY 1'b1;
        else 
            dec_done<=#`UDLY 1'b0;
    end
    else
        dec_done<=#`UDLY 1'b0;
end

//Generate the signal:dec_done0.
always @(posedge DOUB_BLF or posedge dec_done or negedge rst_n)
begin
    if(!rst_n)
        dec_done0<=#`UDLY 1'b0;
    else if(dec_done)
        dec_done0<=#`UDLY 1'b1;
    else
        dec_done0<=#`UDLY 1'b0;
end

//Generate the signal:dec_done1.
always @(posedge DOUB_BLF or negedge rst_n)
begin
    if(!rst_n)
        dec_done1<=#`UDLY 1'b0;
    else if(dec_done0)
        dec_done1<=#`UDLY 1'b1;
    else
        dec_done1<=#`UDLY 1'b0;
end

//Generate the signal:dec_done2.
always @(posedge DOUB_BLF or negedge rst_n)
begin
    if(!rst_n)
        dec_done2<=#`UDLY 1'b0;
    else if(dec_done1)
        dec_done2<=#`UDLY 1'b1;
    else
        dec_done2<=#`UDLY 1'b0;
end

//Generate the signal:dec_done3.
always @(posedge DOUB_BLF or negedge rst_n)
begin
    if(!rst_n)
        dec_done3<=#`UDLY 1'b0;
    else if(dec_done2)
        dec_done3<=#`UDLY 1'b1;
    else
        dec_done3<=#`UDLY 1'b0;
end

//Generate the signal:dec_done4.
always @(posedge DOUB_BLF or negedge rst_n)
begin
    if(!rst_n)
        dec_done4<=#`UDLY 1'b0;
    else if(dec_done3)
        dec_done4<=#`UDLY 1'b1;
    else
        dec_done4<=#`UDLY 1'b0;
end

//Generate the signal:dec_done5.
always @(posedge DOUB_BLF or negedge rst_n)
begin
    if(!rst_n)
        dec_done5<=#`UDLY 1'b0;
    else if(dec_done4)
        dec_done5<=#`UDLY 1'b1;
    else
        dec_done5<=#`UDLY 1'b0;
end

//Generate the signal:dec_done6.
always @(posedge DOUB_BLF or negedge rst_n)
begin
    if(!rst_n)
        dec_done6<=#`UDLY 1'b0;
    else if(dec_done5)
        dec_done6<=#`UDLY 1'b1;
    else
        dec_done6<=#`UDLY 1'b0;
end
    
endmodule
