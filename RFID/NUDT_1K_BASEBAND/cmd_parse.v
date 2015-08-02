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
//`include "./macro.v"
//`include "./timescale.v"
`include "D:/xilinx/12.4/xlinx_work/NUDT_1K_BASEBAND/timescale.v"
`include "D:/xilinx/12.4/xlinx_work/NUDT_1K_BASEBAND/macro.v"

module CMD_PARSE(                 
                 DOUB_BLF       ,       //from DIV     
                 rst_n          ,       //from Analog Frontend                                   
                 tpp_clk        ,       //from DECODER              
                 tpp_data       ,       //from DECODER                                            
                 delimiter      ,       //from DECODER              
                 dec_done       ,       //from DECODER
                 dec_done3      ,       //from DECODER 
                 dec_done6      ,       //from DECODER                 

                 mtp_data       ,        //from IE                   
                 //word_done      ,       //from IE                                   												
                 //job_done       ,       //from IE                   
                 handle         ,       //from RNG                                                                                               
                 rn16           ,       //from RNG                                                       
                 tag_state      ,       //from SCU
                 crc5_back      ,       //from OCU 
			        	 /////10.18
			        	 read_pwd_status,       //from init
			         	 write_pwd_status,      //from init 
                                                       
                 //OUTPUTs
                 parse_done     ,       //to PMU           
                 parse_iereq    ,       //to PMU                                           
                 rn1_update     ,       //to RNG           
                 divide_position,       //to RNG                 
                 membank        ,       //to IE and OCU    
                 pointer_par    ,       //to IE and OCU    
                 length_par     ,       //to IE and OCU    
                 read_en        ,       //to IE                                             
                 rule           ,       //to SCU           
                 cmd_head       ,       //to SCU           
                 mask_match     ,       //to SCU                          
                 rn_match       ,       //to SCU                                                       
                 parse_err      ,       //to SCU and PMU                  
                 DR             ,       //to OCU           
                 M              ,       //to ENCODER                                               
                 data_buffer    ,       //to OCU;share the same registers with payload                                                          
                 cmd_end        ,       //to DECODER
                 set_m          ,       //to DIV
//                 sort_err    ,       ////////////!!!!!!!!!!!!!!!!!!
                 addr_over       ,    
                 condition      ,
                 target         ,
                 trext          ,
                 head_finish    ,                
                 lock_action    ,  
                                                                  
                 killpwd1_match    ,
                 killpwd2_match    ,
                 lockpwd1_match    ,
                 lockpwd2_match    ,
                 pwd_addr          ,
                 killpwd_match     ,
                 lockpwd_match     ,
                 ////10.18
                 rd_pwd1_match    ,       //to OCU
			           rd_pwd2_match    ,       //to OCU
                 wr_pwd1_match    ,       //to OCU
                 wr_pwd2_match    ,       //to OCU
			           rd_pwd_match     ,       //to SCU
                 wr_pwd_match     ,       //to SCU    
                 len_zero                 //add in 11.15                                                                                            
                 );
                 
// ************************
// DEFINE PARAMETER(s)
// ************************

 
// ************************
// DEFINE INPUT(s)
// ************************
input          DOUB_BLF          ;      //used for data exchange between CMD_PARSE and IE
input          rst_n             ;      //asynchronous reset signal, low active
input          tpp_clk           ;      //Module CMD_PARSE receives signals by the this pulse signal
input  [1:0]   tpp_data          ;      //The TPP datas (0 or 1) are sent to CMD_PARSE by TPP_data together with tpp_clk       

input          dec_done6         ;      //series of dec_done 
input          dec_done3         ;      //series of dec_done
input          dec_done          ;      //series of dec_done
input          delimiter         ;      //Indicate the begining of a command!
input  [ 15:0] mtp_data          ;      //the port through with CMD_PARSE recieves data from EEPROM
//input          word_done         ;      //a flag by which IE tells this module a byte(8 bits) has been sent																				
//input          job_done          ;      //a flag by which IE tells this module job has been successfully completely

input  [2:0]   tag_state         ;      //from SCU
input  [15:0]  handle            ;      //handle from RNG
input  [4:0]   crc5_back         ;
input  [15:0]  rn16              ;      //rn16 frome RNG

input          read_pwd_status   ;
input          write_pwd_status  ;

// ************************                       
// DEFINE OUTPUT(s)                               
// ************************
output          parse_done       ;      //this signal is asserted when CMD_PARSE has finished its job
output          parse_iereq      ;
output          rn1_update       ;
output  [ 1:0]  membank          ;      //tell IE which memory bank should be choosen
output  [ 5:0]  pointer_par      ;      //tell IE the initiatory bit of a read operation
output  [ 5:0]  length_par       ;      //tell IE the length of the a read operation
output          read_en          ;      //we us this signal to enable a read operation
output  [ 1:0]  rule             ;      //the target parameter in a SORT command
output  [ 7:0]  cmd_head         ;      //the head of a received command
output          head_finish      ;
output          mask_match       ;      //acts as an arbitrator whether the mask in a select matches the specific content stored in the tag memory      
output          rn_match         ;      //a signal to notify SCU that the handle in a command matched the one the tag sent out immediately before                
output          parse_err        ;      //to notify the tag that an error happened during the reception of a command
output  [ 1:0]  DR               ;      //DR  sent to ENCODER

output  [ 1:0]  condition        ;
output          target           ;
output          trext            ;
 
output  [ 1:0]  M                ;      //a parameter sent to a ENCODER, based on which a tag chooses the encoding style
output  [15:0]  data_buffer      ;      // data buffer for both write and erase!
output          divide_position  ;     //to RNG

output          cmd_end          ;
output          addr_over        ;     
output          set_m            ;  
   
output [1:0]    lock_action      ;
output          killpwd1_match   ;   //to oCU 
output          killpwd2_match   ;   //to oCU 
output          lockpwd1_match   ;   //to oCU 
output          lockpwd2_match   ;   //to oCU 
output  [3:0]   pwd_addr         ;   //to OCU   
output          killpwd_match    ;

output          lockpwd_match    ;   //to SCU

output          rd_pwd1_match    ;      //indicate the read pwd in access pwd match with the pwd in the user region
output 		    	rd_pwd2_match    ;
output          wr_pwd1_match    ;      //indicate the write pwd in access pwd match with the pwd in the user region
output          wr_pwd2_match    ;
output 		    	rd_pwd_match     ;      //indicate the 32 bits read pwd are match
output          wr_pwd_match     ;      //indicate the 32 bits write pwd are match
output          len_zero         ;   


// ***************************                    
// DEFINE OUTPUT(s) ATTRIBUTE                     
// *************************** 
//REG(s)
reg          parse_iereq        ;

