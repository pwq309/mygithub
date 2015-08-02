// ************************************************************** 
// COPYRIGHT, Xi'an XDU Radio-frequency IC Co.,Ltd 
// All rights reserved. 
// 
// IP LIB INDEX : IP lib index just sa UTOPIA_B 
// IP Name      : OPTIM
//
// File name    : scu.v
// Module name  : SCU
// Full name    : System Control Unit 
// 
// Author       : panwanqiang
// Email        : 
// Data         : 2013/04/28
// Version      : V1.0 
// 
// Abstract     : 
// Called by    : OPTIM
// 
// Modification history 
// ---------------------------------------- 
//
// $NOTICE$ 
// We define A as 1 and B as 0 for implementing easily.
// ************************************************************** 

`timescale 1ns/1ns
`define UDLY #5

module SCU(
                //inputs
                DOUB_BLF,
                rst_n,
                scu_en,
                target,
                action,
                cmd_head,
                session_match,
                flag_match,
                mask_match,
                trunc,
                rn_match,
                slot_valid,
                init_done,
                pwd_match,
                acs_status,
                kill_status,
                new_cmd,
                T2_OT_PULSE,
                session_val,
                S1,
                S2,
                S3,
                SL,
                
                //outpus
                scu_done,
                tag_state,
                bsc,
                rn_update,
                handle_update,
                SADR,
                SUPD,
                SS0,
                SS1,
                SS2,
                SS3,
                SSL,                
                T2_CHK_EN
            );
            
    //parameters
    //tag states
    parameter READY           =4'b0001;
    parameter ARBITRATE       =4'b0010;
    parameter REPLY           =4'b0011;
    parameter ACKNOWLEDGED    =4'b0100;
    parameter OPEN            =4'b0101;
    parameter SECURED         =4'b0110;
    parameter KILLED          =4'b0111;
    parameter HALF_KILLED     =4'b1000;
    parameter HALF_SECURED    =4'b1001;
    //cmds. must be same as defined in CMD_PARSE.
    parameter QUERYREP        =5'd3;
    parameter ACK             =5'd4;    
    parameter QUERY           =5'd10;
    parameter QUERYADJ        =5'd11;
    parameter SELECT          =5'd12;    
    parameter NAK             =5'd20;
    parameter REQ_RN          =5'd21;
    parameter READ            =5'd22;
    parameter WRITE           =5'd23;
    parameter KILL            =5'd24;
    parameter LOCK            =5'd25;
    parameter ACCESS          =5'd27;
    parameter VERIFY          =5'd28;
    //back-scatered type.
    parameter BS_NONE         =4'b0000;
    parameter BS_HANDLE_NOCRC =4'b0001;
    parameter BS_HANDLE_CRC   =4'b0010;
    parameter BS_SUCCESS      =4'b0011;
    parameter BS_RN16         =4'b0100;
    parameter BS_EPC_ALL      =4'b0101;
    parameter BS_EPC_PART     =4'b0110;
    parameter BS_ERROR        =4'b0111;
    parameter ET_READ         =4'b1000;
    parameter ET_WRITE        =4'b1001;
    parameter ET_LOCK         =4'b1010;
    parameter ET_KILL         =4'b1011;
    parameter ET_VERIFY       =4'b1100;
    //othes

     //inputs
    input             DOUB_BLF;
    input             rst_n;
    input             scu_en;
    input    [2:0]    target;
    input    [2:0]    action;
    input    [4:0]    cmd_head;
    input             session_match;
    input             flag_match;
    input             mask_match;
    input             trunc;
    input             rn_match;
    input             slot_valid;
    input             init_done;
    input             pwd_match;
    input             acs_status;
    input             kill_status;
    input             new_cmd;
    input             T2_OT_PULSE;
    input    [1:0]    session_val;
    input             S1;
    input             S2;
    input             S3;
    input             SL;
    
    //outpus                
    output            scu_done;
    output   [3:0]    tag_state;
    output   [3:0]    bsc;
    output            rn_update;
    output            handle_update;
    output   [1:0]    SADR;
    output            SUPD;
    output            SS0;
    output            SS1;
    output            SS2;
    output            SS3;
    output            SSL;    
    output            T2_CHK_EN;
    
    //regs
    reg      [3:0]    tag_state;
    reg      [3:0]    nxt_state;
    reg      [3:0]    bsc;
    reg               st_flg;
    reg               pre_pulse;
    reg               post_pulse;
    reg               rn_update;
    reg               handle_update;
    reg      [1:0]    SADR;
    reg               SUPD;
    reg               SS0;
    reg               SS1;
    reg               SS2;
    reg               SS3;
    reg               SSL;
    reg               SSX;
    reg               SST;       
    reg               T2_CHK_EN;
    reg               gate_ctrl;
    
    //wires    
    wire              scu_clk;
    wire              scu_rst;
    wire              fsm_pulse;  
    wire              scu_done;
    ////////VAR_FOR_CHK
    wire              ISEL;
    wire              ISQX;
    wire              IS_READY;
    wire              IS_ARBITRATE;
    wire              IS_REPLY;
    wire              IS_ACKNOWLEDGED;
    wire              IS_OPEN;
    wire              IS_SECURED;
    wire              IS_HALF_KILLED;
    wire              IS_KILLED;
    
    //********************************************************// 
    
    always @(posedge DOUB_BLF or negedge rst_n)
    begin
        if(!rst_n)
            gate_ctrl<=`UDLY 1'b0;
        else if(scu_en)
            gate_ctrl<=`UDLY 1'b1;
        else
            gate_ctrl<=`UDLY 1'b0;
    end
    
    assign scu_clk=DOUB_BLF&scu_en&gate_ctrl;
    
    assign scu_rst=rst_n&~new_cmd;                           //reset SCU when a new comand is coming.
        
    always @(negedge scu_clk or negedge scu_rst)
    begin
        if(!scu_rst)
            st_flg<=`UDLY 1'b0;
        else
            st_flg<=`UDLY 1'b1;
    end
    
    //Generate a pulse for treating the action that the command requested.
    always @(posedge scu_clk or negedge rst_n)
    begin
        if(!rst_n)
            pre_pulse<=`UDLY 1'b0;
        else
            pre_pulse<=`UDLY ~st_flg;
    end
    
    //Generate a pulse , which makes the FSM jump.
    always @(negedge scu_clk or negedge rst_n)
    begin
        if(!rst_n)
            post_pulse<=`UDLY 1'b0;
        else
            post_pulse<=`UDLY pre_pulse;
    end
    
    //Generate a pulse , which tells the SCU has finished works.
    assign scu_done=post_pulse;
    
    //********************************************************//
    
    assign IS_READY        = (tag_state==READY);
    assign IS_ARBITRATE    = (tag_state==ARBITRATE);
    assign IS_REPLY        = (tag_state==REPLY);
    assign IS_ACKNOWLEDGED = (tag_state==ACKNOWLEDGED);
    assign IS_OPEN         = (tag_state==OPEN);
    assign IS_SECURED      = (tag_state==SECURED);
    assign IS_HALF_KILLED  = (tag_state==HALF_KILLED);
    assign IS_KILLED       = (tag_state==KILLED);
    assign IS_HALF_SECURED = (tag_state==HALF_SECURED);
    
    //********************************************************//
    
    assign fsm_pulse=post_pulse;
        
    //Confirm the current state.
    always @(posedge fsm_pulse or posedge T2_OT_PULSE or negedge rst_n)
    begin
        if(!rst_n)
            tag_state<=`UDLY READY;
        else if(T2_OT_PULSE)
            tag_state<=`UDLY ARBITRATE;
        else        
            tag_state<=`UDLY nxt_state;
    end
    
    //Judge the next state according to the cmd_head,flag_match & session_match.
    always @(posedge pre_pulse or negedge rst_n)
    begin
        if(!rst_n)
            nxt_state<=`UDLY READY;
        else
            case(1'b1)
            IS_READY:////////READY
                if(cmd_head==QUERY)
                    if(flag_match&session_match)
                        if(slot_valid)
                            nxt_state<=`UDLY REPLY;
                        else
                            nxt_state<=`UDLY ARBITRATE;
                    else
                        nxt_state<=`UDLY READY;
                else
                    nxt_state<=`UDLY READY;
            IS_ARBITRATE:////////ARBITRATE
                case(cmd_head)
                SELECT:
                    nxt_state<=`UDLY READY;
                QUERYREP,
                QUERYADJ:
                    if(session_match)
                        if(slot_valid)
                            nxt_state<=`UDLY REPLY;
                        else
                            nxt_state<=`UDLY ARBITRATE;
                    else
                        nxt_state<=`UDLY ARBITRATE;
                QUERY:
                    if(flag_match&session_match)
                        if(slot_valid)
                            nxt_state<=`UDLY REPLY;
                        else
                            nxt_state<=`UDLY ARBITRATE;
                    else
                        nxt_state<=`UDLY READY;                    
                default:
                    nxt_state<=`UDLY ARBITRATE;
                endcase               
            IS_REPLY:////////REPLY
                case(cmd_head)
                SELECT:
                    nxt_state<=`UDLY READY;
                QUERY:
                    if(flag_match&session_match)
                        if(slot_valid)
                            nxt_state<=`UDLY REPLY;
                        else
                            nxt_state<=`UDLY ARBITRATE;
                    else
                        nxt_state<=`UDLY READY;
                QUERYADJ:
                    if(session_match)
                        if(slot_valid)
                            nxt_state<=`UDLY REPLY;
                        else
                            nxt_state<=`UDLY ARBITRATE;
                    else
                        nxt_state<=`UDLY REPLY;
                ACK:
                    if(rn_match)
                        nxt_state<=`UDLY ACKNOWLEDGED;
                    else
                        nxt_state<=`UDLY ARBITRATE;
                default:
                    nxt_state<=`UDLY ARBITRATE;
                endcase           
            IS_ACKNOWLEDGED:////////ACKNOWLEDGED
                case(cmd_head)
                SELECT:
                    nxt_state<=`UDLY READY;
                QUERYREP,
                QUERYADJ:
                    if(session_match)
                        nxt_state<=`UDLY READY;
                    else
                        nxt_state<=`UDLY ACKNOWLEDGED;
                QUERY:
                    if(flag_match&session_match)
                        if(slot_valid)
                            nxt_state<=`UDLY REPLY;
                        else
                            nxt_state<=`UDLY ARBITRATE;
                    else
                        nxt_state<=`UDLY READY;
                ACK:
                    if(rn_match)
                        nxt_state<=`UDLY ACKNOWLEDGED;
                    else
                        nxt_state<=`UDLY ARBITRATE;
                REQ_RN:
                    if(rn_match)
                        if(acs_status)
                            nxt_state<=`UDLY OPEN;
                        else
                            nxt_state<=`UDLY SECURED;
                    else
                        nxt_state<=`UDLY ACKNOWLEDGED;
                default:
                    nxt_state<=`UDLY ARBITRATE;
                endcase                
            IS_OPEN:////////OPEN
                case(cmd_head)
                SELECT:
                    nxt_state<=`UDLY READY;
                QUERYREP,
                QUERYADJ:
                    if(session_match)
                        nxt_state<=`UDLY READY;
                    else
                        nxt_state<=`UDLY OPEN;
                QUERY:
                    if(flag_match&session_match)
                        if(slot_valid)
                            nxt_state<=`UDLY REPLY;
                        else
                            nxt_state<=`UDLY ARBITRATE;
                    else
                        nxt_state<=`UDLY READY;
                ACK:
                    if(rn_match)
                        nxt_state<=`UDLY OPEN;
                    else
                        nxt_state<=`UDLY ARBITRATE;
                NAK:
                    nxt_state<=`UDLY ARBITRATE;
                KILL:
                    if(rn_match&pwd_match&kill_status)
                        nxt_state<=`UDLY HALF_KILLED;
                    else
                        nxt_state<=`UDLY OPEN;
                ACCESS:
                    if(rn_match&pwd_match)
                        nxt_state<=`UDLY HALF_SECURED;
                    else
                        nxt_state<=`UDLY OPEN;
                default:
                    nxt_state<=`UDLY OPEN;
                endcase
            IS_HALF_SECURED:////////HALF_SECURED
                case(cmd_head)
                ACCESS:
                    if(rn_match&pwd_match)
                        nxt_state<=`UDLY SECURED;
                    else
                        nxt_state<=`UDLY HALF_SECURED;
                REQ_RN:
                    nxt_state<=`UDLY HALF_SECURED;
                SELECT://To be modified.??????????
                    nxt_state<=`UDLY READY;
                QUERY:
                    if(flag_match&session_match)
                        nxt_state<=`UDLY ARBITRATE;
                    else
                        nxt_state<=`UDLY HALF_SECURED;
                QUERYADJ,
                QUERYREP:
                    if(session_match)
                        nxt_state<=`UDLY ARBITRATE;
                    else
                        nxt_state<=`UDLY HALF_SECURED;                
                ACK,
                READ,
                WRITE,
                LOCK,
                KILL:
                    if(rn_match)
                        nxt_state<=`UDLY ARBITRATE;
                    else
                        nxt_state<=`UDLY HALF_SECURED;
                NAK:
                    nxt_state<=`UDLY ARBITRATE;                
                default: 
                    nxt_state<=`UDLY HALF_SECURED;
                endcase                        
            IS_SECURED:////////SECURED
                case(cmd_head)
                SELECT:
                    nxt_state<=`UDLY READY;
                QUERYREP,
                QUERYADJ:
                    if(session_match)
                        nxt_state<=`UDLY READY;
                    else
                        nxt_state<=`UDLY SECURED;
                QUERY:
                    if(flag_match&session_match)
                        if(slot_valid)
                            nxt_state<=`UDLY REPLY;
                        else
                            nxt_state<=`UDLY ARBITRATE;
                    else
                        nxt_state<=`UDLY READY;
                ACK:
                    if(rn_match)
                        nxt_state<=`UDLY SECURED;
                    else
                        nxt_state<=`UDLY ARBITRATE;
                NAK:
                    nxt_state<=`UDLY ARBITRATE;                    
                KILL:
                    if(rn_match&pwd_match&kill_status)
                        nxt_state<=`UDLY HALF_KILLED;
                    else
                        nxt_state<=`UDLY SECURED;
                default:
                    nxt_state<=`UDLY SECURED;
                endcase
            IS_HALF_KILLED:////////HALF_KILLED
                case(cmd_head)
                KILL:
                    if(rn_match&pwd_match&kill_status)
                        nxt_state<=`UDLY KILLED;
                    else
                        nxt_state<=`UDLY HALF_KILLED;
                REQ_RN:
                    nxt_state<=`UDLY HALF_KILLED;
                SELECT://To be modified.??????????
                    nxt_state<=`UDLY READY;
                QUERY:
                    if(flag_match&session_match)
                        nxt_state<=`UDLY ARBITRATE;
                    else
                        nxt_state<=`UDLY HALF_KILLED;
                QUERYADJ,
                QUERYREP:
                    if(session_match)
                        nxt_state<=`UDLY ARBITRATE;
                    else
                        nxt_state<=`UDLY HALF_KILLED;                
                ACK,
                READ,
                WRITE,
                LOCK:
                    if(rn_match)
                        nxt_state<=`UDLY ARBITRATE;
                    else
                        nxt_state<=`UDLY HALF_KILLED;
                NAK:
                    nxt_state<=`UDLY ARBITRATE;                
                default:
                    nxt_state<=`UDLY HALF_KILLED;
                endcase                
            IS_KILLED:////////KILLED
                nxt_state<=`UDLY KILLED;
            default:
                nxt_state<=`UDLY tag_state;
            endcase
    end    
    
    //********************************************************//
    
    //Start checking for T2. the timing should be checked by OCU.
    always @(negedge post_pulse or negedge scu_rst)
    begin
        if(!scu_rst)
            T2_CHK_EN=1'b0;
        else if(IS_REPLY|IS_ACKNOWLEDGED)
            T2_CHK_EN=1'b1;
        else
            T2_CHK_EN=1'b0; 
    end
    
    assign ISEL=(cmd_head==SELECT);
    
    assign ISQX=(
                 cmd_head==QUERY   ||
                 cmd_head==QUERYREP||
                 cmd_head==QUERYADJ
                )&&(IS_ACKNOWLEDGED||IS_OPEN||IS_SECURED);
                
    always @(target or SS0 or S1 or SS2 or SS3 or SSL)
    begin
        case(target)
        3'b000:  SSX=SS0;
        3'b001:  SSX=S1;   //S1 need to be from Analog Front.                    
        3'b010:  SSX=SS2;
        3'b011:  SSX=SS3;
        3'b100:  SSX=~SSL;
        default: SSX=1'b0;
        endcase
    end
    
    //Prepare the value of SSX(0,1,2,3,L).
    always @(ISEL or mask_match or action or SSX)
    begin
        if(ISEL)                  
            case({mask_match,action})
            4'b1000,
            4'b1001, 
            4'b0100,
            4'b0110: SST=1'b0;
            4'b1011,
            4'b0111: SST=~SSX;                
            4'b1100,
            4'b1101,
            4'b0000,
            4'b0010: SST=1'b1;
            default: SST=SSX;
            endcase            
        else
            SST=1'b0;
    end
    
    always @(posedge pre_pulse or negedge rst_n)
    begin
        if(!rst_n)
            SS0<=`UDLY 1'b0;
        else if(ISEL)
            if(target==3'b000)                 
                SS0<=`UDLY SST;
            else
                SS0<=`UDLY SS0;
        else if(ISQX)
            if(session_val==2'b00)
                SS0<=`UDLY ~SS0;
            else
                SS0<=`UDLY SS0;
        else
            SS0<=`UDLY SS0;
    end
    
    always @(posedge pre_pulse or  negedge rst_n)
    begin
        if(!rst_n)
            SS1<=`UDLY 1'b0;
        else if(ISEL)
            if(target==3'b001)                 
                SS1<=`UDLY SST;
            else
                SS1<=`UDLY SS1;
        else if(ISQX)
            if(session_val==2'b01)
                SS1<=`UDLY ~S1;
            else
                SS1<=`UDLY SS1;
        else
            SS1<=`UDLY SS1;
    end
    
    always @(posedge pre_pulse or posedge init_done or  negedge rst_n)
    begin
        if(!rst_n)
            SS2<=`UDLY 1'b0;
        else if(init_done)
            SS2<=`UDLY S2;
        else if(ISEL)
            if(target==3'b010)                 
                SS2<=`UDLY SST;
            else
                SS2<=`UDLY SS2;
        else if(ISQX)
            if(session_val==2'b10)
                SS2<=`UDLY ~SS2;
            else
                SS2<=`UDLY SS2;
        else
            SS2<=`UDLY SS2;
    end
    
    always @(posedge pre_pulse or posedge init_done or  negedge rst_n)
    begin
        if(!rst_n)
            SS3<=`UDLY 1'b0;
        else if(init_done)
            SS3<=`UDLY S3;
        else if(ISEL)
            if(target==3'b011)                 
                SS3<=`UDLY SST;
            else
                SS3<=`UDLY SS3;
        else if(ISQX)
            if(session_val==2'b11)
                SS3<=`UDLY ~SS3;
            else
                SS3<=`UDLY SS3;
        else
            SS3<=`UDLY SS3;
    end
    
    always @(posedge pre_pulse or posedge init_done or  negedge rst_n)
    begin
        if(!rst_n)
            SSL<=`UDLY 1'b0;
        else if(init_done)
            SSL<=`UDLY SL;
        else if(ISEL)
            if(target==3'b100)                 
                SSL<=`UDLY ~SST;
            else
                SSL<=`UDLY SSL;
        else
            SSL<=`UDLY SSL;
    end
    
    //The address of S1 S2 S3 SL.
    always @(ISEL or ISQX or target or session_val)
    begin
        if(ISEL)
            case(target)            
            3'b001: SADR=2'b00;     //S1
            3'b010: SADR=2'b01;     //S2
            3'b011: SADR=2'b10;     //S3
            3'b100: SADR=2'b11;     //SL
            default: 
                SADR=2'b00;    
            endcase                 
        else if(ISQX)               
            case(session_val)       
            2'b01: SADR=2'b00;      //S1
            2'b10: SADR=2'b01;      //S2
            2'b11: SADR=2'b10;      //S3
            default: 
                SADR=2'b00;
            endcase
        else
            SADR=2'b00;
    end    
    
    assign VTAR=target[2]^(target[1]|target[0]);                      //Valid Target from "Select".
            
    assign VSES=session_val[1]|session_val[0];                        //Valid session from "Query".
    
    //Enalbe Anolog Front to preserve the flags of S1 S2 S3 SL.
    always @(ISEL or ISQX or VTAR or VSES or post_pulse)
    begin
        if(ISEL&VTAR|ISQX&VSES)
            SUPD=post_pulse;
        else
            SUPD=1'b0;
    end
    
    //Generate a pulse for updating RN16    
    always @(posedge pre_pulse or posedge post_pulse or negedge scu_rst)
    begin
        if(!scu_rst)
            rn_update<=`UDLY 1'b0;
        else if(post_pulse)
            rn_update<=`UDLY 1'b0;
        else if(cmd_head==REQ_RN)
            if(IS_OPEN|IS_SECURED|IS_HALF_KILLED)
                if(rn_match)
                    rn_update<=`UDLY 1'b1;
                else
                    rn_update<=`UDLY 1'b0;
            else
                rn_update<=`UDLY 1'b0;
        else
            rn_update<=`UDLY 1'b0;
    end
    
    //Generate a pulse fro updating handle.
    always @(posedge pre_pulse or posedge post_pulse or negedge scu_rst)
    begin
        if(!scu_rst)
            handle_update<=`UDLY 1'b0;
        else if(post_pulse)
            handle_update<=`UDLY 1'b0;
        else
            case(cmd_head)
            QUERY:
                if(IS_READY|IS_ARBITRATE|IS_REPLY|IS_ACKNOWLEDGED|IS_OPEN|IS_SECURED)
                    if(flag_match&slot_valid)
                        handle_update<=`UDLY 1'b1;
                    else
                        handle_update<=`UDLY 1'b0;
                else
                    handle_update<=`UDLY 1'b0;
            QUERYREP,
            QUERYADJ:
                if(IS_ARBITRATE)
                    if(slot_valid)
                        handle_update<=`UDLY 1'b1;
                    else
                        handle_update<=`UDLY 1'b0;
                else
                    handle_update<=`UDLY 1'b0;
            REQ_RN:
                if(IS_ACKNOWLEDGED)
                    if(rn_match)
                        handle_update<=`UDLY 1'b1;
                    else
                        handle_update<=`UDLY 1'b0;
                else
                    handle_update<=`UDLY 1'b0;
            default:
                handle_update<=`UDLY 1'b0;
            endcase
    end    
    
    //Give the type of data to be back scatered.
    always @(posedge pre_pulse or negedge scu_rst)
    begin
        if(!scu_rst)
            bsc<=`UDLY BS_NONE;
        else
            case(cmd_head)
            QUERY:
                if(!IS_KILLED)
                    if(session_match&flag_match&slot_valid)
                        bsc<=`UDLY BS_HANDLE_NOCRC;
                    else
                        bsc<=`UDLY BS_NONE;
                else
                    bsc<=`UDLY BS_NONE;
            QUERYREP:
                if(IS_ARBITRATE)
                    if(session_match&slot_valid)
                        bsc<=`UDLY BS_HANDLE_NOCRC;
                    else
                        bsc<=`UDLY BS_NONE;
                else
                    bsc<=`UDLY BS_NONE;
            QUERYADJ:
                if(IS_ARBITRATE|IS_REPLY)
                    if(session_match&slot_valid)
                        bsc<=`UDLY BS_HANDLE_NOCRC;
                    else
                        bsc<=`UDLY BS_NONE;
                else
                    bsc<=`UDLY BS_NONE;
            ACK:
                if(IS_REPLY|IS_ACKNOWLEDGED|IS_OPEN|IS_SECURED)
                    if(rn_match)
                        if(trunc)
                            bsc<=`UDLY BS_EPC_PART;
                        else
                            bsc<=`UDLY BS_EPC_ALL;
                    else
                        bsc<=`UDLY BS_NONE;
                else
                    bsc<=`UDLY BS_NONE;
            REQ_RN:
                if(IS_ACKNOWLEDGED)
                    if(rn_match)
                        bsc<=`UDLY BS_HANDLE_CRC;
                    else
                        bsc<=`UDLY BS_NONE;
                else if(IS_OPEN|IS_SECURED|IS_HALF_KILLED|IS_HALF_SECURED)
                    if(rn_match)
                        bsc<=`UDLY BS_RN16;
                    else
                        bsc<=`UDLY BS_NONE;
                else
                    bsc<=`UDLY BS_NONE;
            READ:
                if(IS_OPEN|IS_SECURED)
                    if(rn_match)
                        bsc<=`UDLY ET_READ;
                    else
                        bsc<=`UDLY BS_NONE;
                else
                    bsc<=`UDLY BS_NONE;
            WRITE:
                if(IS_OPEN|IS_SECURED)
                    if(rn_match)
                        bsc<=`UDLY ET_WRITE;
                    else
                        bsc<=`UDLY BS_NONE;
                else
                    bsc<=`UDLY BS_NONE;
            LOCK:
                if(IS_SECURED)
                    if(rn_match)
                        bsc<=`UDLY ET_LOCK;
                    else
                        bsc<=`UDLY BS_NONE;
                else
                    bsc<=`UDLY BS_NONE;
            KILL:
                if(IS_OPEN|IS_SECURED|IS_HALF_KILLED)
                    if(rn_match&pwd_match&kill_status)
                        bsc<=`UDLY ET_KILL;
                    else
                        bsc<=`UDLY BS_NONE;
                else
                    bsc<=`UDLY BS_NONE;
            ACCESS:
                if(IS_OPEN|IS_HALF_SECURED)
                    if(rn_match&pwd_match)
                        bsc<=`UDLY BS_HANDLE_CRC;
                    else
                        bsc<=`UDLY BS_NONE;
                else
                    bsc<=`UDLY BS_NONE;
            VERIFY:
                if(IS_OPEN|IS_SECURED)
                    if(rn_match)
                        bsc<=`UDLY ET_VERIFY;
                    else
                        bsc<=`UDLY BS_NONE;
                else
                    bsc<=`UDLY BS_NONE;
            default:
                bsc<=`UDLY BS_NONE;
            endcase
    end
    
endmodule
