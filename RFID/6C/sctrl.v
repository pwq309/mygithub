`timescale 1ns/1ns
`define UDLY #2

module SCTRL(
                //inputs
                init_srd_pulse,
                par_srd_pulse,
                swr_pulse,
                saddr,
                
                //outputs
                SRD,
                S1UPD,
                SXUPD
            );
    
    //inputs
    input             init_srd_pulse;
    input             par_srd_pulse;
    input             swr_pulse;
    input    [1:0]    saddr;
    
    //outputs
    output            SRD;
    output            S1UPD;
    output            SXUPD;
                      
    //regs            
    reg               S1UPD;
    reg               SXUPD;
    
    assign SRD=init_srd_pulse|par_srd_pulse;
    
    always @(swr_pulse or saddr)
    begin
        if(saddr==2'b00)
            S1UPD<=`UDLY swr_pulse;
        else
            S1UPD<=`UDLY 1'b0;        
    end
    
    
    always @(swr_pulse or saddr)
    begin
        if(saddr==2'b00)
            SXUPD<=`UDLY 1'b0; 
        else
            SXUPD<=`UDLY swr_pulse;            
    end
    
endmodule