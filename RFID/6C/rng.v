// ************************************************************** 
// COPYRIGHT, Xi'an XDU Radio-frequency IC Co.,Ltd 
// All rights reserved. 
// 
// IP LIB INDEX : IP lib index just sa UTOPIA_B 
// IP Name      : OPTIM
//
// File name    : rng.v
// Module name  : RNG
// Full name    : Random Number Generater 
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
`define UDLY #2

module RNG(
                //inputs
                DOUB_BLF,
                rst_n,
                Q_update,
                Q,
                slot_update,
                handle_update,
                rn16_update,
                RNS,
                init_done,
                
                //outputs
                slot_valid,
                rn16,
                handle
            );
     
    //inputs        
    input             DOUB_BLF;
    input             rst_n;
    input             Q_update;
    input    [3:0]    Q;
    input             slot_update;
    input             handle_update;
    input             rn16_update;
    input    [15:0]   RNS;
    input             init_done;
    
    //outputs
    output            slot_valid;
    output   [15:0]   rn16;
    output   [15:0]   handle;
    
    //regs
    reg               slot_valid;
    reg      [14:0]   slot_val;
    reg      [15:0]   rn16;
    reg      [15:0]   handle;
    reg      [15:0]   SH_CYC_L;                                //the left_circular_shift_register  
    
    
    assign cyc_pulse=Q_update|rn16_update|handle_update;  
    
    assign CYCB=^SH_CYC_L[15:12];
            
    //Shift left-cyclically and generate the random number.
    always @(negedge cyc_pulse or posedge init_done or negedge rst_n)
    begin
        if(!rst_n)
            SH_CYC_L<=`UDLY 16'h0000;
        else if(init_done)
            SH_CYC_L<=`UDLY RNS;
        else
            SH_CYC_L<=`UDLY {SH_CYC_L[14:0],CYCB};
    end
        
    //Update slot.
    always @(posedge slot_update or posedge Q_update or negedge rst_n)
    begin
        if(!rst_n)
            slot_val<=`UDLY 15'h0000;
        else if(Q_update)
            slot_val<=`UDLY SH_CYC_L[14:0];            
        else
            slot_val<=`UDLY slot_val-1'b1;
    end
    
    always @(Q or slot_val)
    begin
        case(Q)
        4'h0: slot_valid=1'b1;
        4'h1: slot_valid=!slot_val[0];
        4'h2: slot_valid=!slot_val[1:0];
        4'h3: slot_valid=!slot_val[2:0];
        4'h4: slot_valid=!slot_val[3:0];
        4'h5: slot_valid=!slot_val[4:0];
        4'h6: slot_valid=!slot_val[5:0];
        4'h7: slot_valid=!slot_val[6:0];
        4'h8: slot_valid=!slot_val[7:0];
        4'h9: slot_valid=!slot_val[8:0];
        4'ha: slot_valid=!slot_val[9:0];
        4'hb: slot_valid=!slot_val[10:0];
        4'hc: slot_valid=!slot_val[11:0];
        4'hd: slot_valid=!slot_val[12:0];
        4'he: slot_valid=!slot_val[13:0]; 
        default: slot_valid=!slot_val;
        endcase
    end    
    
    //Update rn16.
    always @(posedge rn16_update or negedge rst_n)
    begin
        if(!rst_n)
            rn16<=`UDLY 16'h0000;
        else
            rn16<=`UDLY SH_CYC_L;
    end
    
    //Update handle.
    always @(posedge handle_update or negedge rst_n)
    begin
        if(!rst_n)
            handle<=`UDLY 16'h0000;
        else
            handle<=`UDLY SH_CYC_L;
    end
    
endmodule