reg  [ 1:0]  membank            ;
reg  [ 5:0]  pointer_par        ;
reg  [ 5:0]  length_par         ;
reg          read_en            ;
reg  [ 1:0]  rule               ;
reg  [ 7:0]  cmd_head           ;


reg          mask_match         ;
reg          mask_en            ; 
reg          rn_match           ;
//reg          parse_err          ;
reg  [ 1:0]  DR                 ;
reg  [ 1:0]  condition          ;
reg          target             ;
reg          trext              ;


reg  [ 1:0]  M                  ;
reg          divide_position    ;
reg  [15:0]  data_buffer        ;
reg  [ 6:0]  mask_end           ;
reg          cmd_end            ;
reg          set_m              ;  
 
reg          data_end           ;  
reg   [65:0] data_shifter       ;  
      
reg          data_end_delay1    ;
reg          data_end_delay2    ;
reg   [ 5:0] temp1              ;
reg   [15:0] temp2              ;
reg          receive_flag_delay ;

reg          crc16_en1          ;

reg          rn1_update         ;


reg          rd_pwd1_match      ;  
reg          rd_pwd2_match      ;
reg          wr_pwd1_match      ;
reg          wr_pwd2_match      ;

wire         parse_done         ;  
wire         parse_err          ; 
// *************************
// INNER SIGNAL DECLARATION
// *************************


reg          head_finish         ;      //a signal that indicates whether a command head has been successfully received

reg  [15:0]  crc16_Q1            ;      //the 16 bits register for CRC16 
reg  [ 2:0]  head_cnt            ;      //the counter for witch we know how many bits of a command head a tag has recieved  
reg  [ 5:0]  cmd_cnt             ;      //the counter for witch we know how many bits of a command content a tag has received, except the command head
reg  [ 3:0]  length_down         ;      //a standard by witch a tag will determine whether to receive mask
reg          read_en_ctr         ;      //use to generate a pulse for the signal read_en
reg          sort_err            ;
reg          addr_over           ;    
reg  [15:0]  pointer             ;
reg  [15:0]  length              ;
reg          receive_flag        ; 
reg  [1:0]   lock_action         ;
reg          cmd_err             ;       



//WIRE(s)
wire          rst_del             ;
wire          mask_match_en       ;   
//wire          rst_del_addr_err    ;  
reg           receive_sign        ;

//access pwd_match
//reg            get_rn_come         ;
reg            killpwd1_match      ;
reg            killpwd2_match      ;
wire           killpwd_match       ;

reg            lockpwd1_match      ;
reg            lockpwd2_match      ;
wire           lockpwd_match       ;

wire 	    	   rd_pwd_match        ;   
wire           wr_pwd_match        ;

wire    [3:0]  pwd_addr            ;
wire           para_clk            ;
wire           head_clk            ;        //added by panwanqiang 5.21
wire           crc16_err           ;
//wire           killing1_match      ;
//wire           killing2_match      ;
//wire           locking1_match      ;
//wire           locking2_match      ;
//wire           reading1_match      ;
//wire           reading2_match      ;
//wire           writing1_match      ;
//wire           writing2_match      ;
wire           In_OP_SE            ;    //a signal indicate the tag is in open or secured state
wire           len_zero            ;

// ************************
// MAIN CODE
// ************************
//assign rst_del_addr_err = ~((~rst_n) | addr_over | delimiter | sort_err); 
assign rst_del = rst_n & ~delimiter        ;                 
                 

