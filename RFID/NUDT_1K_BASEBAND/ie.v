// *******************************************************************
// COPYRIGHT, Xi'an XDU Radio-frequency IC Co.,Ltd 
// All rights reserved.
//
// IP NAME      :  RFID
// File name    :  ie.v
// Module name  :  IE
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
//`include "./macro.v"
//`include "./timescale.v"
`include "D:/xilinx/12.4/xlinx_work/NUDT_1K_BASEBAND/timescale.v"
`include "D:/xilinx/12.4/xlinx_work/NUDT_1K_BASEBAND/macro.v"

module IE(  
            //INPUTs
            DOUB_BLF            ,          
            clk_1_92m           ,
            rst_n               ,
            new_cmd             ,
            ie_en               ,
            pointer_init        ,
            length_init         ,
            read_en_init        ,
            pointer_par         ,
            length_par          ,
            read_en_par         ,
            pointer_OCU         ,
            length_OCU          ,
            read_en_OCU         ,
            wr_pulse            , 
            DBO                 ,
            READY               , 
            data_clk            ,
            clk_sel             ,
            
            //OUTPUTs 
            word_done           ,
            job_done            , 
            A                   ,   
            CEN                 ,
            OEN                 ,
            WEN                 ,
            CHER                ,
            CHWR                ,            
            RD_CLK              ,
            PCH                 , 
            ERFL                ,
            OPT                 ,
            PT                  ,
            ET                  ,
            EXCP                ,
            mtp_data            ,
            WSEN                ,         
            WS                  ,         
            ITEST 
        );
                                 
input               DOUB_BLF    ;      
input               clk_1_92m   ;      
input               rst_n       ;      
input               new_cmd     ;      
input               ie_en       ;      
input     [5:0]     pointer_init;      
input     [5:0]     length_init ;      
input               read_en_init;      
input     [5:0]     pointer_par ;      
input     [5:0]     length_par  ;      
input               read_en_par ;      
input     [5:0]     pointer_OCU ;      
input     [5:0]     length_OCU  ;      
input               read_en_OCU ;      
input               wr_pulse    ;      
input     [15:0]    DBO         ;      
input               READY       ;           //Enable new write operation when READY is high.
input               data_clk    ;
input               clk_sel     ;  

output              word_done   ;
output              job_done    ;
output    [5:0]     A           ;
output              CEN         ;
output              OEN         ;
output              WEN         ;           //Write enalbe: when WEN=0, write operation is enabled.
output              CHER        ;           //Chip Erase enable: Set to 1 to enable "Chip Erase"
output              CHWR        ;           //Chip Write enable: Set to 1 to enable "Chip Write"
output              RD_CLK      ;          
output    [2:0]     PCH         ;           //Sensing option; Default setting PCH[2:0]=3b'111
output              ERFL        ;           //Test option; Default setting ERFL=1b'0
output              OPT         ;           //Test option; Default setting OPT=1b'0
output    [1:0]     PT          ;           //Write time option; Default setting PT[1:0]=2'b00
output    [1:0]     ET          ;           //Erase time option; Default setting ET[1:0]=2'b00
output              EXCP        ;           //Write option; Set EXCP=1b'1 when performing Chip Erase/Write, EXCP=1b'0;Internal charge pump
output    [15:0]    mtp_data    ;          
output              WSEN        ;           //Write option; Self-timing wirte start control.  WSEN=1; External write start controllable by WS.
output              WS          ;           //Write Start; Control the start time of Write operation
output              ITEST       ;           //just for test

reg                 job_done    ;
reg       [5:0]     A           ;           //Address input; Control the row 
reg                 CEN         ;           //Chip Enable/Select: when CEN=0, the IP block is enabled/selected
reg                 OEN         ;           //Output enable: when OEN=0, data output is enabled
reg                 WEN         ;           //write enable signal of MTP, active low
reg                 EXCP        ;           //write choose signal
reg       [15:0]    mtp_data    ;
reg                 WSEN        ;

wire                word_done   ; 
wire                RD_CLK      ;           //Read clock; 40KHz~800KHz
  
