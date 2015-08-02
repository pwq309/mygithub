// *******************************************************************
// COPYRIGHT, Xi'an XDU Radio-frequency IC Co.,Ltd 
// All rights reserved.
//
// IP NAME      :  RFID
// File name    :  pmu.v
// Module name  :  PMU
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

module PMU(
           //INPUTs
           rst_n           ,                 //from Analog Frontend
           dec_done        ,              
           parse_done      ,                 //from CMD_PARSE
           parse_iereq     ,                 //from CMD_PARSE
           //mask_match      ,                 //from CMD_PARSE
           init_done       ,                 //from INIT
           tag_status      ,                 //from INIT 
           job_done        ,                 //from IE
           scu_done        ,                 //from SCU
           cmd_head        ,
           parse_err       ,                 //from CMD_PARSE
           ocu_iereq       ,                 //from OCU
           ocu_done        ,
           DOUB_BLF        ,                 
           T2_overstep     ,                              
           new_cmd         ,                
           
           //OUTPUTs
           dec_en          ,                 //to DECODER
           init_en         ,                 //to INIT
           ie_en           ,                 //to IE
           scu_en          ,                 //to SCU
           ocu_en          ,                 //to OCU
           div_en                           
		   
           );
       
// ************************
// DEFINE PARAMETER(s)
// ************************
//PMU states
parameter PMU_RDY   = 4'b0000;
parameter INIT_ON   = 4'b0001;
parameter REC_ON    = 4'b0010;
parameter SCU_ON    = 4'b0011;
parameter OCU_ON    = 4'b0100;
parameter NOP_ONE   = 4'b1000;
parameter NOP_TWO   = 4'b1001;
parameter NOP_THR   = 4'b1010;
parameter NOP_FOU   = 4'b1011;
parameter NOP_FIV   = 4'b1100;
parameter NOP_SIX   = 4'b1101; 
parameter NOP_SEV   = 4'b1110; 
parameter PMU_END   = 4'b1111;  

// ************************
// DEFINE INPUT(s)
// ************************
input        new_cmd         ; 
input        DOUB_BLF        ;
input        dec_done        ;  
input [7:0]  cmd_head        ;
input        rst_n           ;
input        parse_done      ;
input        init_done       ;             
input        tag_status      ;           //indicates the kill status of a tag when tag powers up,0=>alive,1=>killed
input        job_done        ;
input        scu_done        ;
input        parse_iereq     ;
//input        mask_match      ;
input        parse_err       ;
input        ocu_iereq       ;
input        ocu_done        ;
input        T2_overstep     ;

// ************************      
// DEFINE OUTPUT(s)                               
// ************************
output       dec_en          ;
output       init_en         ;
output       ie_en           ;
output       scu_en          ;
output       ocu_en          ;
output       div_en          ;

// ***************************                    
// DEFINE OUTPUT(s) ATTRIBUTE                     
// ***************************
reg          dec_en          ; 
reg          div_en          ;  
reg          init_en         ; 
reg          ie_en           ; 
reg          scu_en          ; 
reg          ocu_en          ; 

// ****************************
// INNER SIGNAL(s) DECLARATION
// ****************************
reg          init_done_delay ;
reg          init_div_cut    ;

//FSM*****************************
reg    [3:0] pmu_state       ;
reg    [3:0] nxt_state       ;
//wire*****************************
wire	       div_off         ;
wire         div_on          ;
wire         ie_on           ;
wire         ie_off          ;
wire         rst_del         ;
wire         pmu_clk         ;

//********************************************************//
assign   pmu_clk = DOUB_BLF          ;
assign   rst_del = rst_n&(~new_cmd)  ;

//current state of FSM jumps.
always @(posedge pmu_clk or negedge rst_n)
begin
    if(!rst_n)
        pmu_state <= #`UDLY PMU_RDY  ;
    else if(tag_status)
        pmu_state <= #`UDLY PMU_END  ;
    else
        pmu_state <= #`UDLY nxt_state;
end
    
