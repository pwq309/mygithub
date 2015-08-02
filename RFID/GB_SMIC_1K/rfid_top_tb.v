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
`include "./macro.v"
`include "./timescale.v"

module RFID_TOP_TB(
                  clk_50m,
				    rst_p,
                 //outputs
                  din,
                  dout,
			      led_sort,
				  led_query,
				  led_ack,
			     led_read,
				  led_write,
				  led_done
				  );

input           clk_50m            ;  
input           rst_p              ;  

output          din;
output          dout;
output          led_sort;
output          led_query;
output          led_ack;
output          led_read;
output          led_write;
output          led_done;

wire           din                 ;
wire           dout                ; 
wire           led_sort;
wire           led_query;
wire           led_ack;
wire           led_read;
wire           led_write;
wire           led_done;

// integer           file_result;


ANATENNA U_ANATENNA(
                    .clk_50m(clk_50m),
                    .tag_data(dout),
                    .rst_p(rst_p),
                    .rd_data(din),
						  //.RESET(rst_n),
				    .led_sort(led_sort),
				    .led_query(led_query),
					.led_ack(led_ack),
					.led_read(led_read),
					.led_write(led_write),
					.led_done(led_done)
									
                    );

OPTIM_TOP U_OPTIM_TOP(
                     .clk_50m(clk_50m),
				     .rst_p(rst_p),
				     .din(din),
				     .dout(dout)
                      );
  

   // initial
   // begin
    //   rst_p=1'b0;
    //   clk_50m=1'b0;
       
    //   #50000 rst_p=1'b1;
   //    #2000  rst_p=1'b0;        
   // end
    
   // always
    //begin
        //#10 clk_50m=~clk_50m;
    //end
                              
endmodule