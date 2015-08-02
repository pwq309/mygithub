// ************************************************************** 
// COPYRIGHT, Xi'an XDU Radio-frequency IC Co.,Ltd 
// All rights reserved. 
// 
// IP LIB INDEX : IP lib index just sa UTOPIA_B 
// IP Name      : OPTIM
//
// File name    : pmu.v
// Module name  : PMU
// Full name    : Power Manage Unit
// 
// Author       : pananqaing
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

module PMU(
                //inputs
                DOUB_BLF,                
                rst_n,
                tag_status,
                new_cmd,
                init_done,
                dec_done,
                parse_done,
                parse_err,
                scu_done,
                ocu_done,
                cmd_head,
                tag_state,
                par_div_req,
                par_div_off,
                T2_OT_PULSE,
                T2_CHK_EN,
                vee_rdy,
                ie_60k_req,
                ie_60k_off,
                
                //outputs            
                dec_en,
                scu_en,
                ocu_en,
                init_en,
                div_en,
                vee_req,
                vchk_en,
                vee_err,
                K60_EN
            );
            
    //parameters
    parameter PMU_RDY    =4'b0000;
    parameter INIT_ON    =4'b0001;
    parameter REC_ON     =4'b0010;
    parameter SCU_ON     =4'b0011;
    parameter OCU_ON     =4'b0100;
    parameter NOP_ONE    =4'b1000;
    parameter NOP_TWO    =4'b1001;
    parameter NOP_THR    =4'b1010;
    parameter NOP_FOU    =4'b1011;
    parameter NOP_FIV    =4'b1100;
    parameter NOP_SIX    =4'b1101; 
    parameter NOP_SEV    =4'b1110; 
    parameter PMU_END    =4'b1111;  
    //cmds. must be same as defined in CMD_PARSE.
    parameter QUERYREP   =5'd3;
    parameter ACK        =5'd4;    
    parameter QUERY      =5'd10;
    parameter QUERYADJ   =5'd11;
    parameter SELECT     =5'd12;    
    parameter NAK        =5'd20;
    parameter REQ_RN     =5'd21;
    parameter READ       =5'd22;
    parameter WRITE      =5'd23;
    parameter KILL       =5'd24;
    parameter LOCK       =5'd25;
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
    
    //inputs        
    input             DOUB_BLF;                
    input             rst_n;
    input             tag_status;
    input             new_cmd;
    input             init_done;
    input             dec_done;
    input             parse_done;
    input             parse_err;
    input             scu_done;
    input             ocu_done;
    input    [4:0]    cmd_head;
    input    [3:0]    tag_state;
    input             par_div_req;
    input             par_div_off;
    input             T2_OT_PULSE;
    input             T2_CHK_EN;
    input             vee_rdy;
    input             ie_60k_req;
    input             ie_60k_off;
    
    //outputs
    output            dec_en;
    output            scu_en;
    output            ocu_en;
    output            init_en;
    output            div_en;
    output            vee_req;
    output            vchk_en;
    output            vee_err;
    output            K60_EN;
    
    //regs
    reg               dec_en;
    reg               scu_en;
    reg               ocu_en;
    reg               init_en;
    reg               div_en;
    reg               vee_req;
    reg               vchk_en;
    reg               vee_err;
    reg               K60_EN;
    ////////////////FSM
    reg      [3:0]    pmu_state;
    reg      [3:0]    nxt_state;
    
    //wires
    wire              pmu_clk;
    wire              div_req;
    wire              div_off;    
    
    //********************************************************// 
    
    assign pmu_clk=DOUB_BLF;
    
    //current state of FSM jumps.
    always @(posedge pmu_clk or negedge rst_n)
    begin
        if(!rst_n)
            pmu_state<=`UDLY PMU_RDY;
        else if(tag_status)
            pmu_state<=`UDLY PMU_END;
        else
            pmu_state<=`UDLY nxt_state;
    end
    
    always @(init_done or parse_done or parse_err or scu_done or ocu_done or pmu_state)
    begin
        case(pmu_state)
        PMU_RDY:
            nxt_state=INIT_ON;
        INIT_ON:
            if(init_done)
                nxt_state=REC_ON;
            else
                nxt_state=INIT_ON;
        REC_ON:
            if(parse_done)
                nxt_state=NOP_ONE;
            else if(parse_err)
                nxt_state=REC_ON;
            else
                nxt_state=REC_ON;
        NOP_ONE:
            nxt_state=NOP_TWO;
        NOP_TWO:
            nxt_state=NOP_THR;
        NOP_THR:
            nxt_state=SCU_ON;
        SCU_ON:
            if(scu_done)
                nxt_state=NOP_FOU;
            else
                nxt_state=SCU_ON;
        NOP_FOU:
            nxt_state=NOP_FIV;
        NOP_FIV:
            nxt_state=NOP_SIX;
        NOP_SIX:
            nxt_state=NOP_SEV;
        NOP_SEV:
            nxt_state=OCU_ON;
        OCU_ON:
            if(ocu_done)
                nxt_state=REC_ON;            
            else
                nxt_state=OCU_ON;
        PMU_END:
            nxt_state=PMU_END;
        default:
            nxt_state=REC_ON;
        endcase
    end
    
    //********************************************************//
    
    //Switch INIT module.
    always @(negedge pmu_clk or negedge rst_n)
    begin
        if(!rst_n)
            init_en<=`UDLY 1'b0;
        else if(pmu_state==INIT_ON)
            init_en<=`UDLY 1'b1;
        else
            init_en<=`UDLY 1'b0;
    end
    
    //Switch DECODER module.
    always @(negedge pmu_clk or negedge rst_n)
    begin
        if(!rst_n)
            dec_en<=`UDLY 1'b0;
        else if(pmu_state==REC_ON)
            dec_en<=`UDLY 1'b1;
        else
            dec_en<=`UDLY 1'b0;
    end
    
    //Switch SCU module.
    always @(negedge pmu_clk or negedge rst_n)
    begin
        if(!rst_n)
            scu_en<=`UDLY 1'b0;
        else if(pmu_state==SCU_ON)
            scu_en<=`UDLY 1'b1;
        else
            scu_en<=`UDLY 1'b0;
    end
    
    //Switch OCU module.
    always @(negedge pmu_clk or negedge rst_n)
    begin
        if(!rst_n)
            ocu_en<=`UDLY 1'b0;
        else if(pmu_state==OCU_ON)
            ocu_en<=`UDLY 1'b1;
        else
            ocu_en<=`UDLY 1'b0;
    end
    
    //********************************************************//
    
    //assign pmu_div_off=~T2_CHK_EN&(pmu_state==REC_ON);
    
    assign div_req=par_div_req|dec_done;                                     //a pulse form other modules is used to apply for DIV.
    assign div_off=new_cmd|par_div_off;                                      //a pulse form other modules is used to release DIV.
    
    //Switch DIV module.    
    always @(posedge div_req or posedge div_off or negedge rst_n)
    begin
        if(!rst_n)
            div_en<=`UDLY 1'b1;
        else if(div_off)
            div_en<=`UDLY 1'b0;
        else
            div_en<=`UDLY 1'b1;          
    end
    
    //Switch clk_60k.
    always @(posedge ie_60k_req or posedge ie_60k_off or negedge rst_n)
    begin
        if(!rst_n)
            K60_EN<=`UDLY 1'b0;
        else if(ie_60k_req)
            K60_EN<=`UDLY 1'b1;
        else
            K60_EN<=`UDLY 1'b0;
    end
    
    //********************************************************//
    //power check
    
    assign wr_come=cmd_head==WRITE||cmd_head==KILL&&tag_state==HALF_KILLED||cmd_head==LOCK;

    always @(posedge dec_done or posedge ocu_done or negedge rst_n)
    begin
       if(!rst_n)
           vee_req<=`UDLY 1'b0;
       else if(dec_done)
           vee_req<=`UDLY wr_come;
       else 
           vee_req<=`UDLY 1'b0;
    end
    
    always @(posedge dec_done or negedge scu_done or negedge rst_n)
    begin
       if(!rst_n)
           vchk_en<=`UDLY 1'b0;
       else if(dec_done)
           vchk_en<=`UDLY wr_come;
       else
           vchk_en<=`UDLY 1'b0;
    end
    
    always @(posedge scu_done or negedge rst_n)
    begin
        if(!rst_n)
            vee_err<=`UDLY 1'b0;
        else if(vchk_en)
            vee_err<=`UDLY ~vee_rdy;
        else
            vee_err<=`UDLY 1'b0;
    end
    
endmodule    
    