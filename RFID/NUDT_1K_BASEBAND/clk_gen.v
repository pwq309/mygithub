// ************************************************************** 
// COPYRIGHT, Xi'an XDU Radio-frequency IC Co.,Ltd 
// All rights reserved. 
// 
// IP LIB INDEX : IP lib index just sa UTOPIA_B 
// IP Name      : OPTIM
//
// File name    : clk_gen.v
// Module name  : CLK_GEN
// Full name    : Clock Generator Unit 
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
`define UDLY #0

module CLK_GEN(
                //inputs
                clk_50m,
                rst_p,
                
                //outputs
				clk_1_92m,
				rst_n
				
				);
            
    //inputs
    input           clk_50m;
    input           rst_p;
	 
    //outputs
    output          clk_1_92m;
    output          rst_n;
    
    //regs
    // reg             clk_10m;
    reg             clk_1_92m;
    reg    [7:0]    m1_92_cnt;
    // reg    [2:0]    m10_cnt;
	
	wire            rst_n;
    
	assign rst_n=~rst_p;
	
	
    //********************************************************//
    //clk_1_92m
    
    always @(posedge clk_50m or negedge rst_n)
    begin
       if(!rst_n)
           m1_92_cnt<=`UDLY 8'd0;
       else if(m1_92_cnt==8'd12)
           m1_92_cnt<=`UDLY 8'd0;
       else
           m1_92_cnt<=`UDLY m1_92_cnt+1'b1;
    end
    
    always @(negedge clk_50m or negedge rst_n)
    begin
        if(!rst_n)
            clk_1_92m<=`UDLY 1'b0;
        else if(m1_92_cnt==8'd0)
            clk_1_92m<=`UDLY ~clk_1_92m;
        else
            clk_1_92m<=`UDLY clk_1_92m;
    end
    
  
    //********************************************************//
    //clk_10m
    
     // always @(posedge clk_50m or negedge rst_n)
     // begin
         // if(!rst_n)
             // m10_cnt<=`UDLY 3'd0;
         // else if(m10_cnt==3'd4)
             // m10_cnt<=`UDLY 3'd0;
         // else
             // m10_cnt<=`UDLY m10_cnt+1'b1;
     // end
    
     // always @(negedge clk_50m or negedge rst_n)
     // begin
         // if(!rst_n)
             // clk_10m<=`UDLY 1'b0;
         // else if(m10_cnt==3'd0)
             // clk_10m<=`UDLY 1'b0;
         // else if(m10_cnt==3'd2)
             // clk_10m<=`UDLY 1'b1;
         // else
             // clk_10m<=`UDLY clk_10m;
     // end
    
    
endmodule
    
    
    
    
    
      
                