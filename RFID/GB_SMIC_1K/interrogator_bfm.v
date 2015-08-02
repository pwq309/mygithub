// *******************************************************************
// COPYRIGHT, Xi'an XDU Radio-frequency IC Co.,Ltd 
// All rights reserved.
//
// IP NAME      :  RFID
// File name    :  interrogator_bfm.v
// Module name  :  INTERROGATOR_BFM
//
// Author       : 
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

module INTERROGATOR_BFM	(
                         tag_data,
                         data_to_tag
						 
                         );
                         
//####################################//
//            Port Define             //
//####################################//
input           tag_data;
output          data_to_tag;
reg             data_to_tag;

//####################################//
//            Inner Singal            //
//####################################//
reg                           send_cmd_en;

reg    [15:0]                 NewCRC16;
reg    [15:0]                 CRC16    ; // register used for crc16 calc,
reg    [15:0]                 CRC16_0  ;
reg    [15:0]                 NewCRC16_0;
reg    [15:0]                 NewCRC16_1;
reg    [15:0]                 rx_crc16_data;
reg                           cmd_send_w;

reg    [`Mask_Len-1:0]        Mask_value;
                              
reg    [`Query_Len-1:0]       Query_cmd;                                               
reg    [3:0]                  DR_value ;
reg                           Trext_value    ;
reg    [1:0]                  M_value  ;    
reg    [`Divide_Len-1:0]      Divide_cmd;
reg    [`QueryRep_Len-1:0]    QueryRep_cmd;
reg    [`Disperse_Len-1:0]    Disperse_cmd;
reg    [`Shrink_Len-1:0]      Shrink_cmd;
reg    [`Ack_Len-1:0]         Ack_cmd  ; 
reg    [`Nak_Len-1:0]         Nak_cmd  ;
reg    [`Get_RN_Len-1:0]      Get_RN_cmd;
reg    [`RefreshRN_Len-1:0]   REFRESHRN_cmd;
reg    [`Access_Len-1:0]      Access_cmd;
reg    [`Get_SecPara_Len-1:0] Get_SecPara_cmd;
reg    [`Req_XAuth_Len-1:0]   Req_XAuth_cmd;  
reg    [`RW_XAuth_Len-1:0]    RW_XAuth_cmd;
reg    [`Req_SAuth_Len-1:0]   Req_SAuth_cmd;
reg    [`Mul_SAuth_Len-1:0]   Mul_SAuth_cmd;
reg    [`RefreshRN_Len-1:0]   RefreshRN_cmd;
reg    [15:0]                 Length_sec;
reg    [15:0]                 rn16_interrogator;
reg    [15:0]                 SK;

//reg    [`Req_RW_Len-1:0]      Req_RW_cmd;                
//reg    [`Req_LC_Len-1:0]      Req_LC_cmd;   
//reg    [`Req_KL_Len-1:0]      Req_KL_cmd;
//reg    [`Req_RE_Len-1:0]      Req_RE_cmd;
reg    [`Read_Len-1 :0]       Read_cmd  ;
reg    [`Write_Len-1:0]       Write_cmd ;
reg    [`Erase_Len-1:0]       Erase_cmd ;
reg    [`Lock_Len-1:0 ]       Lock_cmd  ;
reg    [`Kill_Len-1:0 ]       Kill_cmd  ;
reg    [255:0]                Sec_Com_cmd;
                              
                              
reg    [15:0]                       r_words_cnt;   
                              
integer                       TC;   
integer                       TC2;
integer                       TC3;
integer                       TC4;
integer                       TC7; 
integer                       LAST_EDGE;      
integer                       Tpri_real_FM0;     
integer                       Tpri_real_Miller;
integer                       Tpri_real;
integer                       Tpri_calc;

integer                        Tpri_real_LB     ; // real symbol length used by tag, lower bdry
integer                        Tpri_real_UB     ; // real symbol length used by tag, upper bdry
integer                        half_Tpri_LB     ; // half of real symbol length used by tag, lower bdry
integer                        half_Tpri_UB     ; // half of real symbol length used by tag, upper bdry
integer                        oah_Tpri         ; // one and half symbol length 
integer                        oah_Tpri_LB      ; // lower bound
integer                        oah_Tpri_UB      ; // upper bound
integer                        FT               ;
                               
reg                            BLF_OK           ;

reg                            restored_clk     ; // the clk restore from tag_data signal by our BFM
                               
integer                        T1_FM0 ;
integer                        T1_Miller;
integer                        T1;          
                               
integer                        MIN_T1           ;
integer                        MAX_T1           ;
integer                        MIN_T3           ;
integer                        MIN_T4           ;
                               
reg                            FM0_dec_en       ; // FM0 receive enable
reg                            FM0_decoding     ; // FM0_decoding!
integer                        FM0_clk_cnt      ; // count how many cycles pass by, when tag_data is high
                               
reg                            Miller_dec_en    ; //Miller receive enable
reg                            Miller_decoding  ; //Miller decoding
integer                        Miller_cnt       ;
integer                        Miller_ending_cnt;

// data temp register
reg [15:0]                     Miller8_temp     ; // temporarily storing the data captured by decode process, ini-->16'b0;
reg [7:0]                      Miller4_temp     ;
reg [3:0]                      Miller2_temp     ;
                               
reg        [`TDATA_BUF_LEN-1:0] tdata_buffer     ;
reg        [15 :0]             rn16_Query           ;
reg        [15 :0]             rn16_Get_RN      ;

reg        [15: 0]             SNT              ;
reg        [15: 0]             RNT              ;
wire        [15:0]              NT               ;
reg        [15:0]              KT               ;
reg        [15:0]              BNT              ;
wire       [15:0]              RBNT             ;
reg                            SNT_done         ;
                               
reg                            rxed_symbol      ; // every bit decoded from tag's bitstream 
integer                        symbol_cnt       ; // count the num of received symbol
integer                        i                ; //to reverse BNT!!!   
integer                        file_result      ;                          
time                           send_done        ;
//####################################//
//            Main Code               //
//####################################//                         

//####################################//
//         Parameter Init             //
//####################################//
initial
begin
    data_to_tag     = 1'b1       ;    
    send_cmd_en     = 1'b0       ;
    CRC16           = 16'hFFFF   ;
    TC              = 6250       ;
    cmd_send_w      = 1'b0        ;
            
    rn16_Query          = 16'b0;
    rn16_Get_RN         = 16'b0;
    SNT                 = 16'b0;
    KT                  = 16'h3014;
    SK                  = 16'h3014;
    BNT                 = 16'b0;
  
    
    FM0_dec_en    = 1'b0        ; // FM0 receive enable
    FM0_decoding  = 0           ; // FM0_decodeing!
//    // tdata_bits_num= 0         ; // denotes how many bits should receive in decode process,changed by Control or handly 
    rxed_symbol   = 0           ; // received symbol value is 0
    symbol_cnt    = 1'b1        ; // received symbol cnt value is 1
    tdata_buffer  = `TDATA_BUF_LEN'd0      ; // received tag data,propose 200 bits totally max! 
    
// Tpri group
    FM0_clk_cnt   = 0           ;
    FT            = 0           ; // Frequency tolerance
    Tpri_calc     = 0           ; // caled symbol length               
    Tpri_real     = 4160        ; // real symbol length used by tag,presume it is 3125ns
    Tpri_real_LB  = 0           ; // real symbol length used by tag, lower bound
    Tpri_real_UB  = 0           ; // real symbol length used by tag, upper bound
    half_Tpri_LB  = 0           ; // half of real symbol length used by tag, lower bound
    half_Tpri_UB  = 0           ; // half of real symbol length used by tag, upper bound
    oah_Tpri      = 0           ; // one and half symbol length 
    oah_Tpri_LB   = 0           ; // lower bound
    oah_Tpri_UB   = 0           ; // upper bound
    send_done     = 0           ; // time event shuolde be sampled at every cmd send done
// link timing group

    MIN_T1        = 0           ;
    MAX_T1        = 0           ;   
    MIN_T3        = 0           ;
    MIN_T4        = 0           ;
    Mask_value    = 128'h0514_0514_0514_0514_0514_0514_0514_0514;//本询问机SORT命令中编入的Mask是Mask_value的[47:0]
end

initial
begin
    TC2=TC*2;
    TC3=TC*3;
    TC4=TC*4;
    TC7=TC*7;
end
      

//#####################################//
//         Encode & Cmd_send           //
//#####################################//
      
task send_preamble;
begin
    send_cmd_en = 1'b0;
    data_to_tag = 1'b0;
    #12500   data_to_tag = 1'b1;
    #TC7     data_to_tag = 1'b0;
    #TC      data_to_tag = 1'b1;
    #TC      data_to_tag = 1'b0;
    #TC      data_to_tag = 1'b1;
    send_cmd_en = 1'b1;
end 
endtask


// ----------------------------------------------------------
// Sort send tasks
// ----------------------------------------------------------
// the send_Sort task excuted a fuction of sending
// sort cmd,it is called in the following way:
// pack_Sort(Membank,Rule,Pointer,Length)
// Sort cmd has Membank,Rule,Pointer,Length,Mask_value as its Parameter
// CRC16
task send_Sort;
input           [5:0] MemBank;
input           [3:0] Target_Sort;
input           [1:0] Rule;
input           [15:0]Pointer;    
input           [7:0] Length;
reg             [7:0] cmd_head;
integer               bit_cnt;
begin
    cmd_head = `SORT;
    CRC16 = 16'hFFFF;        
    send_preamble;
    send_cmd_en = 1;
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"Sending Select cmd bit...\n");
    `endif
    if(send_cmd_en)
    begin
        bit_cnt = 'd8;
        repeat(4)
        begin
            send_cmd_bit({cmd_head[bit_cnt-1],cmd_head[bit_cnt-2]});
            crc16_calc({cmd_head[bit_cnt-1],cmd_head[bit_cnt-2]});
            bit_cnt = bit_cnt - 2;
        end
        bit_cnt = 6;     
        repeat(3)
        begin
            send_cmd_bit({MemBank[bit_cnt-1],MemBank[bit_cnt-2]});
            crc16_calc({MemBank[bit_cnt-1],MemBank[bit_cnt-2]});
            bit_cnt = bit_cnt - 2;
        end 
        bit_cnt = 4;     
        repeat(2)
        begin
            send_cmd_bit({Target_Sort[bit_cnt-1],Target_Sort[bit_cnt-2]});
            crc16_calc({Target_Sort[bit_cnt-1],Target_Sort[bit_cnt-2]});
            bit_cnt = bit_cnt - 2;
        end 
        bit_cnt = 2;
        repeat(1)
        begin
            send_cmd_bit({Rule[bit_cnt-1],Rule[bit_cnt-2]});
            crc16_calc({Rule[bit_cnt-1],Rule[bit_cnt-2]});
            bit_cnt = bit_cnt - 2;
        end
        bit_cnt = 16;
        repeat(8)
        begin
            send_cmd_bit({Pointer[bit_cnt-1],Pointer[bit_cnt-2]});
            crc16_calc({Pointer[bit_cnt-1],Pointer[bit_cnt-2]});
            bit_cnt = bit_cnt - 2;
        end
        bit_cnt = 8;
        repeat(4)
        begin
            send_cmd_bit({Length[bit_cnt-1],Length[bit_cnt-2]});
            crc16_calc({Length[bit_cnt-1],Length[bit_cnt-2]});
            bit_cnt = bit_cnt - 2;
        end        
        bit_cnt = 1;
        repeat(Length[7:1])
        begin
            send_cmd_bit({Mask_value[`Mask_Len-bit_cnt],Mask_value[`Mask_Len-bit_cnt-1]});
            crc16_calc({Mask_value[`Mask_Len-bit_cnt],Mask_value[`Mask_Len-bit_cnt-1]});
            bit_cnt = bit_cnt + 2;
        end
        
        bit_cnt = 16;
        repeat(8)
        begin
            send_cmd_bit({~CRC16[bit_cnt-1],~CRC16[bit_cnt-2]});
            bit_cnt = bit_cnt - 2;
        end
    end
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"Select cmd send done.\n");
    `endif
    send_cmd_en = 0;
end
endtask



task pack_Query; 
input [1:0] condition;
input [1:0] session;
input       target ;
input       trext  ;
input [3:0] DR     ;
input [1:0] M      ;
integer     bit_cnt         ; 
begin
    Query_cmd = 36'b0;
    Query_cmd = {`QUERY,condition,session,target,trext,DR,M,16'b0};
    bit_cnt=`Query_Len-1;
    CRC16=16'hFFFF;  
    while(bit_cnt>16)    
    begin
    # 100 crc16_calc({Query_cmd[bit_cnt],Query_cmd[bit_cnt-1]});
    bit_cnt=bit_cnt-2;
    end
    Query_cmd = {Query_cmd[`Query_Len-1:16],~CRC16};
end
endtask


task send_Query;  
input [1:0] Condition;
input [1:0] Session;
input       Target ;
input       Trext  ;
input [3:0] DR     ;
input [1:0] M      ;
integer     bit_cnt; // bit send index
begin
    bit_cnt = `Query_Len;
    DR_value = DR;
    Trext_value =Trext;
    M_value  = M;
    cmd_send_w = 1'b0;
    pack_Query(Condition,Session,Target,Trext,DR,M);
    data_to_tag = 1;   
    send_preamble;
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"sending Query cmd bit ...\n");
    `endif    
    if(send_cmd_en)
    begin
        repeat(`Query_Len/2)
        begin
            send_cmd_bit({Query_cmd[bit_cnt-1],Query_cmd[bit_cnt-2]});
            bit_cnt = bit_cnt - 2;
        end    
    end
    LAST_EDGE=$time;
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"Query cmd send done @ %t\n",$time);
    `endif
    send_cmd_en = 0;
end
endtask


// ----------------------------------------------------------
// Divide command pack and send tasks
// ----------------------------------------------------------
// the pack_Divide task excuted a function of packup
// Preview cmd,it is called in the following way:
// pack_Divide(divide_position);
// has no parameters;
task pack_Divide; //code ok
input [1:0]    divide_position;
input [1:0]    session;
begin    
    Divide_cmd = 6'b0;
    Divide_cmd = {`DIVIDE,divide_position,session};       
