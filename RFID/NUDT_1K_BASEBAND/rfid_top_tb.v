// *******************************************************************
// COPYRIGHT, Xi'an XDU Radio-frequency IC Co.,Ltd 
// All rights reserved.
//
// IP NAME      :  RFID
// File name    :  rfid_top_tb.v
// Module name  :  RFID_TOP_TB
//
// Author       :  panwanqiang
// Email        :  
// Data         :  
// Version      :  v1.0 
// 
// Tech Info    :  
//
// Abstract     :  
// Called by    :  RFID_TOP
// 
// Modification history
// -------------------------------------------------------------------
// $Log$
// VERSION             MOD CONTENT                 DATE              TIME                 NAME
//  
// *******************************************************************
`include "D:/xilinx/12.4/xlinx_work/NUDT_SMIC_1K_FPGA/timescale.v"
`include "D:/xilinx/12.4/xlinx_work/NUDT_SMIC_1K_FPGA/macro.v"

module RFID_TOP_TB(
                   clk_50m,
                   rst_p
                   );

output         clk_50m ;
output         rst_p   ;

reg            clk_50m ;
reg            rst_p ;

wire           din;
wire           dout;

OPTIM_TOP U_OPTIM_TOP(
                     .clk_50m(clk_50m),
				             .rst_p(rst_p),
								 .din(din),
								 .dout(dout)
                      );
  

    initial
    begin
       rst_p=1'b0;
       clk_50m=1'b0;
       
       #50000 rst_p=1'b1;
       #15    rst_p=1'b0;        
    end
    
    always
    begin
        #10 clk_50m=~clk_50m;
    end
    

                              
endmodule