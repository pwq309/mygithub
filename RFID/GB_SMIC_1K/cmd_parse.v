// *******************************************************************
// COPYRIGHT, Xi'an XDU Radio-frequency IC Co.,Ltd 
// All rights reserved.
//
// IP NAME      :  RFID
// File name    :  cmd_parse.v
// Module name  :  CMD_PARSE
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

// ************************
// DEFINE MACRO(s)
// ************************
`include "./macro.v"
`include "./timescale.v"

// ************************
// DEFINE MODULE
// ************************
module CMD_PARSE(    
                //INPUTs   
                DOUB_BLF         ,       //from DIV     
                rst_n            ,       //from Analog Fronted                                   
                tpp_clk          ,       //from DECODER              
                tpp_data         ,       //from DECODER                                            
                delimiter        ,       //from DECODER              
                dec_done         ,       //from DECODER
                dec_done3        ,       //from DECODER 
                dec_done6        ,       //from DECODER                 
                mtp_data         ,       //from IE                                                
                handle           ,       //from RNG                                                                                               
                rn16             ,       //from RNG                                                       
                tag_state        ,       //from SCU
                crc5_back        ,       //from OCU  
			        	read_pwd_status  ,       //from init
			         	write_pwd_status ,       //from init
				 
                //OUTPUTs
                parse_done       ,       //to PMU           
                parse_iereq      ,       //to PMU                                           
                rn1_update       ,       //to RNG           
                divide_position  ,       //to RNG                 
                membank          ,       //to IE and OCU    
                pointer_par      ,       //to IE and OCU    
                length_par       ,       //to IE and OCU    
                read_en          ,       //to IE                                             
                //rule           ,       //to SCU  
                //target_sort    ,       //to SCU				 
                cmd_head         ,       //to SCU           
                mask_match       ,       //to SCU                          
                rn_match         ,       //to SCU                                                       
                parse_err        ,       //to SCU and PMU   
                addr_over        ,       //to OCU				
                DR               ,       //to DIV           
                M                ,       //to ENCODER                                               
                data_buffer      ,       //to OCU                                                                 
                cmd_end          ,       //to DECODER
                set_m            ,       //to DIV                  
                //condition      ,       //to SCU
                //target_query   ,       //to SCU
                trext            ,       //to OCU
                head_finish      ,       //to DECODER            
                lock_action      ,       //to OCU
                lock_deploy      ,       //to OCU                            
                killpwd1_match   ,       //to OCU
                killpwd2_match   ,       //to OCU
                lockpwd1_match   ,       //to OCU
                lockpwd2_match   ,       //to OCU
                acc_pwd          ,       //to OCU
                killpwd_match    ,       //to SCU
                lockpwd_match    ,       //to SCU
                rd_pwd1_match    ,       //to OCU
			          rd_pwd2_match    ,       //to OCU
                wr_pwd1_match    ,       //to OCU
                wr_pwd2_match    ,       //to OCU
			          rd_pwd_match     ,       //to SCU
                wr_pwd_match     ,       //to SCU
				        //session_val    ,
			        	session_match    ,
				        flag_match       ,
				        SL_match         
				
                );
                 
// ************************
// DEFINE INPUT(s)
// ************************
input           DOUB_BLF         ;      //used for data exchange between CMD_PARSE and IE
input           rst_n            ;      //asynchronous reset signal, low active
input           tpp_clk          ;      //Module CMD_PARSE receives signals by the this pulse signal
input   [ 1:0]  tpp_data         ;      //The TPP dates (0 or 1) are sent to CMD_PARSE by TPP_data together with tpp_clk       
input           dec_done6        ;      //series of dec_done 
input           dec_done3        ;      //series of dec_done
input           dec_done         ;      //series of dec_done
input           delimiter        ;      //Indicate the beginning of a command!
input   [15:0]  mtp_data         ;      //the port through with CMD_PARSE receives data from EEPROM
input   [ 3:0]  tag_state        ;      //from SCU
input   [15:0]  handle           ;      //handle from RNG
input   [ 4:0]  crc5_back        ;      //part of the reply for query
input   [15:0]  rn16             ;      //rn16 from RNG
input           read_pwd_status  ;
input           write_pwd_status ;

// ************************                       
// DEFINE OUTPUT(s)                               
// ************************
output          parse_done       ;      //this signal is asserted when CMD_PARSE has finished its job
output          parse_iereq      ;      //a signal indicate that need to access ie
output          rn1_update       ;      //a signal to generate 1 bit random data, active high
output  [ 5:0]  membank          ;      //tell IE which memory bank should be chosen
output  [ 5:0]  pointer_par      ;      //tell IE the initiatory bit of a read operation
output  [ 5:0]  length_par       ;      //tell IE the length of the a read operation
output          read_en          ;      //we use this signal to enable a read operation
//output  [ 1:0]  rule             ;      //the rule parameter in a SORT command
output  [ 7:0]  cmd_head         ;      //the head of a received command
output          head_finish      ;      //a signal that indicates whether a command head has been successfully received
output          mask_match       ;      //acts as an arbitrator whether the mask in a select matches the specific content stored in the tag memory      
output          rn_match         ;      //a signal to notify SCU that the handle in a command matched the one the tag sent out immediately before                
output          parse_err        ;      //to notify the tag that an error happened during the reception of a command
output          addr_over        ;      //indicate the address overflows
output  [ 3:0]  DR               ;      //DR  sent to DIV
//output  [ 3:0]  target_sort      ;      //target of sort cmd
//output  [ 1:0]  condition        ;      //condition of query cmd
//output          target_query     ;      //target of query cmd
output          trext            ;      //TRext of query cmd
output  [ 1:0]  M                ;      //a parameter sent to a ENCODER, based on which a tag chooses the encoding style
output  [15:0]  data_buffer       ;      //data buffer for both write and erase!
output          divide_position  ;      //divide position of divide cmd
output          cmd_end          ;      //indicate the end of a cmd
output          set_m            ;      //a signal used to judge when to calculate the divide coefficient
output  [ 1:0]  lock_action      ;      //action of lock cmd
output  [ 1:0]  lock_deploy      ;      //deploy of lock cmd
output          killpwd1_match   ;      //indicate the kill pwd in access pwd match with the pwd in the safe region  
output          killpwd2_match   ;     
output          lockpwd1_match   ;      //indicate the lock pwd in access pwd match with the pwd in the safe region
output          lockpwd2_match   ;      
output  [ 3:0]  acc_pwd          ;      //buffer the 4 bits pwd type in access cmd   
output          killpwd_match    ;      //indicate the 32 bits kill pwd are match
output          lockpwd_match    ;      //indicate the 32 bits lock pwd are match
output          rd_pwd1_match    ;      //indicate the read pwd in access pwd match with the pwd in the user region
output 		    	rd_pwd2_match    ;
output          wr_pwd1_match    ;      //indicate the write pwd in access pwd match with the pwd in the user region
output          wr_pwd2_match    ;
output 		    	rd_pwd_match     ;      //indicate the 32 bits read pwd are match
output          wr_pwd_match     ;      //indicate the 32 bits write pwd are match
//output  [ 1:0]  session_val      ;
output          session_match    ;
output          flag_match       ;
output          SL_match         ;

// ***************************                    
// DEFINE OUTPUT(s) ATTRIBUTE                     
// *************************** 
//REG(s)
reg             head_finish      ;      
reg     [ 1:0]  lock_deploy      ; 
reg     [ 1:0]  lock_action      ;
reg             parse_iereq      ;
reg     [ 5:0]  membank          ;
reg             read_en          ;
reg     [ 1:0]  rule             ;
reg     [ 7:0]  cmd_head         ;
reg             mask_match       ;
reg             rn_match         ;
reg     [ 3:0]  DR               ;
reg     [ 1:0]  condition        ;
reg             trext            ;
reg     [ 1:0]  M                ;
reg             divide_position  ;
reg     [15:0]  data_buffer      ;
reg             cmd_end          ;
reg             set_m            ;    
reg             rn1_update       ;
reg             killpwd1_match   ;
reg             killpwd2_match   ;
reg             lockpwd1_match   ;
reg             lockpwd2_match   ;
reg             rd_pwd1_match    ;  
reg             rd_pwd2_match    ;
reg             wr_pwd1_match    ;
reg             wr_pwd2_match    ;
reg     [ 1:0]  session_val      ;
reg             session_match    ;

//WIRE(s)
wire    [ 5:0]  pointer_par      ;
wire    [ 5:0]  length_par       ;
wire    [ 3:0]  acc_pwd          ;
wire            parse_err        ;
wire            killpwd_match    ;
wire            lockpwd_match    ;
wire 	    	    rd_pwd_match     ;   
wire            wr_pwd_match     ;
wire            parse_done       ;

// *************************
// INNER SIGNAL DECLARATION
// *************************
reg          data_end            ;  
reg  [15:0]  CRC16               ;      //the 16 bits register for CRC16 
reg  [ 2:0]  head_cnt            ;      //the counter for witch we know how many bits of a command head a tag has received  
reg  [ 5:0]  cmd_cnt             ;      //the counter for witch we know how many bits of a command content a tag has received, except the command head
reg  [ 3:0]  length_down         ;      //a standard by witch a tag will determine whether to receive mask
reg          read_en_ctr         ;      //use to generate a pulse for the signal read_en
reg          sort_err            ;      //parameter error.just for sort cmd
reg          addr_over           ;      //the access is invalid.active high
reg  [15:0]  pointer             ;      //buffer the data of pointer in cmd
reg  [15:0]  length              ;      //buffer the data of length in cmd
reg          receive_flag        ; 
reg          CRC16_err           ;      //crc16 checking is error.active high
reg          cmd_err             ;      //indicate the cmd is not match with the protocol 
reg  [ 6:0]  mask_end            ;
reg          receive_flag_delay  ;
reg          target_query        ;
reg  [ 3:0]  target_sort         ;
reg          data_end_delay1     ;
reg          data_end_delay2     ;
reg          data_end_delay3     ;
reg          mask_en             ; 
reg  [69:0]  data_shifter        ;     //buffer the data when receive the tpp_data
reg  [ 5:0]  ptr_mem             ;     //pointer the membank
reg  [15:0]  ptr_word            ;     //the word length in cmd
reg          receive_sign        ;
reg          set_flag            ;
reg          invert              ;
reg          inventory_flag      ;
reg          inventory_flag1     ;
reg          inventory_flag2     ;
reg          S0                  ;
reg          S1                  ;
reg          S2                  ;
reg          S3                  ;
reg          SL                  ;
reg          SL_match            ;
reg          flag_match          ;