wire                rd_pulse    ;
wire                blc_clk     ;
wire                rd_clock    ;
wire                get_pulse   ;
wire                wr_clk      ;
wire                wr_done_a   ;
wire                pre_pulse   ;
wire                clk_pro     ;
wire                enclk       ;
wire                CHER        ;           
wire                CHWR        ;           
wire                ERFL        ;
wire                WS          ;
wire      [2:0]     PCH         ;
wire      [1:0]     PT          ;
wire                OPT         ;
wire      [1:0]     ET          ;
wire                ITEST       ;            //Test Mode. To determine whether to measure Icell (ITEST=0)

//wire                write_en_pulse;
wire                reset       ;
wire                reset_cnt   ;
wire                addr_pulse  ;

reg                 blc_en      ;
reg                 prd_pulse   ;
reg                 rd_en       ;
reg       [3:0]     rd_cnt      ;
reg                 a_pulse     ;
//reg                 b_pulse     ;
reg                 c_pulse     ;
reg                 RD_CLK_a    ;
reg                 RD_CLK_b    ;
reg                 rd_end      ;
reg                 rd_done     ;
//reg                 clk_pro_doub;
//reg                 write_en_pa ;
//reg                 write_en_pb ;
reg                 wr_en       ;    
//reg                 wr_pulse    ; 
reg                 wr_flg      ;  
reg       [5:0]     word_cnt    ;
reg                 init_pro    ;
reg                 OCU_pro     ;
reg                 par_pro     ;
reg                 ie_en_delay ;  
reg                 wr_done     ;

assign CHER =1'b0  ;
assign CHWR =1'b0  ;
assign ERFL =1'b0  ;
assign WS   =1'b0  ;
assign PCH  =3'b111;
assign PT   =2'b00 ;
assign OPT  =1'b0  ;
assign ET   =2'b00 ;
assign ITEST=1'b0  ;

//read
assign  rd_pulse = read_en_OCU|read_en_par|read_en_init|wr_done;  //revised in 11/4
assign  blc_clk  = blc_en & DOUB_BLF;
assign  rd_clock = clk_1_92m & rd_en;
//assign  RD_CLK   = (RD_CLK_a & RD_CLK_b)|wr_done;
assign  RD_CLK   = RD_CLK_a & RD_CLK_b;
assign  get_pulse= c_pulse & ~RD_CLK_b;

always @(posedge rd_pulse or negedge rd_done or negedge rst_n)
begin
    if(!rst_n)
        blc_en <= #`UDLY 1'b0;
    else if(rd_pulse)
        blc_en <= #`UDLY 1'b1;
    else
        blc_en <= #`UDLY 1'b0;  
end

always @(negedge blc_clk or negedge rst_n )
begin
    if(!rst_n)
        prd_pulse <= #`UDLY 1'b0;
    else if(rd_pulse)
        prd_pulse <= #`UDLY 1'b1;
    else
        prd_pulse <= #`UDLY 1'b0;
end

always @(posedge rd_pulse or negedge c_pulse or negedge rst_n)
begin
    if(!rst_n)
        rd_en <= #`UDLY 1'b0;
    else if(rd_pulse)
        rd_en <= #`UDLY 1'b1;
    else
        rd_en <= #`UDLY 1'b0;
end

always @(posedge rd_clock or negedge rst_n)         
begin
    if(!rst_n)
        rd_cnt <= #`UDLY 4'd0; 
    else 
        rd_cnt <= #`UDLY rd_cnt + 1'b1;
end

