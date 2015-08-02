// ************************************************************** 
// COPYRIGHT, Xi'an XDU Radio-frequency IC Co.,Ltd 
// All rights reserved. 
// 
// IP LIB INDEX : IP lib index just sa UTOPIA_B 
// IP Name      : OPTIM
//
// File name    : ocu.v
// Module name  : OCU
// Full name    : Output Control Unit 
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

module OCU(
                //inputs
                DOUB_BLF,
                rst_n,                
                ocu_en,
                TRext,
                m_value,                
                membank,
                pointer,
                length,
                data_buffer,
                rd_done,
                wr_done,
                mtp_data,
                rn16,
                handle,
                lock_state,
                CRC16_EPC,
                EPC_SOA,
                pc_val,
                ver_code,
                init_done,
                new_cmd,
                bsc,
                tag_state,
                T2_CHK_EN,
                vee_err,
                
                //outputs
                ocu_done,
                ocu_pointer,
                ocu_rd_pulse,
                wr_pulse,
                data_wr,
                T2_OT_PULSE,
                dout
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
    //states for OCU
    parameter OCU_RDY         =4'b0000;
    parameter READ_CHK        =4'b0001;
    parameter WRITE_CHK       =4'b0010;
    parameter ELSE_CHK        =4'b0011;    
    parameter WRITE_MTP       =4'b0100;
    parameter KILL_TAG        =4'b0101;
    parameter LOCK_TAG        =4'b0110;
    parameter PRE_BSC         =4'b0111;
    parameter BSC_DATA        =4'b1000;
    parameter LOCK_CHK        =4'b1001;
    parameter KILL_CHK        =4'b1010;
    parameter OCU_END         =4'b1011;
    parameter NOP_ONE         =4'b1100;
    parameter NOP_TWO         =4'b1101;
    parameter NOP_THR         =4'b1110;
    parameter NOP_FOU         =4'b1111;    
    //membank
    parameter RSV             =2'b00;
    parameter EPC             =2'b01;
    parameter TID             =2'b10;
    parameter USER            =2'b11;    
    //states for encoder
    parameter ENC_RDY         =3'b000;
    parameter POS_ZERO        =3'b001;
    parameter POS_ONE         =3'b010;
    parameter NEG_ZERO        =3'b011;
    parameter NEG_ONE         =3'b100;
    //back scatered types.
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
    
    //inputs
    input              DOUB_BLF;
    input              rst_n;
    input              ocu_en;
    input              TRext;
    input     [1:0]    m_value;
    input     [1:0]    membank;
    input     [13:0]   pointer;
    input     [7:0]    length;
    input     [19:0]   data_buffer;
    input              rd_done;
    input              wr_done;
    input     [15:0]   mtp_data;
    input     [15:0]   rn16;
    input     [15:0]   handle;
    input     [9:0]    lock_state;
    input     [15:0]   CRC16_EPC;
    input     [4:0]    EPC_SOA;
    input     [15:0]   pc_val;
    input     [7:0]    ver_code;
    input              init_done;
    input              new_cmd;
    input     [3:0]    bsc;
    input     [3:0]    tag_state;
    input              T2_CHK_EN;
    input              vee_err;
                
    //outputs
    output             ocu_done;
    output    [4:0]    ocu_pointer;
    output             ocu_rd_pulse;
    output             wr_pulse;
    output    [15:0]   data_wr;
    output             T2_OT_PULSE;
    output             dout;
    
    //regs
    reg                ocu_done;
    reg                ocu_rd_pulse;
    reg                T2_OT_PULSE;
    reg                dout;
    ////////////////BSC_CHK   
    reg                rchk_pulse;
    reg                wchk_pulse;
    reg                addr_over;
    reg                addr_lock;
    reg                lock_err;
    reg                pc_err;
    ////////////////PRE-TREAT
    reg                addr_pulse;
    reg       [3:0]    bs_type;   
    reg       [7:0]    err_code;
    ////////////////WRITE
    reg       [15:0]   data_wr;
    reg                write_en;
    reg                wr_flg;
    reg                wr_pulse;
    ////////////////ENCODER
    reg                pre_pulse;
    reg                rst_pulse;
    reg                bsc_done;    
    reg                SEC_BLF;
    reg                QTR_BLF;
    reg                ETH_BLF;
    reg                enc_en_ctrl;
    reg                enc_en;
    reg                enc_clk;
    reg       [2:0]    enc_state;
    reg                clk_buf_a;
    reg                clk_buf_b;
    reg                clk_buf_c;
    reg                clk_buf_d;
    reg                bool_pilot;                     //For telling if there are pilot.
    reg                bool_preamble;
    reg       [15:0]   enc_buf;     
    reg                data_end;                      //Set it to high when data has finished receiving.
    reg                enc_end;    
    reg                bit_mask;                      //For telling the FSM whether the current enc_state-jumping is violative.
    reg       [3:0]    max_cnt;
    reg       [3:0]    bit_cnt;
    reg       [4:0]    frm_cnt;
    reg       [4:0]    abs_ptr;  
    reg       [4:0]    word_cnt;
    reg       [4:0]    rd_len;
    reg       [4:0]    rd_end;
    reg       [4:0]    end_cnt;  
    ////////////////CRC16
    reg       [15:0]   CRC16;
    reg                crc_en;
    ////////////////FSM
    reg       [3:0]    ocu_state;
    reg       [3:0]    nxt_state;
    ////////////////
    reg                gate_ctrl;
    ////////////////T2
    reg       [5:0]    T2_CNT;
    reg                T2_CLK_EN;
       
    //wires
    ////////////////
    wire               ocu_rst;
    wire      [19:0]   payload;
    wire      [9:0]    lock_act;
    wire               enc_done;   
    wire               ocu_clk;
    wire               base_clk;
    wire               enc_rst;
    //wire               enc_clk;
    wire               bit_in;    
    wire               addr_err; 
    wire      [4:0]    addr_start;
    wire      [5:0]    addr_end;
    wire      [1:0]    ACT_KILL;
    wire      [1:0]    ACT_ACS;
    wire      [1:0]    ACT_EPC;
    wire      [1:0]    ACT_TID;
    wire      [1:0]    ACT_USER; 
    wire      [4:0]    epc_len;
    wire      [4:0]    epc_end;
    ////////////////WRITE
    wire      [15:0]   WR_BUF;
    wire               vee_err;
    ////////////////ENCODER    
    wire               data_pulse; 
    wire               st_pulse;   
    wire               bit_pulse;
    wire               sos_pulse;
    wire               mos_pulse;
    ////////////////T2
    wire               T2_CLK;
    ////////////////CRC16
    wire               crc_pulse;
    
    //********************************************************//
    
    always @(posedge DOUB_BLF or negedge rst_n)
    begin
        if(!rst_n)
            gate_ctrl<=`UDLY 1'b0;
        else if(ocu_en)
            gate_ctrl<=`UDLY 1'b1;
        else
            gate_ctrl<=`UDLY 1'b0;
    end
    
    assign ocu_clk=DOUB_BLF&ocu_en&gate_ctrl;
    
    assign ocu_rst=rst_n&~new_cmd;
    
    //State jumps.
    always @(posedge ocu_clk or negedge ocu_rst)
    begin
       if(!ocu_rst)
            ocu_state<=`UDLY OCU_RDY;
        else
            ocu_state<=`UDLY nxt_state;
    end
    
    //Prepare the next state.
    always @(bsc or addr_err or pc_err or vee_err or lock_err or wr_done or bsc_done or ocu_state or tag_state)
    begin
        case(ocu_state)
        OCU_RDY:
            case(bsc)
            BS_NONE:
                nxt_state=OCU_END; 
            ET_READ:
                nxt_state=READ_CHK;
            ET_WRITE:
                nxt_state=WRITE_CHK;         
            ET_LOCK:
                nxt_state=LOCK_CHK;
            ET_KILL:
                nxt_state=KILL_CHK;            
            default:
                nxt_state=ELSE_CHK;
            endcase
        ELSE_CHK:
            nxt_state=PRE_BSC;
        READ_CHK:
            nxt_state=PRE_BSC;
        WRITE_CHK:
            if(addr_err|pc_err|vee_err)
                nxt_state=PRE_BSC;
            else
                nxt_state=WRITE_MTP;        
        LOCK_CHK:
            if(lock_err|vee_err)
                nxt_state=PRE_BSC;
            else
                nxt_state=LOCK_TAG;
        KILL_CHK:
            if(tag_state==HALF_KILLED)            
                nxt_state=PRE_BSC;
            else if(vee_err)
                nxt_state=PRE_BSC;
            else 
                nxt_state=KILL_TAG;
        WRITE_MTP:
            if(wr_done)
                nxt_state=PRE_BSC;
            else
                nxt_state=WRITE_MTP;
        KILL_TAG:
            if(wr_done)
                nxt_state=PRE_BSC;
            else
                nxt_state=KILL_TAG;
        LOCK_TAG:
            if(wr_done)
                nxt_state=PRE_BSC;
            else
                nxt_state=LOCK_TAG;
        PRE_BSC:
            nxt_state=NOP_ONE;
        NOP_ONE:
            nxt_state=NOP_TWO;
        NOP_TWO:
            nxt_state=NOP_THR;
        NOP_THR:
            nxt_state=NOP_FOU;
        NOP_FOU:
            nxt_state=BSC_DATA;    
        BSC_DATA:
            if(bsc_done)
                nxt_state=OCU_END;
            else
                nxt_state=BSC_DATA;
        OCU_END:
            nxt_state=OCU_END;
        default:
            nxt_state=OCU_END;
        endcase
    end
    
    //********************************************************//
    //OCU_END
    
    //Generate ocu_done, which tell PMU that OCU has finished performing.
    always @(negedge ocu_clk or negedge ocu_rst)
    begin
        if(!ocu_rst)
            ocu_done<=`UDLY 1'b0;
        else if(ocu_done)
            ocu_done<=`UDLY 1'b0;
        else if(ocu_state==OCU_END)
            ocu_done<=`UDLY 1'b1;
        else
            ocu_done<=`UDLY 1'b0;
    end
    
    //********************************************************//
    //BSC_CHK
    assign addr_start=pointer[4:0];
    
    assign addr_end={1'b0,pointer[4:0]}+{1'b0,length[4:0]};    
    
    assign addr_err=addr_over|addr_lock;
    
    assign chk_pulse=rchk_pulse|wchk_pulse;
    
    //Generate a pulse for checking the address of read.
    always @(negedge ocu_clk or negedge rst_n)
    begin
        if(!rst_n)
            rchk_pulse<=`UDLY 1'b0;
        else if(ocu_state==READ_CHK)
            rchk_pulse<=`UDLY 1'b1;
        else
            rchk_pulse<=`UDLY 1'b0;
    end
    
    //Generate a pulse for checking the address of write.
    always @(negedge ocu_clk or negedge rst_n)
    begin
        if(!rst_n)
            wchk_pulse<=`UDLY 1'b0;
        else if(ocu_state==WRITE_CHK)
            wchk_pulse<=`UDLY 1'b1;
        else
            wchk_pulse<=`UDLY 1'b0;
    end
    
    //Check if the address is over end of bank.
    always @(posedge chk_pulse or negedge ocu_rst)
    begin
        if(!ocu_rst)
            addr_over<=`UDLY 1'b0;
        else if(length==8'd0)
            addr_over<=`UDLY 1'b1;
        else if(pointer[13:5]==9'h00)        
            case(membank)
            RSV:
                if(addr_end>5'h04) 
                    addr_over<=`UDLY 1'b1;
                else
                    addr_over<=`UDLY 1'b0;
            EPC:
                if(addr_end>epc_end)
                    addr_over<=`UDLY 1'b1;
                else
                    addr_over<=`UDLY 1'b0;
            TID:
                if(addr_end>5'h08) 
                    addr_over<=`UDLY 1'b1;
                else
                    addr_over<=`UDLY 1'b0;
            USER:
                if(addr_end>5'h0a)
                    addr_over<=`UDLY 1'b1;
                else
                    addr_over<=`UDLY 1'b0;
            endcase
        else
            addr_over<=`UDLY 1'b1;
    end
    
    always @(posedge chk_pulse or negedge ocu_rst)
    begin
        if(!ocu_rst)
            addr_lock<=`UDLY 1'b0;
        else if(membank==RSV)
            if(addr_start>5'h01)                                       //For access-pwd location
                if(ACT_ACS==2'b11)
                    addr_lock<=`UDLY 1'b1;
                else if(ACT_ACS==2'b10&&tag_state==OPEN)
                    addr_lock<=`UDLY 1'b1;
                else
                    addr_lock<=`UDLY 1'b0;
            else                                                       //For kill-pwd location
                if(ACT_KILL==2'b11)
                    addr_lock<=`UDLY 1'b1;
                else if(ACT_KILL==2'b10&&tag_state==OPEN)
                    addr_lock<=`UDLY 1'b1;
                else
                    addr_lock<=`UDLY 1'b0;
        else if(bsc==ET_WRITE)
            case(membank)
            EPC:
                if(ACT_EPC==2'b11)
                    addr_lock<=`UDLY 1'b1;
                else if(ACT_EPC==2'b10&&tag_state==OPEN)
                    addr_lock<=`UDLY 1'b1;
                else
                    addr_lock<=`UDLY 1'b0;
            TID:
                if(ACT_TID==2'b11)
                    addr_lock<=`UDLY 1'b1;
                else if(ACT_TID==2'b10&&tag_state==OPEN)
                    addr_lock<=`UDLY 1'b1;
                else
                    addr_lock<=`UDLY 1'b0;
            USER:
                if(ACT_USER==2'b11)
                    addr_lock<=`UDLY 1'b1;
                else if(ACT_USER==2'b10&&tag_state==OPEN)
                    addr_lock<=`UDLY 1'b1;
                else
                    addr_lock<=`UDLY 1'b0;
            endcase
        else
            addr_lock<=`UDLY 1'b0;
    end
    
    //Ckeck if the value of pc to write is valid.
    always @(posedge wchk_pulse or negedge ocu_rst)
    begin
        if(!ocu_rst)
            pc_err<=`UDLY 1'b0;
        else if(membank==EPC)
            if(pointer==14'h0001)
                if(WR_BUF[15:11]>5'd6)
                    pc_err<=`UDLY 1'b1;
                else
                    pc_err<=`UDLY 1'b0;
            else
                pc_err<=`UDLY 1'b0;
        else
            pc_err<=`UDLY 1'b0;   
    end
       
    //********************************************************//
    //LOCK_CHK
    
    assign ACT_KILL=lock_state[9:8];
    assign ACT_ACS =lock_state[7:6];
    assign ACT_EPC =lock_state[5:4];
    assign ACT_TID =lock_state[3:2];
    assign ACT_USER=lock_state[1:0];
    
    assign payload=data_buffer;
    
    //Prepare datas for locking tag.
    assign lock_act[0]=payload[10]? payload[0] : lock_state[0];//User
    assign lock_act[1]=payload[11]? payload[1] : lock_state[1];
    assign lock_act[2]=payload[12]? payload[2] : lock_state[2];//TID
    assign lock_act[3]=payload[13]? payload[3] : lock_state[3];
    assign lock_act[4]=payload[14]? payload[4] : lock_state[4];//UII
    assign lock_act[5]=payload[15]? payload[5] : lock_state[5];
    assign lock_act[6]=payload[16]? payload[6] : lock_state[6];//Access
    assign lock_act[7]=payload[17]? payload[7] : lock_state[7];
    assign lock_act[8]=payload[18]? payload[8] : lock_state[8];//Kill
    assign lock_act[9]=payload[19]? payload[9] : lock_state[9];    
    
    //Judge if Lock is right.
    always @(negedge ocu_clk or negedge ocu_rst)
    begin
        if(!ocu_rst)
            lock_err<=`UDLY 1'b0;
        else if(ocu_state==LOCK_CHK)
            if((~lock_act&10'b0101010101)&(lock_state&10'b0101010101))      //doesn't allow unlock permalock-bit.
                lock_err<=`UDLY 1'b1;
            else if(ACT_KILL[0]==1'b1&&lock_act[9:8]!=ACT_KILL) //if(ACT_KILL==2'b01&&lock_act[9:8]!=2'b01)
                lock_err<=`UDLY 1'b1;
            else if(ACT_ACS[0]==1'b1&&lock_act[7:6]!=ACT_ACS)  //if(ACT_ACS==2'b01&&lock_act[7:6]!=2'b01)
                lock_err<=`UDLY 1'b1;
            else if(ACT_EPC[0]==1'b1&&lock_act[5:4]!=ACT_EPC)  //if(ACT_EPC==2'b01&&lock_act[5:4]!=2'b01)
                lock_err<=`UDLY 1'b1;
            else if(ACT_TID[0]==1'b1&&lock_act[3:2]!=ACT_TID)  //if(ACT_TID==2'b01&&lock_act[3:2]!=2'b01)
                lock_err<=`UDLY 1'b1;
            else if(ACT_USER[0]==1'b1&&lock_act[1:0]!=ACT_USER) //if(ACT_USER==2'b01&&lock_act[1:0]!=2'b01)
                lock_err<=`UDLY 1'b1;
            else
                lock_err<=`UDLY 1'b0;
        else
            lock_err<=`UDLY lock_err;
    end
    
    //********************************************************//
    //WRITE_MTP
    
    assign WR_BUF=data_buffer[15:0]^rn16;
    
    //Enable opration of writing.
    always @(negedge ocu_clk or negedge rst_n)
    begin
        if(!rst_n)
            write_en<=`UDLY 1'b0;
        else if(ocu_state==WRITE_MTP||ocu_state==LOCK_TAG||ocu_state==KILL_TAG)
            write_en<=`UDLY 1'b1;
        else
            write_en<=`UDLY 1'b0;
    end
    
    assign wr_clk=ocu_clk&write_en;
    
    //count for enc_state of write,
    always @(negedge wr_clk or negedge ocu_rst)
    begin
        if(!ocu_rst)
            wr_flg<=`UDLY 1'b0;
        else
            wr_flg<=`UDLY 1'b1;
    end
    
    //Start writing the MTP.
    always @(posedge wr_clk or negedge rst_n)
    begin
        if(!rst_n)
            wr_pulse<=`UDLY 1'b0;
        else if(wr_flg)
            wr_pulse<=`UDLY 1'b0;
        else
            wr_pulse<=`UDLY 1'b1;
    end
    
    //Prepare the data to write.
    always @(posedge wr_pulse or negedge rst_n)
    begin
        if(!rst_n)
            data_wr<=`UDLY 16'h0000;
        else
            case(ocu_state)
            WRITE_MTP:
                data_wr<=`UDLY WR_BUF;
            LOCK_TAG:
                data_wr<=`UDLY {lock_act,6'b001110};
            KILL_TAG:
                data_wr<=`UDLY 16'h3014;
            default:
                data_wr<=`UDLY data_wr;
            endcase
    end
    
    //********************************************************//
    //Manege the address for reading/writing MTP.
    
    //"ocu_state==ELSE_CHK"????
    always @(negedge ocu_clk or negedge rst_n)
    begin
        if(!rst_n)
            addr_pulse<=`UDLY 1'b0;
        else if(ocu_state==ELSE_CHK||ocu_state==READ_CHK||ocu_state==WRITE_CHK||ocu_state==LOCK_CHK||ocu_state==KILL_CHK)
            addr_pulse<=`UDLY 1'b1;
        else
            addr_pulse<=`UDLY 1'b0;
    end
    
    //Prepare the address for reading data from MTP and writing data to MTP.
    always @(posedge addr_pulse or negedge rst_n)
    begin
        if(!rst_n)
            abs_ptr<=`UDLY 5'h00;
        else
            case(bsc)
            BS_EPC_ALL:
                abs_ptr<=`UDLY 5'h08;
            BS_EPC_PART: 
                abs_ptr<=`UDLY 5'h06+EPC_SOA;
            ET_LOCK: 
                abs_ptr<=`UDLY 5'h04;
            ET_KILL: 
                abs_ptr<=`UDLY 5'h05;
            ET_READ,
            ET_WRITE:
                case(membank)
                RSV : abs_ptr<=`UDLY 5'h00+pointer[4:0];
                EPC : abs_ptr<=`UDLY 5'h06+pointer[4:0];
                TID : abs_ptr<=`UDLY 5'h0e+pointer[4:0];
                USER: abs_ptr<=`UDLY 5'h16+pointer[4:0];
                endcase
            default:
                abs_ptr<=`UDLY 5'h00;
            endcase
    end
    
    always @(posedge rd_done or negedge ocu_rst)
    begin
        if(!ocu_rst)
            word_cnt<=`UDLY 5'd0;
        else
            word_cnt<=`UDLY word_cnt+1'b1;
    end
    
    assign ocu_pointer=abs_ptr+word_cnt;
    
    //********************************************************//
    //PRE_BSC
    
    //pre-treat before encoding.
    always @(negedge ocu_clk or negedge rst_n)
    begin
        if(!rst_n)
            pre_pulse<=`UDLY 1'b0;
        else if(ocu_state==PRE_BSC)
            pre_pulse<=`UDLY 1'b1;
        else
            pre_pulse<=`UDLY 1'b0;
    end
    
    always @(posedge ocu_clk or negedge rst_n)
    begin
        if(!rst_n)
            rst_pulse<=`UDLY 1'b0;
        else if(pre_pulse)
            rst_pulse<=`UDLY 1'b1;
        else
            rst_pulse<=`UDLY 1'b0;
    end
    
    //Tell the type to be back-scattered.
    always @(posedge pre_pulse or negedge rst_n)
    begin
        if(!rst_n)
            bs_type<=`UDLY BS_NONE;
        else if(addr_err|pc_err|vee_err|lock_err)
            bs_type<=`UDLY BS_ERROR;
        else if(bsc==ET_WRITE||bsc==ET_LOCK)
            bs_type<=`UDLY BS_SUCCESS;
        else if(bsc==ET_KILL)
            if(tag_state==HALF_KILLED)
                bs_type<=`UDLY BS_HANDLE_CRC;
            else
                bs_type<=`UDLY BS_SUCCESS;
        else
            bs_type<=`UDLY bsc;
    end
    
    assign use_pilot=(TRext||bsc==ET_WRITE||bsc==ET_LOCK||(bsc==ET_KILL&tag_state==KILLED));
    
    //Prepare the error code if an error has occured.
    always @(posedge pre_pulse or negedge rst_n)
    begin
        if(!rst_n)
            err_code<=`UDLY 8'b0000_0000;
        else if(addr_over|pc_err)
            err_code<=`UDLY 8'b0000_0011;
        else if(addr_lock)
            err_code<=`UDLY 8'b0000_0100;
        else if(lock_err)
            err_code<=`UDLY 8'b0000_1111;
        else if(vee_err)
            err_code<=`UDLY 8'b0000_1011;
        else
            err_code<=`UDLY 8'b0000_0000;
    end
    
    //********************************************************//
    //BSC_DATA
    
    assign epc_len=pc_val[15:11];
    assign epc_end=epc_len+5'd2;
    
    //a level denoting that back-scattering has finished.
    always @(negedge enc_done or negedge ocu_rst)
    begin
        if(!ocu_rst)
            bsc_done<=`UDLY 1'b0;
        else
            bsc_done<=`UDLY 1'b1;
    end
        
    //Start encoder
    always @(negedge ocu_clk or negedge rst_n)
    begin
        if(!rst_n)
            enc_en<=`UDLY 1'b0;
        else if(enc_en_ctrl)
            enc_en<=`UDLY 1'b0;
        else if(ocu_state==BSC_DATA)
            enc_en<=`UDLY 1'b1;
        else
            enc_en<=`UDLY 1'b0;
    end
    
    assign base_clk=ocu_clk&enc_en;
    
    assign enc_rst=rst_n&~rst_pulse;
    
    //a pulse which denotes the end of encoding.
    assign enc_done=enc_en_ctrl&enc_en;
    
    //Half of BLF.
    always @(posedge base_clk or negedge enc_rst)
    begin
        if(!enc_rst)
            SEC_BLF<=`UDLY 1'b0;
        else if(m_value!=2'b00)
            SEC_BLF<=`UDLY ~SEC_BLF;
        else
            SEC_BLF<=`UDLY 1'b0;
    end
    
    //Quauter of BLF.
    always @(posedge SEC_BLF or negedge enc_rst)
    begin
        if(!enc_rst)
            QTR_BLF<=`UDLY 1'b0;
        else if(m_value==2'b10||m_value==2'b11)
            QTR_BLF<=`UDLY ~QTR_BLF;
        else
            QTR_BLF<=`UDLY 1'b0;
    end
    
    //ETH_BLF of BLF
    always @(posedge QTR_BLF or negedge enc_rst)
    begin
        if(!enc_rst)
            ETH_BLF<=`UDLY 1'b0;
        else if(m_value==2'b11)
            ETH_BLF<=`UDLY ~ETH_BLF;
        else
            ETH_BLF<=`UDLY 1'b0;
    end
    
    //Gennerate a clock for encoding.               
    always @(m_value or base_clk or SEC_BLF or QTR_BLF or ETH_BLF)
    begin
        case(m_value)
        2'b00: enc_clk=base_clk;
        2'b01: enc_clk=SEC_BLF;
        2'b10: enc_clk=QTR_BLF;
        2'b11: enc_clk=ETH_BLF;
        endcase
    end
                  
    always @(posedge enc_clk or negedge enc_rst)
    begin
        if(!enc_rst)
            clk_buf_a<=`UDLY 1'b0;
        else
            clk_buf_a<=`UDLY ~clk_buf_a;
    end
    
    always @(negedge base_clk or negedge enc_rst)
    begin
        if(!enc_rst)
            clk_buf_b<=`UDLY 1'b0;
        else
            clk_buf_b<=`UDLY clk_buf_a;
    end
    
    always @(posedge base_clk or negedge enc_rst)
    begin
        if(!enc_rst)
            clk_buf_c<=`UDLY 1'b0;
        else
            clk_buf_c<=`UDLY clk_buf_b;
    end
    
    always @(negedge base_clk or negedge enc_rst)
    begin
        if(!enc_rst)
            clk_buf_d<=`UDLY 1'b0;
        else
            clk_buf_d<=`UDLY clk_buf_c;
    end
    
    assign data_pulse=clk_buf_a&~clk_buf_b&(&bit_cnt)&~bool_pilot;
    
    assign st_pulse=clk_buf_b&~clk_buf_c;
    
    assign bit_pulse=clk_buf_c&~clk_buf_d;
    
    assign sos_pulse=clk_buf_b&~clk_buf_d;                                //Denotes the mid-point of a symbol.
    
    assign mos_pulse=~clk_buf_b&clk_buf_d;                                //Denotes the start of a symbol.
       
    //Initial the length.                   
    always @(bs_type or length[4:0] or epc_len or EPC_SOA)
    begin
        case(bs_type)
        ET_READ:
            rd_len=length[4:0];
        BS_EPC_ALL:
            rd_len=epc_len[4:0];
        BS_EPC_PART:
            rd_len=epc_len+2'b10-EPC_SOA;
        default:
            rd_len=5'd0;
        endcase
    end
    
    always @(bs_type or rd_len)
    begin
        if(bs_type==ET_READ||bs_type==BS_EPC_ALL||bs_type==BS_EPC_PART)
            rd_end=rd_len+2'b10;
        else
            rd_end=5'd0;
    end
    
    always @(bs_type or rd_end)
    begin
        case(bs_type)
        ET_READ:
            end_cnt=rd_end+2'b10;
        BS_EPC_ALL,
        BS_EPC_PART:
            end_cnt=rd_end+1'b1;
        default:
            end_cnt=6'd0;
        endcase
    end
    
     //Prepare the next frame of data to output.
    always @(posedge data_pulse or negedge enc_rst)
    begin
        if(!enc_rst)
            enc_buf<=`UDLY 16'h0000;
        else
            if(frm_cnt==5'd0)//Prepare the preamble.
                if(m_value==2'b00)
                    enc_buf<=`UDLY 16'b1010_1100_0000_0000;
                else
                    enc_buf<=`UDLY 16'b0000_0101_1100_0000;
            else
                case(bs_type)
                BS_HANDLE_NOCRC:
                    enc_buf<=`UDLY handle;
                BS_HANDLE_CRC:
                    if(frm_cnt==5'd1)
                        enc_buf<=`UDLY handle;
                    else
                        enc_buf<=`UDLY ~CRC16;
                BS_SUCCESS:
                    if(frm_cnt==5'd1)
                        enc_buf<=`UDLY 16'h0000;
                    else if(frm_cnt==5'd2)
                        enc_buf<=`UDLY handle;
                    else
                        enc_buf<=`UDLY ~CRC16;
                BS_RN16:
                    if(frm_cnt==5'd1)
                        enc_buf<=`UDLY rn16;
                    else
                        enc_buf<=`UDLY ~CRC16;
                ET_READ:
                    if(frm_cnt==5'd1)
                        enc_buf<=`UDLY 16'h0000;
                    else if(frm_cnt==rd_end)
                        enc_buf<=`UDLY handle;
                    else if(frm_cnt==rd_end+1'b1)
                        enc_buf<=`UDLY ~CRC16;
                    else
                        enc_buf<=`UDLY mtp_data;
                BS_EPC_ALL:
                    if(frm_cnt==5'd1)
                        enc_buf<=`UDLY pc_val;           
                    else if(frm_cnt==rd_end)
                        enc_buf<=`UDLY CRC16_EPC;
                    else    
                        enc_buf<=`UDLY mtp_data;
                BS_EPC_PART:
                    if(frm_cnt==5'd1)
                        enc_buf<=`UDLY 16'h0000;            
                    else if(frm_cnt==rd_end)
                        enc_buf<=`UDLY CRC16_EPC;
                    else    
                        enc_buf<=`UDLY mtp_data;
                BS_ERROR:
                    if(frm_cnt==5'd1)
                        enc_buf<=`UDLY 16'h8000;
                    else if(frm_cnt==5'd2)
                        enc_buf<=`UDLY {err_code,8'h00};
                    else if(frm_cnt==5'd3)
                        enc_buf<=`UDLY handle;
                    else
                        enc_buf<=`UDLY ~CRC16;
                ET_VERIFY:
                    if(frm_cnt==5'd1)
                        enc_buf<=`UDLY 16'h8000;
                    else if(frm_cnt==5'd2)
                        enc_buf<=`UDLY {ver_code,8'h00};
                    else if(frm_cnt==5'd3)
                        enc_buf<=`UDLY handle;
                    else
                        enc_buf<=`UDLY ~CRC16;
                default:
                    enc_buf<=`UDLY 16'h0000;
                endcase
    end
    
     //Judge the max value of bit_cnt.Nf-1
    always @(posedge data_pulse or negedge enc_rst)
    begin
        if(!enc_rst)
            max_cnt<=`UDLY 4'd4;
        else if(frm_cnt==5'd0)
            if(m_value==2'b00)
                max_cnt<=`UDLY 4'd10;
            else
                max_cnt<=`UDLY 4'd6;
        else
            case(bs_type)            
            BS_SUCCESS,
            ET_READ:
                if(frm_cnt==5'd1)
                    max_cnt<=`UDLY 4'd15;
                else
                    max_cnt<=`UDLY 4'd0;
            BS_EPC_PART:
                if(frm_cnt==5'd1)
                    max_cnt<=`UDLY 4'd11;
                else
                    max_cnt<=`UDLY 4'd0;
            ET_VERIFY,
            BS_ERROR:
                if(frm_cnt==5'd1)
                    max_cnt<=`UDLY 4'd15;
                else if(frm_cnt==5'd2)
                    max_cnt<=`UDLY 4'd8;
                else
                    max_cnt<=`UDLY 4'd0;
            default:
                max_cnt<=`UDLY 4'd0;
            endcase            
    end
    
     //Control the data_end.(Nf+1 for dummy-1)
    always @(posedge data_pulse or negedge enc_rst)
    begin
        if(!enc_rst)
            data_end<=`UDLY 1'b0;
        else
            case(bs_type)
            BS_HANDLE_NOCRC:
                if(frm_cnt==5'd2)
                    data_end<=`UDLY 1'b1;
                else
                    data_end<=`UDLY data_end;
            BS_RN16,
            BS_HANDLE_CRC:
                if(frm_cnt==5'd3)
                    data_end<=`UDLY 1'b1;
                else
                    data_end<=`UDLY data_end;
            BS_SUCCESS:            
                if(frm_cnt==5'd4)
                    data_end<=`UDLY 1'b1;
                else
                    data_end<=`UDLY data_end;
            ET_READ,           
            BS_EPC_ALL,
            BS_EPC_PART:
                if(frm_cnt==end_cnt)
                    data_end<=`UDLY 1'b1;
                else
                    data_end<=`UDLY data_end;
            ET_VERIFY,
            BS_ERROR:
                if(frm_cnt==5'd5)
                    data_end<=`UDLY 1'b1;
                else
                    data_end<=`UDLY data_end;
            default:
                data_end<=`UDLY data_end;
            endcase
    end
    
    always @(negedge sos_pulse or negedge enc_rst)
    begin
        if(!enc_rst)
            enc_end<=`UDLY 1'b0;
        else if(data_end)
            enc_end<=`UDLY 1'b1;
        else
            enc_end<=`UDLY enc_end;
    end
    
    //Enable base_clk.
    always @(negedge sos_pulse or negedge enc_rst)
    begin
        if(!enc_rst)
            enc_en_ctrl<=`UDLY 1'b0;
        else if(enc_end)
            enc_en_ctrl<=`UDLY 1'b1;
        else
            enc_en_ctrl<=`UDLY enc_en_ctrl;
    end
    
    //Judge if there are leading zeros.
    always @(posedge bit_pulse or negedge enc_rst)
    begin
        if(!enc_rst)
            bool_pilot<=`UDLY use_pilot;
        else if(bool_pilot)
            if(bit_cnt==4'd4)
                bool_pilot<=`UDLY 1'b0;
            else
                bool_pilot<=`UDLY 1'b1;
        else
            bool_pilot<=`UDLY 1'b0;
    end
    
    //Mark the premble location. 
    always @(posedge data_pulse or negedge enc_rst)
    begin
        if(!enc_rst)
            bool_preamble<=`UDLY 1'b1;
        else if(frm_cnt==5'd1)
            bool_preamble<=`UDLY 1'b0;
        else
            bool_preamble<=`UDLY bool_preamble;
    end
    
    always @(negedge data_pulse or negedge enc_rst)
    begin
        if(!enc_rst)
            frm_cnt<=`UDLY 6'd0;
        else
            frm_cnt<=`UDLY frm_cnt+1'b1;
    end
        
    assign bit_in=data_end? 1'b1 : enc_buf[bit_cnt];
    
    assign mask_pulse=~clk_buf_c&clk_buf_d;
        
    //Prepare bit_mask.
    always @(posedge mask_pulse or negedge rst_n)
    begin
        if(!rst_n)
            bit_mask<=`UDLY 1'b0;
        else if(bool_pilot)
            bit_mask<=`UDLY 1'b1;
        else if(bool_preamble)
            if(m_value==2'b00)
                if(bit_cnt==4'd11)
                    bit_mask<=`UDLY 1'b1;
                else
                    bit_mask<=`UDLY 1'b0;
            else
                if(bit_cnt>4'd10)
                    bit_mask<=`UDLY 1'b1;
                else
                    bit_mask<=`UDLY 1'b0;
        else
            bit_mask<=`UDLY 1'b0;
    end
    
    //bit_cnt++.
    always @(negedge bit_pulse or negedge enc_rst)
    begin
        if(!enc_rst)
            bit_cnt<=`UDLY 4'd15;
        else if(bit_cnt==max_cnt)
            bit_cnt<=`UDLY 4'd15;
        else
            bit_cnt<=`UDLY bit_cnt-1'b1;
    end
    
    //Prepare enc_state
    always @(posedge st_pulse or negedge enc_rst)
    begin
        if(!enc_rst)
            enc_state<=`UDLY ENC_RDY;
        else if(enc_end)
            enc_state<=`UDLY ENC_RDY;
        else
            case(enc_state)
            ENC_RDY:
                if(bit_in)
                    enc_state<=`UDLY POS_ONE;
                else
                    enc_state<=`UDLY POS_ZERO;
            POS_ZERO:
                if(bit_in)
                    if(bit_mask)
                        enc_state<=`UDLY NEG_ONE;
                    else
                        enc_state<=`UDLY POS_ONE;
                else if(bit_mask||m_value==2'b00)
                    enc_state<=`UDLY POS_ZERO;
                else
                    enc_state<=`UDLY NEG_ZERO;
            POS_ONE:
                if(bit_in)
                    enc_state<=`UDLY NEG_ONE;
                else
                    enc_state<=`UDLY NEG_ZERO;
            NEG_ZERO:
                if(bit_in)
                    enc_state<=`UDLY NEG_ONE;
                else if(m_value==2'b00)
                    enc_state<=`UDLY NEG_ZERO;
                else
                    enc_state<=`UDLY POS_ZERO;
            NEG_ONE:
                if(bit_in)
                    enc_state<=`UDLY POS_ONE;
                else
                    enc_state<=`UDLY POS_ZERO;
            default:
                enc_state<=`UDLY ENC_RDY;
            endcase
    end
    
    always @(posedge base_clk or negedge enc_rst)
    begin
        if(!enc_rst)
            dout<=`UDLY 1'b0;
        else if(enc_state==ENC_RDY)
            dout<=`UDLY 1'b0;
        else if(sos_pulse)         
            case(enc_state)
            POS_ZERO,
            POS_ONE:
                dout<=`UDLY 1'b1;
            default:
                dout<=`UDLY 1'b0;
            endcase
        else if(mos_pulse)
            if(m_value==2'b00)
                case(enc_state)            
                POS_ONE,
                NEG_ZERO:
                    dout<=`UDLY 1'b1;
                default:
                    dout<=`UDLY 1'b0;
                endcase
            else          
                case(enc_state)               
                POS_ZERO,
                NEG_ONE:
                    dout<=`UDLY 1'b1;
                default:
                    dout<=`UDLY 1'b0;
                endcase
        else
            dout<=`UDLY ~dout;
    end
    
    //Generate a pluse, which touch off reading data from MTP.
    always @(posedge base_clk or negedge rst_n)
    begin
        if(!rst_n)
            ocu_rd_pulse<=`UDLY 1'b0;
        else if(data_end)
            ocu_rd_pulse<=`UDLY 1'b0;
        else if(bs_type==BS_EPC_PART||bs_type==BS_EPC_ALL||bs_type==ET_READ)
            if(frm_cnt==5'd1||frm_cnt>5'd2&&frm_cnt<rd_end)
                if(bit_cnt==4'd14)
                    ocu_rd_pulse<=`UDLY mos_pulse;
                else
                    ocu_rd_pulse<=`UDLY 1'b0;
            else
                ocu_rd_pulse<=`UDLY 1'b0;
        else
            ocu_rd_pulse<=`UDLY 1'b0;
    end
        
    //********************************************************//    
    //Calculate CRC16.
    
    //Switch the CRC16 calculation.
    always @(posedge data_pulse or negedge rst_n)
    begin
        if(!rst_n)
            crc_en<=`UDLY 1'b0;
        else
            case(bs_type)
            BS_RN16,
            BS_HANDLE_CRC:
                if(frm_cnt==5'd1)
                    crc_en<=`UDLY 1'b1;
                else if(frm_cnt==5'd2)
                    crc_en<=`UDLY 1'b0;
                else
                    crc_en<=`UDLY crc_en;
            BS_SUCCESS:
                if(frm_cnt==5'd1)
                    crc_en<=`UDLY 1'b1;
                else if(frm_cnt==5'd3)
                    crc_en<=`UDLY 1'b0;
                else
                    crc_en<=`UDLY crc_en;
            ET_READ:
                if(frm_cnt==5'd1)
                    crc_en<=`UDLY 1'b1;
                else if(frm_cnt==rd_len+2'b11)
                    crc_en<=`UDLY 1'b0;
                else
                    crc_en<=`UDLY crc_en;
            ET_VERIFY,
            BS_ERROR:
                if(frm_cnt==5'd1)
                    crc_en<=`UDLY 1'b1;
                else if(frm_cnt==5'd4)
                    crc_en<=`UDLY 1'b0;
                else
                    crc_en<=`UDLY crc_en;
            default:
                crc_en<=`UDLY 1'b0;
            endcase            
    end
    
    assign crc_xor0=bit_in^CRC16[15];
    
    assign crc_xor1=crc_xor0^CRC16[4];
    
    assign crc_xor2=crc_xor0^CRC16[11];
    
    assign crc_pulse=st_pulse;//&crc_en;
    
    always @(posedge crc_pulse or negedge enc_rst)
    begin
        if(!enc_rst)
            CRC16<=`UDLY 16'hffff;
        else if(crc_en)
            CRC16<=`UDLY {CRC16[14:12],crc_xor2,CRC16[10:5],crc_xor1,CRC16[3:0],crc_xor0};
        else
            CRC16<=`UDLY CRC16;
    end
    
    //********************************************************//
    //T2
    
    assign T2_RST=ocu_rst;
    
    always @(negedge T2_OT_PULSE or posedge enc_done or negedge T2_RST)
    begin
        if(!T2_RST)
            T2_CLK_EN<=`UDLY 1'b0;
        else if(enc_done)
            T2_CLK_EN<=`UDLY T2_CHK_EN;
        else
            T2_CLK_EN<=`UDLY 1'b0;
    end
    
    assign T2_CLK=DOUB_BLF&T2_CLK_EN;
    
    always @(posedge T2_CLK or negedge T2_RST)
    begin
        if(!T2_RST)
            T2_CNT<=`UDLY 6'd0;
        else
            T2_CNT<=`UDLY T2_CNT+1'b1;
    end
    
    always @(negedge T2_CLK or negedge T2_RST)
    begin
        if(!T2_RST)
            T2_OT_PULSE<=`UDLY 1'b0;
        else if(T2_CNT==6'd45)
            T2_OT_PULSE<=`UDLY 1'b1;
        else
            T2_OT_PULSE<=`UDLY 1'b0;
    end
    
endmodule
