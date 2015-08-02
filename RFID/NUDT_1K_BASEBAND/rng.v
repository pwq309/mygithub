// *******************************************************************
// COPYRIGHT, Xi'an XDU Radio-frequency IC Co.,Ltd 
// All rights reserved.
//
// IP NAME      :  RFID
// File name    :  rng.v
// Module name  :  RNG
//
// Author       :  panwanqiang
// Email        : 
// Data         :  
// Version      :  v1.0 
// 
// Tech Info    :  clk=DOUB_BLF, here use epc_crc16 as the initial data of shift registers. 
//                 while Q_updata effective, get 15bits slot_val;  
//                 while enable signal for rn16 or handle, get rn16.
//
// Abstract     :  It's mainly a Random data Generator Module, include slot-count (Q) selection algorithm 
//                 and handle signal of 16bits. while slot_updata effective, operate slot_value.
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

 module RNG (
            //INPUTs
            DOUB_BLF          ,
            rst_n             ,
            //new_cmd           ,
            cmd_head          ,
            init_done         , 
            crc_calc          , 
            handle_update     ,
            rn16_update       ,           
            rn1_update        ,           
            dec_done5         ,          
            divide_position   ,
            tag_state         ,
			
            //OUTPUTs
            slot_val          ,
            rn16              , 
            handle            

            );
//
// ********************************
// PARAMETERS
// ********************************
parameter   SLOTEFFECT = 15'b0000_0000_0000_000;

// ********************************
// DEFINE INPUT  
// ********************************
//
// *****************
// INPUT FROM ANALOG FRONT_END
// *****************
input            DOUB_BLF            ;         //DOUB_BLF double the frequency of BLF(Tpri) 
input            rst_n               ;         //reset signal, active low

// *****************
// INPUT FROM DECODER
// *****************
//input            new_cmd             ;         //flag of new commend

// *****************
// INPUT FROM CMD_PARSE 
// *****************
input  [7:0]     cmd_head            ;
  
// *****************
// INPUT FROM SCU
// *****************
input            handle_update       ;         //enable signal for new rn16t as a handle
input            rn16_update         ;
input            rn1_update          ;       
input            divide_position     ; 
input   [2:0]    tag_state           ;

// *****************
// INPUT FROM DECODER
// *****************
input            dec_done5           ;       
input  [15:0]    crc_calc            ;       
input            init_done           ;       

// ********************************
// DEFINE OUTPUT SIGNALS 
// ********************************
output [14:0]    slot_val            ;         //15bits slot for selection algorithm
output [15:0]    handle              ;         //output rn16t as a handle signal 
output [15:0]    rn16                ; 
 
// ********************************
// OUTPUT ATTRIBUTE   
// ********************************  
reg    [14:0]    slot_val            ;           
reg    [15:0]    handle              ; 
reg    [15:0]    rn16                ;  

// ********************************
// INNER SIGNAL DECLARATION
// ********************************
// REGS 
reg    [15:0]    shiftreg            ;         //a shift_register to generate Random data 
reg              rn1                 ;
// wire 
wire             updata_pulse        ;
wire             temp_data           ;
    
//assign updata_pulse = rn1_update | rn16_update | handle_update | init_done;  

assign updata_pulse = rn1_update | rn16_update | handle_update;

assign temp_data = ^shiftreg[15:12];

// controlling shift_register work 
always @(negedge updata_pulse or posedge init_done or negedge rst_n)
begin: RANDOMDATE_GENERATOR
    if(!rst_n)
        shiftreg <= #`UDLY 16'b0;
	  else if(init_done)
		    shiftreg <= #`UDLY crc_calc;                         //load epc_crc16 as the initial data
	  else
		    shiftreg <= #`UDLY {shiftreg[14:0], temp_data};
end  

// always @(updata_pulse or init_done or crc_calc or shiftreg)
// begin
	  // if(init_done)
	      // shiftreg = crc_calc;     //load epc_crc16 as the initial data
	  // else 
	      // shiftreg = {shiftreg[14:0], ^shiftreg[15:12]};	      
// end 

// always @(posedge DOUB_BLF or negedge rst_n)               //这里会引起下面建立时间违例
// begin: RANDOMDATE_GENERATOR
    // if(!rst_n)
        // shiftreg <= #`UDLY 16'b0;
	  // else if(init_done)
		    // shiftreg <= #`UDLY crc_calc;                         //load epc_crc16 as the initial data
	  // else if(updata_pulse)
		    // shiftreg <= #`UDLY {shiftreg[14:0], temp_data};
	  // else
	        // shiftreg <= #`UDLY shiftreg;
// end  

// slot_value generator and operation
always@(posedge dec_done5 or negedge rst_n)  
begin: SLOT_COUNTER
    if(!rst_n) 
        slot_val <= #`UDLY SLOTEFFECT; 
    else if(cmd_head == `QUERY)
        slot_val <= #`UDLY 15'b0;
    else if(cmd_head == `DIVIDE)       
        if(tag_state == `ARBITRATE)
            if(divide_position == 1'b0)     
                if(slot_val == 15'b0)
                    slot_val <= #`UDLY {14'b0,rn1};
                else
                    slot_val <= #`UDLY slot_val + 1'b1;
            else 
                if(slot_val == 15'b1)
                    slot_val <= #`UDLY {14'b0,rn1};
                else
                    slot_val <= #`UDLY slot_val;
        else if(tag_state == `REPLY)
            if(divide_position == 1'b0)               
                slot_val <= #`UDLY {14'b0,rn1} ;
            else
                slot_val <= #`UDLY slot_val;
        else
            slot_val <= #`UDLY slot_val;                            
    else if(cmd_head == `QUERYREP )
        if(tag_state == `ARBITRATE || tag_state == `REPLY)
            slot_val <= #`UDLY slot_val -1'b1;
        else
            slot_val <= #`UDLY slot_val ;
    else if(cmd_head == `DISPERSE)
        if(tag_state == `ARBITRATE)
            if(slot_val == 15'b0)
                slot_val <= #`UDLY {14'b0,rn1};
            else if(slot_val <15'b1000_0000_0000_000)
                slot_val <= #`UDLY {slot_val[13:0], 1'b0}+ rn1;
            else 
                slot_val <= #`UDLY 15'h7FFF;
        else if(tag_state == `REPLY)
            slot_val <= #`UDLY {14'b0,rn1};
        else
            slot_val <= #`UDLY slot_val;
    else if(cmd_head == `SHRINK)
        if(tag_state == `ARBITRATE)
            if(slot_val == 15'b0)
                slot_val <= #`UDLY 15'b0;           
            else 
                slot_val <= #`UDLY {1'b0, slot_val[14:1]};
        else if(tag_state == `REPLY)
            slot_val <= #`UDLY 15'b0;
        else
            slot_val <= #`UDLY slot_val;
    else
        slot_val <= #`UDLY slot_val;
end

always@(posedge handle_update or negedge rst_n) 
begin: HANDLE_GENERATOR
    if(!rst_n)   
        handle <= #`UDLY 16'b0000_0000_0000_0000;  
    else      
        handle <= #`UDLY shiftreg; 
end  

always@(posedge rn16_update or negedge rst_n)   
begin: RN16_GENERATOR
    if(!rst_n)   
        rn16 <= 16'b0000_0000_0000_0000;  
    else      
        rn16 <= #`UDLY shiftreg; 

end

always@(posedge rn1_update or negedge rst_n)
begin :RN1_GENERATOR
    if(!rst_n)
        rn1 <= #`UDLY 1'b0;
    else
        rn1 <= #`UDLY shiftreg[15];
end      

endmodule       
            


