always @(data_shifter[31:0] or cmd_head)
begin
    if(cmd_head==`WRITE )
        data_buffer = data_shifter[31:16]; 
    else if(cmd_head==`TID_WRITE)
        data_buffer = data_shifter[15:0];   
    else if(cmd_head ==`ERASE)
        data_buffer=16'b0;
    else
        data_buffer=16'b0;
end

//cmd_head judeg
always @(posedge head_clk or negedge rst_del)     
begin 
    if(!rst_del)
        head_cnt <= #`UDLY 3'b0;
    else if(head_cnt<3'd4)     
        head_cnt <= #`UDLY head_cnt + 1'b1;
    else
        head_cnt <=#`UDLY head_cnt;
end

always@(negedge tpp_clk or negedge rst_del)  
begin
    if(!rst_del)
        head_finish <= #`UDLY 1'b0;
    else if(head_cnt == 3'd1 && cmd_head[1:0] != 2'b10 )
        head_finish <= #`UDLY 1'b1;
    else if(head_cnt == 3'd2 && cmd_head [1]== 1'b0)
        head_finish <= #`UDLY 1'b1;
    else if(head_cnt == 3'd4 )
        head_finish <= #`UDLY 1'b1;
    else
        head_finish <= #`UDLY head_finish;
end

//Turn off the head-parse when finishing parsing the head of commands
assign head_clk = tpp_clk & (~head_finish);
   
always@(posedge head_clk or negedge rst_del)
begin 
    if(!rst_del)
        cmd_head <= #`UDLY 8'd0;
    else if(head_finish!=1'b1)     
        cmd_head <= #`UDLY {cmd_head[5:0],tpp_data} ;    
    else
        cmd_head <= #`UDLY cmd_head;
end

//Turn on the para-parse when finishing parsing the head of commands
assign para_clk=tpp_clk&head_finish;                   
               
always @(negedge para_clk or negedge rst_del)  
begin 
    if(!rst_del)
        cmd_cnt <= #`UDLY 6'b0;
    else
        if(cmd_head==`SORT )               
            if(cmd_cnt==6'd13)             
                cmd_cnt <= #`UDLY 6'd0;
            else if(receive_sign)
                if(cmd_cnt==6'd7)           
                   cmd_cnt <=#`UDLY 6'd0; 
                else
                   cmd_cnt<=#`UDLY cmd_cnt+1'b1;
            else
                cmd_cnt<= #`UDLY  cmd_cnt+1'b1;      
        else
            cmd_cnt <= #`UDLY cmd_cnt +1'b1;                             
end


//data_end judge,whithout CRC!!!
//If the cmd has no crc,we use dec_done instead of data_end!!!
always @(negedge tpp_clk or negedge rst_del)
begin
    if(!rst_del)
        data_end <= #`UDLY 1'b0;
    else if(head_finish== 1'b1)    
        case(cmd_head)
            `TID_WRITE: 
                if(cmd_cnt==6'd16)                   
                    data_end<=#`UDLY 1'b1;
                else
                    data_end<= #`UDLY data_end;
//            `TID_DONE:
//                if(cmd_cnt==6'd)                   
//                    data_end<=#`UDLY 1'b1;
//                else
//                    data_end<= #`UDLY data_end;
            `SORT: 
                if(cmd_cnt==6'd13)                   
                    data_end<=#`UDLY 1'b1;
                else
                    data_end<= #`UDLY data_end;
            `QUERY: 
                if(cmd_cnt == 6'd3)
                    data_end <= #`UDLY 1'b1;
                else
                    data_end <= #`UDLY data_end;               
            `ACK:     
                if(cmd_cnt == 6'd7)           
                    data_end <= #`UDLY 1'b1;        
                else 
                    data_end <= #`UDLY data_end;                                               
            `GET_RN:
                if(cmd_cnt== 6'd7)
                    data_end <= #`UDLY 1'b1;
                else
                    data_end <= #`UDLY data_end;           
            `REFRESHRN:
                if(cmd_cnt== 6'd7)
                    data_end <= #`UDLY 1'b1;
                else
                    data_end <= #`UDLY data_end; 
            `ACCESS:
                if(cmd_cnt== 6'd17)
                    data_end <= #`UDLY 1'b1;
                else
                    data_end <= #`UDLY data_end;                             				      
            `READ:
            		if(cmd_cnt == 6'd24)
            				data_end <= #`UDLY 1'b1;
            		else
            				data_end <= #`UDLY data_end;	
            `WRITE:
                if(cmd_cnt==6'd32)
                    data_end<= #`UDLY 1'b1;		
                else
                    data_end <= #`UDLY data_end;	
            `ERASE:
                if(cmd_cnt == 6'd24)
                    data_end <= #`UDLY 1'b1;
                else 
                    data_end <= #`UDLY data_end;														            	
            `LOCK:
            		if(cmd_cnt==6'd9)
            		    data_end <= #`UDLY 1'b1;
            		else
            		    data_end <= #`UDLY data_end; 
            `KILL:
            		if(cmd_cnt == 6'd7)
            				data_end <= #`UDLY 1'b1;
            		else
            				data_end <= #`UDLY data_end;                  
            default:
                data_end <= #`UDLY data_end;
        endcase  
    else                                     
        data_end <= #`UDLY data_end;     
end


//just for timing requirement!
always @(posedge tpp_clk or negedge rst_del)
begin
    if(!rst_del)
        data_end_delay1<= #`UDLY 1'b0;
    else
        data_end_delay1<= #`UDLY data_end;
end


always @(posedge tpp_clk or negedge rst_del)
begin
    if(!rst_del)
        data_end_delay2<= #`UDLY 1'b0;
    else
        data_end_delay2<= #`UDLY data_end_delay1;
end


//data receiver
always @(posedge tpp_clk or negedge rst_del)    //shift tpp_data into data_shifter! MSB!
begin
    if(!rst_del)
        data_shifter<= #`UDLY 66'd0;
    else if(head_finish== 1'b1 )//due to MSB,when sec_com cmd,the high bit is discarded!
        if(cmd_head==`SORT)
            if(data_end==1'b0)
                data_shifter[27:0]<= #`UDLY {data_shifter[25:0],tpp_data};
            else
                data_shifter[43:28]<=#`UDLY {data_shifter[41:28],tpp_data};  //the mask data of sort cmd
        else if(data_end==1'b0)
            data_shifter[65:0]<= #`UDLY {data_shifter[63:0],tpp_data}; 
        else
            data_shifter<= #`UDLY data_shifter;               
    else
        data_shifter<= #`UDLY data_shifter;
end  


//parameter of SORT command      
always@(data_shifter[25:24] or cmd_head or rule)
begin
    if(cmd_head==`SORT)
        rule = data_shifter[25:24];
    else
        rule = 2'b00;           //!!!!!!!!!!!!!!!!!!!!!!!!!!
end      
      
always@(data_shifter or cmd_head)
begin
    if(cmd_head==`SORT)
        membank =  data_shifter[27:26];
    else if(cmd_head==`TID_WRITE)
        membank =  data_shifter[33:32];   
    else if(cmd_head==`READ)
        membank =  data_shifter[49:48];
    else if(cmd_head==`WRITE)
        membank = data_shifter[65:64];
    else if(cmd_head==`ERASE)
        membank = data_shifter[49:48];         
    else if(cmd_head ==`LOCK)
        membank = data_shifter[19:18];
//    else if(cmd_head == `GET_SECPARA)
//        membank =  2'b10;
    else
        membank = 2'b00;       //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
end       

//Lock action
always@(data_shifter[17:16] or cmd_head)
begin
    if(cmd_head == `LOCK)
        lock_action = data_shifter[17:16];
    else
        lock_action = 2'b00;  //////////////////////////////////
end 


always@(cmd_head or data_shifter[63:12])
begin
    if(cmd_head==`SORT)
        temp2 = {4'b0000,data_shifter[23:12]};    //buffer pointer in sort command
    else if(cmd_head == `TID_WRITE)
        temp2 = data_shifter[31:16];              //buffer pointer in TID_write command
    else if(cmd_head == `ACCESS)
        temp2 = {12'b00,data_shifter[35:32]};     //buffer 4 bits password type in access command
    else if(cmd_head==`READ || cmd_head ==`ERASE)
        temp2 = data_shifter[47:32];              //buffer pointer in read and erase command
    else if(cmd_head==`WRITE)
        temp2 = data_shifter[63:48];              //buffer pointer in write command
    else 
        temp2 = 16'b0;  ///////////////////////////////////////////
end 

assign pwd_addr = temp2[3:0];     //for access command, the 4 bits password type


always@(membank)
begin
    if(membank==2'b00)         //transfer membank to physical address in eeprom
         temp1 = 6'h00;
    else if(membank==2'b01)
         temp1 = 6'h08;
    else if(membank==2'b10)
         temp1 = 6'h19;
    else 
         temp1 = 6'h28;
end 


//transfer pointer and length calculating in bit into pointer and length calculating in word
always@(temp1 or temp2 or cmd_head)
begin
    if(cmd_head != `ACCESS)  
       pointer = temp1 + temp2;
    else   
        case(temp2[3:0])
            4'b0000:
                pointer = 16'h001A;
            4'b0001:
                pointer = 16'h0019;
            4'b0010:
                pointer = 16'h001C;
            4'b0011:
                pointer = 16'h001B;
            4'b0100:
                pointer = 16'h0020;
            4'b0101:
                pointer = 16'h001F;
            4'b0110:
                pointer = 16'h001E;
            4'b0111:
                pointer = 16'h001D;
            default:
                pointer = 16'h0000;
        endcase                                                      
end
     
     
always@(data_shifter or cmd_head)
begin
    if(cmd_head==`SORT )
        length = {12'b0,data_shifter[7:4]};
    else if (cmd_head==`WRITE || cmd_head==`ERASE || cmd_head==`TID_WRITE || cmd_head ==`ACCESS)
        length = 16'b1;
    else if(cmd_head==`READ)
        length = data_shifter[31:16];
    else 
        length = 16'b0; 
end

always @(pointer[5:0]) 
begin
		pointer_par=pointer[5:0];				
end

always @(length[5:0]) 
begin
		length_par=length[5:0];				
end    

//End of operating to EEPROM
//used for judging of addr_over!!!
always @(posedge data_end or negedge rst_n)
begin
    if(!rst_n)
        mask_end <= #`UDLY 7'd0;
    else if(cmd_head==`SORT || cmd_head==`READ)   ////////////////////////////////11.15
        if(len_zero!=1'b0)
            mask_end <= #`UDLY pointer + length - 1'b1 ;
        else
            mask_end <= #`UDLY pointer; 
    else if(cmd_head==`WRITE || cmd_head==`ERASE || cmd_head==`TID_WRITE)
        mask_end <= #`UDLY pointer;
    else
        mask_end <= #`UDLY mask_end ; 
end 
           
//address over judge!           
always @(posedge data_end_delay1 or negedge rst_del)     
begin : ADDR_OVER_JUDGEMENT                      
    if(!rst_del)        
       addr_over <= #`UDLY 1'b0;
    else if(cmd_head==`SORT ||cmd_head==`READ ||cmd_head==`WRITE || cmd_head == `ERASE || cmd_head==`TID_WRITE)
        case(membank)
            2'b00 :
                if(mask_end > 7'h07)
                    addr_over <= #`UDLY 1'b1;
                else
                    addr_over <= #`UDLY 1'b0;
            2'b01 :
                if(mask_end > 7'h18)
                    addr_over <= #`UDLY 1'b1;
                else
                    addr_over <= #`UDLY 1'b0;
            2'b10 :
                if(mask_end > 7'h27) 
                    addr_over <= #`UDLY 1'b1;
                else
                    addr_over <= #`UDLY 1'b0;
            2'b11 :
                if(mask_end > 7'h3F)
                    addr_over <= #`UDLY 1'b1;
                else
                    addr_over <= #`UDLY 1'b0;
            default:
               addr_over <= #`UDLY 1'b0     ;  
        endcase
    else
        addr_over <= #`UDLY 1'b0;
end   

//sort_err judge,find the sort command parameter error
always @(posedge data_end or negedge rst_del) 
begin 
    if(!rst_del)
        sort_err <= #`UDLY 1'b0;
    else
        case(cmd_head)
            `SORT :
                if(data_shifter[27:26]==2'b10)
                    sort_err <= #`UDLY 1'b1;
                else if(data_shifter[11:8]!= 4'b0000)
                    sort_err <= #`UDLY 1'b1;
                else if(data_shifter[3:0] != 4'b0000) 
                    sort_err <= #`UDLY 1'b1;                   
                else
                    sort_err <= #`UDLY 1'b0;                                                          
            default :
                sort_err <= #`UDLY 1'b0;
        endcase
end


//the evaluation of parse_err
always @(posedge dec_done3 or negedge rst_del )        
begin
    if(!rst_del)                                                                             
        cmd_err <= #`UDLY 1'b0;
    else 
        case(cmd_head) 
            `QUERY :
                if(data_shifter[7:6] == 2'b11)
                    cmd_err <= #`UDLY 1'b1;             
                else
                    if(crc16_err)
                        cmd_err<= #`UDLY 1'b1;
                    else
                        cmd_err<= #`UDLY 1'b0;
            `DIVIDE:       
                if(data_shifter[1:0]==2'b10 || data_shifter[1:0]== 2'b11 )
                    cmd_err <= #`UDLY 1'b1;              
                else
                    cmd_err<= #`UDLY 1'b0;   
            `READ :
                 if(data_shifter[31:16]== 16'b0 || data_shifter[49:48]==2'b10)
                     cmd_err <= #`UDLY 1'b1;                 
                 else
                     if(crc16_err)
                         cmd_err <= #`UDLY 1'b1;
                     else
                         cmd_err <= #`UDLY 1'b0;  
            `ACCESS:
                 if(data_shifter[35:34] != 2'b00 )
                     cmd_err <= #`UDLY 1'b1;
                 else
                     if(crc16_err)
                         cmd_err <= #`UDLY 1'b1;
                     else
                         cmd_err <= #`UDLY 1'b0;
            `WRITE:
                 if(data_shifter[65:64]==2'b00 || data_shifter[47:32] != 16'd1)
                     cmd_err <= #`UDLY 1'b1;
                 else
                     if(crc16_err)
                         cmd_err <= #`UDLY 1'b1;
                     else
                         cmd_err <= #`UDLY 1'b0;
            `ERASE:
                if(data_shifter[49:48]==2'b00 || data_shifter[31:16] != 16'd1)
                     cmd_err <= #`UDLY 1'b1;
                 else
                     if(crc16_err)
                         cmd_err <= #`UDLY 1'b1;
                     else
                         cmd_err <= #`UDLY 1'b0;  
            `TID_WRITE,                 
            `SORT ,                                       
            `GET_RN ,                              
            `REFRESHRN,                     
            `LOCK ,            
            `KILL  :                  
                if(crc16_err)
                    cmd_err<= #`UDLY 1'b1;
                else
                    cmd_err<= #`UDLY 1'b0;
            default :
                cmd_err <= #`UDLY 1'b0;
        endcase
end  

//assign the value of parse error
assign parse_err = cmd_err | sort_err                 ;  

//use dec_done6 signal as parse_done
assign parse_done= dec_done6                          ;


//mask matching one by one while length_down minus!
always @(negedge tpp_clk  or negedge rst_del)     
begin
    if(!rst_del)
        length_down<=#`UDLY 4'd0;
		else if(cmd_head==`SORT)
		    if((!receive_sign)&&(cmd_cnt==6'd13))
				    length_down <= #`UDLY data_shifter[7:4];
		    else if((receive_sign)&&(cmd_cnt==6'd7))
				    length_down <= #`UDLY	length_down - 1'b1 ;
				else
				    length_down <= #`UDLY	length_down ;  
		else
				length_down <= #`UDLY	length_down ;						
end


//indicate wheather to receive the mask!
always @(length_down)
begin
    if(length_down!=0)
        receive_sign =  1'b1;
    else
        receive_sign =  1'b0;
end 


always @(posedge tpp_clk or negedge rst_del)
begin
    if(!rst_del)
        receive_flag <= #`UDLY 1'b0;
    else if(receive_sign && cmd_cnt==6'd7)
        receive_flag <= #`UDLY ~receive_flag;
    else
        receive_flag <= #`UDLY receive_flag;
end

always @(negedge tpp_clk or negedge rst_del)
begin
    if(!rst_del)
        receive_flag_delay <= #`UDLY 1'b0;
    else 
        receive_flag_delay <= #`UDLY receive_flag;
end

assign  mask_match_en = receive_flag^ receive_flag_delay;


//IE module requst,tell IE module coming is an operating of EEPROM!
always @(posedge tpp_clk or negedge rst_n)    
begin : PAR_IEREG_CONTROL
    if(!rst_n)                                                           
        parse_iereq<= #`UDLY 1'b0;
    else if((cmd_head==`SORT && receive_sign)|| cmd_head == `ACCESS)
        if((data_end_delay1==1'b1&&data_end_delay2==1'b0) && (addr_over != 1'b1))
            parse_iereq <= #`UDLY 1'b1;
        else
            parse_iereq <= #`UDLY 1'b0;    
    else
        parse_iereq <= #`UDLY 1'b0;
end


always @(posedge DOUB_BLF  or negedge rst_del)                     
begin 
    if(!rst_del)
        read_en_ctr <= #`UDLY 1'b0;             
    else if(cmd_head== `SORT && receive_sign)
        if((cmd_cnt == 6'd7) && (addr_over == 1'b0)) 
            read_en_ctr <= #`UDLY 1'b1;
        else
            read_en_ctr <= #`UDLY 1'b0;
    else if(cmd_head== `ACCESS )
        if((cmd_cnt == 6'd21) && (addr_over == 1'b0)) 
            read_en_ctr <= #`UDLY 1'b1;
        else
            read_en_ctr <= #`UDLY 1'b0;
    else
        read_en_ctr <= #`UDLY 1'b0;   
end

always @(posedge DOUB_BLF  or negedge rst_del)                     
begin 
    if(!rst_del)
        read_en <= #`UDLY 1'b0; 
    else if(read_en_ctr)
        read_en <= #`UDLY 1'b0; 
    else if(cmd_head== `SORT && receive_sign)
        if((cmd_cnt == 6'd7) && (addr_over == 1'b0)) 
            read_en <= #`UDLY 1'b1;
        else
            read_en <= #`UDLY 1'b0;
    else if(cmd_head == `ACCESS && In_OP_SE)
        if((cmd_cnt == 6'd21) && (addr_over == 1'b0)) 
            read_en <= #`UDLY 1'b1;
        else
            read_en <= #`UDLY 1'b0;       
    else
        read_en <= #`UDLY 1'b0;
end

always @(posedge tpp_clk or negedge rst_n)
begin
    if(!rst_n)
        mask_en <=#`UDLY 1'b0;                         
    else if(cmd_head==`SORT || cmd_head == `ACCESS)
        if(cmd_cnt==7'd12)
            mask_en <=#`UDLY 1'b1;
        else
            mask_en <=#`UDLY 1'b0 ; 
    else
        mask_en <=#`UDLY mask_en ;
end

assign len_zero = (|length);   //if length=16'b0,len_zero=1'b0.

//the result of mask matching!
//always @(negedge mask_match_en or negedge rst_del_addr_err or posedge mask_en)
always @(negedge mask_match_en or negedge rst_n or posedge mask_en)
begin : MASK_MATCH_EVAL                
    if(!rst_n)	      
        mask_match <= #`UDLY 1'b0;     
    else if(mask_en==1'b1)
        mask_match <= #`UDLY 1'b1; 
    else 
        if(cmd_head == `SORT)
            if(data_shifter[43:28]!=mtp_data)
                mask_match <= #`UDLY 1'b0;
            else
                mask_match <= #`UDLY mask_match;
        else
            mask_match <= #`UDLY mask_match;  				
end

// always@(posedge dec_done or negedge rst_n)
// begin
    // if(!rst_n)
        // get_rn_come <= #`UDLY 1'b0;
    // else if(cmd_head == `GET_RN)
        // get_rn_come <= #`UDLY 1'b1;
    // else
        // get_rn_come <= #`UDLY 1'b0;
// end

//if tag is in open or secured state, then pull In_OP_SE to high
assign In_OP_SE = (tag_state == `OPENSTATE|| 
	                 tag_state == `SECURED  || 
			             tag_state == `OPENKEY  || 
			             tag_state == `SECUREDKEY);

//--------------------------------------------------------
//access password match
//--------------------------------------------------------
////indicate the pwd is first 16 bits kill pwd
//assign killing1_match = (pwd_addr == 4'b0000)?1'b1:1'b0;
////indicate the pwd is second 16 bits kill pwd
//assign killing2_match = (pwd_addr == 4'b0001)?1'b1:1'b0;
////indicate the pwd is first 16 bits lock pwd			  
//assign locking1_match = (pwd_addr == 4'b0010)?1'b1:1'b0;
////indicate the pwd is second 16 bits lock pwd
//assign locking2_match = (pwd_addr == 4'b0011)?1'b1:1'b0;
////indicate the pwd is first 16 bits read pwd
//assign reading1_match = (pwd_addr == 4'b0110)?1'b1:1'b0;
////indicate the pwd is second 16 bits read pwd
//assign reading2_match = (pwd_addr == 4'b0111)?1'b1:1'b0;
////indicate the pwd is first 16 bits write pwd
//assign writing1_match = (pwd_addr == 4'b0100)?1'b1:1'b0;
////indicate the pwd is second 16 bits write pwd
//assign writing2_match = (pwd_addr == 4'b0101)?1'b1:1'b0;

//define a function to help judge kill/lock/read/write pwd match
function        pwd_match      ;
    input       In_OP_SE_f     ;
    input       pwd1_match     ;
    input       pwd2_match     ;
    input[ 7:0] cmd_head_f     ;
    input[15:0] data_shifter_f ; 
  	input[15:0] mtp_data_f     ;
  	input[15:0] rn16_f         ;
begin
    if(In_OP_SE_f)
	      if(pwd1_match != 1'b1|| 
		       pwd2_match != 1'b1)
		        if(cmd_head_f == `ACCESS)
				        if(data_shifter_f==(mtp_data_f ^ rn16_f))
                    pwd_match = 1'b1       ;
					      else
					          pwd_match = 1'b0       ;				
			      else if(cmd_head_f == `GET_RN)
			          pwd_match = pwd1_match         ;
            else
                pwd_match = 1'b0	             ;
		    else 
		        if(cmd_head_f == `ACCESS&& 
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
    else if(pwd_addr == 4'b0000)
	      killpwd1_match <= #`UDLY pwd_match(In_OP_SE           ,
		                                       killpwd1_match     ,
										                       killpwd2_match     ,
										                       cmd_head           ,
										                       data_shifter[31:16],
										                       mtp_data           ,
										                       rn16)              ;
	  else
	      killpwd1_match <= #`UDLY killpwd1_match               ;
end

always @(posedge dec_done or negedge rst_n)
begin: KILLPWD2_MATCH 
    if(!rst_n)	      
        killpwd2_match <= #`UDLY 1'b0                         ;    
    else if(pwd_addr == 4'b0001)
	      killpwd2_match <= #`UDLY pwd_match(In_OP_SE           ,
		                                       killpwd2_match     ,
										                       killpwd1_match     ,
										                       cmd_head           ,
										                       data_shifter[31:16],
										                       mtp_data           ,
										                       rn16)              ;
		else
		    killpwd2_match <= #`UDLY killpwd2_match               ;
end

assign killpwd_match = killpwd1_match & killpwd2_match        ;

//always @(posedge dec_done or negedge rst_n)
//begin                 
//    if(!rst_n)	      
//        killpwd1_match <= #`UDLY 1'b0;      
//    else if(tag_state == `OPENSTATE || tag_state == `SECURED || tag_state == `OPENKEY || tag_state == `SECUREDKEY)
//        if(killpwd1_match !=1'b1 ||killpwd2_match != 1'b1)
//            if(cmd_head == `ACCESS)// && get_rn_come== 1'b1 )
//                if(temp2== {12'b00,4'b0000})
//                    if(data_shifter[31:16]==(mtp_data ^ rn16))
//                        killpwd1_match <= #`UDLY 1'b1;
//                    else 
//                        killpwd1_match <= #`UDLY 1'b0;
//                else 
//                    killpwd1_match <= #`UDLY killpwd1_match ;
//            else if(cmd_head == `GET_RN)
//                killpwd1_match <= #`UDLY killpwd1_match;
//            else 
//                killpwd1_match <= #`UDLY 1'b0;
//        else
//            if(cmd_head == `ACCESS && temp2== {12'b00,4'b0000} && data_shifter[31:16]!=(mtp_data ^ rn16))
//                killpwd1_match <= #`UDLY 1'b0;
//            else
//                killpwd1_match <= #`UDLY killpwd1_match;    
//    else
//        killpwd1_match <= #`UDLY 1'b0;
//end
//
//always @(posedge dec_done or negedge rst_n)
//begin                 
//    if(!rst_n)	      
//        killpwd2_match <= #`UDLY 1'b0;      
//    else if(tag_state == `OPENSTATE || tag_state == `SECURED || tag_state == `OPENKEY || tag_state == `SECUREDKEY)
//        if(killpwd1_match !=1'b1 ||killpwd2_match != 1'b1)
//            if(cmd_head == `ACCESS)// && get_rn_come== 1'b1)
//                if(temp2== {12'b00,4'b0001} )
//                    if(data_shifter[31:16]==(mtp_data ^ rn16))
//                        killpwd2_match <= #`UDLY 1'b1;
//                    else
//                        killpwd2_match <= #`UDLY 1'b0;
//                else 
//                    killpwd2_match <= #`UDLY killpwd2_match ;
//            else if(cmd_head == `GET_RN)
//                killpwd2_match <= #`UDLY killpwd2_match;
//            else 
//                killpwd2_match <= #`UDLY 1'b0;
//        else
//            if(cmd_head == `ACCESS && temp2== {12'b00,4'b0001} && mtp_data != (data_shifter[31:16] ^ rn16))
//                killpwd2_match <= #`UDLY 1'b0;
//            else
//                killpwd2_match <= #`UDLY killpwd2_match;     
//    else
//        killpwd2_match <= #`UDLY 1'b0;
//end
//
//assign killpwd_match = killpwd1_match & killpwd2_match;


//access lock pwd match
always @(posedge dec_done or negedge rst_n)
begin: LOCKPWD1_MATCH 
    if(!rst_n)	      
        lockpwd1_match <= #`UDLY 1'b0                         ;    
    else if(pwd_addr == 4'b0010)
	      lockpwd1_match <= #`UDLY pwd_match(In_OP_SE           ,
		                                       lockpwd1_match     ,
										                       lockpwd2_match     ,
										                       cmd_head           ,
										                       data_shifter[31:16],
										                       mtp_data           ,
										                       rn16)              ;
    else
        lockpwd1_match <= #`UDLY lockpwd1_match               ;
end

always @(posedge dec_done or negedge rst_n)
begin: LOCKPWD2_MATCH 
    if(!rst_n)	      
        lockpwd2_match <= #`UDLY 1'b0                         ;    
    else if(pwd_addr == 4'b0011)
	      lockpwd2_match <= #`UDLY pwd_match(In_OP_SE           ,
		                                       lockpwd2_match     ,
										                       lockpwd1_match     ,
										                       cmd_head           ,
										                       data_shifter[31:16],
										                       mtp_data           ,
									                     	   rn16)              ;
		else
		    lockpwd2_match <= #`UDLY lockpwd2_match               ;
end

assign lockpwd_match = lockpwd1_match & lockpwd2_match        ;

//always @(posedge dec_done or negedge rst_n)
//begin                 
//    if(!rst_n)	      
//        lockpwd1_match <= #`UDLY 1'b0;      
//    else if(tag_state == `OPENSTATE || tag_state == `SECURED || tag_state == `OPENKEY || tag_state == `SECUREDKEY)
//        if(lockpwd1_match !=1'b1 ||lockpwd2_match != 1'b1)
//            if(cmd_head == `ACCESS)// && get_rn_come== 1'b1)
//                if(temp2== {12'b00,4'b0010} )
//                    if(data_shifter[31:16]==(mtp_data ^ rn16))
//                        lockpwd1_match <= #`UDLY 1'b1;
//                    else
//                        lockpwd1_match <= #`UDLY 1'b0;
//                else 
//                    lockpwd1_match <= #`UDLY lockpwd1_match ;
//            else if(cmd_head == `GET_RN)
//                lockpwd1_match <= #`UDLY lockpwd1_match;
//            else 
//                lockpwd1_match <= #`UDLY 1'b0;
//        else
//            if(cmd_head == `ACCESS && temp2== {12'b00,4'b0010} && data_shifter[31:16]!=(mtp_data ^ rn16))
//               lockpwd1_match <= #`UDLY 1'b0;
//            else
//               lockpwd1_match <= #`UDLY lockpwd1_match;    
//    else
//        lockpwd1_match <= #`UDLY 1'b0;
//end
//            
//    
//always @(posedge dec_done or negedge rst_n)
//begin                 
//    if(!rst_n)	      
//        lockpwd2_match <= #`UDLY 1'b0;      
//    else if(tag_state == `OPENSTATE || tag_state == `SECURED || tag_state == `OPENKEY || tag_state == `SECUREDKEY)
//        if(lockpwd1_match !=1'b1 ||lockpwd2_match != 1'b1)
//            if(cmd_head == `ACCESS)// && get_rn_come== 1'b1)
//                if(temp2== {12'b00,4'b0011})
//                    if( data_shifter[31:16]==(mtp_data ^ rn16))
//                        lockpwd2_match <= #`UDLY 1'b1;
//                    else
//                        lockpwd2_match <= #`UDLY 1'b0;
//                else 
//                    lockpwd2_match <= #`UDLY lockpwd2_match ;
//            else if(cmd_head == `GET_RN)
//                lockpwd2_match <= #`UDLY lockpwd2_match;
//            else 
//                lockpwd2_match <= #`UDLY 1'b0;
//        else
//            if(cmd_head == `ACCESS && temp2== {12'b00,4'b0011} && data_shifter[31:16]!=(mtp_data ^ rn16))
//                lockpwd2_match <= #`UDLY 1'b0;
//            else
//                lockpwd2_match <= #`UDLY lockpwd2_match;
//     
//    else
//        lockpwd2_match <= #`UDLY 1'b0;
//end
//
//assign lockpwd_match = lockpwd1_match & lockpwd2_match;

//access read pwd match
always @(posedge dec_done or negedge rst_n)
begin: RD_PWD1_MATCH 
    if(!rst_n)	      
        rd_pwd1_match <= #`UDLY 1'b0                         ;    
    else if(pwd_addr == 4'b0110)
	      rd_pwd1_match <= #`UDLY pwd_match(In_OP_SE           ,
		                                      rd_pwd1_match      ,
										                      rd_pwd2_match      ,
										                      cmd_head           ,
										                      data_shifter[31:16],
									                    	  mtp_data           ,
									                    	  rn16)              ;
    else
        rd_pwd1_match <= #`UDLY rd_pwd1_match                ;
end

always @(posedge dec_done or negedge rst_n)
begin: RD_PWD2_MATCH 
    if(!rst_n)	      
        rd_pwd2_match <= #`UDLY 1'b0                         ;    
    else if(pwd_addr == 4'b0111)
	      rd_pwd2_match <= #`UDLY pwd_match(In_OP_SE           ,
		                                      rd_pwd2_match      ,
										                      rd_pwd1_match      ,
									                     	  cmd_head           ,
										                      data_shifter[31:16],
									                    	  mtp_data           ,
									                    	  rn16)              ;
		else
		    rd_pwd2_match <= #`UDLY rd_pwd2_match                ;
end

assign rd_pwd_match = (read_pwd_status==1'b0)?1'b1:(rd_pwd1_match & rd_pwd2_match)    ;

//access write pwd match
always @(posedge dec_done or negedge rst_n)
begin: WR_PWD1_MATCH 
    if(!rst_n)	      
        wr_pwd1_match <= #`UDLY 1'b0                         ;    
    else if(pwd_addr == 4'b0100)
	      wr_pwd1_match <= #`UDLY pwd_match(In_OP_SE           ,
		                                      wr_pwd1_match      ,
										                      wr_pwd2_match      ,
								                    		  cmd_head           ,
										                      data_shifter[31:16],
									                    	  mtp_data           ,
									                     	  rn16)              ;
		else
		    wr_pwd1_match <= #`UDLY wr_pwd1_match                ;
end

always @(posedge dec_done or negedge rst_n)
begin: WR_PWD2_MATCH 
    if(!rst_n)	      
        wr_pwd2_match <= #`UDLY 1'b0                         ;    
    else if(pwd_addr == 4'b0101)
	      wr_pwd2_match <= #`UDLY pwd_match(In_OP_SE           ,
		                                      wr_pwd2_match      ,
									                    	  wr_pwd1_match      ,
								                    		  cmd_head           ,
								                    		  data_shifter[31:16],
								                     		  mtp_data           ,
									                     	  rn16)              ;
	  else
	      wr_pwd2_match <= #`UDLY wr_pwd2_match                ;
end

assign wr_pwd_match = (write_pwd_status==1'b0)?1'b1:(wr_pwd1_match & wr_pwd2_match)   ;


always @(posedge data_end or negedge rst_n)
begin : DR_RECEIVER
    if(!rst_n)
        DR <= #`UDLY 2'b0;
    else if(cmd_head == `QUERY) 
        DR <= #`UDLY data_shifter[3:2];
    else
        DR <= #`UDLY DR;
end

//parameter receiver
always@(data_shifter[7:5] or cmd_head or condition or target)
begin
    if(cmd_head == `QUERY)
        begin
            condition = data_shifter[7:6];
            target = data_shifter[5];
        end 
    else
        begin
            condition = 2'b00;
            target    = 1'b0 ;    
        end 
end 

always@(posedge data_end_delay1 or negedge rst_n)  
begin
    if(!rst_n)
        trext <= #`UDLY 1'b0;
    else if(cmd_head == `QUERY)
        trext <= #`UDLY data_shifter[4];
    else
        trext <= #`UDLY trext;
end 


//a sign given to div decide when to calculate the divide coefficient!
always @(posedge tpp_clk or negedge rst_n)
begin
    if(!rst_n)
        set_m <= #`UDLY 1'b0;
    else if((cmd_head == `QUERY) && (cmd_cnt==6'd7))
        set_m <= #`UDLY 1'b1;
    else
        set_m <= #`UDLY 1'b0;
end

always@(posedge data_end or negedge rst_n)
begin
    if(!rst_n)
        M <= #`UDLY 2'b00;
    else if(cmd_head==`QUERY)
        M <= #`UDLY data_shifter[1:0];
    else
        M <= #`UDLY M;
end


always @(posedge dec_done or negedge rst_n)
begin
    if(!rst_n)
        divide_position <= #`UDLY 1'b0;
    else if(cmd_head == `DIVIDE)
        divide_position <= #`UDLY data_shifter[0];
    else 
        divide_position <= #`UDLY divide_position;
end



always @(posedge dec_done or negedge rst_del)      
begin
    if(!rst_del)
        rn1_update <= #`UDLY 1'b0;
    else if(cmd_head == `QUERY || cmd_head == `DIVIDE || cmd_head == `DISPERSE || cmd_head == `SHRINK) 
        rn1_update <= 1'b1;
    else
        rn1_update <= #`UDLY 1'b0;
end

//rn_match judging!
always @(posedge dec_done3 or negedge rst_del)        
begin 
    if(!rst_del)                                       
        rn_match <= #`UDLY 1'b0;
    else if(cmd_head==`ACK || cmd_head==`GET_RN || cmd_head==`REFRESHRN || cmd_head==`ACCESS || 
            cmd_head == `READ || cmd_head==`WRITE ||cmd_head== `ERASE || cmd_head == `LOCK || cmd_head== `KILL)      
        if({handle[15:5],crc5_back} == data_shifter[15:0])
            rn_match <= #`UDLY 1'b1;
        else
            rn_match <=  #`UDLY 1'b0; 
    else
        rn_match <=  #`UDLY 1'b0;                                                        
end

   
//cmd_end to indicate the end of a command,module DECODER output a dec_done when receive this signal!
always @(posedge tpp_clk or negedge rst_del)
begin
    if(!rst_del)
        cmd_end <= #`UDLY 1'b0;
    else if(head_finish== 1'b1)   
            case(cmd_head)
                `TID_WRITE:
                    if(cmd_cnt == 7'd24)
                        cmd_end <= #`UDLY 1'b1;
                    else
                        cmd_end <= #`UDLY cmd_end;
                `TID_DONE:
                    if(cmd_head==`TID_DONE)
                        cmd_end <= #`UDLY 1'b1;
                    else
                        cmd_end <= #`UDLY cmd_end;
                `SORT:
                     if(cmd_cnt == 7'd7 && data_end == 1'b1 && length_down == 4'b0)  
                         cmd_end <= #`UDLY 1'b1;
                     else
                         cmd_end <= #`UDLY cmd_end;
                `QUERY: 
                    if(cmd_cnt == 7'd11)
                        cmd_end <= #`UDLY 1'b1;
                    else
                        cmd_end <= #`UDLY cmd_end;
                `DIVIDE :
                    if(head_finish)
                        cmd_end <= #`UDLY 1'b1;
                    else
                        cmd_end <= #`UDLY 1'b0;
                `QUERYREP:
                    if(cmd_head==`QUERYREP)
                        cmd_end <= #`UDLY 1'b1;
                    else
                        cmd_end <= #`UDLY cmd_end;
                `DISPERSE:
                    if(cmd_head==`DISPERSE)
                        cmd_end <= #`UDLY 1'b1;
                    else
                        cmd_end <= #`UDLY cmd_end;     
                `SHRINK:
                    if(cmd_head==`SHRINK)
                        cmd_end <= #`UDLY 1'b1;
                    else
                        cmd_end <= #`UDLY cmd_end;            
                `ACK:
                    if(cmd_cnt == 7'd7)
                        cmd_end <= #`UDLY 1'b1;
                    else   
                        cmd_end <= #`UDLY cmd_end;
                `NAK :
                    if(cmd_head == `NAK)
                        cmd_end <= #`UDLY 1'b1;
                    else 
                        cmd_end <= #`UDLY 1'b0;           	            				                     	                
                `GET_RN:
                		if(cmd_cnt == 7'd15)
                				cmd_end <= #`UDLY 1'b1;
                		else
                				cmd_end <= #`UDLY cmd_end;												            
                `REFRESHRN:
                    if(cmd_cnt == 7'd15)
                        cmd_end <= #`UDLY 1'b1;
                    else 
                        cmd_end <= #`UDLY 1'b0;
                `ACCESS   :
                    if(cmd_cnt == 7'd25)
                        cmd_end <= #`UDLY 1'b1;
                    else
                        cmd_end <= #`UDLY 1'b0;
                `READ:
                		if(cmd_cnt==7'd32)
                		    cmd_end <= #`UDLY 1'b1;
                		else
                		    cmd_end <= #`UDLY cmd_end;
                `WRITE:
                		if(cmd_cnt==7'd40)
                		    cmd_end <= #`UDLY 1'b1;
                		else
                		    cmd_end <= #`UDLY cmd_end;
                `ERASE:
                		if(cmd_cnt==7'd32)
                		    cmd_end <= #`UDLY 1'b1;
                		else
                		    cmd_end <= #`UDLY cmd_end;
                `LOCK:
                		if(cmd_cnt==7'd17)
                		    cmd_end <= #`UDLY 1'b1;
                		else
                		    cmd_end <= #`UDLY cmd_end;           
                `KILL:
                    if(cmd_cnt == 7'd15)
                        cmd_end <= #`UDLY 1'b1;
                    else
                        cmd_end <= #`UDLY 1'b0;                          		           
                default:
                    cmd_end <= #`UDLY cmd_end;
            endcase          
    else                                     
        cmd_end <= #`UDLY cmd_end;     
end


//--------------------------------------------------------
//CRC16 check
//--------------------------------------------------------

function [15:0] nextCRC16_D2;
    input [1:0] Data  ;
    input [15:0] CRC   ;
    reg   [15:0] D     ;
    reg   [15:0] C     ;
    reg   [15:0] NewCRC;
begin
    D = Data;
    C = CRC;
    NewCRC[0] = D[0] ^ C[14];
    NewCRC[1] = D[1] ^ C[15];
    NewCRC[2] = C[0];
    NewCRC[3] = C[1];
    NewCRC[4] = C[2];
    NewCRC[5] = D[0] ^ C[3] ^ C[14];
    NewCRC[6] = D[1] ^ C[4] ^ C[15];
    NewCRC[7] = C[5];
    NewCRC[8] = C[6];
    NewCRC[9] = C[7];
    NewCRC[10] = C[8];
    NewCRC[11] = C[9];
    NewCRC[12] = D[0] ^ C[10] ^ C[14];
    NewCRC[13] = D[1] ^ C[11] ^ C[15];
    NewCRC[14] = C[12];
    NewCRC[15] = C[13];
    nextCRC16_D2 = NewCRC;
end
endfunction

//call fuction nextCRC16_D2 to check crc16! 
always @(posedge tpp_clk or negedge rst_del)
begin :CRC16_CHECK1
    if(!rst_del)
        crc16_Q1 <= #`UDLY 16'hFFFF;
    else if(crc16_en1 == 1'b1)       
        crc16_Q1 <= #`UDLY nextCRC16_D2(tpp_data,crc16_Q1);
    else crc16_Q1 <= #`UDLY 16'hFFFF;//It is control by tpp_clk!
end


always @(posedge tpp_clk or negedge rst_del)
begin
    if(!rst_del)
        crc16_en1 <= 1'b1;
    else if(head_finish ==1'b1 && (cmd_head == `DIVIDE || cmd_head == `QUERYREP || cmd_head == `TID_DONE ||
    cmd_head== `DISPERSE || cmd_head == `SHRINK || cmd_head == `ACK || cmd_head == `NAK))
        crc16_en1 <= 1'b0;
    else
        crc16_en1 <= 1'b1;
end

assign crc16_err = (crc16_Q1!=16'h1D0F);

endmodule