always @(negedge rd_clock or negedge rst_n)
begin
    if(!rst_n)
        a_pulse <= #`UDLY 1'b0;
    else if(rd_cnt==4'd8)
        a_pulse <= #`UDLY 1'b1;
    else 
        a_pulse <= #`UDLY 1'b0;
end

//always @(negedge rd_clock or negedge rst_n)
//begin
//    if(!rst_n)
//        b_pulse <= #`UDLY 1'b0;
//    else if(rd_cnt==4'd11)
//        b_pulse <= #`UDLY 1'b1;
//    else 
//        b_pulse <= #`UDLY 1'b0;
//end

always @(negedge rd_clock or negedge rst_n)
begin
    if(!rst_n)
        c_pulse <= #`UDLY 1'b0;
    else if(rd_cnt==4'd15)
        c_pulse <= #`UDLY 1'b1;
    else 
        c_pulse <= #`UDLY 1'b0;
end

always @(negedge rd_clock or negedge rst_n)
begin
    if(!rst_n)
        RD_CLK_a <= #`UDLY 1'b0;
    else if(rd_cnt>=4'd11 && rd_cnt<=4'd14)
        RD_CLK_a <= #`UDLY 1'b1;
    //else if(rd_cnt<=4'd15)
        //RD_CLK_a<=`UDLY 1'b0;
    else
        RD_CLK_a <= #`UDLY 1'b0;
end

always @(posedge rd_clock or negedge rst_n)
begin
    if(!rst_n)
        RD_CLK_b <= #`UDLY 1'b0;
    else if(RD_CLK_a)
        RD_CLK_b <= #`UDLY 1'b1;
    else
        RD_CLK_b <= #`UDLY 1'b0;
end

always @(posedge get_pulse or negedge rst_n)
begin
    if(!rst_n)
        mtp_data <= #`UDLY 16'd0;
    else
        mtp_data <= #`UDLY DBO;            //DBO:16 bits output of MTP read operation 
end

always @(posedge get_pulse or negedge rst_n or negedge rd_done)
begin
    if(!rst_n)
        rd_end <= #`UDLY 1'b0;
    else if(get_pulse)
        rd_end <= #`UDLY 1'b1;
    else
        rd_end <= #`UDLY 1'b0;
end

always @(negedge clk_pro or negedge rst_n)
begin
    if(!rst_n)
        rd_done <= #`UDLY 1'b0;
    else if(rd_done)
        rd_done <= #`UDLY 1'b0;            
    else if(rd_end)//|wr_done)      //after read the wr_data from eeprom,generate rd_done.revised in 11/4.pan
        rd_done <= #`UDLY 1'b1;
    else
        rd_done <= #`UDLY 1'b0;
end

//write

assign wr_clk = wr_en & DOUB_BLF;
assign wr_done_a = wr_flg & READY;

always @(posedge wr_pulse or negedge rst_n or negedge wr_done)
begin
    if(!rst_n)
        wr_en <= #`UDLY 1'b0;
    else if(wr_pulse)
        wr_en <= #`UDLY 1'b1;
    else
        wr_en <= #`UDLY 1'b0;
end

always @(posedge wr_pulse or negedge rst_n or negedge wr_done)
begin
    if(!rst_n)
        WSEN <= #`UDLY 1'b1;
    else if(wr_pulse)
        WSEN <= #`UDLY 1'b0;      //write choose signal
    else 
        WSEN <= #`UDLY 1'b1;
end

always @(posedge wr_clk or negedge rst_n)
begin
    if(!rst_n)
        WEN <= #`UDLY 1'b1;
    else if(wr_pulse)
        WEN <= #`UDLY 1'b0;       //write enable signal, active low
    else
        WEN <= #`UDLY 1'b1;
end

always @(negedge READY or negedge rst_n or  negedge wr_done)
begin
    if(!rst_n)
        wr_flg <= #`UDLY 1'b0;
    else if(~READY)
        wr_flg <= #`UDLY 1'b1;
    else
        wr_flg <= #`UDLY 1'b0;
end

always @(negedge wr_clk or negedge rst_n)   
begin                                       
    if(!rst_n)                              
        wr_done <= #`UDLY 1'b0;                
    else if(wr_done)                        
        wr_done <= #`UDLY 1'b0;                
    else if(wr_done_a)                   
        wr_done <= #`UDLY 1'b1;                
    else                                                  
        wr_done <= #`UDLY 1'b0;                
end     

/////////////////////////////////////////////////

assign  word_done=rd_done|wr_done;
assign  pre_pulse=wr_pulse|a_pulse;
//assign  reset    = ~((~rst_n) | new_cmd );
assign  reset    = rst_n & ~new_cmd;
assign  reset_cnt= ~((~rst_n) | new_cmd | job_done );
assign  clk_pro  =clk_sel?data_clk:DOUB_BLF;
assign  enclk    =clk_pro&ie_en_delay;
assign  addr_pulse=prd_pulse|wr_pulse;  

always @(posedge pre_pulse or negedge rst_n or negedge job_done)
begin
    if(!rst_n)
        CEN <= #`UDLY 1'b1;
    else if(pre_pulse)
        CEN <= #`UDLY 1'b0;
    else
        CEN <= #`UDLY 1'b1; 
end

always @(posedge a_pulse or negedge rst_n or negedge rd_done)
begin                    
    if(!rst_n)           
        OEN <= #`UDLY 1'b1; 
    else if(a_pulse)     
        OEN <= #`UDLY 1'b0; 
    else                 
        OEN <= #`UDLY 1'b1; 
end                      

//always @(posedge RD_CLK or negedge rd_done or negedge rst_n)
//begin                    
//    if(!rst_n)           
//        OEN <= #`UDLY 1'b1; 
//    else if(RD_CLK)     
//        OEN <= #`UDLY 1'b0; 
//    else                 
//        OEN <= #`UDLY 1'b1;    //revised in 11/4.pan
//end 

always @(negedge clk_pro or negedge rst_n )
begin
    if(!rst_n )
        ie_en_delay <= #`UDLY 1'b0;
    else
        ie_en_delay <= #`UDLY ie_en;
end

always @(posedge word_done or negedge reset_cnt )
begin
    if(!reset_cnt)
        word_cnt <= #`UDLY 6'd0;
    else if(ie_en_delay)
        word_cnt <= #`UDLY word_cnt+1'b1; 
    else
        word_cnt <= #`UDLY 6'd0; 
end

always @(posedge enclk or negedge reset)
begin
    if(!reset)
        job_done <= #`UDLY 1'b0;
    else if(par_pro)
        if(word_cnt<length_par)
            job_done <= #`UDLY 1'b0;
        else
            job_done <= #`UDLY 1'b1;
    else if(init_pro) 
        if(word_cnt<length_init)
            job_done <= #`UDLY 1'b0;
        else if(word_done)
            job_done <= #`UDLY 1'b1; 
        else
       		job_done <= #`UDLY 1'b0;
    else if(OCU_pro)
        if(word_cnt<length_OCU)
            job_done <= #`UDLY 1'b0;
        else
            job_done <= #`UDLY 1'b1;
    else 
        job_done <= #`UDLY 1'b0;
end

always @(negedge enclk or negedge reset)
begin
    if(!reset)
        par_pro <= #`UDLY 1'b0;
    else if(read_en_par)
        par_pro <= #`UDLY 1'b1;
    else if(job_done)
        par_pro <= #`UDLY 1'b0;
    else 
        par_pro <= #`UDLY par_pro;
end

always @(negedge enclk or negedge reset)
begin
    if(!reset)
        init_pro <= #`UDLY 1'b0;
    else if(read_en_init)
        init_pro <= #`UDLY 1'b1;
    else if(job_done)
        init_pro <= #`UDLY 1'b0;
    else 
        init_pro <= #`UDLY init_pro;
end

always @(negedge enclk or negedge reset)
begin
    if(!reset)
        OCU_pro <= #`UDLY 1'b0;
    else if(read_en_OCU||wr_pulse)
        OCU_pro <= #`UDLY 1'b1;
    else if(job_done)
        OCU_pro <= #`UDLY 1'b0;
    else 
        OCU_pro <= #`UDLY OCU_pro;
end
  
always @(posedge addr_pulse or negedge rst_n) 
begin                                         
    if(!rst_n)                                
        A <= #`UDLY 6'h00;                       
    else if(read_en_init)                    
        A <= #`UDLY pointer_init+word_cnt;                                                    
    else if(read_en_par)                     
        A <= #`UDLY pointer_par+word_cnt;                 
    else if(read_en_OCU)
        A <= #`UDLY pointer_OCU+word_cnt;   
    else
        A <= #`UDLY pointer_OCU;        
end    

endmodule                                        