end
endtask


// the send_Divide task excuted a function of sending
// Divide cmd,it is called in the following way:
// send_Divide;
// has no parameters.

task send_Divide;  //code ok
input [1:0]    divide_position;
input [1:0]    session ;
integer     bit_cnt;
begin
    bit_cnt = `Divide_Len;
    pack_Divide(divide_position,session);
    data_to_tag = 1;
    // tdata_bits_num = 'd16; // ask decode section waiting for 16bit RN16 data 
    send_preamble;
    cmd_send_w = 1'b0;
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"Sending Divide cmd bit...\n");
    `endif
    if(send_cmd_en)
    begin
        repeat(`Divide_Len/2)
        begin
            send_cmd_bit({Divide_cmd[bit_cnt-1],Divide_cmd[bit_cnt-2]});
            bit_cnt = bit_cnt - 2;
        end
    end
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"Divide cmd send done.\n");
    `endif
    send_cmd_en = 0;
end
endtask

// ----------------------------------------------------------
// QueryRep command pack and send tasks
// ----------------------------------------------------------
// the send_QueryRep task excuted a function of sending
// QueryRep cmd,it is called in the following way:
// send_QueryRep;
// no parameter
// no crc
task pack_QueryRep; //code ok
input  [1:0]     session;
integer   bit_cnt;
begin
    QueryRep_cmd = 4'b0;
    QueryRep_cmd = {`QUERYREP,session};    
end
endtask


// the send_QueryRep task excuted a function of sending
// QueryRep cmd,it is called in the following way:
// send_QueryRep;
// no parameter
// no crc
task send_QueryRep;  //code ok
input  [1:0]     session;
integer     bit_cnt;
begin
    bit_cnt = `QueryRep_Len;
    pack_QueryRep(session);
    data_to_tag = 1;
    // tdata_bits_num = 'd16; // ask decode section waiting for 16bit RN16 data 
    send_preamble;
    cmd_send_w = 1'b0;
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"Sending QueryRep cmd bit...\n");
    `endif
    if(send_cmd_en)
    begin
        repeat(`QueryRep_Len/2)
        begin
            send_cmd_bit({QueryRep_cmd[bit_cnt-1],QueryRep_cmd[bit_cnt-2]});
            bit_cnt = bit_cnt - 2;
        end
    end
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"QueryRep cmd send done.\n");
    `endif
    send_cmd_en = 0;
end
endtask


// ----------------------------------------------------------
// Disperse command pack and send tasks
// ----------------------------------------------------------
// the pack_Disperse task excuted a function of packup
// Disperse cmd,it is called in the following way:
// pack_Disperse;
// has no parameters;
task pack_Disperse; //code ok
input  [1:0]   session;
begin    
    Disperse_cmd = 6'b0;
    Disperse_cmd = {`DISPERSE,session};       
end
endtask


// the send_Disperse task excuted a function of sending
// Disperse cmd,it is called in the following way:
// send_Disperse;
// has no parameters.

task send_Disperse;  //code ok
input  [1:0]     session;
integer     bit_cnt;
begin
    bit_cnt = `Disperse_Len;
    pack_Disperse(session);
    data_to_tag = 1;
    // tdata_bits_num = 'd16; // ask decode section waiting for 16bit RN16 data 
    send_preamble;
    cmd_send_w = 1'b0;
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"Sending Preview cmd bit...\n");
    `endif
    if(send_cmd_en)
    begin
        repeat(`Disperse_Len/2)
        begin
            send_cmd_bit({Disperse_cmd[bit_cnt-1],Disperse_cmd[bit_cnt-2]});
            bit_cnt = bit_cnt - 2;
        end
    end
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"Disperse cmd send done.\n");
    `endif
    send_cmd_en = 0;
end
endtask

// ----------------------------------------------------------
// Shrink command pack and send tasks
// ----------------------------------------------------------
// the pack_Shrink task excuted a function of packup
// Shrink cmd,it is called in the following way:
// pack_Shrink;
// has no parameters;
task pack_Shrink; //code ok
input  [1:0]   session;
begin    
    Shrink_cmd = 6'b0;
    Shrink_cmd = {`SHRINK,session};       
end
endtask


// the send_Shrink task excuted a function of sending
// Divide cmd,it is called in the following way:
// send_Shrink;
// has no parameters.

task send_Shrink;  //code ok
input  [1:0]     session;
integer     bit_cnt;
begin
    bit_cnt = `Shrink_Len;
    pack_Shrink(session);
    data_to_tag = 1;
    // tdata_bits_num = 'd16; // ask decode section waiting for 16bit RN16 data 
    send_preamble;
    cmd_send_w = 1'b0;
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"Sending Shrink cmd bit...\n");
    `endif
    if(send_cmd_en)
    begin
        repeat(`Shrink_Len/2)
        begin
            send_cmd_bit({Shrink_cmd[bit_cnt-1],Shrink_cmd[bit_cnt-2]});
            bit_cnt = bit_cnt - 2;
        end
    end
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"Shrink cmd send done.\n");
    `endif
    send_cmd_en = 0;
end
endtask


// ----------------------------------------------------------
// Ack command pack and send tasks
// ----------------------------------------------------------
// the pack_Ack task excuted a function of packup
// Ack cmd,it is called in the following way:
// pack_Ack;
// has handle(rn11+crc5) as parameters;
task pack_Ack; //code ok
begin
    Ack_cmd = 0;
    Ack_cmd = {`ACK,rn16_Query};
end
endtask

// the send_Ack task excuted a function of sending
// Ack cmd,it is called in the following way:
// send_Ack;
// has handle(rn11+crc5) as its parameters.
task send_Ack; //code ok
integer bit_cnt;
begin
    bit_cnt = `Ack_Len;
    pack_Ack;
    data_to_tag = 1;
    cmd_send_w = 1'b0;
    // tdata_bits_num  waiting to be detemined
    send_preamble;
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"Sending ACK command bit ...\n");
    `endif
    if(send_cmd_en)
    begin
        repeat(`Ack_Len/2)
        begin
            send_cmd_bit({Ack_cmd[bit_cnt-1],Ack_cmd[bit_cnt-2]});
            bit_cnt = bit_cnt - 2;
        end
    end
    LAST_EDGE=$time;
    send_cmd_en = 0;
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"ACK command send done.\n");
    `endif
end
endtask


// ----------------------------------------------------------
// Nak command pack and send tasks
// ----------------------------------------------------------
// the pack_Nak task excuted a function of packup
// Nak cmd,it is called in the following way:
// pack_Nak;
// has no parameters;
task pack_Nak; //code ok
begin
    Nak_cmd = 0;
    Nak_cmd = {`NAK};
end
endtask

// the send_Nak task excuted a function of sending
// Ack cmd,it is called in the following way:
// send_Ack;
// has no parameters.
task send_Nak; //code ok
integer bit_cnt;
begin
    bit_cnt = `Nak_Len;
    pack_Nak;
    data_to_tag = 1;
    cmd_send_w = 1'b0;
    // tdata_bits_num  waiting to be detemined
    send_preamble;
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"Sending Nak command bit ...\n");
    `endif
    if(send_cmd_en)
    begin
        repeat(`Nak_Len/2)
        begin
            send_cmd_bit({Nak_cmd[bit_cnt-1],Nak_cmd[bit_cnt-2]});
            bit_cnt = bit_cnt - 2;
        end
    end
    LAST_EDGE=$time;
    send_cmd_en = 0;
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"Nak command send done.\n");
    `endif
end
endtask





// the send_Get_RN task excuted a function of send
// Get_RN cmd,it is called in the following way:
// send_Get_RN
// has a random number and rn16_Query  as its parameters.
task pack_Get_RN;
integer     bit_cnt;
begin
    bit_cnt = `Get_RN_Len-1;
    Get_RN_cmd = 0;
    Get_RN_cmd = {`GET_RN,rn16_Query,16'b0};
    CRC16 = 16'hFFFF;
    while(bit_cnt>16)    
        begin
            # 100 crc16_calc({Get_RN_cmd[bit_cnt],Get_RN_cmd[bit_cnt-1]});
            bit_cnt=bit_cnt-2;
        end
    Get_RN_cmd = {Get_RN_cmd[`Get_RN_Len-1:16],~CRC16};
end
endtask


// the send_Get_RN task excuted a function of send
// Get_RN cmd,it is called in the following way:
// send_Get_RN
// has rn16_Query num as its parameters.
task send_Get_RN;
integer     bit_cnt;
begin
    bit_cnt = `Get_RN_Len;
    pack_Get_RN;
    data_to_tag = 1;
    cmd_send_w = 1'b0;
    send_preamble;
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"Sending Get_RN cmd bit...\n");
    `endif
    if(send_cmd_en)
    begin
        repeat(`Get_RN_Len/2)
        begin
            send_cmd_bit({Get_RN_cmd[bit_cnt - 1],Get_RN_cmd[bit_cnt - 2]});
            bit_cnt = bit_cnt-2;
        end
    end
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"Get_RN cmd send done.\n");
    `endif
    send_cmd_en = 0;
end
endtask

//////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////

task pack_REFRESHRN;
integer     bit_cnt;
begin
    bit_cnt = `RefreshRN_Len-1;
    REFRESHRN_cmd = 0;
    REFRESHRN_cmd = {`REFRESHRN,rn16_Query,16'b0};
    CRC16 = 16'hFFFF;
    while(bit_cnt>16)    
        begin
            # 100 crc16_calc({REFRESHRN_cmd[bit_cnt],REFRESHRN_cmd[bit_cnt-1]});
            bit_cnt=bit_cnt-2;
        end
    REFRESHRN_cmd = {REFRESHRN_cmd[`RefreshRN_Len-1:16],~CRC16};
end
endtask



task send_REFRESHRN;
integer     bit_cnt;
begin
    bit_cnt = `RefreshRN_Len;
    pack_REFRESHRN;
    data_to_tag = 1;
    cmd_send_w = 1'b0;
    send_preamble;
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"Sending REFRESHRN cmd bit...\n");
    `endif
    if(send_cmd_en)
    begin
        repeat(`RefreshRN_Len/2)
        begin
            send_cmd_bit({REFRESHRN_cmd[bit_cnt - 1],REFRESHRN_cmd[bit_cnt - 2]});
            bit_cnt = bit_cnt-2;
        end
    end
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"RefreshRN cmd send done.\n");
    `endif
    send_cmd_en = 0;
end
endtask



// the send_Access task excuted a function of send
// Access cmd,it is called in the following way:
// send_Access
// has rn16_Req_RN num as its parameters.
task pack_Access;
input    [5:0]  MemBank;
input    [3:0]  acc_pwd;
input    [15:0] password;
integer     bit_cnt;
begin
    bit_cnt = `Access_Len-1;
    Access_cmd = 0;
    Access_cmd = {`ACCESS,MemBank,acc_pwd,password^rn16_Get_RN ,rn16_Query, 16'b0};
    CRC16 = 16'hFFFF;
    while(bit_cnt>16)    
        begin
            # 100 crc16_calc({Access_cmd[bit_cnt],Access_cmd[bit_cnt-1]});
            bit_cnt=bit_cnt-2;
        end
    Access_cmd = {Access_cmd[`Access_Len-1:16],~CRC16};
