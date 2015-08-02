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

module SCU(
            //input ports:
            DOUB_BLF,
            rst_n,
            scu_en,          //from PMU
            delimiter,       //from decoder
            cmd_head,        //from CMD_PARSE
            rn_match,        //from CMD_PARSE
            kill_pwd_status,
            lock_pwd_status,
            TID_write_status,
            condition,       //from CMD_PARSE, condition of query;
            parse_err,       //from CMD_PARSE
            slot_val,
            rule,            //from CMD_PARSE, rule of select;
            killpwd_match,
            lockpwd_match,
            rd_pwd_match,
            wr_pwd_match,
            mask_match,      //from CMD_PARSE
            dec_done5,       //from decoder
            dec_done4,       //from decoder 
            pwd_addr,
//            init_done,       //from init
//            match_flag_preserve, //from analog front
//            inventory_flag_preserve,//from analog front 
            membank,    
            target,
            T2_overstep,
            tid_tag,
            len_zero,

            //output ports:
            tag_state,        //to OCU
            bsc,              //to OCU
            T2_judge_en,
            handle_update,    //to RNG;
            rn16_update,      //to RNG;
            scu_done          //to PMU  
//            bsc_en            //to RNG

                      
            );

//define output ports:
output [2:0]  tag_state;
output [3:0]  bsc;
output        scu_done;
output        handle_update;
output        rn16_update;

//output        bsc_en;
//output        inventory_flag;
output        T2_judge_en;

//define input ports:
input         DOUB_BLF;
input         rst_n;
//input         match_flag_preserve;
//input         inventory_flag_preserve;
input [14:0]  slot_val;

//******************************
// input from decoder            
//******************************
input         delimiter;
input         dec_done5;
input         dec_done4;

//******************************
// input from CMD_PARSE            
//******************************
input [7:0]   cmd_head;
input         rn_match;
input         parse_err;
input [1:0]   condition;
input         lockpwd_match;
input [1:0]   rule;
input         mask_match;
input         killpwd_match;
input         rd_pwd_match;
input         wr_pwd_match;
input         target;
input [3:0]   pwd_addr;
input [1:0]   membank;
input         len_zero;
//******************************
// input from OCU           
//******************************
input         T2_overstep;
input         tid_tag;
//******************************
// input from PMU            
//******************************
input         scu_en;
     
//******************************
// input from INIT            
//******************************
//input        init_done;
input         kill_pwd_status;
input         lock_pwd_status;
input         TID_write_status;
//define output attributes:
reg    [2:0]  tag_state;
reg    [3:0]  bsc;
//reg           T2_judge_en;
wire          T2_judge_en;
wire          scu_done;

//inner signal declarations:
wire          rst_del;
wire          rst_done;
wire          In_OP_SE;
wire          tag_select;
wire          all_pwd_match   ;

reg           trans_end;
reg           scu_end;
reg    [3:0]  tag_nx_state;
reg    [1:0]  flag_action;
reg           get_rn_come;
reg           match_flag;
reg           inventory_flag;
reg           handle_update;
reg           rn16_update;
//reg           flag_match;


//main code:
assign rst_del = ~((~rst_n) | delimiter);
//assign bsc_en = bsc_end ^ bsc_end1;
assign rst_done = ~((~rst_n) | dec_done5);


