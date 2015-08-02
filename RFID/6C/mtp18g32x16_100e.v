

//*******************************************************************************
//*TSMC Library/IP Product
//*Filename: mtp18g32x16_100e.v
//*Technology: CE018G
//*Product Type: MTP IP
//*Product Name: MTP18G32X16
//*Version: 100e
//*******************************************************************************
//*
//*STATEMENT OF USE
//*
//*This information contains confidential and proprietary information of TSMC.
//*No part of this information may be reproduced, transmitted, transcribed,
//*stored in a retrieval system, or translated into any human or computer
//*language, in any form or by any means, electronic, mechanical, magnetic,
//*optical, chemical, manual, or otherwise, without the prior written permission
//*of TSMC. This information was prepared for informational purpose and is for
//*use by TSMC's customers only. TSMC reserves the right to make changes in the
//*information at any time and without notice.
//*
//*******************************************************************************


//----------------------------------------------------------------------------
// Copyright (c) 2005 Taiwan Semiconductor Manufacturing Ltd.
// All Rights Reserved.
//
//----------------------------------------------------------------------------
// Model Name    : MTP18G32X16
// Creation Date : 2009/02/13, 10:00:00
// Version       : 1.4
//
//----------------------------------------------------------------------------
// Ports
//        FUSEADR : word address of MTP IP input buffer
//        DIN  : data input bus
//        DOUT : data output bus
//        DATARDY: data ready indication signal
//        FE   : word address of MTP IP enable
//        SE   : sense amplifier enable        
//        RECALL: RECALL cycle
//        PROG : write cycle
//        NVSTR: non-volatile store cycle
//        DRT :  Data retention test
//        MRGEN: Margin read enable 
//        MRGSEL: Margin read selection signal    
//
//----------------------------------------------------------------------------
// Note:
//       This verilog model is designed for TSMC MTP IP. All function
//       and timing specs are inlcuded. When abnormal function and
//       timing violation occur, the whole memory will be set unknown.
//       If you want to turn off the unknown setting, use
//       +define+no_whole_flash_unknown in the simulation command.
//
//       For the function & timing accuracy, the constant timing is used. It
//       will cause some SDF back-annotation errors and you can bypass them.
//
//
//----------------------------------------------------------------------------
// Revision history:
// Revised Date  : 2007/11/08, 11:30:00    by Schenga (Shanghai)
// Revised Items : 1. Revised the FE to DOUT relation 
//                 2. Revised the Tpch violation mis-error-report 
//                    about recall=0 and posedge during the write cycle
//                 3. Add the DATARDY signal
//                 4. The DOUT will be set to x state when RECALL or FE or 
//                    FUSEADR is changed in the recall cycle
//
// Revised Date  : 2008/03/31    by Schenga (Shanghai)
//                 1. Add 3 pins: DRT, MRGEN, MRGSEL, delete VDD33
// Revised Date	 : 2008/07/11	 by Ghli
//		 : 1. Change the output state from 'z' to 'x' and keep previous data
//		 : 2. Modified the recall behavior based on new waveform
// Revised Date	 : 2008/07/25	 by Ghli
//		 : 1. parameterize Tse and Trh
//		 : 2008/08/08	 by GH Li
//		 : 1. Modified the Tse max.
// Revised Date	 : 2008/11/28    by G.H. Li
//		   1.Modify Twrite spec to 5~10ms
//		   2.Enhance Tse and Trh check
// Revised Date  : 2009/01/05    by G.H. Li
//                 1.RECALL pulse must < 5ns without toggling SE and FE
//                 2.Enhance the ERROR message when RECALL goes low before data ready
//                 3.Change Tsc to 100ns and Tac to 200ns
// Revised Date  : 2009/02/13    by HCYang/ESLD
//                 1. Added DRT Write and DRT Recall function.
//                 2. Gated error message caused by recall driven low before datardy when mrgen driven high
// Revised Date  : 2009/12/28	by CYLIU
//		   1. Fixed a bug to check Tpa violation, generate prog_tpa_chk and recall_tpa_chk to check Tpa.
//----------------------------------------------------------------------------
`timescale 1ns/10ps
`celldefine
module MTP18G32X16   (DIN,
                      FE,
                      FUSEADR,
                      PROG,
                      NVSTR,
                      RECALL,
                      SE,
                      DRT,
                      MRGEN,
                      MRGSEL,
                      
                      DOUT,
                      DATARDY
                      );

