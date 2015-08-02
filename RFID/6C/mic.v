`timescale 1ns/1ns
`define UDLY #2

module MIC(
                //inputs
                A,
                DBO,
                TVAL,
                
                //outputs
                DATA_RD
            );
            
            
    //inputs
    input     [5:0]    A;
    input     [15:0]   DBO;
    input     [15:0]   TVAL;
    
    //outputs
    output    [15:0]   DATA_RD;
    
    //regs
    reg       [15:0]   DATA_RD;
    
    always @(A or TVAL or DBO)
    begin
        if(A==10'h007)
            DATA_RD=TVAL;
        else
            DATA_RD=DBO;       
    end
    
endmodule