//WIRE(s)
wire         rst_del             ;
//wire         rst_err             ;
wire         data_end_pedge      ;
wire         mask_match_en       ;     
wire         crc_xor0            ;    //bits of crc16
wire         crc_xor1            ;
wire         crc_xor2            ;
wire         crc_xor3            ;
wire         crc_xor4            ;
wire         crc_xor5            ;
wire         para_clk            ;  
wire         In_OP_SE            ;    //a signal indicate the tag is in open or secured state
wire         killing1_match      ;
wire         killing2_match      ;
wire         locking1_match      ;
wire         locking2_match      ;
wire         reading1_match      ;
wire         reading2_match      ;
wire         writing1_match      ;
wire         writing2_match      ;

// ************************
// MAIN CODE
// ************************

//assign rst_err = rst_n & ~parse_err ;                
assign rst_del = rst_n & ~delimiter        ; 

//cmd_head judge
always @(posedge tpp_clk or negedge rst_del)     
begin: HEAD_CNT
    if(!rst_del)
        head_cnt <= #`UDLY 3'b0            ;
    else if(head_cnt<3'd4)     
        head_cnt <= #`UDLY head_cnt + 1'b1 ;
    else
        head_cnt <= #`UDLY head_cnt        ;
end

always@(negedge tpp_clk or negedge rst_del)
begin: HEAD_FINISH_JUDGE
    if(!rst_del)
        head_finish <= #`UDLY 1'b0         ;
    else if(head_cnt == 3'd1 && cmd_head[1:0] != 2'b10 )
        head_finish <= #`UDLY 1'b1         ;
    else if(head_cnt == 3'd2 && cmd_head [1]== 1'b0)
        head_finish <= #`UDLY 1'b1         ;
    else if(head_cnt == 3'd4 )
        head_finish <= #`UDLY 1'b1         ;
    else
        head_finish <= #`UDLY head_finish  ;
end
   
always@(posedge tpp_clk  or negedge rst_del)
begin: CMD_HEAD_JUDGE
    if(!rst_del)
        cmd_head <= #`UDLY 8'd0                     ;
    else if(head_finish!=1'b1)     
        cmd_head <= #`UDLY {cmd_head[5:0],tpp_data} ;    
    else
        cmd_head <= #`UDLY cmd_head                 ;
end

//Turn on the para-parse when finishing parsing the head of commands
assign para_clk = tpp_clk & head_finish             ;                   

//count the content of cmd,receive a para_clk then plus 1       
always @(negedge para_clk or negedge rst_del)  
begin: CMD_CNT
    if(!rst_del)
        cmd_cnt <= #`UDLY 6'b0                      ;
    else if(cmd_head == `SORT )               
            if(cmd_cnt == 6'd17)
                cmd_cnt <= #`UDLY 6'd0              ;
            else if(receive_sign)
                if(cmd_cnt == 6'd7)
                   cmd_cnt <= #`UDLY 6'd0           ; 
                else
                   cmd_cnt <= #`UDLY cmd_cnt+1'b1   ;
            else
                cmd_cnt <= #`UDLY  cmd_cnt+1'b1     ;      
    else
        cmd_cnt <= #`UDLY cmd_cnt +1'b1             ;                             
end

//data_end judge,whithout CRC!!!
//If the cmd has no crc,we use cmd_end instead of data_end!!!
always @(posedge tpp_clk or negedge rst_del)
begin: DATA_END_JUDGE
    if(!rst_del)
        data_end <= #`UDLY 1'b0                     ;
    else if(head_finish == 1'b1)    
        case(cmd_head)
            `SORT     :
                if(cmd_cnt == 6'd17)
                    data_end <= #`UDLY 1'b1         ;
                else
                    data_end <= #`UDLY data_end     ;
            `QUERY    : 
                if(cmd_cnt == 6'd5)
                    data_end <= #`UDLY 1'b1         ;
                else
                    data_end <= #`UDLY data_end     ; 
            `QUERYREP :
                data_end <= #`UDLY cmd_end          ; 
            `DIVIDE   :
                data_end <= #`UDLY cmd_end          ;
            `DISPERSE :
                data_end <= #`UDLY cmd_end          ;   
            `SHRINK   :
                data_end <= #`UDLY cmd_end          ;
            `ACK      :     
                if(cmd_cnt == 6'd7)                   //it doesn't matter
                    data_end <= #`UDLY 1'b1         ;
                else 
                    data_end <= #`UDLY data_end     ;
            `GET_RN   :
                if(cmd_cnt == 6'd7)
                    data_end <= #`UDLY 1'b1         ;
                else
                    data_end <= #`UDLY data_end     ;
            `REFRESHRN:
                if(cmd_cnt == 6'd7)
                    data_end <= #`UDLY 1'b1         ;
                else
                    data_end <= #`UDLY data_end     ;
            `ACCESS   :
                if(cmd_cnt == 6'd20)
                    data_end <= #`UDLY 1'b1         ;
                else
                    data_end <= #`UDLY data_end     ;                             				      
            `READ     :
            	  if(cmd_cnt == 6'd26)   
            		    data_end <= #`UDLY 1'b1         ;
            	  else
            	    	data_end <= #`UDLY data_end     ;
            `WRITE    :
                if(cmd_cnt == 6'd34)
                    data_end<= #`UDLY 1'b1          ;		
                else
                    data_end <= #`UDLY data_end     ;	
            `ERASE    :
                if(cmd_cnt == 6'd26)
                    data_end <= #`UDLY 1'b1         ;
                else 
                    data_end <= #`UDLY data_end     ;														            	
            `LOCK     :
            	  if(cmd_cnt == 6'd12)
            	    	data_end <= #`UDLY 1'b1         ;
            	  else
            	    	data_end <= #`UDLY data_end     ; 
            `KILL     :
            	  if(cmd_cnt == 6'd7)
            		    data_end <= #`UDLY 1'b1         ;
                else
            	    	data_end <= #`UDLY data_end     ;                  
            default   :
                data_end <= #`UDLY data_end         ;
        endcase  
    else                                     
        data_end <= #`UDLY data_end                 ;     
end

//just for timing requirement!
always @(posedge tpp_clk or negedge rst_del)
begin: DATA_END_DELAY1
    if(!rst_del)
        data_end_delay1 <= #`UDLY 1'b0              ;
    else
        data_end_delay1 <= #`UDLY data_end          ;
end

always @(posedge tpp_clk or negedge rst_del)
begin: DATA_END_DALAY2
    if(!rst_del)
        data_end_delay2 <= #`UDLY 1'b0              ;
    else
        data_end_delay2 <= #`UDLY data_end_delay1   ;
end

always @(posedge tpp_clk or negedge rst_del)
begin: DATA_END_DALAY3
    if(!rst_del)
        data_end_delay3 <= #`UDLY 1'b0              ;
    else
        data_end_delay3 <= #`UDLY data_end_delay2   ;
end

//generate posedge data_end
assign data_end_pedge = ({data_end_delay1,data_end_delay2} == 2'b10)?1'b1:1'b0;

//data receiver
always @(posedge tpp_clk or negedge rst_del)           //shift tpp_data into data_shifter! MSB!
begin: DATA_RECEIVER
    if(!rst_del)
        data_shifter <= #`UDLY 70'd0                                       ;
    else if(head_finish== 1'b1)                        //due to MSB,when sec_com cmd,the high bit is discarded!
        if(cmd_head == `SORT)
            if(data_end==1'b0)
                data_shifter[35:0] <= #`UDLY {data_shifter[33:0],tpp_data} ;
            else
                data_shifter[51:36]<=#`UDLY {data_shifter[49:36],tpp_data} ;
        else if(data_end==1'b0)
            data_shifter[69:0] <= #`UDLY {data_shifter[67:0],tpp_data}     ; 
        else
            data_shifter <= #`UDLY data_shifter                            ;               
    else
        data_shifter <= #`UDLY data_shifter                                ;
end  

//buffer the data of write or erase cmd
always @(data_shifter[31:16] or cmd_head)
begin: DATA_WRITE_ERASE
    if(cmd_head == `WRITE )
        data_buffer = data_shifter[31:16];    
    else if(cmd_head ==`ERASE)                         
        data_buffer = 16'b0              ;
    else
        data_buffer = 16'b0              ;
end

//get the value of membank 
always @(data_shifter[41:30] or data_shifter[53:48] or data_shifter[69:64] or data_shifter[25:20] or cmd_head)
begin: MEMBANK_DATA
    if(cmd_head ==`SORT)
        membank = data_shifter[35:30]   ;
    else if(cmd_head==`READ)
        membank = data_shifter[53:48]   ;
    else if(cmd_head==`WRITE)
        membank = data_shifter[69:64]   ;
    else if(cmd_head==`ERASE)
        membank = data_shifter[53:48]   ;         
    else if(cmd_head ==`LOCK)
        membank = data_shifter[25:20]   ;
    else if(cmd_head ==`ACCESS)
        membank = data_shifter[41:36]   ;
    else
        membank = 6'b0                  ;
end 

//get the value of rule of SORT command      
always @(posedge data_end or negedge rst_n)
begin: RULE_SORT
    if(!rst_n)
	      rule <= #`UDLY 2'b00                     ;
    else if(cmd_head == `SORT)
        rule <= #`UDLY data_shifter[25:24]       ;
    else
        rule <= #`UDLY rule                      ;
end          

//get the value of target of SORT command 
always @(posedge data_end or negedge rst_n)
begin: TARGET_SORT
    if(!rst_n)
	      target_sort <= #`UDLY 4'b0000            ;
    else if(cmd_head == `SORT)
        target_sort <= #`UDLY data_shifter[29:26];
    else
        target_sort <= #`UDLY target_sort        ;
end     

always @(posedge data_end_delay2 or negedge rst_n)
begin: LOCK_ACTION
    if(!rst_n)
	    lock_action <= #`UDLY 2'b00              ;
    else if(cmd_head == `LOCK)
	    lock_action <= #`UDLY data_shifter[17:16];
	else
	    lock_action <= #`UDLY lock_action        ;
end

always @(posedge data_end_delay2 or negedge rst_n)
begin: LOCK_DEPLOY
    if(!rst_n)
	    lock_deploy <= #`UDLY 2'b00              ;
    else if(cmd_head == `LOCK)
	    lock_deploy <= #`UDLY data_shifter[19:18];
	else
	    lock_deploy <= #`UDLY lock_deploy        ;
end

//receive session_val
always @(posedge data_end_delay1 or negedge rst_n)
begin: SESSION_VALUE
    if(!rst_n)
	      session_val <= #`UDLY 2'b00              ;
	else if(cmd_head == `QUERY)
	    if(tag_state == `READY)
          session_val <= #`UDLY data_shifter[9:8];
      else if(session_match)
          session_val <= #`UDLY data_shifter[9:8];
      else
          session_val <= #`UDLY session_val      ;
  else
      session_val <= #`UDLY session_val          ;
end

//Set session_match
always @(posedge data_end_delay1 or negedge rst_n) 
begin: SESSION_MATCH
    if(!rst_n)
        session_match <= #`UDLY 1'b0             ;
    else if(cmd_head == `QUERY)
        if(tag_state == `READY)
            session_match <= #`UDLY 1'b1         ;
        else if(data_shifter[9:8] == session_val)
            session_match <= #`UDLY 1'b1         ;
        else
            session_match <= #`UDLY 1'b0         ;
    else if(cmd_head == `QUERYREP)
        if(data_shifter[1:0] == session_val)
            session_match <= #`UDLY 1'b1         ;
        else
            session_match <= #`UDLY 1'b0         ; 
    else if(cmd_head == `DIVIDE)
        if(data_shifter[1:0] == session_val)
            session_match <= #`UDLY 1'b1         ;
        else
            session_match <= #`UDLY 1'b0         ; 
    else if(cmd_head == `DISPERSE)
        if(data_shifter[1:0] == session_val)
            session_match <= #`UDLY 1'b1         ;
        else
            session_match <= #`UDLY 1'b0         ; 
	  else if(cmd_head == `SHRINK)
        if(data_shifter[1:0] == session_val)
            session_match <= #`UDLY 1'b1         ;
        else
            session_match <= #`UDLY 1'b0         ; 
    else 
        session_match <= #`UDLY session_match    ;
end

//according the rule, set the flag
always @(posedge data_end_delay1 or negedge rst_n)
begin: SET_FLAG
    if(!rst_n)
	      set_flag <= #`UDLY 1'b0                  ;
    else
	      case(rule)
		    2'b00  :
		        if(mask_match)
			          set_flag <= #`UDLY 1'b1          ;
			      else
			          set_flag <= #`UDLY 1'b0          ;
		    2'b01  :
		        if(mask_match)
			          set_flag <= #`UDLY set_flag      ;
			      else
			          set_flag <= #`UDLY 1'b0          ;
        2'b10  :
		        if(mask_match)
			          set_flag <= #`UDLY 1'b1          ;
			      else
			          set_flag <= #`UDLY set_flag      ;
		    2'b11  :
		        if(mask_match)
			          set_flag <= #`UDLY 1'b0          ;
			      else
			          set_flag <= #`UDLY 1'b1          ;
	    	default:
		        set_flag <= #`UDLY set_flag          ;
	    	endcase
end

//invert the inventory flag judge
always@(cmd_head or SL_match or tag_state or parse_err)
begin: INVERT_FLAG
	  if(parse_err == 1'b1)
	      invert <= #`UDLY 1'b0     ;
    else if( cmd_head == `QUERY     && 
	           SL_match == 1'b1       &&
	          (tag_state== `ACKNOWLEDGED||
			       tag_state== `OPENSTATE ||
			       tag_state== `OPENKEY   ||
			       tag_state== `SECURED   ||
			       tag_state== `SECUREDKEY))
        invert <= #`UDLY 1'b1     ;
	  else if((cmd_head == `QUERYREP  ||
	           cmd_head == `DIVIDE    ||
			       cmd_head == `DISPERSE  ||
			       cmd_head == `SHRINK)   &&
			      (tag_state== `ACKNOWLEDGED||
			       tag_state== `OPENSTATE ||
			       tag_state== `OPENKEY   ||
			       tag_state== `SECURED   ||
			       tag_state== `SECUREDKEY))
        invert <= #`UDLY 1'b1     ;
	  else
	      invert <= #`UDLY 1'b0     ;
end

//set the inventory flag or invert the flag according the invert signal
always @(posedge invert or negedge rst_n)
begin: INVENTORY1_FLAG_SET
	  if(!rst_n)
	      inventory_flag1 <= #`UDLY 1'b0     ;
	  else   
	      inventory_flag1 <= #`UDLY ~set_flag;
end

always @(negedge invert or negedge rst_n)
begin: INVENTORY2_FLAG_SET
	  if(!rst_n)
	      inventory_flag2 <= #`UDLY 1'b0     ;
	  else   
	      inventory_flag2 <= #`UDLY set_flag ;
end

always @(invert or inventory_flag1 or inventory_flag2) 
begin: INVENTORY_FLAG_SET
	  if(invert == 1'b1)
	      inventory_flag <= #`UDLY inventory_flag1 ;
	  else
	      inventory_flag <= #`UDLY inventory_flag2 ;
end

//set the inventory or SL flag of the select session
always @(posedge data_end_delay2 or negedge rst_n)
begin: SESSION_SET
    if(!rst_n)
	    begin
	        S0 <= #`UDLY 1'b0      ;
		      S1 <= #`UDLY 1'b0      ;
          S2 <= #`UDLY 1'b0      ;
          S3 <= #`UDLY 1'b0      ;
          SL <= #`UDLY 1'b0      ;
      end
	else 
	    case(target_sort[2:0])
	  	3'b000:
		      begin
			        S0 <= #`UDLY inventory_flag ;
			  	    S1 <= #`UDLY S1             ;
              S2 <= #`UDLY S2             ;
              S3 <= #`UDLY S3             ;
              SL <= #`UDLY SL             ;
			    end
      3'b001:
		      begin
		          S0 <= #`UDLY S0             ;
		          S1 <= #`UDLY inventory_flag ;
              S2 <= #`UDLY S2             ;
              S3 <= #`UDLY S3             ;
              SL <= #`UDLY SL             ;	
          end				
		  3'b010:
		      begin
		          S0 <= #`UDLY S0             ;
		          S1 <= #`UDLY S1             ;
			        S2 <= #`UDLY inventory_flag ;
				      S3 <= #`UDLY S3             ;
              SL <= #`UDLY SL             ;
			    end
      3'b011:
		      begin
		          S0 <= #`UDLY S0             ;
		          S1 <= #`UDLY S1             ;
              S2 <= #`UDLY S2             ;
			        S3 <= #`UDLY inventory_flag ;
				      SL <= #`UDLY SL             ;
			    end
      3'b100:
		      begin
		          S0 <= #`UDLY S0             ;
		          S1 <= #`UDLY S1             ;
              S2 <= #`UDLY S2             ;
              S3 <= #`UDLY S3             ;
			        SL <= #`UDLY inventory_flag ;
			    end
		  default:
		      begin
			        S0 <= #`UDLY S0             ;
		          S1 <= #`UDLY S1             ;
              S2 <= #`UDLY S2             ;
              S3 <= #`UDLY S3             ;
              SL <= #`UDLY SL             ;
			    end
		endcase
end

//set SL_match
always @(condition or SL)
begin: SET_SL_MATCH
	  case(condition)
    2'b00:
	      SL_match = 1'b1    ;
	  2'b01:
		    if(SL == 1'b1)
			      SL_match = 1'b1;
	      else
			      SL_match = 1'b0;
	  2'b10:
		    if(SL == 1'b0)
			      SL_match = 1'b1;
		    else
		        SL_match = 1'b0;		    
	  default:
	    	SL_match = 1'b0    ;
	endcase
end
		
//inventory flag match
always @(target_query or session_val or S0 or S1 or S2 or S3)
begin: INVENTORY_FLAG_MATCH
    case(session_val)
    2'b00:
	      if(S0 == target_query)
            flag_match = 1'b1 ;
		    else
		        flag_match = 1'b0 ;
  	2'b01:
	      if(S1 == target_query)
            flag_match = 1'b1 ;
		    else
		        flag_match = 1'b0 ;
	  2'b10:
	      if(S2 == target_query)
            flag_match = 1'b1 ;
		    else
		        flag_match = 1'b0 ;
	  2'b11:
	      if(S3 == target_query)
            flag_match = 1'b1 ;
		    else
		        flag_match = 1'b0 ;
    default:
            flag_match = 1'b0 ;
    endcase
end

//transfer bits addr to words addr
always@(posedge data_end_delay1 or negedge rst_n)
begin: WORD_LENGTH
    if(!rst_n)
	      ptr_word <= #`UDLY 16'b0                        ;
    else if(cmd_head == `SORT)
        ptr_word <= #`UDLY {4'b0000,data_shifter[23:12]};     
    else if(cmd_head == `ACCESS)
        ptr_word <= #`UDLY {12'b00,data_shifter[35:32]} ;     //sort of access pwd
    else if(cmd_head == `READ || cmd_head == `ERASE)
        ptr_word <= #`UDLY data_shifter[47:32]          ;     //pointer word addr
    else if(cmd_head == `WRITE)
        ptr_word <= #`UDLY data_shifter[63:48]          ;   
    else 
        ptr_word <= #`UDLY ptr_word                     ;
end 

//assign the value of access pwd type
assign acc_pwd = ptr_word[3:0];

always@(posedge data_end_delay1 or negedge rst_n)
begin: POINTER_MEMBANK
    if(!rst_n)
	      ptr_mem <= #`UDLY 6'd0            ;
	  else
        case(membank[5:4])                     //GB_MTP_1k
	      2'b00:
	          ptr_mem <= #`UDLY 6'd00       ;
	      2'b01:
	          ptr_mem <= #`UDLY 6'd08       ;   
        2'b10:
	          ptr_mem <= #`UDLY 6'd25       ;
	      2'b11: 
	          case(membank[3:0])
		        4'b0000:                           //USER_0         //1k only has one UID
		            ptr_mem <= #`UDLY 6'd40   ;
//		        4'b0001:                           //USER_1
//                ptr_mem <= #`UDLY 10'd94   ;                       
//		        4'b0010:                           //USER_2
//		            ptr_mem <= #`UDLY 10'd156  ;
//		        4'b0011:                           //USER_3
//                ptr_mem <= #`UDLY 10'd218  ;
//		        4'b0100:                           //USER_4
//		            ptr_mem <= #`UDLY 10'd280  ;
//		        4'b0101:                           //USER_5
//                ptr_mem <= #`UDLY 10'd342  ;
//		        4'b0110:                           //USER_6
//		            ptr_mem <= #`UDLY 10'd404  ;
//		        4'b0111:                           //USER_7
//                ptr_mem <= #`UDLY 10'd466  ;
//		        4'b1000:                           //USER_8
//		            ptr_mem <= #`UDLY 10'd528  ;
//		        4'b1001:                           //USER_9
//                ptr_mem <= #`UDLY 10'd590  ;
//		        4'b1010:                           //USER_10
//		            ptr_mem <= #`UDLY 10'd652  ;
//		        4'b1011:                           //USER_11
//                ptr_mem <= #`UDLY 10'd714  ;
//		        4'b1100:                           //USER_12
//		            ptr_mem <= #`UDLY 10'd776  ;
//		        4'b1101:                           //USER_13
//                ptr_mem <= #`UDLY 10'd838  ;	
//		        4'b1110:                           //USER_14
//		            ptr_mem <= #`UDLY 10'd900  ;
//		        4'b1111:                           //USER_15
//                ptr_mem <= #`UDLY 10'd962  ;	
            default:
                ptr_mem <= #`UDLY ptr_mem  ;
            endcase
        default:
            ptr_mem <= #`UDLY ptr_mem      ;
        endcase		
end 

//transfer pointer and length calculating in bit into pointer and length calculating in word
always@(ptr_mem or ptr_word or cmd_head or acc_pwd)
begin: POINTER_CACULATOR
    if(cmd_head != `ACCESS)  
       pointer = ptr_mem + ptr_word        ;
    else   
        case(acc_pwd[3:2])
        2'b00:
			      case(acc_pwd[1:0])
			      2'b00  :
                pointer = 16'h001A         ;
		        2'b01  :
				        pointer = 16'h0019         ;
			      2'b10  :
			         	pointer = 16'h001C         ;
			      2'b11  :
				        pointer = 16'h001B         ;	
            default:
                pointer = 16'h0000         ;	
            endcase						
        2'b01:
			      case(acc_pwd[1:0])
			      2'b10  :
                pointer = ptr_mem + 2'b01  ;
		        2'b11  :
				        pointer = ptr_mem          ;
			      default:
                pointer = 16'h0000         ;
			      endcase
        2'b10:
	          case(acc_pwd[1:0])
			      2'b00  :
                pointer = ptr_mem + 2'b11  ;
			      2'b01  :
				        pointer = ptr_mem + 2'b10  ;
            default:
                pointer = 16'h0000         ;
			      endcase
        default:
            pointer = 16'h0000             ;            
        endcase                           	                                                         
end
        
always@(posedge data_end or negedge rst_n)
begin: LENGTH_CACULATOR
    if(!rst_n)
	      length <= #`UDLY 16'b0                    ;
    else if(cmd_head==`SORT )
        length <= #`UDLY {12'b0,data_shifter[7:4]};
    else if (cmd_head==`WRITE || cmd_head==`ERASE)
        length <= #`UDLY 16'b1                    ;
    else if(cmd_head==`READ)
        length <= #`UDLY data_shifter[31:16]      ;
    else if(cmd_head ==`ACCESS)
        length <= #`UDLY 16'b1                    ;
    else 
        length <= #`UDLY length                   ;               
end

assign pointer_par = pointer[5:0]                 ;

assign length_par  = length[5:0]                  ;	

//End of operating to EEPROM
//used for judging of addr_over!!!
always @(posedge data_end_delay2 or negedge rst_n)
begin: MASK_END_GENERATOR
    if(!rst_n)
        mask_end <= #`UDLY 7'd0                   ;
    else if(cmd_head==`SORT || cmd_head==`READ || cmd_head==`WRITE || cmd_head==`ERASE) 
        if(length!=16'd0)
            mask_end <= #`UDLY (pointer+length)-1'b1;
        else
            mask_end <= #`UDLY pointer             ; 
    else
        mask_end <= #`UDLY mask_end                ; 
end 
           
//address over judge!           
always @(posedge data_end_delay3 or negedge rst_del)     
begin: ADDR_OVER_JUDGEMENT                      
    if(!rst_del)        
       addr_over <= #`UDLY 1'b0                    ;
    else if(cmd_head==`SORT ||cmd_head==`READ ||cmd_head==`WRITE || cmd_head == `ERASE)
        case(membank[5:4])
        2'b00 :
            if(mask_end > 7'd07)
                addr_over <= #`UDLY 1'b1        ;
            else
                addr_over <= #`UDLY 1'b0        ;
        2'b01 :
            if(mask_end > 7'd24)
                addr_over <= #`UDLY 1'b1        ;
            else
                addr_over <= #`UDLY 1'b0        ;
        2'b10 :
            if(mask_end > 7'd39) 
                addr_over <= #`UDLY 1'b1        ;
            else
                addr_over <= #`UDLY 1'b0        ;
        2'b11 :
			      case(membank[3:0])
		        4'b0000:                           //USER_0
                if(mask_end > 7'd63)                       //need to be revised according to the MTP!
						        addr_over <= #`UDLY 1'b1    ;           //this edition only has one UID
						    else
						        addr_over <= #`UDLY 1'b0    ;
//		        4'b0001:                           //USER_1
//                if(mask_end > 11'd155)
//						        addr_over <= #`UDLY 1'b1    ;
//						    else
//						        addr_over <= #`UDLY 1'b0    ;
//		        4'b0010:                           //USER_2
//                if(mask_end > 11'd217)
//						        addr_over <= #`UDLY 1'b1    ;
//						    else
//						        addr_over <= #`UDLY 1'b0    ;
//		        4'b0011:                           //USER_3
//                if(mask_end > 11'd279)
//						        addr_over <= #`UDLY 1'b1    ;
//						    else
//						        addr_over <= #`UDLY 1'b0    ;
//		        4'b0100:                           //USER_4
//                if(mask_end > 11'd341)
//						        addr_over <= #`UDLY 1'b1    ;
//					    	else 
//						        addr_over <= #`UDLY 1'b0    ;
//		        4'b0101:                           //USER_5
//                if(mask_end > 11'd403)
//						        addr_over <= #`UDLY 1'b1    ;
//						    else
//						        addr_over <= #`UDLY 1'b0    ;
//		        4'b0110:                           //USER_6
//                if(mask_end > 11'd465)
//						        addr_over <= #`UDLY 1'b1    ;
//						    else
//						        addr_over <= #`UDLY 1'b0    ;
//		        4'b0111:                           //USER_7
//                if(mask_end > 11'd527)
//						        addr_over <= #`UDLY 1'b1    ;
//					    	else
//						        addr_over <= #`UDLY 1'b0    ;
//		        4'b1000:                           //USER_8
//                if(mask_end > 11'd589)
//						        addr_over <= #`UDLY 1'b1    ;
//						    else
//						        addr_over <= #`UDLY 1'b0    ;
//		        4'b1001:                           //USER_9
//                if(mask_end > 11'd651)
//						        addr_over <= #`UDLY 1'b1    ;
//						    else
//						        addr_over <= #`UDLY 1'b0    ;
//		        4'b1010:                           //USER_10
//                if(mask_end > 11'd713)
//						        addr_over <= #`UDLY 1'b1    ;
//						    else
//						        addr_over <= #`UDLY 1'b0    ;
//		        4'b1011:                           //USER_11
//                if(mask_end > 11'd775)
//						        addr_over <= #`UDLY 1'b1    ;
//						    else
//						        addr_over <= #`UDLY 1'b0    ;
//		        4'b1100:                           //USER_12
//                if(mask_end > 11'd837)
//						        addr_over <= #`UDLY 1'b1    ;
//						    else
//						        addr_over <= #`UDLY 1'b0    ;
//		        4'b1101:                           //USER_13
//                if(mask_end > 11'd899)
//						        addr_over <= #`UDLY 1'b1    ;
//						    else
//						        addr_over <= #`UDLY 1'b0    ;
//		        4'b1110:                           //USER_14
//                if(mask_end > 11'd961)
//						        addr_over <= #`UDLY 1'b1    ;
//						    else
//						        addr_over <= #`UDLY 1'b0    ;
//		        4'b1111:                           //USER_15
//                if(mask_end > 11'd1023)
//						        addr_over <= #`UDLY 1'b1    ;
//						    else
//						        addr_over <= #`UDLY 1'b0    ;
            default:
                addr_over <= #`UDLY 1'b1        ;  //revised by pan in 7.31.2013
            endcase
        default:
           addr_over <= #`UDLY 1'b0             ;          
        endcase
    else
        addr_over <= #`UDLY 1'b0                ;
end   

//par_err judge,find the command parameter error
always @(posedge data_end or negedge rst_del)             //detect data_end signal but not dec_done3, for shutting off the unit immediately if there is an error
begin: SORT_ERROR
    if(!rst_del)
        sort_err <= #`UDLY 1'b0                    ;
    else
        case(cmd_head)
        `SORT :                                      
            if(data_shifter[35:34] == 2'b10)          
                sort_err <= #`UDLY 1'b1        ;     //judge whether the sort cmd is correspond with protocol
			    	else if(data_shifter[29:28] == 2'b10||
				            data_shifter[29:28] == 2'b11)
				        sort_err <= #`UDLY 1'b1        ;
				    else if(data_shifter[29:28] == 2'b01&&
				            data_shifter[27:26] != 2'b00)
					      sort_err <= #`UDLY 1'b1        ;
            else if(data_shifter[11: 8] != 4'b0000)    
                sort_err <= #`UDLY 1'b1        ;
            else if(data_shifter[ 3: 0] != 4'b0000) 
                sort_err <= #`UDLY 1'b1        ;                   
            else
                sort_err <= #`UDLY 1'b0        ;                                                          
        default :
            sort_err <= #`UDLY 1'b0            ;
        endcase
end

//the evaluation of cmd_err
always @(posedge dec_done3 or negedge rst_del )        
begin: CMD_ERR_JUDGE
    if(!rst_del)                                                                             
        cmd_err <= #`UDLY 1'b0                        ;
    else 
        case(cmd_head) 	
            `QUERY    :
                if(data_shifter[11:10] == 2'b11)     
                    cmd_err <= #`UDLY 1'b1            ; 
                else if(data_shifter[5:4] == 2'b10||
				                data_shifter[5:4] == 2'b11)
                    cmd_err <= #`UDLY 1'b1            ;						
                else if(CRC16_err)
                    cmd_err <= #`UDLY 1'b1            ;
                else
                    cmd_err <= #`UDLY 1'b0            ;
            `DIVIDE   :       
                if(data_shifter[3] == 1'b1)
                    cmd_err <= #`UDLY 1'b1            ;             
                else 
                    cmd_err<= #`UDLY 1'b0             ;   
            `READ     :                 
			       // if(data_shifter[53:52] == 2'b10)
                    // cmd_err <= #`UDLY 1'b1; 
				     // else if(data_shifter[31:16]== 16'b0)
                    // case(membank[53:52])
                        // 2'b00,
						 // 2'b11:
						 // 2'b01:    
					   // endcase	    
                if(data_shifter[31:16]== 16'b0|| 
				           data_shifter[49:48]== 2'b10)   //if the length of read cmd is 0,then bsc err
                    cmd_err <= #`UDLY 1'b1            ;                 
                else if(CRC16_err)
                    cmd_err <= #`UDLY 1'b1            ;
                else
                    cmd_err <= #`UDLY 1'b0            ;  
            `ACCESS   :
                if(CRC16_err)		
                    cmd_err <= #`UDLY 1'b1            ;
                else					
			             case(data_shifter[35:34])
				           2'b00:
					              cmd_err <= #`UDLY 1'b0        ;
					         2'b01:
					             case(data_shifter[33:32])
						           2'b00,
							         2'b01:
							             cmd_err <= #`UDLY 1'b1     ;
						           2'b10,
							         2'b11:
							             cmd_err <= #`UDLY 1'b0     ;
							         default:
							             cmd_err <= #`UDLY 1'b0     ;
						           endcase
					         2'b10:
					             case(data_shifter[33:32])
						           2'b00,
							         2'b01:
							             cmd_err <= #`UDLY 1'b0     ;
							         2'b10,
							         2'b11:
							             cmd_err <= #`UDLY 1'b1     ;
							         default:
							             cmd_err <= #`UDLY 1'b0     ;
						           endcase					
			             2'b11:
					             cmd_err <= #`UDLY 1'b1         ;
			             default:
					             cmd_err <= #`UDLY 1'b0         ;
			             endcase
            `WRITE    :
                if(data_shifter[69:68] == 2'b00|| 
				           data_shifter[47:32] != 16'd1)
                    cmd_err <= #`UDLY 1'b1            ;
                else if(CRC16_err)
                        cmd_err <= #`UDLY 1'b1        ;
                     else
                        cmd_err <= #`UDLY 1'b0        ;            
            `ERASE    :                                  
                if(data_shifter[53:52] == 2'b00|| 
				           data_shifter[31:16] != 16'd1)
                    cmd_err <= #`UDLY 1'b1            ;
                 else if(CRC16_err)
                        cmd_err <= #`UDLY 1'b1        ;
                      else
                        cmd_err <= #`UDLY 1'b0        ;     
            `LOCK     :
			          if(data_shifter[19:18] == 2'b10|| 
				           data_shifter[19:18] == 2'b11)
                    cmd_err <= #`UDLY 1'b1            ;
				        else if(data_shifter[19:18] == 2'b01&& 
				                data_shifter[17:16] == 2'b00)
                    cmd_err <= #`UDLY 1'b1            ;
				        else if(CRC16_err)
				            cmd_err <= #`UDLY 1'b1            ;
				        else
				            cmd_err <= #`UDLY 1'b0            ;		
            `SORT     ,                                       
            `GET_RN   ,                              
            `REFRESHRN,                                
            `KILL     :                  
                if(CRC16_err)
                    cmd_err <= #`UDLY 1'b1            ;
                else
                    cmd_err <= #`UDLY 1'b0            ;
            default   :
                cmd_err <= #`UDLY 1'b0                ;
        endcase   
end  

//assign the value of parse error
assign parse_err = cmd_err | sort_err                 ;  
                 
//use dec_done6 signal as parse_done
assign parse_done = dec_done6                         ;  //!!!!!!!!!revised

//mask matching one by one while length_down minus!
always @(negedge tpp_clk  or negedge rst_del)     
begin: LENGTH_DOWN_GENERATOR
    if(!rst_del)
        length_down <= #`UDLY 4'd0                     ;
		else if(cmd_head == `SORT)
		    if((!receive_sign)&&(cmd_cnt == 6'd17))
			     	length_down <= #`UDLY data_shifter[7:4]    ;
		    else if((receive_sign)&&(cmd_cnt == 6'd7))
				    length_down <= #`UDLY length_down - 1'b1   ;
			  else
			    	length_down <= #`UDLY length_down          ;  
		    else
			      length_down <= #`UDLY length_down          ;						
end

//indicate whether to receive the mask!
always @(length_down)
begin: RECEIVE_SIGN
    if(length_down!=0)
        receive_sign = 1'b1 ;
    else
        receive_sign = 1'b0 ;
end 

always @(posedge tpp_clk or negedge rst_del)
begin: RECEIVE_FLAG
    if(!rst_del)
        receive_flag <= #`UDLY 1'b0               ;
    else if(receive_sign && cmd_cnt == 6'd7)
        receive_flag <= #`UDLY ~receive_flag      ;
    else
        receive_flag <= #`UDLY receive_flag       ;
end

always @(negedge tpp_clk or negedge rst_del)
begin: RECEIVE_FLAG_DELAY
    if(!rst_del)
        receive_flag_delay <= #`UDLY 1'b0         ;
    else 
        receive_flag_delay <= #`UDLY receive_flag ;
end

//assign the value of mask match enable signal
assign mask_match_en = (receive_flag ^ receive_flag_delay);

//IE module requst,tell IE module coming is an operating of EEPROM!
always @(posedge tpp_clk or negedge rst_n)    
begin: PAR_IEREG_CONTROL
    if(!rst_n)                                                           
        parse_iereq <= #`UDLY 1'b0                ;
    else if((cmd_head == `SORT && receive_sign)|| cmd_head == `ACCESS)
        if((data_end_pedge == 1'b1) && (parse_err != 1'b1))
            parse_iereq <= #`UDLY 1'b1            ;
        else
            parse_iereq <= #`UDLY 1'b0            ;    
    else
        parse_iereq <= #`UDLY 1'b0                ;
end

always @(posedge DOUB_BLF  or negedge rst_del)                     
begin: READ_EN_CONTROL
    if(!rst_del)
        read_en_ctr <= #`UDLY 1'b0    ;             
    else if(cmd_head== `SORT && receive_sign)
        if((cmd_cnt == 6'd7) && (addr_over == 1'b0)) 
            read_en_ctr <= #`UDLY 1'b1;
        else
            read_en_ctr <= #`UDLY 1'b0;
    else if(cmd_head== `ACCESS )
        if((cmd_cnt == 6'd24) && (addr_over == 1'b0)) 
            read_en_ctr <= #`UDLY 1'b1;
        else
            read_en_ctr <= #`UDLY 1'b0;
    else
        read_en_ctr <= #`UDLY 1'b0    ;   
end

always @(posedge DOUB_BLF or negedge rst_del)                     
begin: READ_EN_GENERATOR
    if(!rst_del)
        read_en <= #`UDLY 1'b0        ; 
    else if(read_en_ctr)
        read_en <= #`UDLY 1'b0        ; 
    else if(cmd_head == `SORT && receive_sign)
        if((cmd_cnt == 6'd7) && (addr_over == 1'b0)) 
            read_en <= #`UDLY 1'b1    ;
        else
            read_en <= #`UDLY 1'b0    ;
    else if(cmd_head  == `ACCESS && In_OP_SE)
        if((cmd_cnt == 6'd24) && (addr_over == 1'b0)) 
            read_en <= #`UDLY 1'b1    ;
        else
            read_en <= #`UDLY 1'b0    ;       
    else
        read_en <= #`UDLY 1'b0        ;
end

always @(posedge tpp_clk or negedge rst_n)
begin: MASK_EN_GENERATOR
    if(!rst_n)
        mask_en <=# `UDLY 1'b0        ;                         
    else if(cmd_head == `SORT || cmd_head == `ACCESS)
        if(cmd_cnt==7'd14)
            mask_en <= #`UDLY 1'b1    ;
        else
            mask_en <= #`UDLY 1'b0    ; 
    else
            mask_en <=# `UDLY mask_en ;
end

//the result of mask matching!
always @(negedge mask_match_en or negedge rst_n or posedge mask_en)
begin: MASK_MATCH_EVAL                
    if(!rst_n)	      
        mask_match <= #`UDLY 1'b0      ;      
    else if(mask_en == 1'b1)
        mask_match <= #`UDLY 1'b1      ; 
    else if(cmd_head == `SORT && data_shifter[49:36] != mtp_data)
        mask_match <= #`UDLY 1'b0      ;        
    else
        mask_match <= #`UDLY mask_match;		    				
end

//if tag is in open or secured state, then pull In_OP_SE to high
assign In_OP_SE = (tag_state == `OPENSTATE|| 
	                 tag_state == `SECURED  || 
			             tag_state == `OPENKEY  || 
			             tag_state == `SECUREDKEY);

//indicate the pwd is first 16 bits kill pwd
assign killing1_match = (ptr_word[3:0] == 4'b0000)?1'b1:1'b0;
//indicate the pwd is second 16 bits kill pwd
assign killing2_match = (ptr_word[3:0] == 4'b0001)?1'b1:1'b0;
//indicate the pwd is first 16 bits lock pwd			  
assign locking1_match = (ptr_word[3:0] == 4'b0010)?1'b1:1'b0;
//indicate the pwd is second 16 bits lock pwd
assign locking2_match = (ptr_word[3:0] == 4'b0011)?1'b1:1'b0;
//indicate the pwd is first 16 bits read pwd
assign reading1_match = (ptr_word[3:0] == 4'b0110)?1'b1:1'b0;
//indicate the pwd is second 16 bits read pwd
assign reading2_match = (ptr_word[3:0] == 4'b0111)?1'b1:1'b0;
//indicate the pwd is first 16 bits write pwd
assign writing1_match = (ptr_word[3:0] == 4'b1000)?1'b1:1'b0;
//indicate the pwd is second 16 bits write pwd
assign writing2_match = (ptr_word[3:0] == 4'b1001)?1'b1:1'b0;
				  
//define a function to help judge kill/lock/read/write pwd match
function        pwd_match      ;
    input       In_OP_SE_f     ;
    input       pwd1_match     ;
    input       pwd2_match     ;
    input[ 7:0] cmd_head_f     ;
    input       ptr_word_f     ;
    input[15:0] data_shifter_f ; 
  	input[15:0] mtp_data_f     ;
  	input[15:0] rn16_f         ;
begin
    if(In_OP_SE_f)
	      if(pwd1_match != 1'b1|| 
		       pwd2_match != 1'b1)
		        if(cmd_head_f == `ACCESS)
                if(ptr_word_f)
				            if(data_shifter_f==(mtp_data_f ^ rn16_f))
                        pwd_match = 1'b1       ;
					          else
					              pwd_match = 1'b0       ;
			        	else
                    pwd_match = pwd1_match     ;				
			      else if(cmd_head_f == `GET_RN)
			          pwd_match = pwd1_match         ;
            else
                pwd_match = 1'b0	             ;
		    else 
		        if(cmd_head_f == `ACCESS&& 
			         ptr_word_f == 1'b1   && 
			         data_shifter_f != (mtp_data_f ^ rn16_f))
                pwd_match = 1'b0               ;
            else
                pwd_match = pwd1_match         ;    
    else
        pwd_match = 1'b0                       ;						
end
endfunction

//access kill pwd match
always @(posedge dec_done or negedge rst_n)
begin: KILLPWD1_MATCH 
    if(!rst_n)	      
        killpwd1_match <= #`UDLY 1'b0                         ;    
    else
	      killpwd1_match <= #`UDLY pwd_match(In_OP_SE           ,
		                                       killpwd1_match     ,
										                       killpwd2_match     ,
										                       cmd_head           ,
										                       killing1_match     ,
										                       data_shifter[31:16],
										                       mtp_data           ,
										                       rn16)              ;
end

always @(posedge dec_done or negedge rst_n)
begin: KILLPWD2_MATCH 
    if(!rst_n)	      
        killpwd2_match <= #`UDLY 1'b0                         ;    
    else
	      killpwd2_match <= #`UDLY pwd_match(In_OP_SE           ,
		                                       killpwd2_match     ,
										                       killpwd1_match     ,
										                       cmd_head           ,
										                       killing2_match     ,
										                       data_shifter[31:16],
										                       mtp_data           ,
										                       rn16)              ;
end

assign killpwd_match = killpwd1_match & killpwd2_match        ;

//access kill pwd match
// always @(posedge dec_done or negedge rst_n)
// begin: KILLPWD1_MATCH                 
    // if(!rst_n)	      
        // killpwd1_match <= #`UDLY 1'b0                       ;      
    // else if(tag_state == `OPENSTATE|| 
	        // tag_state == `SECURED  || 
			// tag_state == `OPENKEY  || 
			// tag_state == `SECUREDKEY)
        // if(killpwd1_match != 1'b1||
		   // killpwd2_match != 1'b1)            
            // if(cmd_head == `ACCESS)
                // if(ptr_word[3:0]== 4'b0000)
                    // if(data_shifter[31:16]==(mtp_data ^ rn16))
                        // killpwd1_match <= #`UDLY 1'b1       ;
                    // else 
                        // killpwd1_match <= #`UDLY 1'b0       ;
                // else 
                    // killpwd1_match <= #`UDLY killpwd1_match ;
            // else if(cmd_head == `GET_RN)
                // killpwd1_match <= #`UDLY killpwd1_match     ;
            // else 
                // killpwd1_match <= #`UDLY 1'b0               ;
        // else                                                    //interrogator can deliver access cmd in a row, and the last two cmds are valid
            // if(cmd_head == `ACCESS    && 
			   // ptr_word[3:0]== 4'b0000&& 
			   // data_shifter[31:16] != (mtp_data ^ rn16))
                // killpwd1_match <= #`UDLY 1'b0               ;
            // else
                // killpwd1_match <= #`UDLY killpwd1_match     ;    
    // else
        // killpwd1_match <= #`UDLY 1'b0                       ;
// end

// always @(posedge dec_done or negedge rst_n)
// begin: KILLPWD2_MATCH                 
    // if(!rst_n)	      
        // killpwd2_match <= #`UDLY 1'b0                       ;      
    // else if(tag_state == `OPENSTATE|| 
	        // tag_state == `SECURED  || 
			// tag_state == `OPENKEY  || 
			// tag_state == `SECUREDKEY)
        // if(killpwd1_match != 1'b1|| 
		   // killpwd2_match != 1'b1)
            // if(cmd_head == `ACCESS)
                // if(ptr_word[3:0] == 4'b0001)
                    // if(data_shifter[31:16]==(mtp_data ^ rn16))
                        // killpwd2_match <= #`UDLY 1'b1       ;
                    // else
                        // killpwd2_match <= #`UDLY 1'b0       ;
                // else 
                    // killpwd2_match <= #`UDLY killpwd2_match ;
            // else if(cmd_head == `GET_RN)
                // killpwd2_match <= #`UDLY killpwd2_match     ;
            // else 
                // killpwd2_match <= #`UDLY 1'b0               ;
        // else
            // if(cmd_head == `ACCESS     && 
			   // ptr_word[3:0] == 4'b0001&& 
			   // mtp_data != (data_shifter[31:16] ^ rn16))
                // killpwd2_match <= #`UDLY 1'b0               ;
            // else
                // killpwd2_match <= #`UDLY killpwd2_match     ;     
    // else
        // killpwd2_match <= #`UDLY 1'b0                       ;
// end

//access lock pwd match
always @(posedge dec_done or negedge rst_n)
begin: LOCKPWD1_MATCH 
    if(!rst_n)	      
        lockpwd1_match <= #`UDLY 1'b0                         ;    
    else
	      lockpwd1_match <= #`UDLY pwd_match(In_OP_SE           ,
		                                       lockpwd1_match     ,
										                       lockpwd2_match     ,
										                       cmd_head           ,
										                       locking1_match     ,
										                       data_shifter[31:16],
										                       mtp_data           ,
										                       rn16)              ;
end

always @(posedge dec_done or negedge rst_n)
begin: LOCKPWD2_MATCH 
    if(!rst_n)	      
        lockpwd2_match <= #`UDLY 1'b0                         ;    
    else
	      lockpwd2_match <= #`UDLY pwd_match(In_OP_SE           ,
		                                       lockpwd2_match     ,
										                       lockpwd1_match     ,
										                       cmd_head           ,
										                       locking2_match     ,
										                       data_shifter[31:16],
										                       mtp_data           ,
									                     	   rn16)              ;
end

assign lockpwd_match = lockpwd1_match & lockpwd2_match        ;

//access lock pwd match
// always @(posedge dec_done or negedge rst_n)
// begin: LOCKPWD1_MATCH                 
    // if(!rst_n)	      
        // lockpwd1_match <= #`UDLY 1'b0                       ;      
    // else if(tag_state == `OPENSTATE|| 
	        // tag_state == `SECURED  || 
			// tag_state == `OPENKEY  || 
			// tag_state == `SECUREDKEY)
        // if(lockpwd1_match != 1'b1||
		   // lockpwd2_match != 1'b1)
            // if(cmd_head == `ACCESS)
                // if(ptr_word[3:0] == 4'b0010)
                    // if(data_shifter[31:16]==(mtp_data ^ rn16))
                        // lockpwd1_match <= #`UDLY 1'b1       ;
                    // else
                        // lockpwd1_match <= #`UDLY 1'b0       ;
                // else 
                    // lockpwd1_match <= #`UDLY lockpwd1_match ;
            // else if(cmd_head == `GET_RN)
                // lockpwd1_match <= #`UDLY lockpwd1_match     ;
            // else 
                // lockpwd1_match <= #`UDLY 1'b0               ;
        // else
            // if(cmd_head == `ACCESS    && 
			  // ptr_word[3:0] == 4'b0010&& 
			  // data_shifter[31:16] != (mtp_data ^ rn16))
               // lockpwd1_match <= #`UDLY 1'b0                ;
            // else
               // lockpwd1_match <= #`UDLY lockpwd1_match      ;    
    // else
        // lockpwd1_match <= #`UDLY 1'b0                       ;
// end
            
// always @(posedge dec_done or negedge rst_n)
// begin: LOCKPWD2_MATCH                
    // if(!rst_n)	      
        // lockpwd2_match <= #`UDLY 1'b0                       ;      
    // else if(tag_state == `OPENSTATE|| 
	        // tag_state == `SECURED  || 
			// tag_state == `OPENKEY  || 
			// tag_state == `SECUREDKEY)
        // if(lockpwd1_match != 1'b1||
		   // lockpwd2_match != 1'b1)
            // if(cmd_head == `ACCESS)
                // if(ptr_word[3:0] == 4'b0011)
                    // if( data_shifter[31:16]==(mtp_data ^ rn16))
                        // lockpwd2_match <= #`UDLY 1'b1       ;
                    // else
                        // lockpwd2_match <= #`UDLY 1'b0       ;
                // else 
                    // lockpwd2_match <= #`UDLY lockpwd2_match ;
            // else if(cmd_head == `GET_RN)
                // lockpwd2_match <= #`UDLY lockpwd2_match     ;
            // else 
                // lockpwd2_match <= #`UDLY 1'b0               ;
        // else
            // if(cmd_head == `ACCESS     && 
			   // ptr_word[3:0] == 4'b0011&& 
			   // data_shifter[31:16] != (mtp_data ^ rn16))
                // lockpwd2_match <= #`UDLY 1'b0               ;
            // else
                // lockpwd2_match <= #`UDLY lockpwd2_match     ;
    // else
        // lockpwd2_match <= #`UDLY 1'b0                       ;
// end

//access read pwd match
always @(posedge dec_done or negedge rst_n)
begin: RD_PWD1_MATCH 
    if(!rst_n)	      
        rd_pwd1_match <= #`UDLY 1'b0                         ;    
    else
	      rd_pwd1_match <= #`UDLY pwd_match(In_OP_SE           ,
		                                      rd_pwd1_match      ,
										                      rd_pwd2_match      ,
										                      cmd_head           ,
										                      reading1_match     ,
										                      data_shifter[31:16],
									                    	  mtp_data           ,
									                    	  rn16)              ;
end

always @(posedge dec_done or negedge rst_n)
begin: RD_PWD2_MATCH 
    if(!rst_n)	      
        rd_pwd2_match <= #`UDLY 1'b0                         ;    
    else
	      rd_pwd2_match <= #`UDLY pwd_match(In_OP_SE           ,
		                                      rd_pwd2_match      ,
										                      rd_pwd1_match      ,
									                     	  cmd_head           ,
										                      reading2_match     ,
										                      data_shifter[31:16],
									                    	  mtp_data           ,
									                    	  rn16)              ;
end

assign rd_pwd_match = (read_pwd_status==1'b0)?1'b1:(rd_pwd1_match & rd_pwd2_match)    ;

//access read pwd match
// always @(posedge dec_done or negedge rst_n)
// begin: RD_PWD1_MATCH                
    // if(!rst_n)	      
        // rd_pwd1_match <= #`UDLY 1'b0                        ;      
    // else if(tag_state == `OPENSTATE|| 
	        // tag_state == `SECURED  || 
			// tag_state == `OPENKEY  || 
			// tag_state == `SECUREDKEY)
        // if(rd_pwd1_match != 1'b1||
		   // rd_pwd2_match != 1'b1)
            // if(cmd_head == `ACCESS)
                // if(ptr_word[3:0] == 4'b0110)
                    // if(data_shifter[31:16]==(mtp_data ^ rn16))
                        // rd_pwd1_match <= #`UDLY 1'b1        ;
                    // else
                        // rd_pwd1_match <= #`UDLY 1'b0        ;
                // else 
                    // rd_pwd1_match <= #`UDLY rd_pwd1_match   ;
            // else if(cmd_head == `GET_RN)
                // rd_pwd1_match <= #`UDLY rd_pwd1_match       ;
            // else 
                // rd_pwd1_match <= #`UDLY 1'b0                ;
        // else
            // if(cmd_head == `ACCESS     && 
			   // ptr_word[3:0] == 4'b0110&& 
			   // data_shifter[31:16] != (mtp_data ^ rn16))
               // rd_pwd1_match <= #`UDLY 1'b0                 ;
            // else
               // rd_pwd1_match <= #`UDLY rd_pwd1_match;    
    // else
        // rd_pwd1_match <= #`UDLY 1'b0                        ;
// end
               
// always @(posedge dec_done or negedge rst_n)
// begin: RD_PWD2_MATCH                
    // if(!rst_n)	      
        // rd_pwd2_match <= #`UDLY 1'b0                        ;      
    // else if(tag_state == `OPENSTATE|| 
	        // tag_state == `SECURED  || 
			// tag_state == `OPENKEY  || 
			// tag_state == `SECUREDKEY)
        // if(rd_pwd1_match != 1'b1||
		   // rd_pwd2_match != 1'b1)
            // if(cmd_head == `ACCESS)
                // if(ptr_word[3:0] == 4'b0111)
                    // if( data_shifter[31:16]==(mtp_data ^ rn16))
                        // rd_pwd2_match <= #`UDLY 1'b1        ;
                    // else
                        // rd_pwd2_match <= #`UDLY 1'b0        ;
                // else 
                    // rd_pwd2_match <= #`UDLY rd_pwd2_match   ;
            // else if(cmd_head == `GET_RN)
                // rd_pwd2_match <= #`UDLY rd_pwd2_match       ;
            // else 
                // rd_pwd2_match <= #`UDLY 1'b0                ;
        // else
            // if(cmd_head == `ACCESS     && 
			   // ptr_word[3:0] == 4'b0111&& 
			   // data_shifter[31:16] != (mtp_data ^ rn16))
                // rd_pwd2_match <= #`UDLY 1'b0                ;
            // else
                // rd_pwd2_match <= #`UDLY rd_pwd2_match       ;
     
    // else
        // rd_pwd2_match <= #`UDLY 1'b0                        ;
// end

//access write pwd match
always @(posedge dec_done or negedge rst_n)
begin: WR_PWD1_MATCH 
    if(!rst_n)	      
        wr_pwd1_match <= #`UDLY 1'b0                         ;    
    else
	      wr_pwd1_match <= #`UDLY pwd_match(In_OP_SE           ,
		                                      wr_pwd1_match      ,
										                      wr_pwd2_match      ,
								                    		  cmd_head           ,
									                    	  writing1_match     ,
										                      data_shifter[31:16],
									                    	  mtp_data           ,
									                     	  rn16)              ;
end

always @(posedge dec_done or negedge rst_n)
begin: WR_PWD2_MATCH 
    if(!rst_n)	      
        wr_pwd2_match <= #`UDLY 1'b0                         ;    
    else
	      wr_pwd2_match <= #`UDLY pwd_match(In_OP_SE           ,
		                                      wr_pwd2_match      ,
									                    	  wr_pwd1_match      ,
								                    		  cmd_head           ,
									                    	  writing2_match     ,
								                    		  data_shifter[31:16],
								                     		  mtp_data           ,
									                     	  rn16)              ;
end

assign wr_pwd_match = (write_pwd_status==1'b0)?1'b1:(wr_pwd1_match & wr_pwd2_match)   ;

// always @(posedge dec_done or negedge rst_n)
// begin: WR_PWD1_MATCH              
    // if(!rst_n)	      
        // wr_pwd1_match <= #`UDLY 1'b0                        ;      
    // else if(tag_state == `OPENSTATE|| 
	        // tag_state == `SECURED  || 
			// tag_state == `OPENKEY  || 
			// tag_state == `SECUREDKEY)
        // if(wr_pwd1_match != 1'b1|| 
		   // wr_pwd2_match != 1'b1)
            // if(cmd_head == `ACCESS)
                // if(ptr_word[3:0] == 4'b1000)
                    // if(data_shifter[31:16]==(mtp_data ^ rn16))
                        // wr_pwd1_match <= #`UDLY 1'b1        ;
                    // else
                        // wr_pwd1_match <= #`UDLY 1'b0        ;
                // else 
                    // wr_pwd1_match <= #`UDLY wr_pwd1_match   ;
            // else if(cmd_head == `GET_RN)
                // wr_pwd1_match <= #`UDLY wr_pwd1_match       ;
            // else 
                // wr_pwd1_match <= #`UDLY 1'b0                ;
        // else
            // if(cmd_head == `ACCESS     && 
			   // ptr_word[3:0] == 4'b1000&& 
			   // data_shifter[31:16] != (mtp_data ^ rn16))
               // wr_pwd1_match <= #`UDLY 1'b0                 ;
            // else
               // wr_pwd1_match <= #`UDLY wr_pwd1_match        ;    
    // else
        // wr_pwd1_match <= #`UDLY 1'b0                        ;
// end
            
// always @(posedge dec_done or negedge rst_n)
// begin: WR_PWD2_MATCH                 
    // if(!rst_n)	      
        // wr_pwd2_match <= #`UDLY 1'b0                        ;      
    // else if(tag_state == `OPENSTATE|| 
	        // tag_state == `SECURED  || 
			// tag_state == `OPENKEY  || 
			// tag_state == `SECUREDKEY)
        // if(wr_pwd1_match != 1'b1|| 
		   // wr_pwd2_match != 1'b1)
            // if(cmd_head == `ACCESS)
                // if(ptr_word[3:0] == 4'b1001)
                    // if( data_shifter[31:16]==(mtp_data ^ rn16))
                        // wr_pwd2_match <= #`UDLY 1'b1        ;
                    // else
                        // wr_pwd2_match <= #`UDLY 1'b0        ;
                // else 
                    // wr_pwd2_match <= #`UDLY wr_pwd2_match   ;
            // else if(cmd_head == `GET_RN)
                // wr_pwd2_match <= #`UDLY wr_pwd2_match       ;
            // else 
                // wr_pwd2_match <= #`UDLY 1'b0                ;
        // else
            // if(cmd_head == `ACCESS     && 
			   // ptr_word[3:0] == 4'b1001&& 
			   // data_shifter[31:16]!=(mtp_data ^ rn16))
                // wr_pwd2_match <= #`UDLY 1'b0                ;
            // else
                // wr_pwd2_match <= #`UDLY wr_pwd2_match       ;
     
    // else
        // wr_pwd2_match <= #`UDLY 1'b0                        ;
// end

always @(posedge data_end_delay1 or negedge rst_n)     
begin: DR_RECEIVER
    if(!rst_n)
        DR <= #`UDLY 4'b0                   ;
    else if(cmd_head == `QUERY) 
        DR <= #`UDLY data_shifter[5:2]      ;
    else
        DR <= #`UDLY DR                     ;
end

//parameter receiver
always@(posedge data_end_delay1 or negedge rst_n)     
begin: CONDITION_RECEIVER
    if(!rst_n)
        condition <= #`UDLY 2'b0                ;
    else if(cmd_head == `QUERY)
        condition <= #`UDLY data_shifter[11:10] ;
    else
        condition <= #`UDLY condition           ;        
end 

always@(posedge data_end_delay1 or negedge rst_n)     
begin: TARGET_QUERY_RECEIVER
    if(!rst_n)
        target_query <= #`UDLY 1'b0             ;
    else if(cmd_head == `QUERY)
        target_query <= #`UDLY data_shifter[7]  ;
    else
        target_query <= #`UDLY target_query     ;             
end 

always@(posedge data_end_delay1 or negedge rst_n)     
begin: TREXT_RECEIVER
    if(!rst_n)
        trext <= #`UDLY 1'b0                ;
    else if(cmd_head == `QUERY)
        trext <= #`UDLY data_shifter[6]     ;
    else
        trext <= #`UDLY trext               ;
end 

//a sign given to div decide when to calculate the divide coefficient!
always @(posedge tpp_clk or negedge rst_n)
begin: SET_M_GENERATOR
    if(!rst_n)
        set_m <= #`UDLY 1'b0                ;
    else if((cmd_head == `QUERY) && (cmd_cnt==6'd7))
        set_m <= #`UDLY 1'b1                ;
    else
        set_m <= #`UDLY 1'b0                ;
end

always@(posedge data_end_delay1 or negedge rst_n)          
begin: M_RECEIVER
    if(!rst_n)
        M <= #`UDLY 2'b00                   ;
    else if(cmd_head==`QUERY)
        M <= #`UDLY data_shifter[1:0]       ;
    else
        M <= #`UDLY M                       ;
end

always @(posedge dec_done or negedge rst_n)
begin: DIVIDE_POSITION
    if(!rst_n)
        divide_position <= #`UDLY 1'b0            ;
    else if(cmd_head == `DIVIDE)
        divide_position <= #`UDLY data_shifter[2] ;
    else 
        divide_position <= #`UDLY divide_position ;
end

always @(posedge dec_done or negedge rst_del)      
begin: RN1_UPDATE
    if(!rst_del)
        rn1_update <= #`UDLY 1'b0   ;
    else if(cmd_head == `DIVIDE || 
		    cmd_head == `DISPERSE) 
        rn1_update <= 1'b1          ;
    else
        rn1_update <= #`UDLY 1'b0   ;
end

//rn_match judging!
always @(negedge rst_del or posedge dec_done3)        
begin: RN_MATCH_JUDGE
    if(!rst_del)                                       
        rn_match <= #`UDLY 1'b0;
    else if(cmd_head == `ACK      || 
	          cmd_head == `GET_RN   || 
			      cmd_head == `REFRESHRN|| 
			      cmd_head == `ACCESS   || 
		      	cmd_head == `READ     || 
		      	cmd_head == `WRITE    ||
			      cmd_head == `ERASE    || 
			      cmd_head == `LOCK     || 
			      cmd_head == `KILL)      
        if({handle[15:5],crc5_back} == data_shifter[15:0])
            rn_match <= #`UDLY 1'b1   ;
        else
            rn_match <=  #`UDLY 1'b0  ;
    else
        rn_match <=  #`UDLY 1'b0      ;                                                        
end

//cmd_end to indicate the end of a command,module DECODER output a dec_done when receive this signal!
always @(posedge tpp_clk  or negedge rst_del)
begin: CMD_END_JUDGE
    if(!rst_del)
        cmd_end <= #`UDLY 1'b0                ;
    else if(head_finish== 1'b1)    	
        case(cmd_head)            
            `SORT     :
                if(cmd_cnt == 7'd7 && data_end == 1'b1 && length_down == 4'b0)
                    cmd_end <= #`UDLY 1'b1    ;
                else
                    cmd_end <= #`UDLY cmd_end ;
            `QUERY    : 
                if(cmd_cnt == 7'd13)
                    cmd_end <= #`UDLY 1'b1    ;
                else
                    cmd_end <= #`UDLY cmd_end ;
            `DIVIDE   :
                if(cmd_cnt == 7'd1)
                    cmd_end <= #`UDLY 1'b1    ;
                else
                    cmd_end <= #`UDLY 1'b0    ;
            `QUERYREP :
                if(head_finish)
                    cmd_end <= #`UDLY 1'b1    ;
                else
                    cmd_end <= #`UDLY cmd_end ;
            `DISPERSE :
                if(head_finish)
                    cmd_end <= #`UDLY 1'b1    ;
                else
                    cmd_end <= #`UDLY cmd_end ;     
            `SHRINK   :
                if(head_finish)
                    cmd_end <= #`UDLY 1'b1    ;
                else
                    cmd_end <= #`UDLY cmd_end ;            
            `ACK      :  
                if(cmd_cnt == 7'd7)
                    cmd_end <= #`UDLY 1'b1    ;
                else   
                    cmd_end <= #`UDLY cmd_end ;
            `NAK      :
                if(cmd_head == `NAK)
                    cmd_end <= #`UDLY 1'b1    ;
                else 
                    cmd_end <= #`UDLY 1'b0    ;           	            				                     	                
            `GET_RN   :
                if(cmd_cnt == 7'd15)
                	  cmd_end <= #`UDLY 1'b1    ;
                else
                	  cmd_end <= #`UDLY cmd_end ;	            															            
            `REFRESHRN:
                if(cmd_cnt == 7'd15)
                    cmd_end <= #`UDLY 1'b1    ;
                else 
                    cmd_end <= #`UDLY 1'b0    ;
            `ACCESS   :
                if(cmd_cnt == 7'd28)
                    cmd_end <= #`UDLY 1'b1    ;
                else
                    cmd_end <= #`UDLY 1'b0    ;
            `READ     :
                if(cmd_cnt==7'd34)
                    cmd_end <= #`UDLY 1'b1    ;
                else
                    cmd_end <= #`UDLY cmd_end ;
            `WRITE    :
                if(cmd_cnt==7'd42)
                    cmd_end <= #`UDLY 1'b1    ;
                else
                    cmd_end <= #`UDLY cmd_end ;
            `ERASE    :
                if(cmd_cnt==7'd34)
                    cmd_end <= #`UDLY 1'b1    ;
                else
                	  cmd_end <= #`UDLY cmd_end ;
            `LOCK     :
                if(cmd_cnt==7'd20)
                  	cmd_end <= #`UDLY 1'b1    ;
                else
                	  cmd_end <= #`UDLY cmd_end ;           
            `KILL     :
                if(cmd_cnt == 7'd15)
                    cmd_end <= #`UDLY 1'b1    ;
                else
                    cmd_end <= #`UDLY 1'b0    ;                          		           
            default   :
                cmd_end <= #`UDLY cmd_end     ;
        endcase          
    else                                     
        cmd_end <= #`UDLY cmd_end             ;     
end

//--------------------------------------------------------
//CRC16 check
//--------------------------------------------------------
always @(posedge dec_done3 or negedge rst_del)
begin: CRC16_ERR_JUDGE
    if(!rst_del)
	      CRC16_err <= #`UDLY 1'b0              ;
	else if(CRC16 != 16'h1d0f)
	      CRC16_err <= #`UDLY 1'b1              ;
	else
	      CRC16_err <= #`UDLY 1'b0              ;
end

always @(posedge tpp_clk or negedge rst_del)
begin: CRC16_GENERATOR
    if(!rst_del)
	      CRC16 <= #`UDLY 16'hffff              ;
	else
	      CRC16 <= #`UDLY {CRC16[13:12],crc_xor5,crc_xor4,CRC16[9:5],crc_xor3,crc_xor2,CRC16[2:0],crc_xor1,crc_xor0} ;
end

//CRC XOR 
assign crc_xor0 = tpp_data[0] ^ CRC16[14]     ;         
assign crc_xor1 = tpp_data[1] ^ CRC16[15]     ;
assign crc_xor2 = CRC16[3]    ^ crc_xor0      ;
assign crc_xor3 = crc_xor1    ^ CRC16[4]      ;
assign crc_xor4 = CRC16[10]   ^ crc_xor0      ;
assign crc_xor5 = CRC16[11]   ^ crc_xor1      ;

endmodule