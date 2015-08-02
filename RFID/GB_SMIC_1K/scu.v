// *******************************************************************
// COPYRIGHT, Xi'an XDU Radio-frequency IC Co.,Ltd 
// All rights reserved.
//
// IP NAME      :  RFID
// File name    :  scu.v
// Module name  :  SCU
//
// Author       :  panwanqiang
// Email        :  
// Data         :  
// Version      :  v1.0 
// 
// Tech Info    :  
//
// Abstract     :  
// Called by    :  OPTIM
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
module SCU(
           //INPUTs 
		       DOUB_BLF         ,
		       scu_en           ,
		       rst_n            ,
		       delimiter        ,
		       cmd_head         ,
		       rn_match         ,
		       kill_pwd_status  ,     //from INIT
		       lock_pwd_status  ,
		       //parse_err        ,    //from CMD_PARSE
		       slot_val         ,    //from RNG
		       killpwd_match    ,
		       //mask_match,         //from CMD_PARSE
		       lockpwd_match    ,
           //dec_done5,          //from DECODER
           //dec_done4,          //from DECODER
		       //init_done,          //from INIT
		       flag_match       ,
		       SL_match         ,
		       rd_pwd_match     ,
		       wr_pwd_match     ,
		       session_match    ,
		       T2_overstep      ,
		       acc_pwd          ,
		       membank          ,
		   
		       //OUTPUTs
		       tag_state        ,
		       scu_done         ,
		       bsc              ,
		       T2_judge_en      ,
		       handle_update    ,
		       rn16_update
		   
		       );

// ************************
// DEFINE INPUT(s)
// ************************
input         DOUB_BLF        ;
input         scu_en          ;
input         rst_n;
input         delimiter       ;
input  [7:0]  cmd_head        ;
input         rn_match        ;
input         kill_pwd_status ;
input         lock_pwd_status ;
input  [14:0] slot_val        ;
input         killpwd_match   ;
input         lockpwd_match   ;
input         flag_match      ;
input         SL_match        ;
input         rd_pwd_match    ;
input         wr_pwd_match    ;
input         session_match   ;
input         T2_overstep     ;
input  [3:0]  acc_pwd         ;
input  [5:0]  membank         ;

// ************************                       
// DEFINE OUTPUT(s)                               
// ************************
output [3:0]  tag_state       ;
output [3:0]  bsc             ;
output        T2_judge_en     ;
output        scu_done        ;
output        handle_update   ;
output        rn16_update     ;

// ***************************                    
// DEFINE OUTPUT(s) ATTRIBUTE                     
// *************************** 
//REG(s)
reg    [3:0]  tag_state       ;
reg    [3:0]  bsc             ;
reg           T2_judge_en     ;
reg           handle_update   ;
reg           rn16_update     ;
 
//WIRE(s)
wire          scu_done        ;

// *************************
// INNER SIGNAL DECLARATION
// *************************
//REG(s)
reg           gate_ctrl       ;
reg           st_flg          ;
reg           pre_pulse       ;
reg           post_pulse      ;
reg    [3:0]  next_state      ;
reg           get_rn_come     ;

//WIRE(s)
wire          scu_clk         ;
wire          rst_del         ;
wire          all_match       ;
wire          slot_valid      ;
wire          all_pwd_match   ;
wire          In_OP_SE        ;


// ************************
// MAIN CODE
// ************************

always @(posedge DOUB_BLF or negedge rst_n)
begin
    if(!rst_n)
        gate_ctrl <= #`UDLY 1'b0;             //just for clk synchronous
    else if(scu_en)
        gate_ctrl <= #`UDLY 1'b1;
    else
        gate_ctrl <= #`UDLY 1'b0;
end
    
assign scu_clk = DOUB_BLF & scu_en & gate_ctrl;  

assign rst_del = rst_n & ~delimiter        ;     //if a new cmd come, then reset scu

always @(negedge scu_clk or negedge rst_del)
begin
    if(!rst_del)
        st_flg <= #`UDLY 1'b0;                //st_flg is a signal just for helping generate pre_pulse and post_pulse
    else
        st_flg <= #`UDLY 1'b1;
end

//Generate a pulse for treating the action that the command requested.
always @(posedge scu_clk or negedge rst_n)
begin
    if(!rst_n)
        pre_pulse <= #`UDLY 1'b0;
    else
        pre_pulse <= #`UDLY ~st_flg;
end
    
