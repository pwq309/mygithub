`timescale 1ns/1ns
`define UDLY #2

module SFLG(
                //inputs
                RSTN,
                SRD,
                SS1,
                SS2,
                SS3,
                SSL,
                S1UPD,
                SXUPD,
                
                //outputs
                S1,
                S2,
                S3,
                SL
            );
            
    //inputs
    input             RSTN;
    input             SRD;
    input             SS1;
    input             SS2;
    input             SS3;
    input             SSL;
    input             S1UPD;
    input             SXUPD;
    
    //outputs
    output            S1;
    output            S2;
    output            S3;
    output            SL;
    
    
    //regs
    reg               S1;   
    reg               S2;   
    reg               S3;   
    reg               SL;    
    
    always @(posedge S1UPD or negedge RSTN)
    begin
        if(!RSTN)
            S1<=`UDLY 1'b0;
        else
            S1<=`UDLY SS1;       
    end
    
    
    always @(posedge SXUPD or negedge RSTN)
    begin
        if(!RSTN)
            S2<=`UDLY 1'b0;
        else
            S2<=`UDLY S2;        
    end
    
    
    always @(posedge SXUPD or negedge RSTN)
    begin
        if(!RSTN)
            S3<=`UDLY 1'b0;
        else
            S3<=`UDLY S3;        
    end
    
    always @(posedge SXUPD or negedge RSTN)
    begin
        if(!RSTN)
            SL<=`UDLY 1'b0;
        else
            SL<=`UDLY SL;        
    end
    
endmodule
