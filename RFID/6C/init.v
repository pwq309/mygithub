// ************************************************************** 
// COPYRIGHT, Xi'an XDU Radio-frequency IC Co.,Ltd 
// All rights reserved. 
// 
// IP LIB INDEX : IP lib index just sa UTOPIA_B 
// IP Name      : OPTIM
//
// File name    : init.v
// Module name  : INIT
// Full name    : System Init Unit 
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

module INIT(
                //inputs
                DOUB_BLF,
                rst_n,
                init_en,
                mtp_data,
                rd_done,
                
                //outputs                
                init_done,
                lock_state,
                CRC16_EPC,
                pc_val,
                tag_status,
                init_pointer,
                init_rd_pulse,
                pwd_kill,
                pwd_acs,
                srd_pulse              
            );
            
    //parameters   
    parameter INIT_RDY =3'b000; 
    parameter RD_KS    =3'b001;
    parameter RD_LS    =3'b010;
    parameter RD_PWD   =3'b011;
    parameter RD_PC    =3'b100;
    parameter RD_EPC   =3'b101;
    parameter RD_FLG   =3'b110;
    parameter INIT_END =3'b111;

    //inputs
    input              DOUB_BLF;
    input              rst_n;
    input              init_en;
    input    [15:0]    mtp_data;
    input              rd_done;
    
    //outputs
    output             init_done;
    output   [9:0]     lock_state;
    output   [15:0]    CRC16_EPC;
    output   [15:0]    pc_val;
    output             tag_status;
    output   [4:0]     init_pointer;
    output             init_rd_pulse;
    output   [31:0]    pwd_kill;
    output   [31:0]    pwd_acs;
    output             srd_pulse;
    
    //regs
    reg                init_done;
    reg      [9:0]     lock_state;
    reg      [15:0]    pc_val;
    reg                tag_status;    
    reg                init_rd_pulse;
    reg      [31:0]    pwd_kill;
    reg      [31:0]    pwd_acs;
    reg                srd_pulse;
    ////////
    reg                gate_ctrl;
    reg      [2:0]     init_state;
    ////////READ
    reg                rd_en;
    reg                rd_flg;
    reg                flg_ctrl;
    reg      [4:0]     word_cnt;
    reg                max_cnt;
    reg      [4:0]     ptr_base;
    reg      [15:0]    MEM_BUF;
    ////////CRC16
    reg                crc_en;
    reg      [15:0]    CRC16;  
    
    //wires
    wire               init_clk;
    wire               rd_clk;
    wire     [4:0]     epc_len;
    wire     [4:0]     max_epc;
    ////////CRC16
    wire               crc_pulse;
    wire     [15:0]    crc_data;
    wire               crc_xor00;
    wire               crc_xor01;
    wire               crc_xor02;
    wire               crc_xor03;
    wire               crc_xor04;
    wire               crc_xor05;
    wire               crc_xor06;
    wire               crc_xor07;
    wire               crc_xor08;
    wire               crc_xor09;
    wire               crc_xor10;
    wire               crc_xor11;
    wire               crc_xor12;
    wire               crc_xor13;
    wire               crc_xor14;
    wire               crc_xor15;
    wire               crc_xor16;
    wire               crc_xor17;
    wire               crc_xor18;
    wire               crc_xor19;
    wire               crc_xor20;
    wire               crc_xor21;
    wire               crc_xor22;
    wire               crc_xor23;
    wire               crc_xor24;
    wire               crc_xor25;
    wire               crc_xor26;
    wire               crc_xor27;
    
    //********************************************************//
    
    always @(posedge DOUB_BLF or negedge rst_n)
    begin
        if(!rst_n)
            gate_ctrl<=`UDLY 1'b0;
        else if(init_en)
            gate_ctrl<=`UDLY 1'b1;
        else
            gate_ctrl<=`UDLY 1'b0;
    end
    
    assign init_clk=DOUB_BLF&init_en&gate_ctrl;  
    
    assign work_done=rd_done&max_cnt;
    
    //manage the state for initiation.
    always @(posedge init_clk or negedge rst_n)
    begin
        if(!rst_n)
            init_state<=`UDLY INIT_RDY;
        else
            case(init_state)
            INIT_RDY:
                init_state<=`UDLY RD_KS;
            RD_KS:
                if(work_done) 
                    if(tag_status)
                        init_state<=`UDLY INIT_END;
                    else
                        init_state<=`UDLY RD_LS;
                else
                    init_state<=`UDLY RD_KS;
            RD_LS:
                if(work_done)
                    init_state<=`UDLY RD_PWD;
                else
                    init_state<=`UDLY RD_LS;
            RD_PWD:
                if(work_done)
                    init_state<=`UDLY RD_PC;
                else
                    init_state<=`UDLY RD_PWD;
            RD_PC:
                if(work_done)
                    if(epc_len==5'd0)
                        init_state<=`UDLY RD_FLG;
                    else
                        init_state<=`UDLY RD_EPC;
                else
                    init_state<=`UDLY RD_PC;
            RD_EPC:
                if(work_done)
                    init_state<=`UDLY RD_FLG;
                else
                    init_state<=`UDLY RD_EPC;
            RD_FLG:
                init_state<=`UDLY INIT_END;
            INIT_END:
                init_state<=`UDLY INIT_END;
            default:
                init_state<=`UDLY INIT_RDY;
            endcase
    end
    
    //********************************************************//
        
    //Generate init_done.
    always @(negedge init_clk or negedge rst_n)
    begin
        if(!rst_n)
            init_done<=`UDLY 1'b0;
        else if(init_done)
            init_done<=`UDLY 1'b0;
        else if(init_state==INIT_END)
            init_done<=`UDLY 1'b1;
        else
            init_done<=`UDLY 1'b0;
    end
    
    //********************************************************//
    
    //Read the flags from analog front.
    always @(negedge init_clk or negedge rst_n)
    begin
        if(!rst_n)
            srd_pulse<=`UDLY 1'b0;
        else if(init_state==RD_FLG)
            srd_pulse<=`UDLY 1'b1;
        else
            srd_pulse<=`UDLY 1'b0;
    end
    
    //********************************************************//
    
    //control the rd_clk and switch on the rd_clk if need to read memory.
    always @(negedge init_clk or negedge rst_n)
    begin
        if(!rst_n)
            rd_en<=`UDLY 1'b0;
        else if(init_state==RD_KS ||
                init_state==RD_LS ||
                init_state==RD_PWD||
                init_state==RD_PC ||
                init_state==RD_EPC)
                rd_en<=`UDLY 1'b1;
        else
            rd_en<=`UDLY 1'b0;
    end
    
    assign rd_clk=init_clk&rd_en;
    
    //only be as a flag and be used to assist to generate rd_pulse.
    always @(negedge rd_clk or negedge rst_n)
    begin
        if(!rst_n)
            rd_flg<=`UDLY 1'b0;
        else
            rd_flg<=`UDLY ~flg_ctrl;
    end
    
    //generate a pulse for reading memory.
    always @(posedge rd_clk or negedge rst_n)
    begin
        if(!rst_n)
            init_rd_pulse<=`UDLY 1'b0;
        else
            init_rd_pulse<=`UDLY ~rd_flg;
    end
    
    //be derived from rd_done and be used to assist to generate rd_pulse.
    always @(posedge init_clk or negedge rst_n)
    begin
        if(!rst_n)
            flg_ctrl<=`UDLY 1'b0;
        else
            flg_ctrl<=`UDLY rd_done;
    end
    
    //prepare the address to be read.
    assign init_pointer=ptr_base+word_cnt;
    
    always @(init_state)
    begin
        case(init_state)
        RD_KS:
            ptr_base<=`UDLY 5'h05;
        RD_LS:
            ptr_base<=`UDLY 5'h04;
        RD_PC:
            ptr_base<=`UDLY 5'h07;
        RD_EPC:
            ptr_base<=`UDLY 5'h08;
        default:
            ptr_base<=`UDLY 5'h00;
        endcase
    end 
    
    //count for the count of words that has been read.
    always @(posedge init_clk or negedge rst_n)
    begin
        if(!rst_n)
            word_cnt<=`UDLY 5'd0;
        else if(rd_done)
            if(max_cnt)
                word_cnt<=`UDLY 5'd0;
            else
                word_cnt<=`UDLY word_cnt+1'b1;
        else
            word_cnt<=`UDLY word_cnt;
    end     
    
    //only be as a flag and denote that word_cnt has come to be maximum.
    always @(posedge rd_done or negedge rst_n)
    begin
        if(!rst_n)
            max_cnt<=`UDLY 1'b0;
        else
            case(init_state)
            RD_KS,
            RD_LS,
            RD_PC:
                if(word_cnt==5'd0)
                    max_cnt<=`UDLY 1'b1;
                else
                    max_cnt<=`UDLY 1'b0;
            RD_PWD:
                if(word_cnt==5'd3)
                    max_cnt<=`UDLY 1'b1;
                else
                    max_cnt<=`UDLY 1'b0;
            RD_EPC:
                if(word_cnt==max_epc)
                    max_cnt<=`UDLY 1'b1;
                else
                    max_cnt<=`UDLY 1'b0;
            default:
                max_cnt<=`UDLY 1'b0;
            endcase
    end
    
    //********************************************************//
    
    //Receive kill-state from MTP.
    always @(posedge rd_done or negedge rst_n)
    begin
        if(!rst_n)
            tag_status<=`UDLY 1'b0;
        else if(init_state==RD_KS)
            tag_status<=`UDLY MEM_BUF[15];
        else
            tag_status<=`UDLY tag_status;
    end
    
    //Receive lock-state from MTP.
    always @(posedge rd_done or negedge rst_n)
    begin
        if(!rst_n)
            lock_state<=`UDLY 10'h000;
        else if(init_state==RD_LS)
            lock_state<=`UDLY MEM_BUF[15:6];
        else
            lock_state<=`UDLY lock_state;
    end
    
    //Receive kill password from MTP.
    always @(posedge rd_done or negedge rst_n)
    begin
        if(!rst_n)
            pwd_kill<=`UDLY 32'h0000_0000;
        else if(init_state==RD_PWD)
            if(word_cnt<5'd2)
                pwd_kill<=`UDLY {pwd_kill[15:0],MEM_BUF};
            else
                pwd_kill<=`UDLY pwd_kill;
        else
            pwd_kill<=`UDLY pwd_kill;
    end
    
    //Receive access password from MTP.
    always @(posedge rd_done or negedge rst_n)
    begin
        if(!rst_n)
            pwd_acs<=`UDLY 32'h0000_0000;
        else if(init_state==RD_PWD)
            if(word_cnt>5'd1)
                pwd_acs<=`UDLY {pwd_acs[15:0],MEM_BUF};
            else
                pwd_acs<=`UDLY pwd_acs;
        else
            pwd_acs<=`UDLY pwd_acs;
    end
    
    //Receive PC from MTP.
    always @(posedge rd_done or negedge rst_n)
    begin
        if(!rst_n)
            pc_val<=`UDLY 16'h0000;
        else if(init_state==RD_PC)
            pc_val<=`UDLY MEM_BUF;
        else
            pc_val<=`UDLY pc_val;
    end
    
    assign epc_len=pc_val[15:11];
    
    assign max_epc=epc_len-1'b1;
    
    //********************************************************//
    //CRC16 for EPC
    
    //Enable CRC16 Checks.
    always @(negedge init_clk or negedge rst_n)
    begin
        if(!rst_n)
            crc_en<=`UDLY 1'b0;
        else if(init_state==RD_EPC||init_state==RD_PC)
            crc_en<=`UDLY 1'b1;
        else
            crc_en<=`UDLY 1'b0;
    end
    
    assign crc_pulse=rd_done;//&crc_en;//don't do this otherwise a blur may come to be.
    
    assign crc_data=MEM_BUF;
    
    assign CRC16_EPC=~CRC16;
    
    assign crc_xor00=crc_data[0]^crc_xor16;
    assign crc_xor01=crc_data[1]^crc_xor17;
    assign crc_xor02=crc_data[2]^crc_xor18;
    assign crc_xor03=crc_data[3]^crc_xor19;
    assign crc_xor04=crc_data[4]^crc_xor26;    
    assign crc_xor05=crc_xor00^crc_xor20;
    assign crc_xor06=crc_xor01^crc_xor21;
    assign crc_xor07=crc_xor02^crc_xor22;
    assign crc_xor08=crc_xor03^crc_xor23;
    assign crc_xor09=crc_xor04^crc_xor24;    
    assign crc_xor10=crc_xor20^crc_xor25;
    assign crc_xor11=crc_xor21^crc_xor27;
    assign crc_xor12=crc_data[0]^crc_xor16^crc_xor22^crc_data[12]^CRC16[12];
    assign crc_xor13=crc_data[1]^crc_xor17^crc_xor23^crc_data[13]^CRC16[13];
    assign crc_xor14=crc_data[2]^crc_xor18^crc_xor24^crc_data[14]^CRC16[14];
    assign crc_xor15=crc_data[3]^crc_xor19^crc_xor25^crc_data[15]^CRC16[15];
    ////////////////
    assign crc_xor16=crc_data[4]^crc_xor26^crc_xor27^CRC16[0];
    assign crc_xor17=crc_xor20^crc_data[12]^CRC16[12]^CRC16[1];
    assign crc_xor18=crc_xor21^crc_data[13]^CRC16[13]^CRC16[2];
    assign crc_xor19=crc_xor22^crc_data[14]^CRC16[14]^CRC16[3];
    assign crc_xor20=crc_data[5]^crc_xor24^CRC16[5];
    assign crc_xor21=crc_data[6]^crc_xor25^CRC16[6];
    assign crc_xor22=crc_data[7]^crc_xor27^CRC16[7];
    assign crc_xor23=crc_data[8]^crc_data[12]^CRC16[12]^CRC16[8];
    assign crc_xor24=crc_data[9]^crc_data[13]^CRC16[13]^CRC16[9];
    assign crc_xor25=crc_data[10]^crc_data[14]^CRC16[14]^CRC16[10];
    assign crc_xor26=crc_xor23^crc_data[15]^CRC16[15]^CRC16[4];
    assign crc_xor27=crc_data[11]^crc_data[15]^CRC16[15]^CRC16[11];
    
    //CRC16 Check
    always @(posedge crc_pulse or negedge rst_n)
    begin
        if(!rst_n)
            CRC16<=`UDLY 16'hffff;
        else if(crc_en)
            CRC16<=`UDLY {crc_xor15,crc_xor14,crc_xor13,crc_xor12,crc_xor11,crc_xor10,crc_xor09,crc_xor08,
                          crc_xor07,crc_xor06,crc_xor05,crc_xor04,crc_xor03,crc_xor02,crc_xor01,crc_xor00};
        else
            CRC16<=`UDLY CRC16;
    end
    
    //********************************************************//
    //Filter the data from memory.
    
    always @(init_state or mtp_data)
    begin
        case(init_state)
        RD_KS:
            if(mtp_data==16'h3014)
                MEM_BUF=16'h8000;
            else
                MEM_BUF=16'h0000;
        RD_LS:
            if(mtp_data[5:0]==6'b001110)
                MEM_BUF=mtp_data;
            else
                MEM_BUF=16'h0000;
        RD_PC:
            if(mtp_data[15:11]>5'd6)
                MEM_BUF={5'd6,mtp_data[10:0]};
            else
                MEM_BUF=mtp_data;        
        default:
            MEM_BUF=mtp_data;
        endcase
    end      
    
endmodule
    
    