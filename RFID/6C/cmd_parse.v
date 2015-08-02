// ************************************************************** 
// COPYRIGHT, Xi'an XDU Radio-frequency IC Co.,Ltd 
// All rights RSV. 
// 
// IP LIB INDEX : IP lib index just sa UTOPIA_B 
// IP Name      : OPTIM
//
// File name    : cmd_parse.v
// Module name  : CMD_PARSE
// Full name    : Command Parse Unit 
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
// $Log$ 
// 
// ************************************************************** 

`timescale 1ns/1ns
`define UDLY #5

module CMD_PARSE(
                //inputs
                rst_n,
                DOUB_BLF,
                pie_clk,
                pie_data,
                CRC_FLG,
                new_cmd,
                dec_done,
                mtp_data,
                rd_done,
                rn16,
                handle,
                tag_state,
                epc_len,
                pwd_kill,
                pwd_acs,
                SS0,
                SS1,
                SS2,
                SS3,
                SSL,
                
                //outputs
                parse_done,
                par_div_req,
                par_div_rel,
                Q_update,
                Q,
                slot_update,
                membank,
                par_pointer,
                par_rd_pulse,
                target,
                action,
                cmd_head,
                pointer,
                length,
                session_match,
                session_val,
                flag_match,
                mask_match,
                trunc,
                EPC_SOA,
                rn_match,
                pwd_match,
                acs_status,
                kill_status,
                parse_err,
                DR,
                TRext,
                M,
                data_buffer,
                cmd_end,
                blc_update,
                ver_pulse,
                srd_pulse
            );

    //parameters
    //tag states
    parameter READY        =4'b0001;
    parameter ARBITRATE    =4'b0010;
    parameter REPLY        =4'b0011;
    parameter ACKNOWLEDGED =4'b0100;
    parameter OPEN         =4'b0101;
    parameter SECURED      =4'b0110;
    parameter KILLED       =4'b0111;
    parameter HALF_KILLED  =4'b1000;
    parameter HALF_SECURED =4'b1001;
    //cmd-head states
    parameter S00          =5'd0;
    parameter S01          =5'd1;
    parameter S02          =5'd2;
    parameter QUERYREP     =5'd3;
    parameter ACK          =5'd4;
    parameter S05          =5'd5;
    parameter S06          =5'd6;
    parameter S07          =5'd7;
    parameter S08          =5'd8;
    parameter S09          =5'd9;
    parameter QUERY        =5'd10;
    parameter QUERYADJ     =5'd11;
    parameter SELECT       =5'd12;
    parameter S13          =5'd13;
    parameter S14          =5'd14;
    parameter S15          =5'd15;
    parameter S16          =5'd16;
    parameter S17          =5'd17;
    parameter S18          =5'd18;
    parameter S19          =5'd19;
    parameter NAK          =5'd20;
    parameter REQ_RN       =5'd21;
    parameter READ         =5'd22;
    parameter WRITE        =5'd23;
    parameter KILL         =5'd24;
    parameter LOCK         =5'd25;
    parameter S26          =5'd26;
    parameter ACCESS       =5'd27;
    parameter VERIFY       =5'd28;
    parameter CH_ERROR     =5'd29;
    //membank
    parameter RSV          =2'b00;
    parameter EPC          =2'b01;
    parameter TID          =2'b10;
    parameter USER         =2'b11;    
    
    //inputs       
    input              rst_n;
    input              DOUB_BLF;
    input              pie_clk;
    input              pie_data;
    input              CRC_FLG;
    input              new_cmd;    
    input              dec_done;
    input     [15:0]   mtp_data;
    input              rd_done;
    input     [15:0]   rn16;
    input     [15:0]   handle;
    input     [3:0]    tag_state;
    input     [4:0]    epc_len;
    input     [31:0]   pwd_kill;
    input     [31:0]   pwd_acs;
    input              SS0;
    input              SS1;
    input              SS2;
    input              SS3;
    input              SSL;
    
    //outputs
    output             parse_done;
    output             par_div_req;
    output             par_div_rel;
    output             Q_update;
    output    [3:0]    Q;
    output             slot_update;
    output    [1:0]    membank;
    output    [4:0]    par_pointer;
    output             par_rd_pulse;
    output    [2:0]    target;
    output    [2:0]    action;
    output    [4:0]    cmd_head;
    output    [13:0]   pointer;
    output    [7:0]    length;
    output             session_match;
    output    [1:0]    session_val;
    output             flag_match;
    output             mask_match;
    output             trunc;
    output    [4:0]    EPC_SOA;                                  //Start Of Address of EPC to be used to response.
    output             rn_match;
    output             pwd_match;
    output             acs_status;
    output             kill_status;
    output             parse_err;
    output             DR;
    output             TRext;
    output    [1:0]    M;
    output    [19:0]   data_buffer;
    output             cmd_end;
    output             blc_update;
    output             ver_pulse;
    output             srd_pulse;
    
    //regs
    reg                Q_update;
    reg       [3:0]    Q;
    reg                slot_update;  
    reg       [1:0]    membank;
    reg                par_rd_pulse;
    reg       [7:0]    length;
    reg                session_match;
    reg       [1:0]    session_val;
    reg                flag_match;
    reg                mask_match;
    reg                trunc;
    reg       [4:0]    EPC_SOA;
    reg                rn_match;
    reg                pwd_match;
    reg                TRext;
    reg       [1:0]    M;
    reg       [19:0]   data_buffer;
    reg                cmd_end;
    reg                blc_update;
    reg                ver_pulse;   
    ////////////////    
    reg       [4:0]    cmd_state;
    reg       [4:0]    nxt_state;
    reg                cmd_en;
    reg                para_en;  
    reg       [5:0]    para_cnt;       
    reg       [35:0]   para_buffer;
    reg       [15:0]   ptr_buffer;
    reg       [15:0]   mask_buffer;
    reg       [4:0]    ebv_cnt;
    reg                ebv_en;
    reg                psh_end;      
    reg                addr_err; 
    reg       [7:0]    mask_cnt;
    reg                div_ctrl;
    reg                mask_en;
    reg                MMT;
    reg       [1:0]    rd_cnt;
    reg                prd_pulse; 
    reg       [4:0]    ptr_base;
    reg       [4:0]    word_cnt;                                            //a pre-read pulse for reading when matching mask.
    reg                TRUNT;
    reg                cmd_flg;
    reg                SSX;
    ////////
    reg                tf_en;
    reg                tf_flg;                                             //a count for generating dec_done;
    reg                pre_pulse;
    reg                pma_pulse;
    reg                pmb_pulse;
    reg                done_pulse;
    reg                ERROR;
    ////////
    reg       [15:0]   CRC16;
    reg       [4:0]    CRC5;
    
    //wires
    wire               par_rst;
    wire               cmd_clk;
    wire               para_clk;
    wire               ebv_clk;
    wire               mask_clk;                                           //from para_clk for matching mask only.
    wire               som_pulse;
    wire               eom_pulse;
    wire      [4:0]    addr_end;
    wire      [4:0]    epc_end;
    wire               ISMM;    
    wire               INVT;
    ////////////////
    wire               tf_clk;
    wire               post_pulse;
    wire               upd_pulse;
    ////////////////CRC
    wire               CRC16_VALID;
    wire               crc_xor0;
    wire               crc_xor1;
    wire               crc_xor2;
    ////////////////
    wire               IS_QUERYREP;
    wire               IS_ACK;
    wire               IS_QUERY;
    wire               IS_QUERYADJ;
    wire               IS_SELECT;
    wire               IS_NAK;
    wire               IS_REQ_RN;
    wire               IS_READ;
    wire               IS_WRITE;
    wire               IS_KILL;
    wire               IS_LOCK;
    wire               IS_ACCESS;
    wire               IS_VERIFY;
    wire               IS_CH_ERROR;
        
    //********************************************************//
    
    assign acs_status=(|pwd_acs);//pwd_acs!=16'h0000;
    assign kill_status=(|pwd_kill);//pwd_kill!=16'h0000;
    
    assign par_rst=rst_n&~new_cmd;
    
    //********************************************************//
    //parse the head of command.  
    
    assign cmd_head=cmd_state;
        
    assign cmd_clk=pie_clk&cmd_en;
    
    always @(posedge cmd_clk or negedge par_rst)
    begin
        if(!par_rst)
            cmd_state<=`UDLY S00;
        else
            cmd_state<=`UDLY nxt_state;
    end
    
    always @(pie_data or cmd_state)
    begin
        case(cmd_state)
        S00: nxt_state=pie_data? S02      : S01;
        S01: nxt_state=pie_data? ACK      : QUERYREP;
        S02: nxt_state=pie_data? S06      : S05; 
        S05: nxt_state=pie_data? S08      : S07;
        S06: nxt_state=pie_data? CH_ERROR : S09;
        S07: nxt_state=pie_data? QUERYADJ : QUERY;
        S08: nxt_state=pie_data? CH_ERROR : SELECT;
        S09: nxt_state=pie_data? CH_ERROR : S13;        
        S13: nxt_state=pie_data? CH_ERROR : S14;
        S14: nxt_state=pie_data? S16      : S15;
        S15: nxt_state=pie_data? S18      : S17;
        S16: nxt_state=pie_data? S26      : S19;
        S17: nxt_state=pie_data? REQ_RN   : NAK;
        S18: nxt_state=pie_data? WRITE    : READ;
        S19: nxt_state=pie_data? LOCK     : KILL;
        S26: nxt_state=pie_data? VERIFY   : ACCESS;
        default: nxt_state=CH_ERROR; 
        endcase
    end
    
    //********************************************************//
    
    assign IS_QUERYREP = (cmd_state==QUERYREP);
    assign IS_ACK      = (cmd_state==ACK);
    assign IS_QUERY    = (cmd_state==QUERY);
    assign IS_QUERYADJ = (cmd_state==QUERYADJ);
    assign IS_SELECT   = (cmd_state==SELECT);
    assign IS_NAK      = (cmd_state==NAK);
    assign IS_REQ_RN   = (cmd_state==REQ_RN);
    assign IS_READ     = (cmd_state==READ);
    assign IS_WRITE    = (cmd_state==WRITE);
    assign IS_KILL     = (cmd_state==KILL);
    assign IS_LOCK     = (cmd_state==LOCK);
    assign IS_ACCESS   = (cmd_state==ACCESS);
    assign IS_VERIFY   = (cmd_state==VERIFY);
    assign IS_CH_ERROR = (cmd_state==CH_ERROR);
    
    //Turn off the head-parse when finishing parsing the head of commands.
    always @(negedge cmd_clk or negedge par_rst)
    begin
        if(!par_rst)
            cmd_en<=`UDLY 1'b1;
        else
        begin
            if(IS_QUERYREP || 
               IS_ACK      || 
               IS_QUERY    || 
               IS_QUERYADJ || 
               IS_SELECT   || 
               IS_NAK      || 
               IS_REQ_RN   || 
               IS_READ     || 
               IS_WRITE    || 
               IS_KILL     || 
               IS_LOCK     ||
               IS_ACCESS   || 
               IS_VERIFY   ||
               IS_CH_ERROR
              )
                cmd_en<=`UDLY 1'b0;
            else
                cmd_en<=`UDLY 1'b1;            
        end
    end
    
    //Turn on the para-parse when finishing parsing the head of commands.
    always @(negedge cmd_clk or negedge par_rst)
    begin
        if(!par_rst)
            para_en<=`UDLY 1'b0;
        else
        begin
            if(IS_QUERYREP || 
               IS_ACK      || 
               IS_QUERY    || 
               IS_QUERYADJ || 
               IS_SELECT   ||    
               IS_REQ_RN   || 
               IS_READ     || 
               IS_WRITE    || 
               IS_KILL     || 
               IS_LOCK     ||
               IS_ACCESS   || 
               IS_VERIFY   ||
               IS_CH_ERROR
              )
                para_en<=`UDLY 1'b1;
            else
                para_en<=`UDLY 1'b0;            
        end
    end
    
    //********************************************************//
    //parse the parameters of command.
    
    assign para_clk=pie_clk&para_en;
    
    //count the bits ,which has been shifted in, for parsing parameters.    
    always @(posedge para_clk or negedge par_rst)
    begin
        if(!par_rst)
            para_cnt<=`UDLY 6'd0;
        else if(ebv_en|mask_en)
            para_cnt<=`UDLY para_cnt;
        else
            para_cnt<=`UDLY para_cnt+1'b1;
    end
    
    //Shift the pie_data into the buffer of parameters.
    always @(posedge para_clk or negedge rst_n)
    begin
        if(!rst_n)
            para_buffer<=`UDLY 16'b0;
        else if(ebv_en|mask_en|psh_end)
            para_buffer<=`UDLY para_buffer;
        else
            para_buffer<=`UDLY {para_buffer[34:0],pie_data};
    end    
    
    //********************************************************//
    
    //Target for Select.
    assign target=para_buffer[15:13];
    
    //Action for Select.
    assign action=para_buffer[12:10];    
    
    //Prepare membank of memory for Selct Read and Write.
    always @(IS_SELECT or IS_READ or IS_WRITE or para_buffer[9:8] or para_buffer[25:24] or para_buffer[33:32])
    begin
        if(IS_SELECT)
            membank=para_buffer[9:8];
        else if(IS_READ)
            membank=para_buffer[25:24];
        else if(IS_WRITE)
            membank=para_buffer[33:32];
        else
            membank=2'b00;
    end                
    
    //Store pay_load of Lock or Data of Write to data_buffer.                   
    always @(IS_WRITE or IS_LOCK or para_buffer[35:16])
    begin
        if(IS_WRITE)
            data_buffer={4'h0,para_buffer[31:16]};
        else if(IS_LOCK)
            data_buffer=para_buffer[35:16];
        else
            data_buffer=20'h000;
    end
    
    //Prepare the nums of words to be read or writen.
    always @(IS_SELECT or IS_READ or IS_WRITE or membank or pointer or para_buffer[7:0] or para_buffer[23:16] or epc_end)
    begin
        if(IS_SELECT)
            length=para_buffer[7:0];
        else if(IS_READ)
            if(para_buffer[23:16]==8'd0)
                case(membank)
                RSV:  length=5'd4-pointer[4:0];
                EPC:  length=epc_end-pointer[4:0];
                TID:  length=5'd8-pointer[4:0];
                USER: length=5'd10-pointer[4:0];
                endcase
            else
                length=para_buffer[23:16];
        else if(IS_WRITE)
            length=8'd1;
        else
            length=8'd0;
    end
    
    //DR for Query.
    assign DR=pie_data;
    
    //Update DOUB_BLF. Must finish updating before dec_done.
    always @(negedge para_clk or negedge rst_n)
    begin
        if(!rst_n)
            blc_update<=`UDLY 1'b0;
        else if(IS_QUERY&&para_cnt==6'd1)
            blc_update<=`UDLY 1'b1;
        else
            blc_update<=`UDLY 1'b0;
    end
    
    //Parse "truncate" of "Select"
    always @(negedge para_clk or negedge rst_n)
    begin
        if(!rst_n)
            TRUNT<=`UDLY 1'b0;
        else if(IS_SELECT)
            if(para_cnt==6'd17)
                TRUNT<=`UDLY pie_data;
            else
                TRUNT<=`UDLY TRUNT;
        else
            TRUNT<=`UDLY TRUNT;
    end
     
    assign bad_select=(TRUNT? (target!=3'b100||membank!=2'b01||~(|addr_end[4:1])) : 1'b0);//~(|addr_end[5:1]) means: addr_end<6'd2
        
    //********************************************************//
    //Check if the pointer is valid for Select. 
    
    //the end-index of address in MTP.  
    assign addr_end=IS_SELECT? (pointer[8:4]+length[7:4]) : 5'h00;
    
    //length of EPC.
    assign epc_end=epc_len+2'b10;
    
    //Set addr_err to high when the addr paras error.   
    always @(IS_SELECT or membank or addr_end or pointer[3:0] or pointer[13:9] or length[3:0] or epc_end)
    begin
        if(IS_SELECT)
            if(pointer[3:0]!=4'h0||pointer[13:9]!=4'h0||length[3:0]!=4'h0)
                addr_err=1'b1;
            else       
                case(membank)
                RSV:
                    addr_err=1'b1;
                EPC:
                    if(addr_end>epc_end)
                        addr_err=1'b1;
                    else
                        addr_err=1'b0;
                TID:
                    if(addr_end>6'h08) 
                        addr_err=1'b1;
                    else
                        addr_err=1'b0;
                USER:
                    if(addr_end>6'h0a)
                        addr_err=1'b1;
                    else
                        addr_err=1'b0;
                endcase
        else
            addr_err=1'b0; 
    end
    
    //********************************************************//
    //Parse the EBV.
    
    //Prepare the pointer of memory to be read or writen.
    assign pointer={ptr_buffer[14:8],ptr_buffer[6:0]};     
        
    //Generate a flag for selecting the buffer for shifting.
    always @(negedge para_clk or negedge par_rst)
    begin
        if(!par_rst)
            ebv_en<=`UDLY 1'b0;
        else if(ebv_en)
            if(ebv_cnt[2:0]==3'd0)
                ebv_en<=`UDLY ptr_buffer[7];
            else
                ebv_en<=`UDLY ebv_en;
        else if(IS_SELECT)
            if(para_cnt==6'd8)
                ebv_en<=`UDLY 1'b1;
            else
                ebv_en<=`UDLY ebv_en;
        else if(IS_READ|IS_WRITE)
            if(para_cnt==6'd2)
                ebv_en<=`UDLY 1'b1;
            else
                ebv_en<=`UDLY ebv_en;            
        else
            ebv_en<=`UDLY 1'b0;
    end
    
    assign ebv_clk=para_clk&ebv_en;
    
    //Count for EBV.
    always @(posedge ebv_clk or negedge par_rst)
    begin
        if(!par_rst)
            ebv_cnt<=`UDLY 5'd0;
        else
            ebv_cnt<=`UDLY ebv_cnt+1'b1;
    end
    
    //Shift the pie_data into ptr_buffer if it locates the ptr area.
    always @(posedge ebv_clk or negedge par_rst)
    begin
        if(!par_rst)
            ptr_buffer<=`UDLY 16'b0;
        else
            ptr_buffer<=`UDLY {ptr_buffer[14:0],pie_data};
    end
    
    //********************************************************//
    //Parse mask for Select.
    
    assign len_zero=(length==8'd0);   
    
    //Request DOUB_BLF to PMU.
    assign par_div_req=som_pulse;
    
    //Release DOUB_BLF.
    assign par_div_rel=eom_pulse; 
          
    always @(negedge para_clk or negedge rst_n)
    begin
        if(!rst_n)
            mask_en<=`UDLY 1'b0;
        else if(mask_en)
            if(mask_cnt==length)
                mask_en<=`UDLY 1'b0;
            else
                mask_en<=`UDLY mask_en;        
        else if(IS_SELECT)
            if(addr_err|len_zero)
                mask_en<=`UDLY 1'b0;
            else if(para_cnt==6'd16)
                mask_en<=`UDLY 1'b1;
            else
                mask_en<=`UDLY mask_en;
        else
            mask_en<=`UDLY 1'b0;        
    end
    
    always @(posedge para_clk or negedge rst_n)
    begin
        if(!rst_n)
            div_ctrl<=`UDLY 1'b0;
        else
            div_ctrl<=`UDLY mask_en;        
    end
    
    //start of match
    assign som_pulse=mask_en&~div_ctrl;
    
    //end of match
    assign eom_pulse=~mask_en&div_ctrl;
    
    //a clock for mask-match.
    assign mask_clk=para_clk&mask_en;
    
    always @(posedge mask_clk or negedge par_rst)
    begin
        if(!par_rst)
            mask_cnt<=`UDLY 8'd0;
        else
            mask_cnt<=`UDLY mask_cnt+1'b1;
    end
    
    //Shift the pie_data into the buffer of parameters.
    always @(posedge mask_clk or negedge rst_n)
    begin
        if(!rst_n)
            mask_buffer<=`UDLY 16'b0;
        else
            mask_buffer<=`UDLY {mask_buffer[14:0],pie_data};
    end
    
    //Prepare the base pointer of the memory to be read.
    always @(posedge som_pulse or negedge rst_n)
    begin
        if(!rst_n)
            ptr_base<=`UDLY 5'h00;
        else
            case(membank)
            RSV:
                ptr_base<=`UDLY 5'h00+pointer[8:4];
            EPC:
                ptr_base<=`UDLY 5'h06+pointer[8:4];
            TID:
                ptr_base<=`UDLY 5'h0e+pointer[8:4];
            USER:
                ptr_base<=`UDLY 5'h16+pointer[8:4];
            endcase
    end
    
    //Count for the nums of words to be read.
    always @(posedge rd_done or negedge par_rst)
    begin
        if(!par_rst)
            word_cnt<=`UDLY 5'd0;
        else
            word_cnt<=`UDLY word_cnt+1'b1;
    end
    
    assign par_pointer=ptr_base+word_cnt;  
    
    //Give a pre-read pulse,which enables generating the rd_pulse pulse.
    always @(negedge mask_clk or negedge rst_n)
    begin
        if(!rst_n)
            prd_pulse<=`UDLY 1'b0;
        else if(mask_cnt[3:0]==4'b0010)
            prd_pulse<=`UDLY 1'b1;
        else
            prd_pulse<=`UDLY 1'b0;
    end 
    
    assign rd_clk=DOUB_BLF&~(rd_cnt[1]&rd_cnt[0]);
    
    //For generating rd_pulse only.
    always @(negedge rd_clk or posedge prd_pulse or negedge rst_n)
    begin
        if(!rst_n)
            rd_cnt<=`UDLY 2'd3;
        else if(prd_pulse)
            rd_cnt<=`UDLY 2'd0;
        else
            rd_cnt<=`UDLY rd_cnt+1'b1;
    end 
    
    //Generate par_rd_pulse.
    always @(posedge DOUB_BLF or negedge rst_n)
    begin
        if(!rst_n)
            par_rd_pulse<=`UDLY 1'b0;
        else if(rd_cnt==2'd2)
            par_rd_pulse<=`UDLY 1'b1;
        else
            par_rd_pulse<=`UDLY 1'b0;
    end
    
    //Mask is matched with mtp_data.
    assign ISMM=MMT&&(mask_buffer==mtp_data);
    
    //Match mask for "Select".(MMT:Mask Match Temperory register)
    always @(negedge mask_clk or negedge par_rst)
    begin
        if(!par_rst)
            MMT<=`UDLY 1'b1;        
        else if(mask_cnt[3:0]==4'b0000)
            MMT<=`UDLY ISMM;
        else
            MMT<=`UDLY MMT;
    end
    
    //********************************************************//    
        
    //Generate a flag that marked as the end of shifting.
    always @(negedge para_clk or negedge par_rst)
    begin
        if(!par_rst)
            psh_end<=`UDLY 1'b0;
        else
            case(1'b1)
            IS_SELECT:
                if(para_cnt==6'd16)
                    psh_end<=`UDLY 1'b1;
                else
                    psh_end<=`UDLY psh_end;
            IS_QUERY:
                if(para_cnt==6'd13)
                    psh_end<=`UDLY 1'b1;
                else
                    psh_end<=`UDLY psh_end;
            IS_VERIFY,
            IS_REQ_RN:
            	if(para_cnt==6'd16)
            		psh_end<=`UDLY 1'b1;
            	else
            		psh_end<=`UDLY psh_end;		            				      
            IS_READ:
                if(para_cnt==6'd26)
                    psh_end<=`UDLY 1'b1;
                else
                	psh_end<=`UDLY psh_end;
            IS_WRITE:
                if(para_cnt==6'd34)
                	psh_end<=`UDLY 1'b1;
                else
                	psh_end<=`UDLY psh_end;
            IS_KILL:
            	if(para_cnt==6'd35)
            		psh_end<=`UDLY 1'b1;
            	else
            		psh_end<=`UDLY psh_end;	
            IS_LOCK:
            	if(para_cnt==6'd36)
            		psh_end<=`UDLY 1'b1;
            	else
            		psh_end<=`UDLY psh_end;
            IS_ACCESS:
            	if(para_cnt==6'd32)
            		psh_end<=`UDLY 1'b1;
            	else
            		psh_end<=`UDLY psh_end;            
            default:
                psh_end<=`UDLY 1'b0;
            endcase
    end 
    
    //********************************************************//      
     
    //Set the cmd_end to high level when all pie_data has received.
    always @(negedge pie_clk or negedge par_rst)
    begin
        if(!par_rst)
            cmd_end<=`UDLY 1'b0;
        else
            case(1'b1)
            IS_CH_ERROR:
                cmd_end<=`UDLY 1'b1;
            IS_SELECT:
                if(para_cnt==6'd33)
                    cmd_end<=`UDLY 1'b1;
                else
                    cmd_end<=`UDLY cmd_end;
            IS_QUERY:
                if(para_cnt==6'd18)
                    cmd_end<=`UDLY 1'b1;
                else
                    cmd_end<=`UDLY cmd_end;
            IS_QUERYADJ:
                if(para_cnt==6'd5)
                    cmd_end<=`UDLY 1'b1;
                else
                    cmd_end<=`UDLY cmd_end;
            IS_QUERYREP:
                if(para_cnt==6'd2)
                    cmd_end<=`UDLY 1'b1;
                else
                    cmd_end<=`UDLY cmd_end;     
            IS_ACK:
                if(para_cnt==6'd16)
                    cmd_end<=`UDLY 1'b1;
                else
                    cmd_end<=`UDLY cmd_end;
            IS_NAK:
                cmd_end<=`UDLY 1'b1;
            IS_VERIFY,
            IS_REQ_RN:
            	if(para_cnt==6'd32)
            		cmd_end<=`UDLY 1'b1;
            	else
            		cmd_end<=`UDLY cmd_end;		            				      
            IS_READ:
                if(para_cnt==6'd42)
                	cmd_end<=`UDLY 1'b1;
                else
                	cmd_end<=`UDLY cmd_end;
            IS_WRITE:
                if(para_cnt==6'd50)
                	cmd_end<=`UDLY 1'b1;
                else
                	cmd_end<=`UDLY cmd_end;
            IS_KILL:
            	if(para_cnt==6'd51)
            		cmd_end<=`UDLY 1'b1;
            	else
            		cmd_end<=`UDLY cmd_end;	
            IS_LOCK:
            	if(para_cnt==6'd52)
            		cmd_end<=`UDLY 1'b1;
            	else
            		cmd_end<=`UDLY cmd_end;
            IS_ACCESS:
            	if(para_cnt==6'd48)
            		cmd_end<=`UDLY 1'b1;
            	else
            		cmd_end<=`UDLY cmd_end;
            default:
                cmd_end<=`UDLY cmd_end;
            endcase
    end
    
    //********************************************************//
    
    //There should not be burrs because DOUB_BLF comes after half-cyle of dec_done.
    always @(posedge dec_done or negedge done_pulse or negedge rst_n)
    begin
        if(!rst_n)
            tf_en<=`UDLY 1'b0;
        else if(dec_done)
            tf_en<=`UDLY 1'b1;
        else 
            tf_en<=`UDLY 1'b0;
    end
    
    assign tf_clk=DOUB_BLF&tf_en;
    
    always @(negedge tf_clk or negedge par_rst)
    begin
        if(!par_rst)
            tf_flg<=`UDLY 1'b0;
        else
            tf_flg<=`UDLY 1'b1;
    end
    
    //For pre-treatment.
    always @(posedge tf_clk or negedge rst_n)
    begin
        if(!rst_n)
            pre_pulse<=`UDLY 1'b0;
        else
            pre_pulse<=`UDLY ~tf_flg;       
    end   
    
    //For post-treatment.
    always @(negedge tf_clk or negedge rst_n)
    begin
        if(!rst_n)
            pma_pulse<=`UDLY 1'b0;
        else
            pma_pulse<=`UDLY pre_pulse;
    end
    
    //For generating the update-signals.
    always @(posedge tf_clk or negedge rst_n)
    begin
        if(!rst_n)
            pmb_pulse<=`UDLY 1'b0;
        else
            pmb_pulse<=`UDLY pma_pulse;
    end
    
    //The signal denoting parsing has finished.
    always @(negedge tf_clk or negedge rst_n)
    begin
        if(!rst_n)
            done_pulse<=`UDLY 1'b0;
        else
            done_pulse<=`UDLY pmb_pulse;
    end
    
    assign post_pulse=pma_pulse&~ERROR;
    
    assign upd_pulse=pmb_pulse&~ERROR;
    
    assign parse_err=done_pulse&ERROR;
    
    assign parse_done=done_pulse&~ERROR;
    
    //********************************************************//
    //Check Process
    
    //Check if CRC is right.
    always @(posedge pre_pulse or negedge par_rst)
    begin
        if(!par_rst) 
            ERROR<=`UDLY 1'b0;
        else if(ebv_cnt>5'd16)                         //This version of code suports 16-bit ebv only.
            ERROR<=`UDLY 1'b1;
        else
            case(1'b1)
            IS_CH_ERROR:
                 ERROR<=`UDLY 1'b1;
            IS_QUERY:
                if(|CRC5)
                    ERROR<=`UDLY 1'b1;
                else
                    ERROR<=`UDLY 1'b0;
            IS_SELECT:
                if(addr_err)
                    ERROR<=`UDLY 1'b1;
                else if(bad_select)
                    ERROR<=`UDLY 1'b1;
                else if(CRC16_VALID)
                    if(~target[2]|target[2]&~target[1]&~target[0])
                        ERROR<=`UDLY 1'b0;
                    else
                        ERROR<=`UDLY 1'b1;
                else
                    ERROR<=`UDLY 1'b1;
            IS_QUERYADJ:       
                if(
                    (para_buffer[0]^para_buffer[2])&para_buffer[1] |
                   ~(para_buffer[0]|para_buffer[1]|para_buffer[2])
                )
                    ERROR<=`UDLY 1'b0;
                else
                    ERROR<=`UDLY 1'b1;            
            IS_VERIFY,
            IS_READ,            
            IS_REQ_RN,            
            IS_LOCK:  
                if(CRC16_VALID)
                    ERROR<=`UDLY 1'b0;                        
                else
                    ERROR<=`UDLY 1'b1;
            IS_ACCESS,
            IS_WRITE,           
            IS_KILL:
                if(CRC16_VALID)
                    if(cmd_flg)
                        ERROR<=`UDLY 1'b0;
                    else
                        ERROR<=`UDLY 1'b1;
                else
                    ERROR<=`UDLY 1'b1;
            default:
                ERROR<=`UDLY 1'b0;
            endcase
    end
    
    //Read values of flags from analog front.
    assign srd_pulse=pre_pulse;
    
    //********************************************************//
    //Post-treat
    
    //Give the value of trunc.
    always @(posedge post_pulse or negedge rst_n)
    begin
        if(!rst_n)
            trunc<=`UDLY 1'b0;
        else if(IS_SELECT)
            trunc<=`UDLY TRUNT;
        else if(IS_QUERY)
            if(para_buffer[8:7]==2'b10||para_buffer[8:7]==2'b11)
                trunc<=`UDLY trunc;                    
            else
                trunc<=`UDLY 1'b0;
        else
            trunc<=`UDLY trunc;
    end
    
    //The start address of EPC to be back-scattered.
    always @(posedge post_pulse or negedge rst_n)
    begin
        if(!rst_n)
            EPC_SOA<=`UDLY 5'h00;
        else if(IS_SELECT)
            EPC_SOA<=`UDLY addr_end;
        else
            EPC_SOA<=`UDLY EPC_SOA;
    end
    
    //Give the value of Q.
    always @(posedge post_pulse or negedge rst_n)
    begin
        if(!rst_n)
            Q<=`UDLY 4'h0;
        else if(IS_QUERY)
            Q<=`UDLY para_buffer[3:0];
        else if(IS_QUERYADJ&&para_buffer[4:3]==session_val)
            case(para_buffer[2:0])
            3'b110:
                if(Q==4'hf)
                    Q<=`UDLY Q;
                else
                    Q<=`UDLY Q+1'b1;
            3'b011:
                if(Q==4'h0)
                    Q<=`UDLY Q;
                else
                    Q<=`UDLY Q-1'b1;
            default:
                Q<=`UDLY Q;
            endcase                
        else
            Q<=`UDLY Q;
    end
    
    //Give the value of rn_match.
    always @(posedge post_pulse or negedge par_rst)        
    begin 
        if(!par_rst)                                       
            rn_match<=`UDLY 1'b0;
        else if(IS_ACK    ||
                IS_REQ_RN ||
                IS_READ   ||
                IS_WRITE  ||
                IS_KILL   ||
                IS_LOCK   ||
                IS_ACCESS ||
                IS_VERIFY  )
        begin
            if(handle==para_buffer[15:0])
                rn_match<=`UDLY 1'b1;
            else
                rn_match<=`UDLY 1'b0;
        end            
        else
            rn_match<=`UDLY 1'b0;                                                        
    end
    
    //Parse bits of "Password" of "Kill"
    always @(negedge post_pulse or negedge par_rst)
    begin
        if(!par_rst)
            pwd_match<=`UDLY 1'b0;
        else if(IS_KILL)
            if(tag_state==HALF_KILLED) //Match lower
                if((rn16^para_buffer[34:19])==pwd_kill[15:0])
                    pwd_match<=`UDLY 1'b1;
                else
                    pwd_match<=`UDLY 1'b0;
            else                      //Match higher 
                if((rn16^para_buffer[34:19])==pwd_kill[31:16])
                    pwd_match<=`UDLY 1'b1;
                else
                    pwd_match<=`UDLY 1'b0;
        else if(IS_ACCESS)
            if(tag_state==HALF_SECURED)//Match lower
                if((rn16^para_buffer[31:16])==pwd_acs[15:0])
                    pwd_match<=`UDLY 1'b1;
                else
                    pwd_match<=`UDLY 1'b0;
            else                      //Match higher 
                if((rn16^para_buffer[31:16])==pwd_acs[31:16])
                    pwd_match<=`UDLY 1'b1;
                else
                    pwd_match<=`UDLY 1'b0;
        else
            pwd_match<=`UDLY pwd_match;
    end
    
    //Give the value of mask_match.
    always@(posedge post_pulse or negedge rst_n)       
    begin
        if(!rst_n)
            mask_match<=`UDLY 1'b0;
        else if(IS_SELECT)
            if(len_zero)
                mask_match<=`UDLY 1'b1;
            else
                mask_match<=`UDLY MMT;
        else 
            mask_match<=`UDLY mask_match;
    end
    
    //Prepare the SSX(0,1,2,3) for matching the inventory flag.
    always @(para_buffer[6:5] or SS0 or SS1 or SS2 or SS3)
    begin
        case(para_buffer[6:5])
        2'b00: SSX=SS0;
        2'b01: SSX=SS1;
        2'b10: SSX=SS2;
        2'b11: SSX=SS3;
        endcase
    end
    
    assign INVT=(~para_buffer[8])|(para_buffer[7]^~SSL);
        
    //Confirm the value of flag_match.[*only for Sel&Target*]
    always @(posedge post_pulse or negedge par_rst)
    begin
        if(!par_rst)
            flag_match<=`UDLY 1'b0;
        else if(IS_QUERY)
            if(para_buffer[4]^SSX)
                flag_match<=`UDLY 1'b0;               
            else
                flag_match<=`UDLY INVT;
        else
            flag_match<=`UDLY flag_match;   
    end
    
    //Set session_match
    always @ (posedge post_pulse or negedge par_rst) 
    begin
        if(!par_rst)
            session_match<=`UDLY 1'b0;
        else if(IS_QUERY)
            if(tag_state==READY)
                session_match<=`UDLY 1'b1;
            else if(para_buffer[6:5]==session_val)
                session_match<=`UDLY 1'b1;
            else
                session_match<=`UDLY 1'b0;
        else if(IS_QUERYADJ)
            if(para_buffer[4:3]==session_val)
                session_match<=`UDLY 1'b1;
            else
                session_match<=`UDLY 1'b0; 
        else if(IS_QUERYREP)
            if(para_buffer[1:0]==session_val)
                session_match<=`UDLY 1'b1;
            else
                session_match<=`UDLY 1'b0; 
        else 
            session_match<=`UDLY session_match;
    end
    
    always@(posedge post_pulse or negedge rst_n)
    begin
        if(!rst_n)
            M<=`UDLY 2'b00;
        else if(IS_QUERY)
            M<=`UDLY para_buffer[11:10];
        else
            M<=`UDLY M;
    end
    
    always@(posedge post_pulse or negedge rst_n)
    begin
        if(!rst_n)
            TRext<=`UDLY 1'b0;
        else if(IS_QUERY)
            TRext<=`UDLY para_buffer[9];
        else
            TRext<=`UDLY TRext;
    end            
    
    //********************************************************//
       
    //Q update signal.
    always @(IS_QUERY or IS_QUERYADJ or upd_pulse or session_match)    
    begin
        if(IS_QUERY||IS_QUERYADJ&&session_match)
            Q_update=upd_pulse;
        else
            Q_update=1'b0;
    end
    
    //Slot update signal
    always @(IS_QUERYREP or upd_pulse or session_match)      
    begin
        if(IS_QUERYREP&&session_match)
            slot_update=upd_pulse;
        else
            slot_update=1'b0;
    end
    
    //Calculate the verify-code for verifying.
    always @(IS_VERIFY or upd_pulse or rn_match)      
    begin
        if(IS_VERIFY&&rn_match)
            ver_pulse=upd_pulse;
        else
            ver_pulse=1'b0;
    end
    
    //Update session_val
    always@(posedge upd_pulse or negedge rst_n)
    begin
        if(!rst_n)
            session_val<=`UDLY 2'b00;
        else if(IS_QUERY)
            if(tag_state==READY)
                session_val<=`UDLY para_buffer[6:5];
            else if(session_match)
                session_val<=`UDLY para_buffer[6:5];
            else
                session_val<=`UDLY session_val;
        else
            session_val<=`UDLY session_val;
    end
    
    //Tell if "Req_RN" has been received.//to be confirmed//
    always @(posedge upd_pulse or negedge rst_n)
    begin
        if(!rst_n)
            cmd_flg<=`UDLY 1'b0;
        else if(IS_REQ_RN&&rn_match&&(tag_state==OPEN||tag_state==SECURED||tag_state==HALF_KILLED||tag_state==HALF_SECURED))
            cmd_flg<=`UDLY 1'b1;
        else
            cmd_flg<=`UDLY 1'b0;
    end
    
    //********************************************************// 
    //Check CRC.
    
    assign CRC16_VALID=(CRC16==16'h1d0f);
       
    //CRC XOR
    assign crc_xor0=CRC_FLG? pie_data^CRC5[4] : pie_data^CRC16[15];
    assign crc_xor1=CRC_FLG? crc_xor0^CRC5[2] : crc_xor0^CRC16[4];
    assign crc_xor2=CRC_FLG? 1'b0             : crc_xor0^CRC16[11];
    
    //Check  CRC5  
    always @(posedge pie_clk or negedge par_rst)
    begin
        if(!par_rst)
            CRC5<=`UDLY 5'b01001;
        else if(CRC_FLG)
            CRC5<=`UDLY {CRC5[3], crc_xor1, CRC5[1], CRC5[0], crc_xor0};
        else
            CRC5<=`UDLY CRC5;
    end
    
    //Check CRC16
    always @(posedge pie_clk or negedge par_rst)
    begin
        if(!par_rst)
            CRC16<=`UDLY 16'hffff;
        else if(CRC_FLG)
            CRC16<=`UDLY CRC16;            
        else
            CRC16<=`UDLY {CRC16[14:12],crc_xor2,CRC16[10:5],crc_xor1,CRC16[3:0],crc_xor0};
    end         
            
endmodule