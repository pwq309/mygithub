`timescale 1ns/1ns
`define UDLY #2

module RSGEN(
                //inputs
                clk_1_92m,
                rst_n,
                TCLK,
                TSTOP,               
                
                //outputs
                RNS
            );
            
            
    //inputs
    input               clk_1_92m;
    input               rst_n;
    input               TCLK;
    input               TSTOP;
    
    //outputs
    output    [15:0]    RNS;
    
    
    //regs
    reg       [15:0]    RNS;
    reg                 RNB; 
    reg                 REN;
    
    always @(negedge clk_1_92m or negedge rst_n)
    begin
        if(!rst_n)
            REN<=`UDLY 1'b0;
        else
            REN<=`UDLY ~TSTOP;    
    end
    
    assign RCLK=clk_1_92m&REN;   
    
    always @(posedge RCLK or negedge rst_n)
    begin
        if(!rst_n)
            RNB<=`UDLY 1'b0;
        else
            RNB<=`UDLY ~RNB;        
    end    
    
    always @(posedge TCLK or negedge rst_n)
    begin
        if(!rst_n)
            RNS<=`UDLY 16'h3014;
        else
            RNS<=`UDLY {RNS[14:0],RNB};        
    end    
    
endmodule
    
    