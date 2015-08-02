// *******************************************************************
// COPYRIGHT, Xi'an XDU Radio-frequency IC Co.,Ltd 
// All rights reserved.
//
// IP NAME      :  RFID
// File name    :  rfid_top_tb.v
// Module name  :  RFID_TOP_TB
//
// Author       :  
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
//`include "./macro.v"
//`include "./timescale.v"
`include "D:/xilinx/12.4/xlinx_work/NUDT_1K_BASEBAND/timescale.v"
`include "D:/xilinx/12.4/xlinx_work/NUDT_1K_BASEBAND/macro.v"

module OPTIM_TOP(
                  //inputs
				  clk_50m  ,
                  rst_p,
				  din,
				  
                  //outputs
                  dout

				  );

input          clk_50m            ;
input          rst_p              ;
input          din                ;
     
output         dout;                      

//optim		  
wire           clk_1_92m          ;  
wire           rst_n              ;  
//wire           din                ;
wire   [15:0]  DBO                ;  
wire           READY              ;  
wire           dout               ; 
wire    [5:0]  A                  ;  
wire           CEN                ;  
wire           OEN                ;  
wire           WEN                ;  
wire           CHER               ;  
wire           CHWR               ;  
wire           RD_CLK             ;  
wire   [2:0]   PCH                ;  
wire           ERFL               ;  
wire           OPT                ;  
wire   [1:0]   PT                 ;  
wire   [1:0]   ET                 ;         
wire           EXCP               ;         
wire   [15:0]  DATA_WR            ;         
wire           WSEN               ;         
wire           WS                 ;         
wire           ITEST              ; 


OPTIM U_OPTIM(
                //inputs
                .clk_1_92m (clk_1_92m )         ,   
                .rst_n     (rst_n     )         ,       
                .din       (din       )         ,
                .DATA_RD   (DBO       )         ,     
                .READY     (READY     )         ,        
                
				//outputs
                .dout      (dout)               ,  
                .A         (A         )         ,                         
                .CEN       (CEN       )         ,         
                .OEN       (OEN       )         ,         
                .WEN       (WEN       )         ,         
                .CHER      (CHER      )         ,        
                .CHWR      (CHWR      )         ,        
                .RD_CLK    (RD_CLK    )         ,      
                .PCH       (PCH       )         ,         
                .ERFL      (ERFL      )         ,        
                .OPT       (OPT       )         ,         
                .PT        (PT        )         ,          
                .ET        (ET        )         ,          
                .EXCP      (EXCP      )         ,        
                .DATA_WR   (DATA_WR   )         ,     
                .WSEN      (WSEN      )         ,        
                .WS        (WS        )         ,          
                .ITEST     (ITEST     )
             );


// ANATENNA U_ANATENNA(
                    ////inputs
                    // .clk_50m(clk_50m),
                    // .rst_p(rst_p),
                    // .tag_data(dout),

                    ////outputs
                    // .rd_data(din),
                    // .rst_n(rst_n),
                    // .clk_1_92m(clk_1_92m)
									
                    // );
 
 
 CLK_GEN U_CLK_GEN(
                   //inputs
                   .clk_50m(clk_50m),
						 .rst_p(rst_p),
						 
						 //outputs
						 .clk_1_92m(clk_1_92m),
						 .rst_n(rst_n)
						 
						 );
 
                  
S018EE1KX16  U_S018EE1KX16(
                           //inputs
                           .A		      (A		    )     ,
                           .RSTN		  (rst_n		)     ,
                           .CEN		      (CEN		    )     ,
                           .OEN		      (OEN		    )     ,
                           .WEN		      (WEN		    )     ,
                           .CHER		  (CHER		    )     ,
                           .CHWR		  (CHWR		    )     ,
                           .EXCP		  (EXCP		    )     ,
                           .CLK1D92       (clk_1_92m    )     ,
                           .RD_CLK        (RD_CLK       )     ,
                           .PCH		      (PCH		    )     ,   
                           .ERFL		  (ERFL		    )     ,
                           .OPT           (OPT          )     ,
                           .PT		      (PT		    )     ,
                           .ET            (ET           )     ,
                           .WS		      (WS		    )     ,
                           .WSEN		  (WSEN		    )     ,
                           .ITEST         (ITEST        )     ,
                           //.REF_BIAS      (REF_BIAS     )     ,
                           .DBI		      (DATA_WR	    )     ,
                           //.IOUT          (IOUT         )     ,
                           //.VPP0          (VPP0         )     ,
						   
						               //outputs
                           .DBO		      (DBO		    )     ,
                           .READY		  (READY		)     
                
                          ); 

endmodule