always @(init_done or parse_done or parse_err or scu_done or ocu_done or pmu_state or cmd_head)
begin
    case(pmu_state)
    PMU_RDY:
        nxt_state = INIT_ON          ;
    INIT_ON:
        if(init_done)
            nxt_state = REC_ON       ;
        else
            nxt_state = INIT_ON      ;
    REC_ON:
        if(parse_done)
            if(cmd_head == `SORT)
                nxt_state = REC_ON   ;
            else  
                nxt_state = NOP_ONE  ;
        else if(parse_err)
            nxt_state = REC_ON       ;
        else
            nxt_state = REC_ON       ;
    NOP_ONE:
        nxt_state = NOP_TWO          ;
    NOP_TWO:
        nxt_state = NOP_THR          ;
    NOP_THR:
        nxt_state = SCU_ON           ;
    SCU_ON:
        if(scu_done)
            nxt_state = NOP_FOU      ;
        else
            nxt_state = SCU_ON       ;
    NOP_FOU:
        nxt_state = NOP_FIV          ;
    NOP_FIV:
        nxt_state = NOP_SIX          ;
    NOP_SIX:
        nxt_state = NOP_SEV          ;
    NOP_SEV:
        nxt_state = OCU_ON           ;
    OCU_ON:
        if(ocu_done)
            nxt_state = REC_ON       ;            
        else
            nxt_state = OCU_ON       ;
    PMU_END:
        nxt_state = PMU_END          ;
    default:
        nxt_state = REC_ON           ;
    endcase
end
    
//********************************************************//
    
//Switch INIT module.
always @(negedge pmu_clk or negedge rst_n)
begin
    if(!rst_n)
        init_en <= #`UDLY 1'b0       ;
    else if(pmu_state==INIT_ON)
        init_en <= #`UDLY 1'b1       ;
    else
        init_en <= #`UDLY 1'b0       ;
end
    
//Switch DECODER module.
always @(negedge pmu_clk or negedge rst_n)
begin
    if(!rst_n)
        dec_en <= #`UDLY 1'b0        ;
    else if(pmu_state==REC_ON)
        dec_en <= #`UDLY 1'b1        ;
    else
        dec_en <= #`UDLY 1'b0        ;
end
    
//Switch SCU module.
always @(negedge pmu_clk or negedge rst_n)
begin
    if(!rst_n)
        scu_en <= #`UDLY 1'b0        ;
    else if(pmu_state==SCU_ON)
        scu_en <= #`UDLY 1'b1        ;
    else
        scu_en <= #`UDLY 1'b0        ;
end
    
//Switch OCU module.
always @(negedge pmu_clk or negedge rst_n)
begin
    if(!rst_n)
        ocu_en <= #`UDLY 1'b0        ;
    else if(pmu_state==OCU_ON)
        ocu_en <= #`UDLY 1'b1        ;
    else
        ocu_en <= #`UDLY 1'b0        ;
end
    
//********************************************************// 

//always @(negedge pmu_clk or negedge rst_n )
//begin 
//    if (!rst_n)
//        init_done_delay <= #`UDLY 1'b0;
//    else
//        init_done_delay <= #`UDLY init_done;
//end 

always @(posedge init_done or negedge rst_del)
begin
    if(!rst_del)
        init_done_delay <= #`UDLY 1'b0           ;
    else
        init_done_delay <= #`UDLY 1'b1           ;
end 

always @(negedge pmu_clk or negedge rst_del)
begin
    if(!rst_del)
        init_div_cut <= #`UDLY 1'b0              ;
    else if(init_done_delay & dec_en)  
        init_div_cut <= #`UDLY 1'b1              ;
    else
        init_div_cut <= #`UDLY 1'b0              ;
end

assign div_on  = parse_iereq|dec_done;                       //a pulse form other modules is used to apply for DIV.
assign div_off = new_cmd|T2_overstep|init_div_cut;           //a pulse form other modules is used to release DIV.

//Switch DIV module.    
always @(posedge div_on or posedge div_off or negedge rst_n)
begin
    if(!rst_n)
        div_en <= #`UDLY 1'b1                    ;
    else if(div_off)
        div_en <= #`UDLY 1'b0                    ;
    // else if(div_on)
        // div_en <= #`UDLY 1'b1                    ;  
    else
        div_en <= #`UDLY 1'b1                    ;        
end

assign ie_on  = parse_iereq|ocu_iereq            ;
assign ie_off = dec_done|ocu_done|(job_done && pmu_state==REC_ON)|init_done;
	
always @(posedge ie_on or posedge ie_off or negedge rst_n)
begin
	  if (!rst_n)
	      ie_en <= #`UDLY 1'b1                     ;
    else if(ie_on)
        ie_en <= #`UDLY 1'b1                     ;
    else 
        ie_en <= #`UDLY 1'b0                     ;
end

endmodule	