end
endtask


// the send_Access task excuted a function of send
// Kill cmd,it is called in the following way:
// send_Kill
// has rn16_Req_RN num as its parameters.
task send_Access;
input    [5:0]  MemBank;
input    [3:0]  acc_pwd;
input    [15:0] Password;
integer     bit_cnt;
begin
    bit_cnt = `Access_Len;
    pack_Access(MemBank,acc_pwd,Password);
    data_to_tag = 1;
    cmd_send_w = 1'b0;
    send_preamble;
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"Sending Access cmd bit...\n");
    `endif
    if(send_cmd_en)
    begin
        repeat(`Access_Len/2)
        begin
            send_cmd_bit({Access_cmd[bit_cnt - 1],Access_cmd[bit_cnt - 2]});
            bit_cnt = bit_cnt-2;
        end
    end
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"Access cmd send done.\n");
    `endif
    send_cmd_en = 0;
end
endtask

//task pack_Req_RW;
//input [31:0] password;
//integer bit_cnt;
//begin
//    bit_cnt =`Req_RW_Len - 1 ;
//    Req_RW_cmd = 0;
//    Req_RW_cmd ={`REQ_RW,password,rn16_Query,16'b0};
//    CRC16= 16'hFFFF;
//    while(bit_cnt>16)    
//        begin
//            # 100 crc16_calc({Req_RW_cmd[bit_cnt],Req_RW_cmd[bit_cnt-1]});
//            bit_cnt=bit_cnt-2;
//        end
//    Req_RW_cmd ={`REQ_RW,password,rn16_Query,~CRC16};
//end
//endtask
//
//
//task send_Req_RW;
//input[31:0] password;
//integer bit_cnt;
//begin
//    bit_cnt = `Req_RW_Len;    
//    pack_Req_RW(password);
//    data_to_tag = 1;   
//    send_preamble;
//    `ifndef SUPPRESS_SENDING_MSG
//        $fdisplay(file_result,"sending Query cmd bit ...\n");
//    `endif    
//    if(send_cmd_en)
//    begin
//        repeat(`Req_RW_Len/2)
//        begin
//            send_cmd_bit({Req_RW_cmd[bit_cnt-1],Req_RW_cmd[bit_cnt-2]});
//            bit_cnt = bit_cnt - 2;
//        end    
//    end
//    LAST_EDGE=$time;
//    `ifndef SUPPRESS_SENDING_MSG
//        $fdisplay(file_result,"Req_RW cmd send done @ %t\n",$time);
//    `endif
//    send_cmd_en = 0;
//end
//endtask
//
//
//task pack_Req_LC;
//input [31:0] password;
//integer bit_cnt;
//begin
//    bit_cnt =`Req_LC_Len - 1 ;
//    Req_LC_cmd = 0;
//    Req_LC_cmd ={`REQ_LC,password,rn16_Query,16'b0};
//    CRC16= 16'hFFFF;
//    while(bit_cnt>16)    
//        begin
//            # 100 crc16_calc({Req_LC_cmd[bit_cnt],Req_LC_cmd[bit_cnt-1]});
//            bit_cnt=bit_cnt-2;
//        end
//    Req_LC_cmd ={`REQ_LC,password,rn16_Query,~CRC16};
//end
//endtask
//
//
//task send_Req_LC;
//input[31:0] password;
//integer bit_cnt;
//begin
//    bit_cnt = `Req_LC_Len;    
//    pack_Req_LC(password);
//    data_to_tag = 1;   
//    send_preamble;
//    `ifndef SUPPRESS_SENDING_MSG
//        $fdisplay(file_result,"sending Query cmd bit ...\n");
//    `endif    
//    if(send_cmd_en)
//    begin
//        repeat(`Req_LC_Len/2)
//        begin
//            send_cmd_bit({Req_LC_cmd[bit_cnt-1],Req_LC_cmd[bit_cnt-2]});
//            bit_cnt = bit_cnt - 2;
//        end    
//    end
//    LAST_EDGE=$time;
//    `ifndef SUPPRESS_SENDING_MSG
//        $fdisplay(file_result,"Req_LC cmd send done @ %t\n",$time);
//    `endif
//    send_cmd_en = 0;
//end
//endtask
//
//
//task pack_Req_KL;
//input [31:0] password;
//integer bit_cnt;
//begin
//    bit_cnt =`Req_KL_Len - 1 ;
//    Req_KL_cmd = 0;
//    Req_KL_cmd ={`REQ_KL,password,rn16_Query,16'b0};
//    CRC16= 16'hFFFF;
//    while(bit_cnt>16)    
//        begin
//            # 100 crc16_calc({Req_KL_cmd[bit_cnt],Req_KL_cmd[bit_cnt-1]});
//            bit_cnt=bit_cnt-2;
//        end
//    Req_KL_cmd ={`REQ_KL,password,rn16_Query,~CRC16};
//end
//endtask
//
//
//task send_Req_KL;
//input[31:0] password;
//integer bit_cnt;
//begin
//    bit_cnt = `Req_KL_Len;    
//    pack_Req_KL(password);
//    data_to_tag = 1;   
//    send_preamble;
//    `ifndef SUPPRESS_SENDING_MSG
//        $fdisplay(file_result,"sending Query cmd bit ...\n");
//    `endif    
//    if(send_cmd_en)
//    begin
//        repeat(`Req_KL_Len/2)
//        begin
//            send_cmd_bit({Req_KL_cmd[bit_cnt-1],Req_KL_cmd[bit_cnt-2]});
//            bit_cnt = bit_cnt - 2;
//        end    
//    end
//    LAST_EDGE=$time;
//    `ifndef SUPPRESS_SENDING_MSG
//        $fdisplay(file_result,"Req_KL cmd send done @ %t\n",$time);
//    `endif
//    send_cmd_en = 0;
//end
//endtask
//
//task pack_Req_RE;
//integer bit_cnt;
//begin
//    bit_cnt =`Req_RE_Len - 1 ;
//    Req_RE_cmd = 0;
//    Req_RE_cmd ={`REQ_RE,rn16_Query,16'b0};
//    CRC16= 16'hFFFF;
//    while(bit_cnt>16)    
//        begin
//            # 100 crc16_calc({Req_RE_cmd[bit_cnt],Req_RE_cmd[bit_cnt-1]});
//            bit_cnt=bit_cnt-2;
//        end
//    Req_RE_cmd ={`REQ_RE,rn16_Query,~CRC16};
//end
//endtask
//
//
//task send_Req_RE;
//integer bit_cnt;
//begin
//    bit_cnt = `Req_RE_Len;  
//    pack_Req_RE;  
//    data_to_tag = 1;   
//    send_preamble;
//    `ifndef SUPPRESS_SENDING_MSG
//        $fdisplay(file_result,"sending Query cmd bit ...\n");
//    `endif    
//    if(send_cmd_en)
//    begin
//        repeat(`Req_RE_Len/2)
//        begin
//            send_cmd_bit({Req_RE_cmd[bit_cnt-1],Req_RE_cmd[bit_cnt-2]});
//            bit_cnt = bit_cnt - 2;
//        end    
//    end
//    LAST_EDGE=$time;
//    `ifndef SUPPRESS_SENDING_MSG
//        $fdisplay(file_result,"Req_RE cmd send done @ %t\n",$time);
//    `endif
//    send_cmd_en = 0;
//end
//endtask


task pack_Get_SecPara;
integer    bit_cnt;
begin
    bit_cnt =`Get_SecPara_Len -1;
    Get_SecPara_cmd=0;
    Get_SecPara_cmd ={`GET_SECPARA,rn16_Query,16'b0};
    CRC16=16'hFFFF;
    while(bit_cnt>16)
        begin
            # 100 crc16_calc({Get_SecPara_cmd[bit_cnt],Get_SecPara_cmd[bit_cnt-1]});
            bit_cnt =bit_cnt -2;
        end
    Get_SecPara_cmd ={Get_SecPara_cmd[`Get_SecPara_Len-1:16],~CRC16};
end
endtask
    
    
    
task send_Get_SecPara;
integer   bit_cnt;
begin
    bit_cnt=`Get_SecPara_Len;
    pack_Get_SecPara;
    data_to_tag =1'b1;
    cmd_send_w =1'b0;
    r_words_cnt =1'b0;
    send_preamble;
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"Sending Get_SecPara cmd bit...\n");
    `endif
    if(send_cmd_en)
    begin
        repeat(`Get_SecPara_Len/2)
        begin
            send_cmd_bit({Get_SecPara_cmd[bit_cnt-1],Get_SecPara_cmd[bit_cnt-2]});
            bit_cnt = bit_cnt - 2;
        end
    end
    LAST_EDGE=$time;
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result," Get_SecPara cmd Send done.\n");
    `endif
    send_cmd_en = 0;
end
endtask




//##################################################//
//##################################################//

task pack_Req_XAuth;
integer    bit_cnt;
begin
    bit_cnt =`Req_XAuth_Len -1;
    Req_XAuth_cmd=0;
    Req_XAuth_cmd ={`REQ_XAUTH,rn16_Query,16'b0};
    CRC16=16'hFFFF;
    while(bit_cnt>16)
        begin
            # 100 crc16_calc({Req_XAuth_cmd[bit_cnt],Req_XAuth_cmd[bit_cnt-1]});
            bit_cnt =bit_cnt -2;
        end
    Req_XAuth_cmd ={Req_XAuth_cmd[`Req_XAuth_Len-1:16],~CRC16};
end
endtask
    
    
    
task send_Req_XAuth;
integer   bit_cnt;
begin
    bit_cnt=`Req_XAuth_Len;
    pack_Req_XAuth;
    data_to_tag =1'b1;
    cmd_send_w =1'b0;
    r_words_cnt =1'b0;
    send_preamble;
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"Sending Req_XAuth cmd bit...\n");
    `endif
    if(send_cmd_en)
    begin
        repeat(`Req_XAuth_Len/2)
        begin
            send_cmd_bit({Req_XAuth_cmd[bit_cnt-1],Req_XAuth_cmd[bit_cnt-2]});
            bit_cnt = bit_cnt - 2;
        end
    end
    LAST_EDGE=$time;
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result," Req_XAuth cmd Send done.\n");
    `endif
    send_cmd_en = 0;
end
endtask

//######################################################//
//######################################################//

task pack_RW_XAuth;
integer    bit_cnt;
begin
    bit_cnt =`RW_XAuth_Len -1;
    RW_XAuth_cmd=0;
    RW_XAuth_cmd ={`RW_XAUTH,RBNT,rn16_Query,16'b0};
    CRC16=16'hFFFF;
    while(bit_cnt>16)
        begin
            # 100 crc16_calc({RW_XAuth_cmd[bit_cnt],RW_XAuth_cmd[bit_cnt-1]});
            bit_cnt =bit_cnt -2;
        end
    RW_XAuth_cmd ={RW_XAuth_cmd[`RW_XAuth_Len-1:16],~CRC16};
end
endtask
    
    
    
task send_RW_XAuth;
integer   bit_cnt;
begin
    bit_cnt=`RW_XAuth_Len;
    pack_RW_XAuth;
    data_to_tag =1'b1;
    cmd_send_w =1'b0;
    r_words_cnt =1'b0;
    send_preamble;
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"Sending RW_XAuth cmd bit...\n");
    `endif
    if(send_cmd_en)
    begin
        repeat(`RW_XAuth_Len/2)
        begin
            send_cmd_bit({RW_XAuth_cmd[bit_cnt-1],RW_XAuth_cmd[bit_cnt-2]});
            bit_cnt = bit_cnt - 2;
        end
    end
    LAST_EDGE=$time;
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result," RW_XAuth cmd Send done.\n");
    `endif
    send_cmd_en = 0;
end
endtask

//###########################################################//
//###########################################################//

task pack_Req_SAuth;
integer    bit_cnt;
begin
    bit_cnt =`Req_SAuth_Len -1;
    Req_SAuth_cmd=0;
    Req_SAuth_cmd ={`REQ_SAUTH,rn16_Query,16'b0};
    CRC16=16'hFFFF;
    while(bit_cnt>16)
        begin
            # 100 crc16_calc({Req_SAuth_cmd[bit_cnt],Req_SAuth_cmd[bit_cnt-1]});
            bit_cnt =bit_cnt -2;
        end
    Req_SAuth_cmd ={Req_SAuth_cmd[`Req_SAuth_Len-1:16],~CRC16};
