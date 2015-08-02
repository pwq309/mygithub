`timescale 1ns/1ns
`define UDLY #2

module TMON(
                //inputs
                RSTN,
                ECLK,
                TCLK,
                
                //outputs
                TSTOP,
                TVAL,
            );
            
    //inputs
    input              RSTN;
    input              ECLK;
    input              TCLK;
                       
    //ouputs           
    output             TSTOP;
    output   [15:0]    TVAL;
    
    //regs
    reg                TSTOP;
    reg      [15:0]    TVAL;
    reg                PCLKA;
    reg                PCLKB;
    reg                PCLKC;
    reg                PCLKD;
    reg                NCLKA;
    reg                NCLKB;
    reg                NCLKC;
    reg                NCLKD;
    reg                TENBA;
    reg                TENBB;
    
    //wires
    wire               TRST;
    wire               TEN;
    
    
    
    //****************************************//
    
    always @(negedge ECLK or negedge RSTN)
    begin
        if(!RSTN)
            NCLKA<=`UDLY 1'b0;
        else
            NCLKA<=`UDLY ~NCLKA;
    end
    
    always @(negedge NCLKA or negedge RSTN)
    begin
        if(!RSTN)
            NCLKB<=`UDLY 1'b0;
        else
            NCLKB<=`UDLY ~NCLKB;
    end
    
    always @(negedge NCLKB or negedge RSTN)
    begin
        if(!RSTN)
            NCLKC<=`UDLY 1'b0;
        else
            NCLKC<=`UDLY ~NCLKC;
    end
    
    always @(negedge NCLKC or negedge RSTN)
    begin
        if(!RSTN)
            NCLKD<=`UDLY 1'b0;
        else
            NCLKD<=`UDLY ~NCLKD;
    end
    
    always @(posedge NCLKD or negedge RSTN)
    begin
        if(!RSTN)
            PCLKA<=`UDLY 1'b0;
        else
            PCLKA<=`UDLY ~PCLKA;
    end
    
    always @(posedge PCLKA or negedge RSTN)
    begin
        if(!RSTN)
            PCLKB<=`UDLY 1'b0;
        else
            PCLKB<=`UDLY ~PCLKB;
    end
    
    always @(posedge PCLKB or negedge RSTN)
    begin
        if(!RSTN)
            PCLKC<=`UDLY 1'b0;
        else
            PCLKC<=`UDLY ~PCLKC;
    end
    
    always @(posedge PCLKC or negedge RSTN)
    begin
        if(!RSTN)
            PCLKD<=`UDLY 1'b0;
        else
            PCLKD<=`UDLY ~PCLKD;
    end   
    
    //****************************************//
    
    always @(posedge TCLK or negedge RSTN)
    begin
        if(!RSTN)
            TENBA<=`UDLY 1'b0;
        else
            TENBA<=`UDLY PCLKD;
    end
    
    always @(negedge TCLK or negedge RSTN)
    begin
        if(!RSTN)
            TENBB<=`UDLY 1'b0;
        else
            TENBB<=`UDLY TENBA;
    end
    
    assign TRST=RSTN&~(TENBA&~TENBB);
    
    always @(negedge PCLKD or negedge RSTN)
    begin
        if(!RSTN)
            TSTOP<=`UDLY 1'b0;
        else
            TSTOP<=`UDLY ~TSTOP;
    end
    
    assign TEN=PCLKD;
    
    always @(posedge TCLK or negedge TRST)
    begin
        if(!TRST)
            TVAL<=`UDLY 1'b0;
        else if(TEN)
            TVAL<=`UDLY TVAL+1'b1;
        else
            TVAL<=`UDLY TVAL;
    end
    
    
endmodule
    
                