//trans_end generation,trans_end is just scu_en with half DOUB_BLF period delay!
always@(posedge DOUB_BLF or negedge rst_done)
begin
    if(!rst_done)
        trans_end <= #`UDLY 1'b0;
    else if(scu_en == 1'b1)
        trans_end <= #`UDLY 1'b1;    //tag_nx_state generation complete
    else
        trans_end <= #`UDLY trans_end;
end 

always@(posedge DOUB_BLF or negedge rst_done)
begin
    if(!rst_done)
        scu_end <= #`UDLY 1'b0;
    else if(trans_end == 1'b1)
        scu_end <= #`UDLY 1'b1;    
    else
        scu_end <= #`UDLY scu_end;

end 

//always@(posedge DOUB_BLF or negedge rst_done)
//begin: BSC_END_GENERATOR
//    if(!rst_done)                    //reset signal,active low
//        bsc_end <= #`UDLY 1'b0; 
//    else if(scu_end)               
//        bsc_end <= #`UDLY 1'b1; 
//    else
//        bsc_end <= #`UDLY bsc_end;        
//end                               //end BSC_END_GENERATOR

// enable signal for bsc 
//always@(posedge DOUB_BLF or negedge rst_done)
//begin: BSC_END1_GENERATOR
//    if(!rst_done)                    //reset signal,active low
//        bsc_end1 <= #`UDLY 1'b0; 
//    else if(bsc_end)               
//        bsc_end1 <= #`UDLY 1'b1; 
//    else
//        bsc_end1 <= #`UDLY bsc_end1;        
//end                                //end BSC_END1_GENERATOR

assign scu_done = trans_end ^ scu_end;      

//always @(tag_state or rst_n)
//begin
//    if(!rst_n)
//        T2_judge_en = 1'b0;
//    else if(tag_state ==`REPLY)
//        T2_judge_en = 1'b1;
//    else
//        T2_judge_en = 1'b0; 
//end

assign T2_judge_en = (tag_state ==`REPLY)?1'b1:1'b0;

assign In_OP_SE = (tag_state == `OPENSTATE || tag_state == `SECURED || tag_state == `OPENKEY || tag_state == `SECUREDKEY);

assign all_pwd_match = (lockpwd_match == 1'b1 || killpwd_match == 1'b1 || rd_pwd_match  == 1'b1 || wr_pwd_match  == 1'b1);

always@(posedge DOUB_BLF or negedge rst_n)
begin
    if(!rst_n)
        get_rn_come <= #`UDLY 1'b0;
    else if(scu_en == 1'b1 && trans_end == 1'b0)
        if(In_OP_SE)
            if(cmd_head == `GET_RN)
                get_rn_come <= #`UDLY 1'b1;
            else
                get_rn_come <= #`UDLY 1'b0;
        else
            get_rn_come <= #`UDLY 1'b0;
    else
        get_rn_come <= #`UDLY get_rn_come;
end 
   
assign tag_select = (condition == 2'b00 || 
                    (condition == 2'b01 && match_flag == 1'b1) || 
                    (condition == 2'b10 && match_flag == 1'b0));

//Confirm the current state.         
always@(posedge DOUB_BLF or negedge rst_n)
begin
    if(!rst_n)
       		 tag_state <= #`UDLY `READY;
       else if(T2_overstep)		
           tag_state <= #`UDLY `ARBITRATE ;			
       else if(scu_en== 1'b1 && scu_done== 1'b1 )                     
           tag_state <= #`UDLY tag_nx_state;     
       else
           tag_state <= #`UDLY tag_state;
end 

//Judge the next state according to the cmd_head
always@(posedge DOUB_BLF or negedge rst_n)
begin
    if(!rst_n)
        tag_nx_state <= #`UDLY `READY;
    else if(scu_en == 1'b1 && trans_end == 1'b0)
        case(cmd_head)
            `SORT:
                case(tag_state) 
                    `KILLED:
                        tag_nx_state <= #`UDLY `KILLED;
                    default:
                        tag_nx_state <= #`UDLY `READY;
                endcase 
            `QUERY:
                case(tag_state)
                    `READY,
                    `OPENSTATE,   
                    `OPENKEY,                     
                    `SECURED,
                    `SECUREDKEY:                     
                        if(tag_select)
                            if(inventory_flag == target)
                                tag_nx_state <= #`UDLY `REPLY;
                            else
                                tag_nx_state <= #`UDLY `READY;
                        else                                 
                            tag_nx_state <= #`UDLY tag_state;   
                    `ARBITRATE,
                    `REPLY:
                        if(tag_select)
                            tag_nx_state <= #`UDLY `REPLY;
                        else
                            tag_nx_state <= #`UDLY tag_state;                                                                                                                          
                    `KILLED:
                        tag_nx_state <= #`UDLY `KILLED;
                    default:
                        tag_nx_state <= #`UDLY `READY;
                endcase
            `QUERYREP,
            `DIVIDE,
            `DISPERSE,
            `SHRINK:
                case(tag_state)
                    `ARBITRATE,
                    `REPLY:
                        if(slot_val == 15'b0)
                            tag_nx_state <= #`UDLY `REPLY;
                        else
                            tag_nx_state <= #`UDLY `ARBITRATE;
                    `KILLED:
                        tag_nx_state <= #`UDLY `KILLED;
                    default:
                        tag_nx_state <= #`UDLY `READY;
                endcase
                                  
            `ACK:
                case(tag_state)
                    `READY,
                    `ARBITRATE,
                    `KILLED:
                        tag_nx_state <= #`UDLY tag_state;
                    `REPLY:
                        if(rn_match == 1'b1) 
                            tag_nx_state <= #`UDLY `OPENSTATE;
                        else
                            tag_nx_state <= #`UDLY `ARBITRATE;                                                                                  
                    `OPENSTATE,
                    `OPENKEY,
                    `SECURED,
                    `SECUREDKEY:                  
                        if(rn_match == 1'b1)
                            tag_nx_state <= #`UDLY tag_state;
                        else
                            tag_nx_state <= #`UDLY `ARBITRATE;           
                    default:
                        tag_nx_state <=#`UDLY `READY;
                endcase 
            `NAK:
                case(tag_state)
                    `ARBITRATE,
                    `REPLY,
                    `OPENSTATE,
                    `OPENKEY,
                    `SECURED,
                    `SECUREDKEY:
                        tag_nx_state <= #`UDLY `ARBITRATE;    
                    `KILLED:    
                        tag_nx_state <= #`UDLY `KILLED;                                                                      
                    default:
                        tag_nx_state <= #`UDLY `READY;
                endcase                                  
            `REFRESHRN:
                case(tag_state)
                    `READY,
                    `ARBITRATE,
                    `REPLY,
                    `KILLED:
                        tag_nx_state <= #`UDLY tag_state;
                    `OPENSTATE,                        
                    `SECURED:                        
                        if(rn_match == 1'b1)
                            tag_nx_state <= #`UDLY tag_state;
                        else
                            tag_nx_state <= #`UDLY `ARBITRATE;
                    `OPENKEY,
                    `SECUREDKEY:
                        tag_nx_state <= #`UDLY `ARBITRATE;                               
                    default:
                        tag_nx_state <= #`UDLY `READY;
                endcase 
            `GET_RN:
                tag_nx_state <= #`UDLY tag_state; 
            `ACCESS:
                case(tag_state)
                    `READY,
                    `ARBITRATE,
                    `REPLY,
                    `KILLED:
                        tag_nx_state <= #`UDLY tag_state;
                    `OPENSTATE:                           
                        if(get_rn_come == 1'b1)
                            if(rn_match == 1'b1)                                    
                                tag_nx_state <= #`UDLY `OPENKEY;
                            else
                                tag_nx_state <= #`UDLY `OPENSTATE;
                        else
                            tag_nx_state <= #`UDLY `OPENSTATE;  
                    `OPENKEY:
                        if(get_rn_come == 1'b1)
                            if(rn_match == 1'b1)
                                if(all_pwd_match)
                                    tag_nx_state <= #`UDLY `SECURED;
                                else
                                    tag_nx_state <= #`UDLY `ARBITRATE;
                            else
                                tag_nx_state <= #`UDLY `OPENKEY;
                        else
                            tag_nx_state <= #`UDLY `OPENKEY;
                    `SECURED:
                        if(get_rn_come == 1'b1)
                            if(rn_match == 1'b1)
                                tag_nx_state <= #`UDLY `SECUREDKEY;
                            else
                                tag_nx_state <= #`UDLY `SECURED;
                        else
                            tag_nx_state <= #`UDLY `SECURED;
                    `SECUREDKEY:
                        if(get_rn_come == 1'b1)
                            if(rn_match == 1'b1)
                                if(all_pwd_match)
                                    tag_nx_state <= #`UDLY `SECURED;
                                else
                                    tag_nx_state <= #`UDLY `ARBITRATE;
                            else
                                tag_nx_state <= #`UDLY `SECUREDKEY;
                        else
                            tag_nx_state <= #`UDLY `SECUREDKEY;                                                                                                 
                    default:
                        tag_nx_state <= #`UDLY `READY;
                endcase 
            `READ,
            `WRITE,
            `ERASE,
            `LOCK:
                case(tag_state)
                    `READY,
                    `ARBITRATE,
                    `REPLY,
                    `OPENSTATE,                        
                    `SECURED,                        
                    `KILLED:
                        tag_nx_state <= #`UDLY tag_state;
                    `OPENKEY:
                        tag_nx_state <= #`UDLY `OPENSTATE;
                    `SECUREDKEY:
                        tag_nx_state <= #`UDLY `SECURED;
                    default:
                        tag_nx_state <= #`UDLY `READY;
                endcase 
            `KILL:
                 case(tag_state)
                     `READY,
                     `ARBITRATE,
                     `REPLY,
                     `OPENSTATE,
                     `KILLED:
                         tag_nx_state <= #`UDLY tag_state;
                     `OPENKEY:
                         tag_nx_state <= #`UDLY `OPENSTATE;
                     `SECUREDKEY,
//                         tag_nx_state <= #`UDLY `ARBITRATE;
                     `SECURED:                           
                         if(rn_match == 1'b1)
                             if(killpwd_match == 1'b1)
                                 if(kill_pwd_status == 1'b1)
                                     tag_nx_state <= #`UDLY `KILLED;
                                 else
                                     tag_nx_state <= #`UDLY `SECURED;
                             else
                                 tag_nx_state <= #`UDLY `SECURED;
                         else
                             tag_nx_state <= #`UDLY `SECURED;
                     default:
                         tag_nx_state <= #`UDLY `READY;
                 endcase 
             default:
                 tag_nx_state <= #`UDLY tag_state;
         endcase 
end                                                                 
                        

//always@(cmd_head or tag_state or scu_en or trans_end or parse_err or slot_val or rn_match 
//     or sec_type or sec_mode or get_rn16_come or get_secpara_come or req_au_come or rst_n)    
always @(posedge DOUB_BLF or negedge rst_del) 
begin
    if(!rst_del)
        bsc <= #`UDLY `NO_BACK;
    else    
    if(scu_en == 1'b1 && trans_end == 1'b0)
        case(cmd_head)
            `TID_WRITE:
                if(TID_write_status|tid_tag)
                    bsc <= #`UDLY `NO_BACK;
                else
                    bsc <= #`UDLY `BACK_TID_WR;
            `TID_DONE:   
                if(TID_write_status|tid_tag)
                    bsc <= #`UDLY `NO_BACK;
                else
                    bsc <= #`UDLY `BACK_TID_DO;
            `SORT:
                bsc <= #`UDLY `NO_BACK;
            `QUERY:
                case(tag_state)
                    `READY,
                    `ARBITRATE,
                    `REPLY,
                    `OPENSTATE,
                    `OPENKEY,
                    `SECURED,
                    `SECUREDKEY:
                        if(tag_select)
                             if(inventory_flag == target)
                                 bsc <= #`UDLY `BACK_HANDLE;
                             else
                                 bsc <= #`UDLY `NO_BACK;
                        else
                            bsc <= #`UDLY `NO_BACK;   
                    default:
                        bsc <= #`UDLY `NO_BACK;
                endcase                
            `DIVIDE,
            `QUERYREP,
            `DISPERSE,
            `SHRINK:
                case(tag_state)
                    `ARBITRATE,
                    `REPLY:                        
                        if(slot_val == 15'b0)
                            bsc <= #`UDLY `BACK_HANDLE;
                        else
                            bsc <= #`UDLY `NO_BACK;
                    default:
                        bsc <= #`UDLY `NO_BACK;
                endcase 
            `ACK:
                case(tag_state)
                    `REPLY,
                    `OPENSTATE,
                    `OPENKEY,
                    `SECURED,
                    `SECUREDKEY:
                        if(rn_match == 1'b1)
                            bsc <= #`UDLY `BACK_UAC;
                        else
                            bsc <= #`UDLY `NO_BACK;   
                    default:
                        bsc <= #`UDLY `NO_BACK;
                endcase 
            `GET_RN:
                case(tag_state)
                    `OPENSTATE,
                    `OPENKEY,
                    `SECURED,
                    `SECUREDKEY:                      
                        if(rn_match == 1'b1)
                            bsc <= #`UDLY `BACK_RN11_CRC5;
                        else
                            bsc <= #`UDLY `NO_BACK;
                    default:
                        bsc <= #`UDLY `NO_BACK;
                endcase 
            `REFRESHRN:
                case(tag_state)
                    `OPENSTATE,
                    `OPENKEY,
                    `SECURED,
                    `SECUREDKEY:                     
                        if(rn_match == 1'b1)
                            bsc <= #`UDLY `BACK_HANDLE;
                        else
                            bsc <= #`UDLY `NO_BACK;
                    default:
                        bsc <= #`UDLY `NO_BACK;
                endcase 
            `ACCESS:
                case(tag_state)
                    `OPENSTATE,
                    `SECURED:                           
                        if(get_rn_come == 1'b1)
                            if(rn_match == 1'b1)
                                bsc <= #`UDLY `BACK_CHECK_RESULT;
                            else
                                bsc <= #`UDLY `NO_BACK;
                        else
                            bsc <= #`UDLY `NO_BACK;
                    `OPENKEY,
                    `SECUREDKEY:
                        if(get_rn_come == 1'b1)
                            if(rn_match == 1'b1)
				                        case(pwd_addr[3:1])
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
					                          3'b010:
					                              if(wr_pwd_match)
					                                  bsc <= #`UDLY `BACK_CHECK_RESULT;
					                              else
						                                bsc <= #`UDLY `BACK_ACC_PWD_ERR;
					                          default:
					                              bsc <= #`UDLY `NO_BACK;
					                      endcase                                   //the operation state is success or not depending on the pwd match or not 
                            else
                                bsc <= #`UDLY `NO_BACK;
                        else
                            bsc <= #`UDLY `NO_BACK;
                     default:
                         bsc <= #`UDLY `NO_BACK;
                 endcase 
             `READ:
                 case(tag_state)
                    `OPENSTATE,
                    `OPENKEY,
                    `SECURED,
                    `SECUREDKEY:
                        if(rn_match == 1'b1)
                            if(!len_zero)
                                bsc <= #`UDLY `NO_BACK;
                            else if(membank == 2'b10)
                                bsc <= #`UDLY `NO_BACK;   //if pointer address is in safe region,tag doesn't response to read command
                            else if(membank == 2'b01)
                                bsc <= #`UDLY `BACK_READ; //EPC always can be read
                            else if(rd_pwd_match)
                                bsc <= #`UDLY `BACK_READ; //TID and USER can be read after getting the authority
                            else
                                bsc <= #`UDLY `NO_AUTHORITY;
                        else
                            bsc <= #`UDLY `NO_BACK;
                     default:
                         bsc <= #`UDLY `NO_BACK;
                 endcase 
            `WRITE:
                case(tag_state)
                    `OPENSTATE,
                    `OPENKEY,
                    `SECURED,
                    `SECUREDKEY:
                        if(rn_match == 1'b1)
                          //  if(!len_zero)
                              //  bsc <= #`UDLY `NO_BACK;
                            if(membank == 2'b00)
                                bsc <= #`UDLY `NO_BACK;   //if pointer address is in TID,tag doesn't response to write command
                            else if(wr_pwd_match)
                                bsc <= #`UDLY `BACK_WRITE; //TID,EPC and USER can be write after getting the authority
                            else
                                bsc <= #`UDLY `NO_AUTHORITY_P; //response data form is different from the state NO_AUTHORITY
                        else
                            bsc <= #`UDLY `NO_BACK;
                     default:
                         bsc <= #`UDLY `NO_BACK;
                endcase 
            `ERASE:
                case(tag_state)
                    `OPENSTATE,
                    `OPENKEY,
                    `SECURED,
                    `SECUREDKEY:
                        if(rn_match == 1'b1)
                           // if(!len_zero)
                             //   bsc <= #`UDLY `NO_BACK;
                            if(membank == 2'b00)
                                bsc <= #`UDLY `NO_BACK;   
                            else if(wr_pwd_match)
                                bsc <= #`UDLY `BACK_ERASE; 
                            else
                                bsc <= #`UDLY `NO_AUTHORITY_P; 
                        else
                            bsc <= #`UDLY `NO_BACK;
                     default:
                         bsc <= #`UDLY `NO_BACK;
                endcase                              
            `LOCK:
                case(tag_state)
                    `SECUREDKEY,
                    `SECURED:                          
                        if(rn_match == 1'b1)
                            if(lock_pwd_status)
                                if(lockpwd_match == 1'b1)
                                    bsc <= #`UDLY `LOCK_EVENT;
                                else
                                    bsc <= #`UDLY `NO_AUTHORITY_P;
                            else
                                bsc <= #`UDLY `NO_AUTHORITY_P;
				                else
				                    bsc <= #`UDLY `NO_BACK;  
                    default:
                        bsc <= #`UDLY `NO_BACK;
                endcase       
            `KILL:
                case(tag_state)
                    `SECUREDKEY,
                    `SECURED:                          
                        if(rn_match == 1'b1)
                            if(kill_pwd_status)
                                if(killpwd_match == 1'b1)
                                    bsc <= #`UDLY `KILL_EVENT;
                                else
                                    bsc <= #`UDLY `NO_AUTHORITY_P;
                            else
                                bsc <= #`UDLY `NO_AUTHORITY_P;
				                else
				                    bsc <= #`UDLY `NO_BACK;  
                    default:
                        bsc <= #`UDLY `NO_BACK;
                endcase     
            default:
                bsc <= #`UDLY `NO_BACK;
        endcase
    else
        bsc <= #`UDLY bsc;
end                 

//flag_action:
//always@(posedge dec_done4 or negedge rst_n)
always@(parse_err or cmd_head or tag_state or condition or match_flag or tag_select)
begin
//    if(!rst_n)
//        flag_action <= #`UDLY 2'b00;      
    if(parse_err == 1'b1) 
        flag_action = 2'b00;
    else 
        if(cmd_head == `SORT)
            case(tag_state)
                `READY,
                `ARBITRATE,
                `REPLY,
                `OPENSTATE,
                `SECURED:
                    flag_action = 2'b01;           //sort
                default:
                    flag_action = 2'b00;
            endcase
        else if(cmd_head == `QUERY)
                if(tag_select)        
                    case(tag_state)
                        `ARBITRATE,
                        `REPLY:                
                            flag_action = 2'b10; //assign target to inventory_flag
                        `OPENSTATE,
                        `OPENKEY,
                        `SECURED,
                        `SECUREDKEY:                   
                            flag_action = 2'b11; //invert the inventory_flag whether the inventory flag is the same with the target only if the match flag satisfy.
                        default:
                            flag_action = 2'b00;
                    endcase
                else
                    flag_action = 2'b00;
        else if(cmd_head == `DIVIDE || cmd_head == `QUERYREP || cmd_head == `DISPERSE || cmd_head == `SHRINK)
                case(tag_state)
                    `OPENSTATE,
                    `OPENKEY,
                    `SECURED,
                    `SECUREDKEY:                  
                        flag_action = 2'b11; //invert the inventory flag
                    default:
                        flag_action = 2'b00;
                endcase      
        else 
            flag_action = 2'b00;
end 

//always@(posedge dec_done4 or negedge rst_n or posedge init_done)
always@(posedge dec_done4 or negedge rst_n)
begin
    if(!rst_n)
        match_flag <= #`UDLY 1'b0;
//   else if(init_done == 1'b1)
//        match_flag <= #`UDLY match_flag_preserve;
    else if(cmd_head == `SORT)
        if(membank!=2'b10&&flag_action == 2'b01)
            if(mask_match == 1'b1)
                case(rule)
                    2'b00,
                    2'b10:
                        match_flag <= #`UDLY 1'b1;
                    2'b01:
                        match_flag <= #`UDLY match_flag;
                    2'b11:
                        match_flag <= #`UDLY 1'b0;
                endcase
            else
                case(rule)
                    2'b00,
                    2'b01:
                        match_flag <= #`UDLY 1'b0;
                    2'b10:
                        match_flag <= #`UDLY match_flag;
                    2'b11:
                        match_flag <= #`UDLY 1'b1;
                endcase
        else
            match_flag <= #`UDLY match_flag;
    else
        match_flag <= #`UDLY match_flag;
end 

//always@(posedge DOUB_BLF or negedge rst_n)
always@(posedge dec_done4 or negedge rst_n)
begin
    if(!rst_n)
        inventory_flag <= #`UDLY 1'b0;  
//    else if(dec_done4)
        else if(flag_action == 2'b10)
            inventory_flag <= #`UDLY target;                    
        else if(flag_action == 2'b11)
            inventory_flag <= #`UDLY ~inventory_flag;
        else
            inventory_flag <= #`UDLY inventory_flag;
//    else
//        inventory_flag <= #`UDLY inventory_flag;
end        


always@(posedge DOUB_BLF or negedge rst_del)
begin
    if(!rst_del)
        handle_update <= #`UDLY 1'b0;
    else if(scu_en == 1'b1 && trans_end == 1'b0)
            if(cmd_head == `QUERY)
                case(tag_state)
                    `READY,
                    `ARBITRATE,
                    `REPLY,
                    `OPENSTATE,
                    `OPENKEY,
                    `SECURED,
                    `SECUREDKEY:                      
                        if(tag_select)
                            if(inventory_flag == target)
                                handle_update <= #`UDLY 1'b1;
                            else
                                handle_update <= #`UDLY 1'b0;                                
                        else
                            handle_update <= #`UDLY 1'b0;
                    default:
                        handle_update <= #`UDLY 1'b0;
                endcase 
            else if(cmd_head == `DIVIDE || cmd_head == `QUERYREP || cmd_head == `DISPERSE || cmd_head == `SHRINK)
                if(tag_state == `ARBITRATE || tag_state == `REPLY)
                    if(slot_val == 15'b0)
                        handle_update <= #`UDLY 1'b1;
                    else
                        handle_update <= #`UDLY 1'b0;
                else
                    handle_update <= #`UDLY 1'b0;
            else if(cmd_head == `REFRESHRN)
                case(tag_state)
                    `OPENSTATE,
                    `SECURED:                       
                        if(rn_match == 1'b1)
                            handle_update <= #`UDLY 1'b1;
                        else
                            handle_update <= #`UDLY 1'b0;
                    default:
                        handle_update <= #`UDLY 1'b0;
                endcase                 
            else
                handle_update <= #`UDLY 1'b0;
    else
        handle_update <= #`UDLY handle_update;
end            

//Generate a pulse for updating RN16 
always@(posedge DOUB_BLF or negedge rst_del)
begin
    if(!rst_del)
        rn16_update <= #`UDLY 1'b0;
    else if(scu_en == 1'b1 && trans_end == 1'b0)
            if(cmd_head == `GET_RN)     
                case(tag_state)
                    `OPENSTATE,
                    `OPENKEY,
                    `SECURED,
                    `SECUREDKEY:                     
                        if(rn_match == 1'b1)
                            rn16_update <= #`UDLY 1'b1;
                        else
                            rn16_update <= #`UDLY 1'b0;
                    default:
                        rn16_update <= #`UDLY 1'b0;
                endcase 
            else
                rn16_update <= #`UDLY 1'b0;
    else
        rn16_update <= #`UDLY rn16_update;
end 
                                                     
endmodule
        
       