end
endtask
    
    
    
task send_Req_SAuth;
integer   bit_cnt;
begin
    bit_cnt=`Req_SAuth_Len;
    pack_Req_SAuth;
    data_to_tag =1'b1;
    cmd_send_w =1'b0;
    r_words_cnt =1'b0;
    send_preamble;
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"Sending Req_SAuth cmd bit...\n");
    `endif
    if(send_cmd_en)
    begin
        repeat(`Req_SAuth_Len/2)
        begin
            send_cmd_bit({Req_SAuth_cmd[bit_cnt-1],Req_SAuth_cmd[bit_cnt-2]});
            bit_cnt = bit_cnt - 2;
        end
    end
    LAST_EDGE=$time;
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result," Req_SAuth cmd Send done.\n");
    `endif
    send_cmd_en = 0;
end
endtask


//######################################################//
//######################################################//
task pack_Mul_SAuth;
integer    bit_cnt;
begin
    bit_cnt =`Mul_SAuth_Len -1;
    Mul_SAuth_cmd=0;
    rn16_interrogator= $random %30000;  
    Mul_SAuth_cmd ={`MUL_SAUTH,~rn16_interrogator,~RNT,~SK,rn16_Query,16'b0};
    CRC16=16'hFFFF;
    while(bit_cnt>16)
        begin
            # 100 crc16_calc({Mul_SAuth_cmd[bit_cnt],Mul_SAuth_cmd[bit_cnt-1]});
            bit_cnt =bit_cnt -2;
        end
    Mul_SAuth_cmd ={Mul_SAuth_cmd[`Mul_SAuth_Len-1:16],~CRC16};
end
endtask
    
  
    
task send_Mul_SAuth;
integer   bit_cnt;
begin
    bit_cnt=`Mul_SAuth_Len;
    pack_Mul_SAuth;
    data_to_tag =1'b1;
    cmd_send_w =1'b0;
    r_words_cnt =1'b0;
    send_preamble;
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"Sending Mul_SAuth cmd bit...\n");
    `endif
    if(send_cmd_en)
    begin
        repeat(`Mul_SAuth_Len/2)
        begin
            send_cmd_bit({Mul_SAuth_cmd[bit_cnt-1],Mul_SAuth_cmd[bit_cnt-2]});
            bit_cnt = bit_cnt - 2;
        end
    end
    LAST_EDGE=$time;
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result," Mul_SAuth cmd Send done.\n");
    `endif
    send_cmd_en = 0;
end
endtask

//######################################################//
//######################################################//

task pack_Read;
input [5:0]MemBank;
input [15:0]Pointer;
input [15:0]Length;
integer  bit_cnt;
begin
    bit_cnt = `Read_Len-1;
    Read_cmd = 0;
    Read_cmd = {`READ, MemBank,Pointer,Length, rn16_Query, 16'b0};
    CRC16 = 16'hFFFF;
    while(bit_cnt>16)    
        begin
            # 100 crc16_calc({Read_cmd[bit_cnt],Read_cmd[bit_cnt-1]});
            bit_cnt=bit_cnt-2;
        end
    Read_cmd = {Read_cmd[`Read_Len-1:16],~CRC16};
end
endtask


// the send_Read task excuted a function of send
// Read cmd,it is called in the following way:
// send_Read(TID,'d30,'d2);
// has membank,EBV,wordcnt,rn16_Query
// values as its parameters.
task send_Read;      
input [5:0]MemBank;
input [15:0]Pointer;
input [15:0]Length;
integer  bit_cnt;
begin
    bit_cnt = `Read_Len;
    pack_Read(MemBank,Pointer,Length);
    data_to_tag = 1;
    cmd_send_w = 1'b0;
    r_words_cnt = Length;
    // tdata_bits_num = 'd33+wordcnt*16; // ask decode section waiting for 1bit header,wordcnt*16 data,16bit RN16,and 16bit crc 
    send_preamble;
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"Sending Read cmd bit...\n");
    `endif
    if(send_cmd_en)
    begin
        repeat(`Read_Len/2)
        begin
            send_cmd_bit({Read_cmd[bit_cnt-1],Read_cmd[bit_cnt-2]});
            bit_cnt = bit_cnt - 2;
        end
    end
    LAST_EDGE=$time;
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result," Read cmd Send done.\n");
    `endif
    send_cmd_en = 0;
end
endtask


// ----------------------------------------------------------
// write command pack and send tasks
// ----------------------------------------------------------
// the pack_Write task excuted a function of packup
// Write cmd,it is called in the following way:
// pack_Write(MemBank, EBV, data);
// has membank,EBV,data values and 
// global rn16_Query, rn16_Req_RN num as its parameters.
// use crc16
task pack_Write;
input [5:0]MemBank;
input [15:0]Pointer;
input [15:0]Length;
input [15:0] data;
integer  bit_cnt;
begin
    bit_cnt = `Write_Len-1;
    Write_cmd = 0;
    Write_cmd = {`WRITE,MemBank,Pointer,Length,data, rn16_Query, 16'b0};
    CRC16 = 16'hFFFF;
    while(bit_cnt>16)    
        begin
            # 100 crc16_calc({Write_cmd[bit_cnt],Write_cmd[bit_cnt-1]});
            bit_cnt=bit_cnt-2;
        end
    Write_cmd = {Write_cmd[`Write_Len-1:16],~CRC16};
end
endtask

task send_Write;      
input [5:0]MemBank;
input [15:0]Pointer;
input [15:0]Length;
input [15:0]data;
integer  bit_cnt;
begin
    bit_cnt = `Write_Len;
    pack_Write(MemBank, Pointer,Length,data);
    data_to_tag = 1;
    cmd_send_w = 1'b1;
    r_words_cnt = Length;
    // tdata_bits_num = 'd33+wordcnt*16; // ask decode section waiting for 1bit header,wordcnt*16 data,16bit RN16,and 16bit crc 
    send_preamble;
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"Sending Read cmd bit...\n");
    `endif
    if(send_cmd_en)
    begin
        repeat(`Write_Len/2)
        begin
            send_cmd_bit({Write_cmd[bit_cnt-1],Write_cmd[bit_cnt-2]});
            bit_cnt = bit_cnt - 2;
        end
    end
    LAST_EDGE=$time;
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result," Read cmd Send done.\n");
    `endif
    send_cmd_en = 0;
end
endtask

// ----------------------------------------------------------
// Lock command pack and send tasks
// ----------------------------------------------------------
// the pack_Lock task excuted a function of packup
// Lock cmd,it is called in the following way:
// pack_Lock(payload);
// has payload value, global rn16_Query as its parameters.
// use crc16
task pack_Lock;
input [5:0] MemBank;
input [1:0] Deploy;
input [1:0] Action;
integer     bit_cnt;
begin
    bit_cnt = `Lock_Len-1;
    Lock_cmd = 0;
    Lock_cmd = {`LOCK, MemBank,Deploy,Action, rn16_Query, 16'b0};
    CRC16 = 16'hFFFF;
    while(bit_cnt>16)    
        begin
            # 100 crc16_calc({Lock_cmd[bit_cnt],Lock_cmd[bit_cnt-1]});
            bit_cnt=bit_cnt-2;
        end
    Lock_cmd = {Lock_cmd[`Lock_Len-1:16],~CRC16};
end
endtask