//Generate a pulse, which makes the FSM jump.
always @(negedge scu_clk or negedge rst_n)
begin
    if(!rst_n)
        post_pulse <= #`UDLY 1'b0;
    else
        post_pulse <= #`UDLY pre_pulse;
end

//Generate a pulse , which tells the SCU has finished works.
assign scu_done = post_pulse;

assign all_match = (SL_match & flag_match & session_match) ; 

assign slot_valid = (slot_val == 15'b0)?1'b1:1'b0;

assign all_pwd_match = (lockpwd_match == 1'b1 || killpwd_match == 1'b1 || rd_pwd_match  == 1'b1 || wr_pwd_match  == 1'b1);

assign In_OP_SE = (tag_state == `OPENSTATE || tag_state == `SECURED || tag_state == `OPENKEY || tag_state == `SECUREDKEY);

//Confirm the current state.
always @(posedge post_pulse or posedge T2_overstep or negedge rst_n)
begin
    if(!rst_n)
        tag_state <= #`UDLY `READY;
    else if(T2_overstep)
        tag_state <= #`UDLY `ARBITRATE;
    else        
        tag_state <= #`UDLY next_state;
end

//Judge the next state according to the cmd_head,flag_match,SL_match and session_match.
//always @(posedge pre_pulse or negedge rst_n)
always @(tag_state or all_match or cmd_head or session_match or slot_valid or rn_match or get_rn_come or all_pwd_match or rd_pwd_match or wr_pwd_match or lockpwd_match or lock_pwd_status or killpwd_match or kill_pwd_status or membank[5:4])
begin
    //if(!rst_n)
       //next_state <= #`UDLY `READY;
    //else
        case(tag_state)
		    `READY:
		        if(cmd_head == `QUERY)
		            if(all_match)
		                next_state = `REPLY;
		            else
				            next_state = `READY;
			      else
			          next_state = tag_state;
		    `ARBITRATE:
		        case(cmd_head)
		        `SORT:
			          next_state = `READY;
			      `QUERY:
			          if(all_match)
				            next_state = `REPLY;
				        else
				            next_state = tag_state;
			      `QUERYREP,
			      `DIVIDE,
			      `DISPERSE,
			      `SHRINK:
			          if(session_match==1'b1 && slot_valid==1'b1)
			              next_state = `REPLY;
				        else
				            next_state = tag_state;
		            default:
			              next_state = tag_state;
			      endcase
		    `REPLY:
		        case(cmd_head)
            `SORT:
				        next_state = `READY;
			      `DIVIDE,
			      `DISPERSE,
			      `SHRINK:
			          if(session_match)
				            if(slot_valid)
					              next_state = tag_state;
					          else
					              next_state = `ARBITRATE;
				        else
				            next_state = tag_state;
			      `ACK:
			          if(rn_match)
                    next_state = `ACKNOWLEDGED;	
                else
                    next_state = `ARBITRATE;
			      `QUERYREP:
			          if(session_match) 
                    next_state = `ARBITRATE;
                else
					          next_state = tag_state;
            `NAK:
                next_state = `ARBITRATE;
			      default:
			          next_state = tag_state;
			      endcase
		    `ACKNOWLEDGED:
		        case(cmd_head)
	          `SORT:
			          next_state = `READY;
			      `QUERY:
			          if(all_match)
				            next_state = `REPLY;
				        else
				            next_state = `READY;
			      `QUERYREP,
            `DIVIDE,
            `DISPERSE,
            `SHRINK:
                if(session_match)
				            next_state = `READY;
				        else
				            next_state = tag_state;
            `ACK:
			          if(rn_match)                            //haven't consider the safe mode now
                    next_state = tag_state;
                else
                    next_state = `ARBITRATE;
			      `REFRESHRN,
			      `GET_RN:
			          if(rn_match)
				            next_state = `OPENSTATE;
				        else
				            next_state = `ARBITRATE;
			      default:
			          next_state = `ARBITRATE;
			      endcase
		    `OPENSTATE:
		        case(cmd_head)
			      `SORT:
			          next_state = `READY;
			      `QUERY:
			          if(all_match)
				            next_state = `REPLY;
				        else
				            next_state = `READY;
		        `QUERYREP,
            `DIVIDE,
            `DISPERSE,
            `SHRINK:
                if(session_match)
				            next_state = `READY;
				        else
				            next_state = tag_state;
		        `ACK:
			          if(rn_match)                            //haven't consider the safe mode now
                    next_state = tag_state;
                else
                    next_state = `READY;
		 	      `NAK:
                next_state = `READY;
            `ACCESS:
				        if(get_rn_come == 1'b1)
				            if(rn_match == 1'b1) 
                        next_state = `OPENKEY;
                    else
                        next_state = tag_state;
                else
                    next_state = tag_state;
	          default:
                next_state = tag_state;
			      endcase
		    `OPENKEY:
		        case(cmd_head)
			      `SORT:
			          next_state = `READY;
			      `QUERY:
			          if(all_match)
				            next_state = `REPLY;
				        else
				            next_state = `READY;
		        `QUERYREP,
            `DIVIDE,
            `DISPERSE,
            `SHRINK:
                if(session_match)
				            next_state = `READY;
				        else
				            next_state = `OPENSTATE;
		        `ACK:
			          if(rn_match)                            
                    next_state = `OPENSTATE;
                else
                    next_state = `READY;
		       	`NAK:
                next_state = `READY;
            `ACCESS:
			         	if(get_rn_come == 1'b1)      
				            if(rn_match == 1'b1)
                        if(all_pwd_match)
                            next_state = `SECURED;
                        else
                            next_state = `OPENSTATE;
                    else
                        next_state = tag_state;
                else
                    next_state = `OPENSTATE;
	          default:
                next_state = tag_state;
			      endcase
		    `SECURED,
		    `SECUREDKEY:
            case(cmd_head)		
			      `SORT,
			      `NAK:
			          next_state = `READY;
			      `QUERY:
			          if(all_match)
				            next_state = `REPLY;
				        else
				            next_state = `READY;
			      `QUERYREP,
            `DIVIDE,
            `DISPERSE,
            `SHRINK:
                if(session_match)
				            next_state = `READY;
				        else
				            next_state = `SECURED;		
			      `ACK:
			          if(rn_match)                            
                    next_state = `SECURED;
                else
                    next_state = `READY;
            `REFRESHRN,
            `GET_RN:
			          if(rn_match)
	                  next_state = `SECURED;	
				        else
				            next_state = `OPENSTATE;
			      `ACCESS:
                if(get_rn_come == 1'b1)
				            if(tag_state == `SECURED)
                        if(rn_match == 1'b1)
                            next_state = `SECUREDKEY;
                        else
                            next_state = `SECURED;
					          else if(rn_match == 1'b1)
					              if(all_pwd_match)
						                next_state = `SECURED;
						            else
						                next_state = `OPENSTATE;
					          else
					              next_state = `SECUREDKEY;
                else
                    next_state = `SECURED;			
			      `READ:
			          if(rn_match)
				            if(membank[5:4] == 2'b11)
					              if(rd_pwd_match)
				                    next_state = `SECURED;
				                else
				                    next_state = `OPENSTATE;
					          else
					              next_state = `SECURED;
				        else
				            next_state = `OPENSTATE;
			      `WRITE,
			      `ERASE:
			          if(rn_match == 1'b1)
				            if(membank[5:4] == 2'b11)
					              if(wr_pwd_match)
				                    next_state = `SECURED;
				                else
				                    next_state = `OPENSTATE;
					          else
					              next_state = `SECURED;
				        else
				            next_state = `OPENSTATE;
			      `LOCK:
				        if(rn_match == 1'b1 && lockpwd_match == 1'b1 && lock_pwd_status == 1'b1)
					          next_state = `SECURED;
				        else
				            next_state = `OPENSTATE;
			      `KILL:
			          if(rn_match == 1'b1 && killpwd_match == 1'b1 && kill_pwd_status == 1'b1)
					          next_state = `KILLED;
				        else
				            next_state =`OPENSTATE;
			      default:
			          next_state = `SECURED;
			      endcase
		   `KILLED:
            next_state = `KILLED;
		    default:
            next_state = tag_state;	   
	      endcase
end 
	 
//Start checking for T2. the timing should be checked by OCU.
always @(negedge post_pulse or negedge rst_del)
begin
    if(!rst_del)
        T2_judge_en=1'b0;
    else if(tag_state == `REPLY || tag_state == `ACKNOWLEDGED)
        T2_judge_en=1'b1;
    else
        T2_judge_en=1'b0; 
end

//check whether the access cmd is coming after get_rn cmd
always@(negedge post_pulse or negedge rst_n)
begin
    if(!rst_n)
        get_rn_come <= #`UDLY 1'b0;
    else if(In_OP_SE)
        if(cmd_head == `GET_RN)
            get_rn_come <= #`UDLY 1'b1;
        else
            get_rn_come <= #`UDLY 1'b0;
    else
        get_rn_come <= #`UDLY get_rn_come;
end 
 
//Generate a pulse for updating handle.
always @(posedge pre_pulse or posedge post_pulse or negedge rst_del)
begin
    if(!rst_del)
        handle_update <= #`UDLY 1'b0;
    else if(post_pulse)
        handle_update <= #`UDLY 1'b0;
    else
     	case(cmd_head)
		`QUERY:
		    if(tag_state==`READY||
			   tag_state==`ARBITRATE||
			   tag_state==`REPLY||
			   tag_state==`ACKNOWLEDGED||
			   In_OP_SE ==1'b1)
                if(all_match)
                    handle_update <= #`UDLY 1'b1;
                else
                    handle_update <= #`UDLY 1'b0;                                
            else
                handle_update <= #`UDLY 1'b0;
        `DIVIDE,
		`DISPERSE,
		`SHRINK:
		    if(tag_state==`ARBITRATE || tag_state==`REPLY)
		        if(slot_valid)
                    handle_update <= #`UDLY 1'b1;
				else
				    handle_update <= #`UDLY 1'b0;
			else
                handle_update <= #`UDLY 1'b0;
		`QUERYREP:	
			if(tag_state==`ARBITRATE)	
		        if(slot_valid)
                    handle_update <= #`UDLY 1'b1;
				else
				    handle_update <= #`UDLY 1'b0;
			else
                handle_update <= #`UDLY 1'b0;				
		`REFRESHRN:
			if(tag_state == `ACKNOWLEDGED||
			   In_OP_SE  == 1'b1)
                if(rn_match == 1'b1)
                    handle_update <= #`UDLY 1'b1;
                else
                    handle_update <= #`UDLY 1'b0;					             
            else
                handle_update <= #`UDLY 1'b0;
		default:
		    handle_update <= #`UDLY handle_update;
		endcase
end 

//Generate a pulse for updating RN16 
always @(posedge pre_pulse or negedge rst_del)
begin
    if(!rst_del)
        rn16_update <= #`UDLY 1'b0;
	else if(cmd_head == `GET_RN)
		if(tag_state == `ACKNOWLEDGED||
		   In_OP_SE  == 1'b1)	
		    if(rn_match)
                rn16_update <= #`UDLY 1'b1;
            else
                rn16_update <= #`UDLY 1'b0;
	    else
            rn16_update <= #`UDLY 1'b0;	
    else
	    rn16_update <= #`UDLY 1'b0;	
end

//Give the type of data to be back scattered
always @(posedge pre_pulse or negedge rst_del)
begin
    if(!rst_del)
	      bsc <= #`UDLY `NO_BACK;
	  else
	      case(cmd_head)
        `SORT:
            bsc <= #`UDLY `NO_BACK;
		    `QUERY:
		        if(tag_state == `KILLED)
			          bsc <= #`UDLY `NO_BACK;
			      else if(all_match)
			          bsc <= #`UDLY `BACK_HANDLE;
            else
			          bsc <= #`UDLY `NO_BACK;
        `QUERYREP:
		         if(tag_state == `ARBITRATE)
                if(session_match & slot_valid)
				            bsc <= #`UDLY `BACK_HANDLE;
				        else
				            bsc <= #`UDLY `NO_BACK;
			       else
			           bsc <= #`UDLY `NO_BACK;
        `DIVIDE,
        `DISPERSE,
        `SHRINK:
		        if(tag_state == `ARBITRATE || tag_state == `REPLY)
                if(session_match & slot_valid)
                    bsc <= #`UDLY `BACK_HANDLE;
				        else
				            bsc <= #`UDLY `NO_BACK;
			      else
			          bsc <= #`UDLY `NO_BACK;
        `ACK:
		        if(tag_state == `REPLY || tag_state == `ACKNOWLEDGED || In_OP_SE==1'b1)
				        if(rn_match == 1'b1)
				            bsc <= #`UDLY `BACK_UAC;
				        else
				            bsc <= #`UDLY `NO_BACK; 
			      else
			          bsc <= #`UDLY `NO_BACK; 
		    `REFRESHRN:
		        if(In_OP_SE==1'b1 || tag_state == `ACKNOWLEDGED)
                if(rn_match == 1'b1)
                    bsc <= #`UDLY `BACK_HANDLE;
				        else
				            bsc <= #`UDLY `NO_BACK;
			      else
			          bsc <= #`UDLY `NO_BACK;
		    `GET_RN:
		        if(In_OP_SE==1'b1 || tag_state == `ACKNOWLEDGED)
				        if(rn_match == 1'b1)
				            bsc <= #`UDLY `BACK_RN11_CRC5;
				        else
				            bsc <= #`UDLY `NO_BACK;
			      else
			          bsc <= #`UDLY `NO_BACK;
		    `ACCESS:
		        if(tag_state == `OPENSTATE||tag_state == `SECURED)
                if(get_rn_come & rn_match)
					          bsc <= #`UDLY `BACK_CHECK_RESULT1;
                else
					          bsc <= #`UDLY `NO_BACK;
            else if(tag_state == `OPENKEY||tag_state == `SECUREDKEY)
			          if(get_rn_come & rn_match)
				            case(acc_pwd[3:1])
					              3'b000:
					                  if(killpwd_match)
					                      bsc <= #`UDLY `BACK_CHECK_RESULT;
					                  else
						                    bsc <= #`UDLY `BACK_ACC_PWD_ERR;
					              3'b001:
					                  if(lockpwd_match)
					                      bsc <= #`UDLY `BACK_CHECK_RESULT;
					                  else
						                    bsc <= #`UDLY `BACK_ACC_PWD_ERR;
					              3'b011:
					                  if(rd_pwd_match)
					                      bsc <= #`UDLY `BACK_CHECK_RESULT;
					                  else
						                    bsc <= #`UDLY `BACK_ACC_PWD_ERR;
					              3'b100:
					                  if(wr_pwd_match)
					                      bsc <= #`UDLY `BACK_CHECK_RESULT;
					                  else
						                    bsc <= #`UDLY `BACK_ACC_PWD_ERR;
					              default:
					                  bsc <= #`UDLY `NO_BACK;
					              endcase
				        else
			              bsc <= #`UDLY `NO_BACK;
			      else
			          bsc <= #`UDLY `NO_BACK;
        `READ:
		        if(In_OP_SE)
		            if(rn_match == 1'b1)
				            if(membank[5:4] == 2'b11)
				                if(rd_pwd_match)
				                    bsc <= #`UDLY `BACK_READ;
				                else
				                    bsc <= #`UDLY `NO_AUTHORITY;
				            else
					              bsc <= #`UDLY `BACK_READ;
			          else
			              bsc <= #`UDLY `NO_BACK;
			      else
			          bsc <= #`UDLY `NO_BACK;
		    `WRITE:
		        if(In_OP_SE)
		            if(rn_match == 1'b1)
				            if(membank[5:4] == 2'b11)
				                if(wr_pwd_match)
				                    bsc <= #`UDLY `BACK_WRITE;
				                else
				                    bsc <= #`UDLY `NO_AUTHORITY_P;
					          else
					              bsc <= #`UDLY `BACK_WRITE;
				        else
				            bsc <= #`UDLY `NO_BACK;
			      else
			          bsc <= #`UDLY `NO_BACK;	
        `ERASE:
		        if(In_OP_SE)
		            if(rn_match == 1'b1)
				            if(membank[5:4] == 2'b11)
				                if(wr_pwd_match)
				                    bsc <= #`UDLY `BACK_ERASE;
				                else
				                    bsc <= #`UDLY `NO_AUTHORITY_P;
					          else
					              bsc <= #`UDLY `BACK_ERASE;
				        else
				            bsc <= #`UDLY `NO_BACK;
			      else
			          bsc <= #`UDLY `NO_BACK;	
        `LOCK:
		        if(tag_state == `SECURED || tag_state == `SECUREDKEY)
			          if(rn_match)
				            if(lock_pwd_status)
				                if(lockpwd_match)
					                  bsc <= #`UDLY `LOCK_EVENT;
					              else
					                  bsc <= #`UDLY `LOCK_ERROR;
					          else
					              bsc <= #`UDLY `LOCK_ERROR;
				        else
				            bsc <= #`UDLY `NO_BACK;
			      else
			          bsc <= #`UDLY `NO_BACK;
		    `KILL:
		        if(tag_state == `SECURED || tag_state == `SECUREDKEY)
			          if(rn_match)
					          if(kill_pwd_status)
			                  if(killpwd_match)
						                bsc <= #`UDLY `KILL_EVENT;
						            else
						                bsc <= #`UDLY `KILL_ERROR;
					          else
					              bsc <= #`UDLY `KILL_ERROR;
				        else
				            bsc <= #`UDLY `NO_BACK;
			      else
			          bsc <= #`UDLY `NO_BACK;
		    default:
		        bsc <= #`UDLY `NO_BACK;
		    endcase
end
			
endmodule
			
			
			
			