//begin parameter
parameter numAddrMTP = 5;
parameter numOut = 16;
//end parameter

// IO ports
input FE, PROG, NVSTR, RECALL, SE, DRT, MRGEN, MRGSEL;
input [numAddrMTP-1:0] FUSEADR;
input [numOut-1:0] DIN;
output [numOut-1:0] DOUT;
output DATARDY;

// IO buffer
wire [numAddrMTP-1:0] FUSEADR_buf;
wire [numOut-1:0] DIN_buf;
wire [numOut-1:0] DOUT_buf;
wire DATARDY_buf;
wire FE_buf;
wire SE_buf;
wire DRT_buf;
wire MRGEN_buf;
wire MRGSEL_buf;
wire RECALL_buf;
wire PROG_buf;
wire NVSTR_buf;

buf (FUSEADR_buf[0], FUSEADR[0]);
buf (FUSEADR_buf[1], FUSEADR[1]);
buf (FUSEADR_buf[2], FUSEADR[2]);
buf (FUSEADR_buf[3], FUSEADR[3]);
buf (FUSEADR_buf[4], FUSEADR[4]);

buf (DIN_buf[0], DIN[0]);
buf (DIN_buf[1], DIN[1]);
buf (DIN_buf[2], DIN[2]);
buf (DIN_buf[3], DIN[3]);
buf (DIN_buf[4], DIN[4]);
buf (DIN_buf[5], DIN[5]);
buf (DIN_buf[6], DIN[6]);
buf (DIN_buf[7], DIN[7]);
buf (DIN_buf[8], DIN[8]);
buf (DIN_buf[9], DIN[9]);
buf (DIN_buf[10], DIN[10]);
buf (DIN_buf[11], DIN[11]);
buf (DIN_buf[12], DIN[12]);
buf (DIN_buf[13], DIN[13]);
buf (DIN_buf[14], DIN[14]);
buf (DIN_buf[15], DIN[15]);