// the send_Lock task excuted a function of send
// Lock cmd,it is called in the following way:
// send_Lock(payload);
// has payload value, global rn16_Query as its parameters.
task send_Lock;  //code ok
input [1:0] MemBank;
input [1:0] Deploy;
input [1:0] Action;
integer     bit_cnt;
begin
    bit_cnt = `Lock_Len;
    pack_Lock(MemBank,Deploy,Action);
    data_to_tag = 1;
    cmd_send_w = 1'b1;
    send_preamble;
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"Sending Lock cmd bit...\n");
    `endif
    if(send_cmd_en)
    begin
        repeat(`Lock_Len/2)
        begin
            send_cmd_bit({Lock_cmd[bit_cnt-1],Lock_cmd[bit_cnt-2]});
            bit_cnt = bit_cnt - 2;
        end
    end
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"Lock cmd send done.\n");
    `endif
    send_cmd_en = 0;
end
endtask


task pack_Kill;
integer     bit_cnt;
begin
    bit_cnt = `Kill_Len-1;
    Kill_cmd = 0;
    Kill_cmd = {`KILL, rn16_Query, 16'b0};
    CRC16 = 16'hFFFF;
    while(bit_cnt>16)    
        begin
            # 100 crc16_calc({Kill_cmd[bit_cnt],Kill_cmd[bit_cnt-1]});
            bit_cnt=bit_cnt-2;
        end
    Kill_cmd = {Kill_cmd[`Kill_Len-1:16],~CRC16};
end
endtask


// the send_Kill task excuted a function of send
// Kill cmd,it is called in the following way:
// send_Kill
// has rn16_Req_RN num as its parameters.
task send_Kill;
integer     bit_cnt;
begin
    bit_cnt = `Kill_Len;
    pack_Kill;
    data_to_tag = 1;
    cmd_send_w = 1'b1;
    send_preamble;
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"Sending Kill_Len cmd bit...\n");
    `endif
    if(send_cmd_en)
    begin
        repeat(`Kill_Len/2)
        begin
            send_cmd_bit({Kill_cmd[bit_cnt - 1],Kill_cmd[bit_cnt - 2]});
            bit_cnt = bit_cnt-2;
        end
    end
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"Kill cmd send done.\n");
    `endif
    send_cmd_en = 0;
end
endtask





task pack_Sec_Com;
input  [ 7:0]  cmd_head;
integer       bit_cnt_sec;
integer       bit_cnt_embeded;
begin
    begin   
        if(cmd_head==`ACCESS)
            begin
                Length_sec = `Access_Len;                            
                bit_cnt_sec = `Access_Len +55;//SEC_COM cmd_head plus Len plus handle plus SEC_COM CRC
                Sec_Com_cmd = 0;
                pack_Access(`UAC,4'b0000,16'hFFFF);                
                Access_cmd = {Access_cmd[`Access_Len -1:16],rn16_interrogator};                                                                
                Sec_Com_cmd = {`SEC_COM,Length_sec,~Access_cmd,rn16_Query,16'b0};
            end
        else if(cmd_head==`READ)
            begin
                Length_sec = `Read_Len;                                             
                bit_cnt_sec = `Read_Len +55;//SEC_COM cmd_head plus Len plus handle plus SEC_COM CRC
                Sec_Com_cmd = 0;
                pack_Read(`UAC,16'h0003,16'h0003);                
                Read_cmd = {Read_cmd[`Read_Len -1:16],rn16_interrogator};                                         
                Sec_Com_cmd = {`SEC_COM,Length_sec,~Read_cmd,rn16_Query,16'b0};
            end
        else if(cmd_head ==`WRITE)
            begin    
                Length_sec = `Write_Len;
                bit_cnt_sec = `Write_Len +55;
                Sec_Com_cmd = 0;
                pack_Write(`UAC,16'b0000_0000_0000_0011,16'b0000_0000_0000_0011,16'b0000_0000_0000_0010);                                           
                Sec_Com_cmd = {`SEC_COM,Length_sec,~Write_cmd,rn16_Query,16'b0};
            end
        else if(cmd_head ==`LOCK)
             begin    
               Length_sec = `Lock_Len;                                           
               bit_cnt_sec = `Lock_Len +55;//55 equal to SEC_COM cmd_head plus Len plus handle plus SEC_COM CRC
               Sec_Com_cmd = 0;
               pack_Lock(`UAC,2'b00,`NR_NW);                
               Lock_cmd = {Lock_cmd[`Lock_Len -1:16],rn16_interrogator};                                         
               Sec_Com_cmd = {`SEC_COM,Length_sec,~Lock_cmd,rn16_Query,16'b0};  
            end            
        else if(cmd_head == `KILL)
            begin    
               Length_sec = `Kill_Len;                                           
               bit_cnt_sec = `Kill_Len +55;//55 equal to SEC_COM cmd_head plus Len plus handle plus SEC_COM CRC
               Sec_Com_cmd = 0;
               pack_Kill;                
               Kill_cmd = {Kill_cmd[`Kill_Len -1:16],rn16_interrogator};                                         
               Sec_Com_cmd = {`SEC_COM,Length_sec,~Kill_cmd,rn16_Query,16'b0};               
            end
           
        else 
            begin                   
                Length_sec = 15'b0;
                bit_cnt_sec = Length_sec +39;
                Sec_Com_cmd = 0;               
            end           
    end
    
    CRC16_0 = 16'hFFFF;
    while(bit_cnt_sec>16)    
        begin
            # 100 crc16_calc_0({Sec_Com_cmd[bit_cnt_sec],Sec_Com_cmd[bit_cnt_sec-1]});
            bit_cnt_sec=bit_cnt_sec-2;
        end
    Sec_Com_cmd = {Sec_Com_cmd[255:16],~CRC16_0};
end
endtask


// the send_Sec_Com task excuted a function of send
// Sec_Com cmd,it is called in the following way:
// send_Sec_Com
// god damn it!
task send_Sec_Com;
input   [7:0]  cmd_head;
integer        bit_cnt_sec;
begin
    
    pack_Sec_Com(cmd_head);
    bit_cnt_sec = Length_sec+55;//cmd_head plus crc16 embeded and crc16 of SEC_COM!!!
    data_to_tag = 1;
    cmd_send_w = 1'b1;
    send_preamble;
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"Sending Sec_Com cmd bit...\n");
    `endif
    if(send_cmd_en)
    begin
        repeat((Length_sec+56)/2)
        begin
            send_cmd_bit({Sec_Com_cmd[bit_cnt_sec ],Sec_Com_cmd[bit_cnt_sec - 1]});
            bit_cnt_sec = bit_cnt_sec-2;
        end
    end
    `ifndef SUPPRESS_SENDING_MSG
        $fdisplay(file_result,"Sec_Com cmd send done.\n");
    `endif
    send_cmd_en = 0;
end
endtask


// ===================================================
// Control Section of BFM
// ===================================================

// -----------------------------------------------
// Push to state you desired
// -----------------------------------------------

// push_to_Ready task is used to force the tag fall 
// to Ready State,actually in case power-up it's 
// Ready,but we can not simulate this power-up procedure,
// so use Select cmd to push it fall into Ready state.
// call this task and monitor the tag's state.
// this task would be called in the following way:
// push_to_Ready;
task push_to_Ready;
begin
    //Mask_value[127:80] = 48'h0000_0000_0000;
    Mask_value[127:80] = 48'h0514_0514_0514;
    send_Sort(`TBI,4'b0000,`MM_NN,16'b0000_0000_0010_0000,8'b0011_0000);
end
endtask

// push_to_Arbitrate task is used to force the tag fall 
// to Arbitrate State,when issuring Query cmd with NonZero
// Q value in Ready state,tag shall fall into the Col_pre_check 
// state, for the time issue,we use Q = 4'b0101;
// this task would be called in the following way:
// push_to_Col_pre_check;
task push_to_Arbitrate;
input  [1:0]M;
input       Trext;
begin
    push_to_Ready;
    #2000000 send_Query(`TAG_NON_MATCH,`SESSION_S0,`TARGET0,Trext,`DR_2,M); // Arbitrate state,no response
    //#2000000 send_Query(`TAG_NON_MATCH,`SESSION_S0,`TARGET0,Trext,`DR_1d5,M);
    //#2000000 send_Query(`TAG_NON_MATCH,`SESSION_S0,`TARGET0,Trext,`DR_1,M);
    //#2000000 send_Query(`TAG_NON_MATCH,`SESSION_S0,`TARGET0,Trext,`DR_2d5,M);
    //#2000000 send_Query(`TAG_NON_MATCH,`SESSION_S0,`TARGET0,Trext,`DR_12d11,M);
end
endtask


// push_to_Reply task is used to force the tag fall 
// to Identification State,when issuring Query cmd with Zero
// Q value in Ready state tag shall fall into the 
// Identification state;
// this task would be called in the following way:
// push_to_Identification;
task push_to_Reply;
input   [1:0]    M    ;
input            Trext;
begin
    push_to_Ready;
   //#2000000 send_Query(`TAG_ALL,`SESSION_S0,`TARGET0,Trext,`DR_2,M); //tag would fall into reply state.
   //#2000000 send_Query(`TAG_ALL,`SESSION_S0,`TARGET0,Trext,`DR_1d5,M);
   #2000000 send_Query(`TAG_ALL,`SESSION_S0,`TARGET0,Trext,`DR_1,M);
   //#2000000 send_Query(`TAG_ALL,`SESSION_S0,`TARGET0,Trext,`DR_2d5,M);
   //#2000000 send_Query(`TAG_ALL,`SESSION_S0,`TARGET0,Trext,`DR_12d11,M);
    Decode ;
    get_Query_Reply;  
end
endtask

// push_to_Open task is used to force the tag fall 
// to open State,when issuring ACK cmd in Identification state,
// tag shall fall into the Identification state;
// this task would be called in the following way:
// push_to_Identification;
task push_to_Open;
begin
    push_to_Reply(`M_FM0,`NO_TREXT);
    //push_to_Reply(`M_FM0,`TREXT);
    //push_to_Reply(`M_MILLER2,`NO_TREXT);
    //push_to_Reply(`M_MILLER2,`TREXT);
    //push_to_Reply(`M_MILLER4,`NO_TREXT);
    //push_to_Reply(`M_MILLER4,`TREXT);
    //push_to_Reply(`M_MILLER8,`NO_TREXT);
    //push_to_Reply(`M_MILLER8,`TREXT);
//    # 40000 send_Ack(rn16_Query);  // send Ack cmd with RN16 backed by tag ,revised 2008/09/09
   # 4011 send_Ack; // revised for T2 2009/11/05
    Decode;
    get_Ack_Reply;
end
endtask


// -----------------------------------------------
// Get rn16 backscatted from Query serious cmd
// -----------------------------------------------
// get_Query_Reply is a task to get the the RN16 data 
// Backscatted by tag due to issuring the Query,QueryAdjust,QueryRep
// but be sure to call it after FM0_decode or Miller_decode.
// and storing the Rn16 data into rn16_Query variable.
// this task is calling in the following way:
// FM0_decode; or Miller_decode;
// get_Query_Resp
// no crc
task get_Query_Reply;   // code OK 
begin		       
    rn16_Query = tdata_buffer[(`TDATA_BUF_LEN-1):(`TDATA_BUF_LEN-16)];          
end
endtask



// -----------------------------------------------
// Get rn16 backscatted from Get_RN serious cmd
// -----------------------------------------------
// get_Get_en_Reply is a task to get the the RN16 data 
// Backscatted by tag due to issuring the Get_RN
// but be sure to call it after FM0_decode or Miller_decode.
// and storing the Rn16 data into rn16_Get_RN variable.
// this task is calling in the following way:
// Decoder
// get_Get_RN_Reply
// no crc
task get_Get_RN_Reply;   // code OK 
output [15:0] resp;
reg    [31:0] temp;
integer          i;		   
    begin  
        temp = tdata_buffer[(`TDATA_BUF_LEN-1):(`TDATA_BUF_LEN-32)];
        rx_crc16_data = 16'hFFFF;
        for(i=1;i<=48;i=i+2)   // CRC check
            #100 crc16_check_bit({tdata_buffer[`TDATA_BUF_LEN-i],tdata_buffer[`TDATA_BUF_LEN-i-1]});
        if(rx_crc16_data == 16'h1D0F) 
            if(temp[15:0] == rn16_Query)
                resp =temp[31:16];
            else
                begin
                $fdisplay(file_result,"Error : Req_RN cmd response handle not match! @ %t.\n",$time);
                #10000  $finish;
                end
        else
            begin
            $fdisplay(file_result,"Error : Req_RN cmd response CRC check failed! @ %t.\n",$time);
            #10000  $finish;
            end
    end                    
endtask



task get_Ack_Reply;
reg   [15:0] uac_len;
integer            i;
begin
    begin
        uac_len = tdata_buffer[`TDATA_BUF_LEN-3:`TDATA_BUF_LEN-18];
        rx_crc16_data = 16'hFFFF;
        for(i=1;i<=((uac_len[15:8]<<4)+34);i=i+2)//34=32+2
            #100 crc16_check_bit({tdata_buffer[`TDATA_BUF_LEN-i],tdata_buffer[`TDATA_BUF_LEN-i-1]});
        if(rx_crc16_data == 16'h1D0F)
        begin
            uac_len = 0; // initial the data register            
            $fdisplay(file_result,"ACK command response CRC check passed! .@ %t.\n",$time);           
        end
        else
        begin
            $fdisplay(file_result,"Error : ACK command response CRC check error.@ %t.\n",$time);
            #100000 $finish;   
        end
    end       
end
endtask



// -----------------------------------------------
// Get rn16 backscatted from Get_RN serious cmd
// -----------------------------------------------
// get_Get_en_Reply is a task to get the the RN16 data 
// Backscatted by tag due to issuring the Get_RN
// but be sure to call it after FM0_decode or Miller_decode.
// and storing the Rn16 data into rn16_Get_RN variable.
// this task is calling in the following way:
// Decoder
// get_Get_RN_Reply
// no crc
task get_Req_XAuth_Reply;   // code OK 
begin		
    if(M_value ==`M_FM0)
        if(Trext_value ==1'b0)       
            if(symbol_cnt >= 19 )   
                begin      
                    SNT = tdata_buffer[(`TDATA_BUF_LEN-1):(`TDATA_BUF_LEN-16)];
                    SNT_done  = 1'b1;
                end   
            else
                begin
                    SNT = SNT; 
                    SNT_done = 1'b0;
                end    
        else 
            if(symbol_cnt >= 33)
                begin
                    SNT = tdata_buffer[(`TDATA_BUF_LEN-1):(`TDATA_BUF_LEN-16)];
                     SNT_done  = 1'b1;
                end     
            else
                begin
                    SNT = SNT; 
                    SNT_done = 1'b0;
                end    
    else 
        if(Trext_value == 1'b0)
            if(symbol_cnt >= 29)  
                begin     
                   SNT = tdata_buffer[(`TDATA_BUF_LEN-1):(`TDATA_BUF_LEN-16)];
                    SNT_done  = 1'b1;
                end   
            else 
                begin
                    SNT =SNT;
                    SNT_done = 1'b0;
                end    
        else
            if(symbol_cnt >= 41)  
                begin     
                    SNT = tdata_buffer[(`TDATA_BUF_LEN-1):(`TDATA_BUF_LEN-16)];
                     SNT_done  = 1'b1;
                end     
            else 
                begin
                    SNT =SNT;
                    SNT_done = 1'b0;
                end    
       
end
endtask




assign NT= SNT ^ KT;

always@ (NT or SNT_done)
begin
    if(SNT_done== 1'b1)
        for(i=0;i<16;i=i+1)
           BNT[i]=NT[15-i];
    else
        BNT =BNT;
end

assign RBNT= BNT ^ KT;




// -----------------------------------------------
// Get rn16 backscatted from Get_RN serious cmd
// -----------------------------------------------
// get_Get_en_Reply is a task to get the the RN16 data 
// Backscatted by tag due to issuring the Get_RN
// but be sure to call it after FM0_decode or Miller_decode.
// and storing the Rn16 data into rn16_Get_RN variable.
// this task is calling in the following way:
// Decoder
// get_Get_RN_Reply
// no crc
task get_Req_SAuth_Reply;   // code OK 
begin		
    if(M_value ==`M_FM0)
        if(Trext_value ==1'b0)       
            if(symbol_cnt >= 19 )      
                RNT = tdata_buffer[(`TDATA_BUF_LEN-1):(`TDATA_BUF_LEN-16)];   
            else
                RNT = RNT;    
        else 
            if(symbol_cnt >= 33)
                RNT = tdata_buffer[(`TDATA_BUF_LEN-1):(`TDATA_BUF_LEN-16)];   
            else
                RNT = RNT;    
    else 
        if(Trext_value == 1'b0)
            if(symbol_cnt >= 29)      
               RNT = tdata_buffer[(`TDATA_BUF_LEN-1):(`TDATA_BUF_LEN-16)];  
            else 
                    RNT =RNT; 
        else
            if(symbol_cnt >= 41)                
                RNT = tdata_buffer[(`TDATA_BUF_LEN-1):(`TDATA_BUF_LEN-16)];
            else              
                RNT =RNT;                                    
end
endtask


task get_Access_Reply;
integer            i;
begin
    begin
        rx_crc16_data = 16'hFFFF;
        for(i=1;i<=40;i=i+2)
            #100 crc16_check_bit({tdata_buffer[`TDATA_BUF_LEN-i],tdata_buffer[`TDATA_BUF_LEN-i-1]});
        if(rx_crc16_data == 16'h1D0F)
        begin                       
            $fdisplay(file_result,"ACK command response CRC check passed! .@ %t.\n",$time);
            if(tdata_buffer[(`TDATA_BUF_LEN-9):(`TDATA_BUF_LEN-24)]==rn16_Query)
                begin
                    $fdisplay(file_result,"Tag backscattering handle: %b.@ %t. right!...\n",rn16_Query,$time); 
                end    
            else
                begin
            			$fdisplay(file_result,"Tag backscattering handle: %b @ %t. wrong!...\n",tdata_buffer[(`TDATA_BUF_LEN-9):(`TDATA_BUF_LEN-24)],$time);
            			#10000	$finish;
            	  end		      
        end
        else
        begin
            $fdisplay(file_result,"Error : ACK command response CRC check error.@ %t.\n",$time);
            #100000 $finish;   
        end
    end       
end
endtask    



task get_Read_Reply;
integer    i;
reg   [7:0]  Header;
reg   [15:0] back_handle;
begin     // symbol_cnt does not determined
    
    if( (symbol_cnt >= 60 && Trext_value==1'b0 && M_value == `M_FM0)||                 
        (symbol_cnt >= 72 && Trext_value==1'b1 && M_value == `M_FM0)||                 
        (symbol_cnt >= 69 && Trext_value==1'b0 && M_value != `M_FM0)|| 
        (symbol_cnt >= 81 && Trext_value==1'b1 && M_value != `M_FM0) 
       )   
         begin 
                rx_crc16_data = 16'hFFFF;
                for(i=1;i<=(8+r_words_cnt*16+16+16);i=i+2)
                    #100 crc16_check_bit({tdata_buffer[`TDATA_BUF_LEN-i],tdata_buffer[`TDATA_BUF_LEN-i-1]});
                if(rx_crc16_data == 16'h1D0F)                        
                    begin
                        $fdisplay(file_result,"Read cmd response CRC Check passed!\n");       
                        Header = tdata_buffer[(`TDATA_BUF_LEN-1):(`TDATA_BUF_LEN-8)];            
                    end                                                                                            
               else
                   begin
                       $fdisplay(file_result,"Error : Read cmd response CRC check failed! @ %t.\n",$time);
                       #1000  $finish;
                   end                  
        end
    else 
        begin
            $fdisplay(file_result,"Tag baclscattering 41bit error code.@ %t.\n",$time);
            rx_crc16_data = 16'hFFFF;
            for(i=1;i<=40;i=i+2)
                #100 crc16_check_bit({tdata_buffer[`TDATA_BUF_LEN-i],tdata_buffer[`TDATA_BUF_LEN-i-1]});
            if(rx_crc16_data == 16'h1D0F)
                begin
                    if(tdata_buffer[`TDATA_BUF_LEN-9:`TDATA_BUF_LEN-24]==rn16_Query)
                        begin
                            $fdisplay(file_result,"Read cmd response CRC Check passed!\n");
                            $fdisplay(file_result,"Read cmd response handle match!\n");
                            Header = tdata_buffer[(`TDATA_BUF_LEN-1):(`TDATA_BUF_LEN-8)];
                            back_handle = tdata_buffer[`TDATA_BUF_LEN-9:`TDATA_BUF_LEN-24]; //get backscatted handle
                        end
                    else
                        begin
                            $fdisplay(file_result,"Error : Read cmd response handle not match! @ %t.\n",$time);
                            #10000  $finish;
                        end  
                end                                                       
            else
                begin
                    $fdisplay(file_result,"Error : Read cmd response CRC check failed! @ %t.\n",$time);
                    #1000  $finish;
                   
                end
           
       end
end
endtask




task get_WELK_Reply;//WELK means the set of Write,Erase,Lock,Kill cmds!
reg   [7:0]  Header;   
reg   [15:0] back_handle;
integer  i;
begin                    
       if(symbol_cnt >= 55 && Trext_value==1'b0  && M_value == `M_FM0)                       
           begin
           rx_crc16_data = 16'hFFFF;
           for(i=1;i<=40;i=i+2)   // CRC check
               #100 crc16_check_bit({tdata_buffer[`TDATA_BUF_LEN-i-13],tdata_buffer[`TDATA_BUF_LEN-i-14]});
           if(rx_crc16_data == 16'h1D0F)
               begin
                   if(tdata_buffer[`TDATA_BUF_LEN-22:`TDATA_BUF_LEN-37]==rn16_Query)
                       begin
                           $fdisplay(file_result,"Write cmd response CRC Check passed!\n");
                           $fdisplay(file_result,"Write cmd response handle match!\n");
                           Header = tdata_buffer[(`TDATA_BUF_LEN-1):(`TDATA_BUF_LEN-8)];
                           back_handle = tdata_buffer[`TDATA_BUF_LEN-9:`TDATA_BUF_LEN-24]; //get backscatted handle
                       end
                   else
                       begin
                           $fdisplay(file_result,"Error : Write cmd response handle not match! @ %t.\n",$time);
                           #10000  $finish;
                       end  
               end                                                       
           else
             begin
                 $fdisplay(file_result,"Error : Write cmd response CRC check failed! @ %t.\n",$time);
                 #1000  $finish;
                
             end 
           end
       else if(symbol_cnt >= 64 && Trext_value==1'b0  && M_value != `M_FM0)   
           begin
           rx_crc16_data = 16'hFFFF;
           for(i=1;i<=40;i=i+2)   // CRC check
               #100 crc16_check_bit({tdata_buffer[`TDATA_BUF_LEN-i-12],tdata_buffer[`TDATA_BUF_LEN-i-13]});
           if(rx_crc16_data == 16'h1D0F)
               begin
                   if(tdata_buffer[`TDATA_BUF_LEN-21:`TDATA_BUF_LEN-36]==rn16_Query)
                       begin
                           $fdisplay(file_result,"Write cmd response CRC Check passed!\n");
                           $fdisplay(file_result,"Write cmd response handle match!\n");
                           Header = tdata_buffer[(`TDATA_BUF_LEN-1):(`TDATA_BUF_LEN-8)];
                           back_handle = tdata_buffer[`TDATA_BUF_LEN-9:`TDATA_BUF_LEN-24]; //get backscatted handle
                       end
                   else
                       begin
                           $fdisplay(file_result,"Error : Write cmd response handle not match! @ %t.\n",$time);
                           #10000  $finish;
                       end  
               end                                                       
           else
             begin
                 $fdisplay(file_result,"Error : Write cmd response CRC check failed! @ %t.\n",$time);
                 #1000  $finish;
                
             end 
           end
       else
           begin    
            rx_crc16_data = 16'hFFFF;
            for(i=1;i<=40;i=i+2)   // CRC check
                #100 crc16_check_bit({tdata_buffer[`TDATA_BUF_LEN-i],tdata_buffer[`TDATA_BUF_LEN-i-1]});
            if(rx_crc16_data == 16'h1D0F)
                begin
                    if(tdata_buffer[`TDATA_BUF_LEN-9:`TDATA_BUF_LEN-24]==rn16_Query)
                        begin
                            $fdisplay(file_result,"Write cmd response CRC Check passed!\n");
                            $fdisplay(file_result,"Write cmd response handle match!\n");
                            Header = tdata_buffer[(`TDATA_BUF_LEN-1):(`TDATA_BUF_LEN-8)];
                            back_handle = tdata_buffer[`TDATA_BUF_LEN-9:`TDATA_BUF_LEN-24]; //get backscatted handle
                        end
                    else
                        begin
                            $fdisplay(file_result,"Error : Write cmd response handle not match! @ %t.\n",$time);
                            #10000  $finish;
                        end  
                end                                                       
            else
              begin
                  $fdisplay(file_result,"Error : Write cmd response CRC check failed! @ %t.\n",$time);
                  #1000  $finish;
                 
              end 
          end      
end               
endtask



//#################################################//
//            Code For Decoding                   //
//#################################################//
always@(Tpri_calc or TC or DR_value)                               //add @ 2009/08/04
begin
    if(DR_value == `DR_2)  
        Tpri_calc = TC/4;             //TC=3012.5ns
    else if(DR_value == `DR_1d5)
        Tpri_calc = TC*2.5;
    else if(DR_value == `DR_1)
        Tpri_calc = TC/2;
	  else if(DR_value == `DR_2d5)
	      Tpri_calc = TC*1.25;
	  else if(DR_value == `DR_12d11)
	      Tpri_calc = TC/2;
    else
        Tpri_calc = 0;  
end    

always @(Tpri_calc or Tpri_real)
begin
    if(Tpri_calc <1563 && (Tpri_real>Tpri_calc* 0.8 && Tpri_real<Tpri_calc * 1.20))
        BLF_OK=1'b1;
    else if(Tpri_calc==3125 && (Tpri_real>Tpri_calc* 0.8 && Tpri_real < Tpri_calc * 1.20))
        BLF_OK=1'b1;
    else if(Tpri_calc==6250 && (Tpri_real > Tpri_calc * 0.85 && Tpri_real < Tpri_calc * 1.25))
        BLF_OK=1'b1;
    else if(Tpri_calc==12500 && (Tpri_real> Tpri_calc * 0.9 && Tpri_real <Tpri_calc * 1.1)) 
        BLF_OK=1'b1;
    else 
        BLF_OK=1'b0;
end

always @(Tpri_real or Tpri_calc)
begin      
    Tpri_real_LB = Tpri_real*0.95;  // T's lower boundary,actual symbol 1's length    
    Tpri_real_UB = Tpri_real*1.05;  // T's upper boundary
    half_Tpri_LB = (Tpri_real*0.95)/2; 
    half_Tpri_UB = (Tpri_real*1.05)/2;
    oah_Tpri     = Tpri_real/2 + Tpri_real; // (0+V)'s width,especially in Preamble!
    oah_Tpri_LB  = (Tpri_real*0.95)/2 + (Tpri_real*0.95) ;   //revised 2008/10/15      
    oah_Tpri_UB  = (Tpri_real*1.05)/2 + (Tpri_real*1.05);   //revised 2008/09/09
    
    MIN_T3 = 0;
    
    MIN_T4 = TC*4; 
end

always@(Tpri_calc)
begin
    // calc the Link timing variables -- T1
    if(Tpri_calc<1563)
    begin
        MIN_T1 = (10 * Tpri_calc) * 0.75 -2000;
        MAX_T1 = (10 * Tpri_calc) * 1.25 +2000;
    end
    else if(Tpri_calc == 3125)
    begin
        MIN_T1 = (10* Tpri_calc) * 0.78 -2000;
        MAX_T1 = (10* Tpri_calc) * 1.22 +2000;
    end
    else if(Tpri_calc == 6250)
    begin
        MIN_T1 = (10* Tpri_calc) * 0.80 -2000;
        MAX_T1 = (10* Tpri_calc) * 1.20 +2000;
    end
    else if(Tpri_calc == 12500)
    begin
        MIN_T1 =(10*Tpri_calc) * 0.85 -2000;
        MAX_T1 =(10*Tpri_calc) * 1.15 +2000;
    end
    else
    begin
        MIN_T1 = 0;
        MAX_T1 =0;
    end
       
end



//##############################################//
//                Decoder                       //
//##############################################//
task Decode;
begin
    if(M_value==`M_FM0)    		    			
        	FM0_decode;        
    else
        Miller_decode;
end
endtask

//##############################################//
//                FM0_decoder                   //
//##############################################//
always @(FM0_dec_en or Miller_dec_en)
begin
    if(FM0_dec_en==1'b1)
        begin
            Tpri_real=Tpri_real_FM0;
            T1=T1_FM0;
        end
    else if(Miller_dec_en==1'b1)
        begin
            Tpri_real=Tpri_real_Miller;
            T1=T1_Miller;
        end
    else
        begin
            Tpri_real=0;
            T1 =0;   
        end       
end


task FM0_decode;
                 //                ________     __
time stamp1_pos; // denote the ___|        |___|   signal's rising edge
                 //                ________     __
time stamp2_neg; // denote the ___|        |___|   signal's falling edge
                 //                ________     __
time stamp3_pos; // denote the ___|        |___|   signal's second rising edge

integer posedge_cnt;

begin :FM_U
    if(M_value != `M_FM0)
   		 begin
        	$fdisplay(file_result,"Fatal Error:Be sure not to do FM0 decode in Miller Encoding Mode!@ %t.\n",$time);
        	#1000 $finish;
    	 end
    else
        $fdisplay(file_result,"FM0 decode begin,@ %t.\n",$time);
    posedge_cnt =0;
    symbol_cnt = 1;
    tdata_buffer = `TDATA_BUF_LEN'd0;
    @(posedge tag_data); // waiting for first rising edge of tag data
    stamp1_pos = $time;
    @(negedge tag_data); // waiting for first fall edge of tag data 
    stamp2_neg = $time;
    T1_FM0 = stamp1_pos - LAST_EDGE ;   
    begin
        if(Trext_value == 1'b0 && cmd_send_w == 1'b0)
            Tpri_real_FM0 = (stamp2_neg - stamp1_pos);    
        else
            Tpri_real_FM0 = (stamp2_neg - stamp1_pos)*2;     
        `ifdef DECODING_MSG            
            $fdisplay(file_result,"1 A symbol 0 is rxed. @ %t.\n",$time);
        `endif
        symbol_cnt = 0;    
    end
    @(posedge tag_data);
    stamp3_pos = $time;
    stamp1_pos = stamp3_pos;
    FM0_dec_en = 1;            // FM0 decoding begin
    FM0_decoding = 1'b1;      // going into decoding process
    // build a naming block, used by our code to detemine when to stop decoding 
    begin : FM0_DECODE
        while(FM0_dec_en)
        begin
            @(negedge tag_data);
            stamp2_neg = $time;
            if(posedge_cnt > 1)
            begin
            if(((stamp2_neg-stamp1_pos)>half_Tpri_LB)&&((stamp2_neg-stamp1_pos)<half_Tpri_UB))
            begin // judge this symbol is 0 or not
                rxed_symbol = 1'b0;
                symbol_cnt = symbol_cnt + 1;
                /*`ifdef DECODING_MSG
                    $fdisplay(file_result,"3 A symbol 0 is rxed. @ %t.\n",$time);
                `endif */ // revised August 6th 2008
            end
            else if(((stamp2_neg-stamp1_pos)>Tpri_real_LB)&&((stamp2_neg-stamp1_pos)<Tpri_real_UB))
            begin // judge this symbol is 1 or not
               rxed_symbol = 1'b1;
               symbol_cnt = symbol_cnt + 1;
               /*`ifdef DECODING_MSG
                   $fdisplay(file_result,"4 A symbol 1 is rxed. @ %t.\n",$time);
               `endif */ //revised August 6th 2008
            end
            else if(((stamp2_neg-stamp1_pos)>oah_Tpri_LB)&&((stamp2_neg-stamp1_pos)<oah_Tpri_UB))
            begin // judge this symbol is violation or not
                $fdisplay(file_result,"Fatal Error : FM0 data Phase does not inverted! @ %t \n",$time);
//                #1000 $finish;
            end
            else
            begin
                $fdisplay(file_result,"Fatal Error : Tag data length error! @ %t",$time);
//                #1000 $finish;
            end
            end
            @(posedge tag_data);  
                posedge_cnt =posedge_cnt +1;             
                stamp3_pos = $time;
                if(posedge_cnt> 1)
                begin
                if((stamp3_pos-stamp2_neg)>Tpri_real_LB &&(stamp3_pos-stamp2_neg)<Tpri_real_UB)
                begin
                    rxed_symbol = 1'b1;
                    symbol_cnt = symbol_cnt + 1;
                    /*`ifdef DECODING_MSG
                        $fdisplay(file_result,"5 A symbol 1 is rxed. @ %t.\n",$time);
                    `endif */ //revised August 6th 2008
                end
                else if(((stamp3_pos-stamp2_neg)>oah_Tpri_LB)&&((stamp3_pos-stamp2_neg)<oah_Tpri_UB))
                     begin
                     `ifndef FULL_FUNC
                     rxed_symbol = 1'b1;   //actually it is V!
                     symbol_cnt = symbol_cnt + 1;
                     $fdisplay(file_result,"Successfully detect Phase violation in FM0 Preamble! @ %t \n",$time);
                     `endif
                    end       
               else if( ~( ((stamp3_pos-stamp2_neg)>half_Tpri_LB) && ((stamp3_pos-stamp2_neg)<half_Tpri_UB) ) )
                   begin
                       $fdisplay(file_result,"Tag data rate wrong. @ %t.\n",$time);
//                       #1000 $finish;
                   end   
               end
            stamp1_pos = stamp3_pos;
         end
     end
     FM0_decoding = 1'b0;
     rxed_symbol =1'b0;
 end
endtask    

initial    
begin
    restored_clk = 0;
    forever
    begin    	
    	  if (FM0_dec_en || Miller_dec_en)// revised 2010-3-11,add decoding clk for miller
    				begin
        				#(Tpri_real/4)
        				restored_clk = ~restored_clk;
        		end
        else if(FM0_clk_cnt >2)
        		begin
        				#(Tpri_real/4);
        				restored_clk = ~restored_clk;
        		end
        else
            begin
          		#(100);
       				restored_clk = 0; 
       		  end								
    end
end


always @(posedge restored_clk or posedge tag_data)
begin 
    if(tag_data == 1'b1)
        FM0_clk_cnt = 1'b0;
    else if(FM0_decoding == 1'b1)
        FM0_clk_cnt = FM0_clk_cnt + 1;
    else 
        FM0_clk_cnt = 1'b0;
end

// determine when to stop FM0 decode
always @(FM0_clk_cnt)
begin   // determine at what time to stop decode process
    if(FM0_clk_cnt > (oah_Tpri/(Tpri_real/2))) 
    begin
        FM0_dec_en = 1'b0;
        disable FM0_decode.FM_U.FM0_DECODE;
        $fdisplay(file_result,"FM0 decode stoped @ %t.\n",$time);
    end
    else if(FM0_decoding)
        FM0_dec_en = 1'b1;
end


//##############################################//
//                Miller_decoder                //
//##############################################//
initial
begin
    Miller_cnt        = 0;
    Miller_ending_cnt = 0;
    Miller_decoding   = 1'b0;
    Miller_dec_en     = 1'b0;
    Miller8_temp      = 16'b0;
    Miller4_temp      = 8'b0;
    Miller2_temp      = 4'b0;
end

always @(posedge restored_clk)
begin
    if(Miller_decoding)
        Miller_cnt <= Miller_cnt + 1;
    else
        Miller_cnt <= 1;
end

always @(posedge restored_clk or posedge tag_data)
begin 
    if(tag_data == 1'b1)
        Miller_ending_cnt = 1'b0;
    else if(Miller_decoding == 1'b1)
        Miller_ending_cnt = Miller_ending_cnt + 1;
    else 
        Miller_ending_cnt = 1'b0;
end

// controling when to stop the Miller decode task
always @(Miller_ending_cnt)
begin   // determine at what time to stop decode process
    if(M_value == `M_MILLER8)
    begin
        if(Miller_ending_cnt >16)
        begin
            Miller_dec_en = 1'b0;
            $fdisplay(file_result,"Miller decode stoped @ %t.\n",$time);
            disable Miller_decode.MILLER8_DECODE;
        end
        else if(Miller_decoding)
            Miller_dec_en = 1'b1;
    end
    else if(M_value == `M_MILLER4)
    begin
        if(Miller_ending_cnt >8)
        begin
            Miller_dec_en = 1'b0;
            $fdisplay(file_result,"Miller decode stoped @ %t.\n",$time);
            disable Miller_decode.MILLER4_DECODE;
        end
        else if(Miller_decoding)
            Miller_dec_en = 1'b1;
    end
    else if(M_value == `M_MILLER2)
    begin
        if(Miller_ending_cnt > 4)
        begin 
            Miller_dec_en = 1'b0;
            $fdisplay(file_result,"Miller decode stoped @ %t.\n",$time);
            disable Miller_decode.MILLER2_DECODE;
        end
        else if(Miller_decoding)
            Miller_dec_en = 1'b1;
    end
end

// ----------------------------------------------------------
// Miller decode task
// ----------------------------------------------------------
// Miller decode process is simpler than FM0 decode. 
// basiclly this task detect the high 
// width for data1 or data0,and low width for data1.
// the violation of phase in preamble can be also
// detected using this way.
// it is called in the following way:
// send_XXXX;
// Miller_decode;

task Miller_decode;  // code OK 
                     //      ___     ___
time     stamp1_pos; // ____|   |___|   |__  signal's rising edge
                     //      ___     ___
time     neg1_stamp; // ____|   |___|   |__  signal's falling edge
integer  index     ;
integer  denotes   ;
begin
    if(M_value == `M_FM0)
        $fdisplay(file_result,"Fatal Error: Can't do Miller decode when tag using FM0 coding!\n");
    else
        $fdisplay(file_result,"Miller decode begin. @ %t .\n",$time);
    symbol_cnt = 1;
    tdata_buffer = `TDATA_BUF_LEN'b0; // clear the data buffer
    @(posedge tag_data);
    stamp1_pos = $time; // capture the first rising edge time
    T1_Miller = stamp1_pos - LAST_EDGE ;
    `ifdef FULL_FUNC //check T1
     if(cmd_send_w == 1'b0)   
     begin
        if((stamp1_pos-send_done)>MIN_T1 &&(stamp1_pos-send_done)<MAX_T1)
            $fdisplay(file_result,"T1 is satisfied!\n");
        else if((stamp1_pos-send_done)<MIN_T1)
        begin
            $fdisplay(file_result,"T1 is too short! @ %t.\n",$time);
            #1000 $finish;
        end
        else if((stamp1_pos-send_done)>MAX_T1)
        begin
            $fdisplay(file_result,"T1 is too long! @ %t.\n",$time); 
            #1000 $finish;
        end
    end
    else if(cmd_send_w == 1'b1)
    begin
        if((stamp1_pos-send_done)>`TREPLY)
        begin
            $fdisplay(file_result,"T1 is too long! @ %t.\n",$time); 
            #1000 $finish;
        end
    end
    `endif
    @(negedge tag_data)
    neg1_stamp = $time;    
    // here Tpri only has a width of shortest high pulse pluse low pulse
    // actually it is M*Tpri long, using this width is for the 
    // conveniently decoding procedure 
    Tpri_real_Miller = (neg1_stamp-stamp1_pos)*2; // calc Tpri to restore the encoding clock
    `ifdef FULLFUNC
    if(Tpri_real_Miller>Tpri_UB || Tpri_real_Miller<Tpri_LB)
    begin
        $fdisplay(file_result,"Fatal Error: Tag sending data at a wrong data length. @ %t.\n",$time);
        $fdisplay(file_result,"Required symbol rate is %d ~ %d\n",Tpri_LB,Tpri_UB);
        $fdisplay(file_result,"Symbol Length at %d.\n",Tpri_real);
    end
    else
        $fdisplay(file_result,"Symbol rate is correct, move on!\n");
    `endif
    Miller_decoding = 1; //caution about the initial sequence
    Miller_dec_en = 1;
    Miller_cnt = 1;  // initial the counter
    denotes = 0;
    if(M_value == `M_MILLER8)
    begin
        // because the first high pulse of tag data is not captured by the restored clk,so push an 1 symbol
        Miller8_temp[0] = 1; 
        begin : MILLER8_DECODE
            while(Miller_dec_en)
            begin
                @(posedge restored_clk);
                Miller8_temp = {Miller8_temp[14:0],tag_data};
                 denotes = 0;
                if((Miller_cnt+1)%16 == 0)//ok, checked @2010-3-11
                //if(Miller_cnt%16 == 0)// revised 2010-3-11
                begin
                    for(index = 15;index >= 1;index = index -1)
                    begin
                        if({Miller8_temp[index],Miller8_temp[index-1]} == 2'b11 ||
                           {Miller8_temp[index],Miller8_temp[index-1]} == 2'b00)
                           denotes = denotes + 1;
                        else
                           denotes = denotes;
                    end
                    // judge there is a 1 or not
                    if(denotes == 1)
                    begin    
                        rxed_symbol = 1'b1;
                   
                    end
                    `ifdef FULL_FUNC
                    else if(denotes>1)
                    begin
                        $fdisplay(file_result,"Fatal Error,can not have several 1 in one symbol.@ %t.\n",$time);
                        #1000 $finish;
                    end
                    `endif
                    else
                        rxed_symbol = 1'b0;
                    // judge this symbol is first one or not
                    if((Miller_cnt+1)/16 == 1)
                        symbol_cnt = 1'b0;
                    else
                        symbol_cnt = symbol_cnt + 1;
                    //display msg     
                   `ifdef DECODING_MSG
                    if(rxed_symbol == 1'b1)
                        $fdisplay(file_result,"A symbol 1 has received. @ %t.\n",$time);
                    else
                        $fdisplay(file_result,"A symbol 0 has received. @ %t.\n",$time);
                    `endif
                end
            end
        end
        Miller_decoding = 0;
    end
    if(M_value == `M_MILLER4)
    begin 
        // because the first high pulse of tag data is not captured by the restored clk,so push an 1 symbol
        Miller4_temp[0] = 1;
        begin : MILLER4_DECODE
            while(Miller_dec_en)  
            begin
                @(posedge restored_clk);
                Miller4_temp = {Miller4_temp[6:0],tag_data};
                if((Miller_cnt+1)%8 == 0)  // ok,2010-3-11,accoding to the simulation wave
                //if (Miller_cnt%8 == 0)   // revised 2010-3-11,
                begin
                    denotes = 0;
                    for(index = 7;index >= 1;index = index -1)
                    begin
                        if({Miller4_temp[index],Miller4_temp[index-1]} == 2'b11 ||
                           {Miller4_temp[index],Miller4_temp[index-1]} == 2'b00)
                           denotes = denotes + 1;
                        else
                           denotes = denotes;
                    end
                    // judge there is a 1 or not
                    if(denotes == 1)
                    begin    
                        rxed_symbol = 1'b1;
                        
                    end
                    `ifdef FULL_FUNC
                    else if(denotes>1)
                    begin
                        $fdisplay(file_result,"Fatal Error ,can't not have several 1 in one symbol.@ %t.\n",$time);
                        #1000 $finish;
                    end
                    `endif
                    else
                        rxed_symbol = 1'b0;
                     // judge this symbol is first one or not
                    if((Miller_cnt+1)/8 == 1)
                        symbol_cnt = 1'b0;
                    else
                        symbol_cnt = symbol_cnt + 1;
                    //display msg  
                    `ifdef DECODING_MSG
                    if(rxed_symbol == 1'b1)
                        $fdisplay(file_result,"A symbol 1 has received. @ %t.\n",$time);
                    else
                        $fdisplay(file_result,"A symbol 0 has received. @ %t.\n",$time);
                    `endif
                end
            end
        end     
        Miller_decoding = 0;
    end
    if(M_value == `M_MILLER2)
    begin
        // because the first high pulse of tag data is not captured by the restored clk,so push an 1 symbol
        Miller2_temp[0] = 1;
        begin : MILLER2_DECODE
            while(Miller_dec_en)  
            begin
                @(posedge restored_clk);
                Miller2_temp = {Miller2_temp[2:0],tag_data};
                denotes = 0;
                //if((Miller_cnt+1)%4 == 0)
                if ((Miller_cnt+1)%4 == 0)//revised 2010-3-11,accoding to the simulation wave
                begin
                    for(index = 3;index >= 1;index = index -1)
                    begin
                        if(({Miller2_temp[index],Miller2_temp[index-1]}) == 2'b11 ||
                           ({Miller2_temp[index],Miller2_temp[index-1]}) == 2'b00)
                           denotes = denotes + 1;
                        else
                           denotes = denotes;
                    end
                    // judge there is a 1 or not
                    if(denotes == 1)
                    begin    
                        rxed_symbol = 1'b1;
                        
                    end
                    `ifdef FULL_FUNC
                    else if(denotes>1)
                    begin
                        $fdisplay(file_result,"Fatal Error ,can't not have several 1 in one symbol.@ %t.\n",$time);
                        #1000 $finish;
                    end
                    `endif
                    else
                        rxed_symbol = 1'b0;
                    // judge this symbol is first one or not
                    if((Miller_cnt+1)/4 == 1)
                        symbol_cnt = 1'b0;
                    else
                        symbol_cnt = symbol_cnt + 1;
                    //display msg  
                    `ifdef DECODING_MSG
                    if(rxed_symbol == 1'b1)
                        $fdisplay(file_result,"A symbol 1 has received. @ %t.\n",$time);
                    else
                        $fdisplay(file_result,"A symbol 0 has received. @ %t.\n",$time);
                    `endif
                end
            end
        end
        Miller_decoding = 0;
    end
    rxed_symbol = 0;
end
endtask
// ----------------------------------------------------------
// Data buffering block
// ----------------------------------------------------------
// data buffering block, receive data from FM0 or Miller
// decode task, and temply processing it and store it
// into tdata_buffer register,waiting the following task 
// to intercept it.
always @(FM0_decoding or Miller_decoding or symbol_cnt)//or Miller_pos_cnt or Miller_decoding)       // code OK
begin
    if(FM0_decoding == 1'b1)
        begin                                        
            begin
                if(Trext_value == 1'b0)  
                    if(symbol_cnt>3)
                       
                            tdata_buffer[`TDATA_BUF_LEN-symbol_cnt+3] = rxed_symbol;
                            /*`ifdef DECODING_MSG
                                $fdisplay(file_result,"%d th Data %b stored @ %t.\n",symbol_cnt,rxed_symbol,$time);
                            `endif */ // revised August 6th 2008
                       
                    else
                        tdata_buffer = tdata_buffer;
                else
                    if(symbol_cnt>16)
                         tdata_buffer[`TDATA_BUF_LEN-symbol_cnt+16] = rxed_symbol;    
                         
                    else                                       
                         tdata_buffer = tdata_buffer;           
            end
        end
    else if(Miller_decoding == 1'b1)
        begin         
            if(Trext_value == 1'b0)      
                if(symbol_cnt >11)
                    begin
                        tdata_buffer[`TDATA_BUF_LEN-symbol_cnt+11] = rxed_symbol;
                        `ifdef DECODING_MSG
                            $fdisplay(file_result,"%d th Data %b stored @ %t.\n",symbol_cnt,rxed_symbol,$time);
                        `endif
                    end  
                else
                    tdata_buffer = tdata_buffer;      
           else
               
                if(symbol_cnt >23)
                    begin
                     tdata_buffer[`TDATA_BUF_LEN-symbol_cnt+23] = rxed_symbol;
                        `ifdef DECODING_MSG
                            $fdisplay(file_result,"%d th Data %b stored @ %t.\n",symbol_cnt,rxed_symbol,$time);
                        `endif       
                    end
                else
                    tdata_buffer = tdata_buffer;   
        end
    else
        tdata_buffer = tdata_buffer;
end

//##################################################//
//             Basic Task                           //
//##################################################//
task send_cmd_bit; 
input [1:0] data;
begin
    data_to_tag = 1;
    if(data == 2'b00)     
        begin
            # TC data_to_tag = 0; 
            # TC data_to_tag= 1;
        end
    else if(data == 2'b01)           
        begin
            # TC2  data_to_tag = 0;         
            # TC   data_to_tag = 1;
        end
    else if(data == 2'b11)
        begin
            # TC3  data_to_tag = 0;            
            # TC   data_to_tag = 1;
        end
    else
        begin             
            # TC4  data_to_tag = 0;
            # TC   data_to_tag = 1;
        end
end
endtask


task crc16_calc;  //clac 
input [1:0] data;
begin
    NewCRC16[0] = data[0] ^ CRC16[14];
    NewCRC16[1] = data[1] ^ CRC16[15];
    NewCRC16[2] = CRC16[0];
    NewCRC16[3] = CRC16[1];
    NewCRC16[4] = CRC16[2];
    NewCRC16[5] = data[0] ^ CRC16[3] ^ CRC16[14];
    NewCRC16[6] = data[1] ^ CRC16[4] ^ CRC16[15];
    NewCRC16[7] = CRC16[5];
    NewCRC16[8] = CRC16[6];
    NewCRC16[9] = CRC16[7];
    NewCRC16[10] = CRC16[8];
    NewCRC16[11] = CRC16[9];
    NewCRC16[12] = data[0] ^ CRC16[10] ^ CRC16[14];
    NewCRC16[13] = data[1] ^ CRC16[11] ^ CRC16[15];
    NewCRC16[14] = CRC16[12];
    NewCRC16[15] = CRC16[13];
    CRC16 =NewCRC16;
end
endtask

task crc16_calc_0;  //special for sec_com
input [1:0] data;
begin
    NewCRC16_0[0] = data[0] ^ CRC16_0[14];
    NewCRC16_0[1] = data[1] ^ CRC16_0[15];
    NewCRC16_0[2] = CRC16_0[0];
    NewCRC16_0[3] = CRC16_0[1];
    NewCRC16_0[4] = CRC16_0[2];
    NewCRC16_0[5] = data[0] ^ CRC16_0[3] ^ CRC16_0[14];
    NewCRC16_0[6] = data[1] ^ CRC16_0[4] ^ CRC16_0[15];
    NewCRC16_0[7] = CRC16_0[5];
    NewCRC16_0[8] = CRC16_0[6];
    NewCRC16_0[9] = CRC16_0[7];
    NewCRC16_0[10] = CRC16_0[8];
    NewCRC16_0[11] = CRC16_0[9];
    NewCRC16_0[12] = data[0] ^ CRC16_0[10] ^ CRC16_0[14];
    NewCRC16_0[13] = data[1] ^ CRC16_0[11] ^ CRC16_0[15];
    NewCRC16_0[14] = CRC16_0[12];
    NewCRC16_0[15] = CRC16_0[13];
    CRC16_0 =NewCRC16_0;
end
endtask


//crc_check
task crc16_check_bit;  //The one-bit-in check matchine has the same performance to this one!
input [1:0] data;
begin
    NewCRC16_1[0] = data[0] ^ rx_crc16_data[14];
    NewCRC16_1[1] = data[1] ^ rx_crc16_data[15];
    NewCRC16_1[2] = rx_crc16_data[0];
    NewCRC16_1[3] = rx_crc16_data[1];
    NewCRC16_1[4] = rx_crc16_data[2];
    NewCRC16_1[5] = data[0] ^ rx_crc16_data[3] ^ rx_crc16_data[14];
    NewCRC16_1[6] = data[1] ^ rx_crc16_data[4] ^ rx_crc16_data[15];
    NewCRC16_1[7] = rx_crc16_data[5];
    NewCRC16_1[8] = rx_crc16_data[6];
    NewCRC16_1[9] = rx_crc16_data[7];
    NewCRC16_1[10] = rx_crc16_data[8];
    NewCRC16_1[11] = rx_crc16_data[9];
    NewCRC16_1[12] = data[0] ^ rx_crc16_data[10] ^ rx_crc16_data[14];
    NewCRC16_1[13] = data[1] ^ rx_crc16_data[11] ^ rx_crc16_data[15];
    NewCRC16_1[14] = rx_crc16_data[12];
    NewCRC16_1[15] = rx_crc16_data[13];
    rx_crc16_data =NewCRC16_1;
end
endtask



endmodule