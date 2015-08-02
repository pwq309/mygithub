// ************************************************************** 
// COPYRIGHT, Xi'an XDU Radio-frequency IC Co.,Ltd 
// All rights reserved. 
// 
// IP LIB INDEX : IP lib index just sa UTOPIA_B 
// IP Name      : OPTIM
//
// File name    : ie.v
// Module name  : IE
// Full name    : IE 
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
`define UDLY #2
`define MDLY #5

`define MDW 16
`define MDN 32
`define MAW 4

module IE(
                //inputs
                DOUB_BLF,
                rst_n,
                new_cmd,
                init_pointer,
                init_rd_pulse,
                par_pointer,
                par_rd_pulse,
                ocu_pointer,
                ocu_rd_pulse,
                wr_pulse,
                clk_60k,
                DATA_RD,
                DATARDY,
                
                //outputs
                ie_div_req,
                ie_div_off,
                ie_60k_req,
                ie_60k_off,
                mtp_data,
                rd_done,
                wr_done,
                MRGSEL,
                MRGEN,
                DRT,
                NVSTR,
                PROG,
                SE,
                RECALL,
                FE,
                FUSEADR
            );
    //inputs
    input                  DOUB_BLF;
    input                  rst_n;
    input                  new_cmd;
    input     [`MAW:0]     init_pointer;
    input                  init_rd_pulse;
    input     [`MAW:0]     par_pointer;
    input                  par_rd_pulse;
    input     [`MAW:0]     ocu_pointer;
    input                  ocu_rd_pulse;
    input                  wr_pulse;
    input                  clk_60k;
    input     [15:0]       DATA_RD;
    input                  DATARDY;
                          
    //outputs
    output                ie_div_req;
    output                ie_div_off;
    output                ie_60k_req;
    output                ie_60k_off;
    output    [15:0]      mtp_data;
    output                rd_done;
    output                wr_done;
    output                MRGSEL;
    output                MRGEN;
    output                DRT;
    output                NVSTR;
    output                PROG;
    output                SE;
    output                RECALL;
    output                FE;
    output    [`MAW:0]    FUSEADR;
    
    //regs
    //reg                   ie_div_req;
    //reg                   ie_div_off;
    reg       [15:0]      mtp_data;
    reg                   rd_done;
    reg                   wr_done;
    reg                   NVSTR;
    reg                   PROG;
    reg                   SE;
    reg                   RECALL;
    reg                   FE;
    reg       [`MAW:0]    FUSEADR;
    ////////
    reg                   rd_en;
    reg                   rone_pulse;
    reg                   rtwo_pulse;
    reg                   rd_end;
    ////////
    reg                   wr_en;
    reg                   wone_pulse;
    reg                   wtwo_pulse;
    reg                   wthd_pulse;
    reg                   wr_end;
    reg        [8:0]      wt_cnt;
    reg                   wt_done;
    reg                   wt_end;
    
    //wires
    wire                  rd_pulse;
    wire                  rd_clk;
    wire                  fe_pulse;
    wire                  addr_pulse;
    ////////
    wire                  wr_clk;
    wire                  wt_clk;
    wire                  wt_rst;
    
    //********************************************************//   
    //DRT,MRGEN,MRGSEL is 0 in user mode.
    
    assign DRT=1'b0;
    assign MRGEN=1'b0;
    assign MRGSEL=1'b0;
    
    //********************************************************//
    
    //Prepare the address for reading or writing.
    assign addr_pulse=rone_pulse|wone_pulse; 
       
    always @(posedge addr_pulse or negedge rst_n)
    begin
        if(!rst_n)
            FUSEADR<=`UDLY `MAW'd0;
        else if(init_rd_pulse)
            FUSEADR<=`UDLY init_pointer;
        else if(par_rd_pulse)
            FUSEADR<=`UDLY par_pointer;
        else
            FUSEADR<=`UDLY ocu_pointer;
    end
    
    //Set FE for reading or writing.
    assign fe_pulse=rtwo_pulse|wone_pulse;
    assign fe_done=rd_done|wt_done;
    
    always @(posedge fe_pulse or negedge fe_done or negedge rst_n)
    begin
        if(!rst_n)
            FE<=`UDLY 1'b0;
        else if(fe_pulse)
            FE<=`UDLY 1'b1;
        else
            FE<=`UDLY 1'b0;
    end    
    
    //********************************************************//
    //READ
    
    assign rd_pulse=init_rd_pulse|par_rd_pulse|ocu_rd_pulse;
    
    always @(posedge rd_pulse or negedge rd_done or negedge rst_n)
    begin
       if(!rst_n)
           rd_en<=`UDLY 1'b0;
       else if(rd_pulse)
           rd_en<=`UDLY 1'b1;
       else
           rd_en<=`UDLY 1'b0;
    end
    
    assign rd_clk=DOUB_BLF&rd_en;
    
    always @(negedge rd_clk or negedge rst_n)
    begin
        if(!rst_n)
            rone_pulse<=`UDLY 1'b0;
        else
            rone_pulse<=`UDLY rd_pulse;
    end
    
    always @(posedge rd_clk or negedge rst_n)
    begin
        if(!rst_n)
            rtwo_pulse<=`UDLY 1'b0;
        else
            rtwo_pulse<=`UDLY rone_pulse;
    end
    
    always @(posedge rone_pulse or negedge rd_done or negedge rst_n)
    begin
        if(!rst_n)
            RECALL<=`UDLY 1'b0;
        else if(rone_pulse)
            RECALL<=`UDLY 1'b1;
        else
            RECALL<=`UDLY 1'b0;
    end
    
    always @(posedge rtwo_pulse or negedge rd_done or negedge rst_n)
    begin
        if(!rst_n)
            SE<=`UDLY 1'b0;
        else if(rtwo_pulse)
            SE<=`UDLY 1'b1;
        else
            SE<=`UDLY 1'b0;
    end
    
    always @(negedge rtwo_pulse or negedge rst_n)
    begin
        if(!rst_n)
            mtp_data<=`UDLY 16'h0000;
        else
            mtp_data<=`UDLY DATA_RD;
    end
    
    always @(negedge rtwo_pulse or posedge rd_pulse or negedge rst_n)
    begin
        if(!rst_n)
            rd_end<=`UDLY 1'b1;
        else if(rd_pulse)
            rd_end<=`UDLY 1'b0;
        else
            rd_end<=`UDLY 1'b1;
    end
    
    always @(negedge rd_clk or negedge rst_n)
    begin
        if(!rst_n)
            rd_done<=`UDLY 1'b0;
        else if(rd_done)
            rd_done<=`UDLY 1'b0;
        else if(rd_end)
            rd_done<=`UDLY 1'b1;
        else
            rd_done<=`UDLY 1'b0;
    end
    
    //********************************************************//
    //WRITE
    
    always @(posedge wr_pulse or negedge wr_done or negedge rst_n)
    begin
       if(!rst_n)
           wr_en<=`UDLY 1'b0;
       else if(wr_pulse)
           wr_en<=`UDLY 1'b1;
       else
           wr_en<=`UDLY 1'b0;
    end
    
    assign wr_clk=DOUB_BLF&wr_en;
    
    always @(negedge wr_clk or negedge rst_n)
    begin
        if(!rst_n)
            wone_pulse<=`UDLY 1'b0;
        else
            wone_pulse<=`UDLY wr_pulse;
    end
    
    always @(posedge wr_clk or negedge rst_n)
    begin
        if(!rst_n)
            wtwo_pulse<=`UDLY 1'b0;
        else
            wtwo_pulse<=`UDLY wone_pulse;
    end
    
    always @(negedge wr_clk or negedge rst_n)
    begin
        if(!rst_n)
            wthd_pulse<=`UDLY 1'b0;
        else
            wthd_pulse<=`UDLY wtwo_pulse;
    end
    
    always @(posedge wone_pulse or posedge wt_done or negedge rst_n)
    begin
        if(!rst_n)
            PROG<=`UDLY 1'b0;
        else if(wone_pulse)
            PROG<=`UDLY 1'b1;
        else
            PROG<=`UDLY 1'b0;
    end
    
    always @(negedge wthd_pulse or posedge wr_end or negedge rst_n)
    begin
        if(!rst_n)
            NVSTR<=`UDLY 1'b0;
        else if(wr_end)
            NVSTR<=`UDLY 1'b0;
        else
            NVSTR<=`UDLY 1'b1;
    end    
    
    assign ie_60k_req=wthd_pulse;
    
    assign ie_60k_off=wr_done;
    
    assign wt_clk=clk_60k;
    
    assign wt_rst=rst_n&~wr_pulse;
    
    always @(posedge wt_clk or negedge wt_rst)
    begin
        if(!wt_rst)
            wt_cnt<=`UDLY 9'd0;
        else
            wt_cnt<=`UDLY wt_cnt+1'b1;
    end
    
    always @(negedge wt_clk or negedge rst_n)
    begin
        if(!rst_n)
            wt_done<=`UDLY 1'b0;
        else if(wt_cnt==9'd480)
            wt_done<=`UDLY 1'b1;
        else
            wt_done<=`UDLY 1'b0;
    end
    
    always @(negedge wt_done or posedge wr_pulse or negedge rst_n)
    begin
        if(!rst_n)
            wr_end<=`UDLY 1'b1;
        else if(wr_pulse)
            wr_end<=`UDLY 1'b0;
        else
            wr_end<=`UDLY 1'b1;
    end
    
    always @(negedge wr_clk or negedge rst_n)
    begin
        if(!rst_n)
            wr_done<=`UDLY 1'b0;
        else if(wr_done)
            wr_done<=`UDLY 1'b0;
        else if(wr_end)
            wr_done<=`UDLY 1'b1;
        else
            wr_done<=`UDLY 1'b0;
    end
    
endmodule