nmos (DOUT[0] ,DOUT_buf[0] ,1'b1 );
nmos (DOUT[1] ,DOUT_buf[1] ,1'b1 );
nmos (DOUT[2] ,DOUT_buf[2] ,1'b1 );
nmos (DOUT[3] ,DOUT_buf[3] ,1'b1 );
nmos (DOUT[4] ,DOUT_buf[4] ,1'b1 );
nmos (DOUT[5] ,DOUT_buf[5] ,1'b1 );
nmos (DOUT[6] ,DOUT_buf[6] ,1'b1 );
nmos (DOUT[7] ,DOUT_buf[7] ,1'b1 );
nmos (DOUT[8] ,DOUT_buf[8] ,1'b1 );
nmos (DOUT[9] ,DOUT_buf[9] ,1'b1 );
nmos (DOUT[10] ,DOUT_buf[10] ,1'b1 );
nmos (DOUT[11] ,DOUT_buf[11] ,1'b1 );
nmos (DOUT[12] ,DOUT_buf[12] ,1'b1 );
nmos (DOUT[13] ,DOUT_buf[13] ,1'b1 );
nmos (DOUT[14] ,DOUT_buf[14] ,1'b1 );
nmos (DOUT[15] ,DOUT_buf[15] ,1'b1 );  

nmos (DATARDY ,DATARDY_buf ,1'b1 );  

buf (FE_buf , FE );
buf (SE_buf , SE );  
buf (RECALL_buf , RECALL );
buf (PROG_buf , PROG );
buf (NVSTR_buf , NVSTR );
buf (DRT_buf , DRT);
buf (MRGEN_buf , MRGEN);
buf (MRGSEL_buf , MRGSEL);

// core function
MTP18G32X16_i flash   (
                       .DIN     ( DIN_buf ) ,
                       .FE      ( FE_buf ) ,
                       .FUSEADR ( FUSEADR_buf ),
                       .PROG    ( PROG_buf ) ,
                       .NVSTR   ( NVSTR_buf ) ,
                       .RECALL  ( RECALL_buf ),
                       .SE      ( SE_buf ) ,     
                       .DRT     ( DRT_buf ) ,
                       .MRGEN   ( MRGEN_buf ) ,
                       .MRGSEL  ( MRGSEL_buf ) ,
                       .DOUT    ( DOUT_buf ),
                       .DATARDY ( DATARDY_buf ) 
                      );

endmodule
`endcelldefine


`timescale 1ns/10ps
`celldefine
module MTP18G32X16_i  (
                       DIN, 
                       FE,
                       FUSEADR,
                       PROG,
                       NVSTR,
                       RECALL,
                       SE,
                       DRT,
                       MRGEN,
                       MRGSEL,
                       DOUT,
                       DATARDY
                       );

//begin parameter
parameter numAddrMTP = 5;
parameter numOut = 16;
parameter wordDepth = 32;
parameter Tsc1 = 100;
//end parameter

// IO ports
input FE, PROG, NVSTR, RECALL, SE, DRT, MRGEN, MRGSEL;
input [numAddrMTP-1:0] FUSEADR;
input [numOut-1:0] DIN;
output [numOut-1:0] DOUT;
output DATARDY;

`protect


// Truth Table
//wire recall_enable = FE && RECALL && SE && !PROG && !NVSTR;
wire recall_enable = RECALL && SE && !PROG && !NVSTR;
wire prog_enable = FE && !RECALL && !SE && PROG && NVSTR;
wire DRT_b = ~DRT;
// data output buffer
reg [numOut-1:0] data_bus;
reg datardy_bus;

// memory array
reg [numOut-1:0] mtp_mem [wordDepth-1:0];
reg [numAddrMTP:0] i;
reg [1:0] addr_err;
reg mem_err,recall_err,drt_write_err;
reg notify_drt_write;

// DRT write record
reg drt_write_record [wordDepth-1:0];

//--------------------------
// initialization
//-------------------------- 
initial begin
  mem_err=0;
  addr_err=0;
  recall_err=0;
  drt_write_err=0;
  notify_drt_write = 0;

  for (i = 0; i < wordDepth; i = i + 1) begin
      drt_write_record[i] = 1'b0;
  end
  
  #51000;
  
  mtp_mem[0]=16'h1234;
  mtp_mem[1]=16'h5678;
  mtp_mem[2]=16'h00cd;
  mtp_mem[3]=16'h00ae;
  mtp_mem[4]=16'hD10E;
  mtp_mem[5]=16'h0000;
  mtp_mem[6]=16'h0000;  
  mtp_mem[7]=16'h3014;
  
  for(i = 8; i < wordDepth; i = i + 1)
  begin
    mtp_mem[i]=i;
  end
  
end

// Error Handling
`ifdef no_whole_flash_unknown
`else
always @(mem_err) begin
   if (mem_err) begin
      for (i = 0; i < wordDepth; i = i + 1)
         mtp_mem[i] = {numOut{1'bx}};
   end
end
`endif


`ifdef no_warning_for_invalid_address
`else
always @(addr_err) begin
   case (addr_err)
      2'b01:
         $display("%.2fns \tERROR! FUSEADR address exceeds %d in recall cycle\n",$realtime,wordDepth-1);
      2'b10:
         $display("%.2fns \tERROR! FUSEADR address exceeds %d in write cycle\n",$realtime,wordDepth-1);
   endcase
   addr_err=0;
end
`endif


always @(PROG) begin
   if (^PROG === 1'bx) begin
      $display("%.2fns %m#\nWarning! PROG input is unknown.", $realtime);
   end
   if (PROG) begin
      if (RECALL) begin
         $display("%.2fns %m#\nERROR! Wrong conditions! PROG is high when recall.",$realtime);
      end
   end
end


always @ (NVSTR) begin
   if (^NVSTR === 1'bx) begin
      $display("%.2fns %m#\nWarning! NVSTR input is unknown.", $realtime);
   end
   if (NVSTR) begin
      if (RECALL) begin
         $display("%.2fns %m#\nERROR! Wrong conditions! NVSTR is high when recall.",$realtime);
         mem_err=1;
      end
      if (!FE) begin
         $display("%.2fns %m#\nERROR! Wrong conditions! FE is low when write.",$realtime);
         mem_err=1;
      end
      if (!PROG) begin
         $display("%.2fns %m#\nERROR! Wrong conditions! PROG is low when write.",$realtime);
         mem_err=1;
      end
   end
end


always @(SE) begin
   if (^SE === 1'bx) begin
      $display("%.2fns %m#\nWarning! SE input is unknown.", $realtime);
   end

   # Tsc1;
   
   //if ((DRT | MRGEN | MRGSEL) !== 0 ) begin
      //$display("%.2fns %m#\nERROR! DRT,MRGEN and MRGSEL must be kept low in user mode",$realtime);
      //data_bus={numOut{1'bx}};              
   //end
     
   if (recall_enable && recall_err==0) begin
       if (DRT == 1'b1) begin
           $display("%.2fns %m#\nWarning! DRT can not be driven high during recall.", $realtime);
           data_bus = {numOut{1'bx}};
       end
       else begin
           Recall; //recall
       end
   end

   if (SE) begin
      if (PROG) begin
         $display("%.2fns %m#\nERROR! Wrong conditions! SE is high when write.",$realtime);
         mem_err=1;
      end
   end
   else if (~SE) begin
      if (RECALL) begin
         data_bus={numOut{1'bx}};
      end
      /* MRG mode */
      else if (MRGEN) begin
         data_bus = {numOut{1'bx}};
      end
   end
end

always @(RECALL) begin
   if (^RECALL === 1'bx) begin
      $display("%.2fns %m#\nWarning! RECALL input is unknown.", $realtime);
   end
   if (RECALL) begin
      if (PROG) begin
         $display("%.2fns %m#\nERROR! Wrong conditions! RECALL is high when write.",$realtime);
         mem_err=1;
      end
      if (~SE) begin
         data_bus={numOut{1'bx}};
      end
   end
end
 
always @(NVSTR) begin 
   # 0.01;
   /* wrong setting during write */
   if (((MRGEN && MRGSEL) === 1) && prog_enable) begin
       $display("%.2fns %m#\nWarning! Wrong setting for write, MRGEN and MRSEL must be driven low during write.", $realtime);
       mem_err = 1;
       drt_write_record[FUSEADR] = 1'b0;
       if (DRT == 1'b1) begin
           drt_write_err = 1;
       end
   end
   else if ((DRT && !MRGEN && !MRGSEL) === 1 ) begin
       if (prog_enable === 1) begin
           $display("entering DRT write mode at %.2fns.", $realtime);
           drt_write_err = 0;
           if (^FUSEADR === 1'bx) begin
               $display("%.2fns %m#\nWarning! FUSEADR is unknown.", $realtime);
           end
           else begin
               drt_write_record[FUSEADR] = 1'b1;
           end
       end   
   end
   else if (!mem_err && prog_enable) begin
      ProgMemory; // program
   end
end 

always @(FE) begin
   if (^FE === 1'bx) begin
      $display("%.2fns %m#\nWarning! FE input is unknown.", $realtime);
   end


   /* MRG mode */
   if (MRGEN && !FE) begin
       data_bus = {numOut{1'bx}};
   end
/*
   # Tsc1;
   
   //if ((DRT | MRGEN | MRGSEL) !== 0 ) begin
      //$display("%.2fns %m#\nERROR! DRT,MRGEN and MRGSEL must be kept low in user mode",$realtime);
      //data_bus={numOut{1'bx}};              
   //end
     
   if (recall_enable && recall_err==0) begin
       if (DRT == 1'b1) begin
           $display("%.2fns %m#\nWarning! DRT can not be driven high during recall.", $realtime);
           data_bus = {numOut{1'b0}};
       end
       else begin
           Recall; //recall
       end
   end
*/
end

always @(DIN) begin
   if (^DIN === 1'bx) begin
      $display("%.2fns %m#\nWarning! DIN input is unknown.", $realtime);
   end
end

always @(FUSEADR) begin
   if (^FUSEADR === 1'bx) begin
      $display("%.2fns %m#\nWarning! FUSEADR input is unknown.", $realtime);
   end
   /* MRG mode */
   if (MRGEN) begin
       data_bus = {numOut{1'bx}};
   end
end

always @(DRT) begin
   if (^DRT === 1'bx) begin
      $display("%.2fns %m#\nWarning! DRT input is unknown.", $realtime);
   end

   if (DRT == 1'b1 && recall_enable && recall_err == 0) begin
      $display("%.2fns %m#\nWarning! DRT can not be driven high during recall.", $realtime);
      data_bus = {numOut{1'bx}};
   end
end

always @(MRGEN) begin
   if (^MRGEN === 1'bx) begin
      $display("%.2fns %m#\nWarning! MRGEN input is unknown.", $realtime);
   end
end

always @(MRGSEL) begin
   if (^MRGSEL === 1'bx) begin
      $display("%.2fns %m#\nWarning! MRGSEL input is unknown.", $realtime);
   end
end

task Recall;
begin
   if (FUSEADR >= wordDepth) begin
      data_bus = {numOut{1'bx}};
      datardy_bus = 0;
      addr_err=1;
   end
   else begin
      /* user mode */
      if ((!DRT && !MRGEN && ! MRGSEL) === 1) begin
          data_bus=mtp_mem[FUSEADR];
          datardy_bus = 1;
          mem_err=0;
      end
      /* mrg read with MRGSEL=0 */
      else if ((!DRT && MRGEN && !MRGSEL) === 1) begin
          $display("MRG read (MRGSEL=0) at %.2fns.", $realtime);
          if (drt_write_err == 1) begin
              data_bus = {numOut{1'bx}};
              $display("MRG read (MRGSEL=0) failed because DRT write failed");
          end
          else if (drt_write_err == 0) begin
              if (drt_write_record[FUSEADR] == 1) begin
                  data_bus = {numOut{1'b0}};
              end
              else if (drt_write_record[FUSEADR] == 0) begin
                  data_bus = mtp_mem[FUSEADR];
                  $display("no drt write record, read mtp_mem out at %.2fns", $realtime);
              end
          end
      end 
      /* mrg read with MRGSEL=1 */
      else if ((!DRT && MRGEN && MRGSEL) === 1) begin
          $display("MRG read (MRGSEL=1) at %.2fns.", $realtime);
          if (drt_write_err == 1) begin
              data_bus = {numOut{1'bx}};
              $display("MRG read (MRGSEL=1) failed because DRT write failed");
          end
          else if (drt_write_err == 0) begin
              data_bus = {numOut{1'b1}};
              if (drt_write_record[FUSEADR] == 1) begin
                  data_bus = {numOut{1'b1}};
              end
              else if (drt_write_record[FUSEADR] == 0) begin
                  data_bus = mtp_mem[FUSEADR];
                  $display("no drt write record, read mtp_mem out at %.2fns", $realtime);
              end
          end
      end
      else if ((!DRT && !MRGEN && MRGSEL) === 1) begin
          $display("%.2fns %m#\nERROR! MRGSEL can not be driven high during user mode recall.", $realtime);
          data_bus = {numOut{1'bx}};
      end
   end
end    
endtask

task ProgMemory;
begin
   // non_fully_decode_handling_begin
   if (FUSEADR>=wordDepth) begin
      addr_err=2;
   end

   // non_fully_decode_handling_end
   else if (^FUSEADR === 1'bx) begin
      $display("%.2fns %m#\nERROR! address unknown when write.", $realtime);
      mem_err=1;
   end
   else begin
      mtp_mem[FUSEADR]=DIN;     
      drt_write_record[FUSEADR] = 1'b0;
      mem_err=0;
      drt_write_err = 0;
   end
   //mem_err=0; 
end
endtask

reg   recall_flag;
reg   program_flag;

always @(negedge NVSTR) begin
   program_flag = 0;
end    
  
always @(posedge PROG) begin
   program_flag = 1;
end

always @(negedge RECALL or negedge FE or negedge SE) begin
   recall_flag = 0;
   recall_err = 0;
end    
  
always @(posedge RECALL) begin
   # 10.01;
   recall_flag = 1;
end

always @(FUSEADR) begin
   if (recall_flag) begin
      data_bus = {numOut{1'bx}};
   end
end

wire [numOut-1 : 0] DOUT;  
reg  notify_mem;
reg notify_err;

assign DOUT = data_bus;
//assign DATARDY = (~SE) ? 0 :  datardy_bus;
assign DATARDY = (~SE || MRGEN) ? 0 :  datardy_bus;

always @(notify_mem) begin
   mem_err = 1;
end

always @(notify_err) begin
   data_bus = {numOut{1'bx}};
   recall_err = 1;
end

always @(notify_drt_write) begin
    drt_write_err = 1;
    $display("ERROR! DRT WRITE failed at %.2fns", $realtime);
end

specify
	specparam Tac = 200.000000;
	specparam Tsc = 100.000000;
	specparam Tpch = 100.000000;
	specparam Tpgs = 1000.000000;
	specparam Twrite = 5000000.000000;
	specparam Tdsg = 10000.000000;
	specparam Trh = 0.000000;
	specparam Tse = -5.000000;

// Program
	$setup(posedge FE &&& DRT_b, posedge NVSTR, Tpgs, notify_mem);
	$setup(FUSEADR &&& DRT_b, posedge NVSTR, Tpgs, notify_mem);
	$setup(DIN &&& DRT_b, posedge NVSTR, Tpgs, notify_mem);    
	$setup(posedge PROG &&& DRT_b, posedge NVSTR, Tpgs, notify_mem);    

	$hold(negedge PROG &&& DRT_b, negedge FE, Tdsg, notify_mem);
	$hold(negedge PROG &&& DRT_b, FUSEADR, Tdsg, notify_mem);    
	$hold(negedge PROG &&& DRT_b, DIN, Tdsg, notify_mem);
	$hold(negedge PROG &&& DRT_b, negedge NVSTR, Tdsg, notify_mem);

	$hold(posedge NVSTR &&& DRT_b, negedge PROG, Twrite, notify_mem);

// DRT write
	$setup(posedge FE &&& DRT, posedge NVSTR, Tpgs, notify_drt_write);
	$setup(FUSEADR &&& DRT, posedge NVSTR, Tpgs, notify_drt_write);
	$setup(DIN &&& DRT, posedge NVSTR, Tpgs, notify_drt_write);    
	$setup(posedge PROG &&& DRT, posedge NVSTR, Tpgs, notify_drt_write);    

	$hold(negedge PROG &&& DRT, negedge FE, Tdsg, notify_drt_write);
	$hold(negedge PROG &&& DRT, FUSEADR, Tdsg, notify_drt_write);    
	$hold(negedge PROG &&& DRT, DIN, Tdsg, notify_drt_write);
	$hold(negedge PROG &&& DRT, negedge NVSTR, Tdsg, notify_drt_write);

	$hold(posedge NVSTR &&& DRT, negedge PROG, Twrite, notify_drt_write);
// Read  
	$setup(posedge RECALL, posedge FE, Tpch, notify_err);
	$setup(posedge RECALL, posedge SE, Tpch, notify_err);          
	$setup(FUSEADR &&& RECALL, posedge SE, Tpch, notify_err); 
	$setup(FUSEADR &&& RECALL, posedge FE, Tpch, notify_err);    

	$width(posedge FE, Tsc, 0, notify_mem);   
	$width(posedge SE, Tsc, 0, notify_mem);  
	$recovery(posedge FE, negedge RECALL, Tsc, notify_mem);    

	$hold(negedge RECALL, FUSEADR, Trh, notify_err);
	$hold(negedge RECALL, negedge FE, Trh, notify_err);
	$hold(negedge RECALL, negedge SE, Trh, notify_err);
endspecify

parameter Tpa = 10;
parameter Tsemax = 5;
parameter Twritemax = 10000000;

real pos_tPROG, pos_tFE, tDIN, tFUSEADR, pos_tRECALL;
real neg_tPROG, pos_tNVSTR, pos_tSE;
real neg_tRECALL;

always @(posedge RECALL) begin
   pos_tRECALL=$realtime;
   # 0.01
   if (SE != 0) begin
      $display("%.2fns %m#\nERROR! Wrong conditions! SE is high before RECALL during RECALL operation.",$realtime);
      data_bus = {numOut{1'bx}};
      recall_err = 1;
   end
   if (FE != 0) begin
      $display("%.2fns %m#\nERROR! Wrong conditions! FE is high before RECALL during RECALL operation.",$realtime);
      data_bus = {numOut{1'bx}};
      recall_err = 1;
   end
end

always @(negedge RECALL) begin
   neg_tRECALL=$realtime;
   #0.01;
   if (((SE != 1) && (FE != 1)) && (neg_tRECALL - pos_tRECALL >= 5)) begin
      $display("%.2fns %m#\nERROR! Wrong conditions! RECALL pulse > 5ns without toggling SE or FE.",$realtime); 
   end
   if (((SE != 0) || (FE != 0)) && ~datardy_bus && !MRGEN) begin // added !MRGEN by HC, 20090213
      $display("%.2fns %m#\nERROR! Wrong conditions! RECALL goes low before DOUT ready.",$realtime); 
   end
end

wire #(Tpa,0) prog_tpa_chk=PROG;
wire #(Tpa,0) recall_tpa_chk=RECALL;
always @(posedge FE) begin
   pos_tFE=$realtime;
   # 0.01
//   if (PROG && (pos_tFE - pos_tPROG >= Tpa + 0.01)) begin
   if(prog_tpa_chk) begin
      $display("%.2fns %m#\nERROR! Timing Violation: [FE:%.2f] should be stable within %.2f ns after [pos PROG:%.2f]",
               $realtime, pos_tFE, Tpa, pos_tPROG);
      mem_err = 1; 
   end
   if (RECALL && SE && (pos_tFE - pos_tSE >= Tsemax + 0.01)) begin
      $display("%.2fns %m#\nERROR! Timing Violation: [pos SE:%.2f] [pos FE:%.2f] [Tse max:%.2f]",
               $realtime, pos_tSE, pos_tFE, Tsemax);
      data_bus = {numOut{1'bx}};
      recall_err = 1;
   end
   if (RECALL && !SE) begin
      $display("%.2fns %m#\nERROR! Wrong conditions! FE is high before SE during RECALL operation.",$realtime);
      data_bus = {numOut{1'bx}};
      recall_err = 1;
   end
end

always @(DIN) begin
   tDIN=$realtime;
   # 0.01
//   if (PROG && (tDIN - pos_tPROG >= Tpa + 0.01)) begin
   if(prog_tpa_chk) begin
      $display("%.2fns %m#\nERROR! Timing Violation: [DIN:%.2f] should be stable within %.2f ns after [pos PROG:%.2f]",
               $realtime, tDIN, Tpa, pos_tPROG);
      mem_err = 1; 
   end
end

always @(FUSEADR) begin
   tFUSEADR=$realtime;
   # 0.01
//   if (PROG && (tFUSEADR - pos_tPROG >= Tpa + 0.01)) begin
   if(prog_tpa_chk) begin
      $display("%.2fns %m#\nERROR! Timing Violation: [FUSEADR:%.2f] should be stable within %.2f ns after [pos PROG:%.2f]",
               $realtime, tFUSEADR, Tpa, pos_tPROG);
      mem_err = 1; 
   end
//   if (RECALL && (tFUSEADR - pos_tRECALL >= Tpa + 0.01)) begin
   if(recall_tpa_chk) begin
      $display("%.2fns %m#\nERROR! One of below timings is violated:\n 1. [FUSEADR:%.2f] should be stable within %.2f ns after [pos RECALL:%.2f].\n 2. Trh Violation : FUSEADR switch before RECALL goes low.",
               $realtime, tFUSEADR, Tpa, pos_tRECALL);
      data_bus = {numOut{1'bx}};
      recall_err = 1;
   end
end

always @(posedge PROG) begin
   pos_tPROG=$realtime;
   # 0.01
   if (NVSTR && prog_enable) begin
      $display("%.2fns %m#\nERROR! Wrong condition: PROG is high late after NVSTR",$realtime);
      mem_err=1;
   end
end

always @(negedge PROG) begin
   neg_tPROG=$realtime;
   # 0.01
   if (NVSTR && (neg_tPROG - pos_tNVSTR >= Twritemax + 0.01)) begin
      $display("%.2fns %m#\nERROR! Timing Violation: [pos NVSTR:%.2f] [neg PROG:%.2f] [Twrite max:%.2f]",
               $realtime,pos_tNVSTR,neg_tPROG,Twritemax);
      mem_err=1;
   end
end

always @(posedge NVSTR) begin
   pos_tNVSTR=$realtime;
end

always @(negedge NVSTR) begin
   # 0.01
   if (PROG) begin
      $display("%.2fns %m#\nERROR! Wrong conditions! PROG is high when negedge NVSTR.",$realtime);
      mem_err=1;
   end
end

always @(posedge SE) begin
   pos_tSE=$realtime;
end


// Timing Check : Trh
always @(negedge FE) begin
   # 0.01
   if (RECALL) begin
      $display("%.2fns %m#\nERROR! Wrong conditions! FE goes low when RECALL=1.",$realtime);
      data_bus = {numOut{1'bx}};
      recall_err = 1;
   end
end

always @(negedge SE) begin
   datardy_bus = 0;
   # 0.01
   if (RECALL) begin
      $display("%.2fns %m#\nERROR! Wrong conditions! SE goes low when RECALL=1.",$realtime);
      data_bus = {numOut{1'bx}};
      recall_err = 1;
   end
end

`endprotect

endmodule
`endcelldefine


