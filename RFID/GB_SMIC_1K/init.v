// ************************************************************** 
// COPYRIGHT, Xi'an XDU Radio-frequency IC Co.,Ltd 
// All rights reserved. 
// 
// IP LIB INDEX :
// IP Name      :
//
// File name    : init.v
// Module name  : INIT
// Full name    : System Initial Unit 
// 
// Author       : panwanqiang
// Email        : 
// Data         : 
// Version      : V1.0 
// 
// Abstract     : 
// Called by    : 
// 
// Modification history 
// ---------------------------------------- 
//
// $Log$ 
// 
// ************************************************************** 

// ************************
// DEFINE MACRO(s)
// ************************
`include "./macro.v"
`include "./timescale.v"

// ************************
// DEFINE MODULE
// ************************
module INIT(    
            //INPUTS
		        DOUB_BLF                ,
			      init_en                 ,
            rst_n                   ,            
			      mtp_data                ,               
			      word_done               ,
			      job_done                ,
			
			      //OUTPUTS
			      init_done               ,
			      lock_state              ,
			      crc_calc                ,
			      uac_len                 ,
			      tag_status              ,
			      kill_pwd_status         ,
            lock_pwd_status         ,
			      read_pwd_status         ,
				    write_pwd_status        , 
			      pointer_init            ,
			      length_init             ,
			      read_en_init 
			      
			     );

// ************************                     
// DEFINE PARAMETER(s)                          
// ************************
parameter INIT_RDY = 4'b0000        ;     //start of init unit
parameter RD_KS    = 4'b0001        ;     //judge whether the tag is killed
parameter RD_LS    = 4'b0010        ;     //judge whether the tag is locked
parameter RD_KLPWD = 4'b0011        ;     //obtain the pwd of K/L,then judge whether it is zero to gen a sign 
parameter RD_RWPWD = 4'b0100        ;     //obtain the pwd of R/W,then judge whether it is zero to gen a sign 
parameter RD_LEN   = 4'b0101        ;     //obtain the length of UAC
parameter RD_UAC   = 4'b0110        ;     //read UAC to caculate CRC
parameter RD_BUFF  = 4'b1100        ;
parameter INIT_END = 4'b0111        ;     //init unit is end

// ************************
// DEFINE INPUT(s)
// ************************ 
//
// *****************
// INPUT FROM DIV
// *****************
input            DOUB_BLF           ;     //double BLF clock
// *****************
// INPUT FROM ANALOG FRONT_END
// *****************
input            rst_n              ;     //reset signal,asynchronous,active low
// *****************
// INPUT FROM PMU
// *****************
input            init_en            ;     //enable signal for module work
// *****************
// INPUT FROM IE
// *****************
input  [15:0]    mtp_data           ;     //data read from mtp
input            word_done          ;     //pulse with each word
input            job_done           ;     //flag of all datas required are got

// ************************                     
// DEFINE OUTPUT(s)                             
// ************************
output           init_done          ;     //to PMU, Initialization finished
output [ 7:0]    lock_state         ;     //to OCU, output 8bits lock_state
output [15:0]    crc_calc           ;     //to RNG and OCU, output epc_crc16
output [ 7:0]    uac_len            ;     //to OCU, output high 8bits of len, the word_length of uac
output           tag_status         ;     //to PMU, tag kill_state, active high
output [ 5:0]    pointer_init       ;     //to IE, word_pointer
output [ 5:0]    length_init        ;     //to IE, word_length
output           kill_pwd_status    ;     //a flag that whether the tag can be killed, active high
output           lock_pwd_status    ;     //a flag that whether the tag can be locked, active high
output           read_pwd_status    ;
output           write_pwd_status   ;
output           read_en_init       ;     //to IE, enable signal for reading eeprom
//output [31:0]    kill_pwd           ;     //the 32bits kill passwords
//output [31:0]    lock_pwd           ;     //the 32bits lock passwords

// ***************************                  
// DEFINE OUTPUT(s) ATTRIBUTE                   
// *************************** 
//REG(s)
//reg              init_done          ;
reg    [ 7:0]    lock_state         ;
reg    [ 7:0]    uac_len            ;
reg              tag_status         ;
reg    [ 5:0]    pointer_init       ;
reg    [ 5:0]    length_init        ;
reg              read_en_init       ;
reg    [31:0]    kill_pwd           ;     
reg    [31:0]    lock_pwd           ; 
reg    [31:0]    read_pwd           ; 
reg    [31:0]    write_pwd          ; 

//WIRE(s)
wire   [15:0]    crc_calc           ; 
wire             kill_pwd_status    ;    
wire             lock_pwd_status    ;
wire             read_pwd_status    ;
wire             write_pwd_status   ;
wire             init_done          ;

// ****************************
// INNER SIGNAL(s) DECLARATION
// ****************************
//REG(s)
reg              gate_ctrl          ;     //a signal to control the clk 
reg    [ 3:0]    init_state         ;     //current state of tag
reg    [ 3:0]    init_next          ;     //next state of tag
reg              rd_en              ;     //enable signal to read eeprom, active high
reg              rd_flg             ;     //assist to generate rd_pulse 
reg              flg_ctrl           ;     //assist to generate rd_pulse
reg    [ 4:0]    word_cnt           ;     //number of received data
reg    [15:0]    MEM_BUF            ;     //fliter the value of mtp_data
reg              crc_en             ;     //CRC check enable signal
reg    [15:0]    CRC16              ;     //result of crc check

//WIRE(s)
wire             init_clk           ;     //derived from DOUB_BLF, the main clk
wire             rd_clk             ;     //derived from init_clk, used for reading eeprom
wire   [15:0]    crc_data           ;     //the data for crc check
wire             crc_xor00          ;     //one bit of crc16
wire             crc_xor01          ;
wire             crc_xor02          ;
wire             crc_xor03          ;
wire             crc_xor04          ;
wire             crc_xor05          ;
wire             crc_xor06          ;
wire             crc_xor07          ;
wire             crc_xor08          ;
wire             crc_xor09          ;
wire             crc_xor10          ;
wire             crc_xor11          ;
wire             crc_xor12          ;
wire             crc_xor13          ;
wire             crc_xor14          ;
wire             crc_xor15          ;
wire             crc_xor16          ;
wire             crc_xor17          ;
wire             crc_xor18          ;
wire             crc_xor19          ;
wire             crc_xor20          ;
wire             crc_xor21          ;
wire             crc_xor22          ;
wire             crc_xor23          ;
wire             crc_xor24          ;
wire             crc_xor25          ;
wire             crc_xor26          ;
wire             crc_xor27          ;

// ************************
// MAIN CODE
// ************************

//generate the gate control signal
always @(posedge DOUB_BLF or negedge rst_n)
begin: GATE_CTRL_GENGRATOR
    if(!rst_n)                                      //asynchronous reset
        gate_ctrl <= #`UDLY 1'b0    ;  
    else if(init_en)
        gate_ctrl <= #`UDLY 1'b1    ;
    else
        gate_ctrl <= #`UDLY 1'b0    ;
end

//assign initial clock
assign init_clk = DOUB_BLF & init_en & gate_ctrl; 

//--------------------------------------------------------
//Main FSM of init_state
//--------------------------------------------------------

//the main FSM for initiation
//always@(posedge init_clk or negedge rst_n)
//begin: INITIAL_STATE_FSM
//    if(!rst_n)
//        init_state <= #`UDLY INIT_RDY                   ;
//    else
//        case(init_state)  
//            INIT_RDY :      
//                init_state <= #`UDLY RD_KS              ;
//            RD_KS    : 
//                if(job_done)
//	                  if(tag_status)
//                        init_state <= #`UDLY INIT_END   ;
//				            else
//					              init_state <= #`UDLY RD_LS      ;
//                else
//                    init_state <= #`UDLY RD_KS          ;                          
//            RD_LS    :
//                if(job_done)                    
//                    init_state <= #`UDLY RD_KLPWD         ;
//                else
//                    init_state <= #`UDLY RD_LS          ;                 
//            RD_KLPWD   :
//                if(job_done)
//                    init_state <= #`UDLY RD_LEN         ;
//                else
//                    init_state <= #`UDLY RD_KLPWD         ;
//            RD_LEN   :
//                if(job_done)
//                    init_state <= #`UDLY RD_UAC         ;
//			          else
//                    init_state <= #`UDLY RD_LEN         ;			
//            RD_UAC   :
//                if(job_done)
//                    init_state <= #`UDLY INIT_END       ;
//                else
//                    init_state <= #`UDLY RD_UAC         ;	       
//            INIT_END :
//                init_state <= #`UDLY INIT_END           ;
//            default  :
//                init_state <= #`UDLY INIT_RDY           ;
//	      endcase
//end    

//initial main state_machine
always@(negedge rst_n or posedge init_clk)
begin: INNITIAL_STATE_MACHINE  
    if(!rst_n)
        init_state <= #`UDLY INIT_RDY           ;
    else 
        init_state <= #`UDLY init_next          ;      
end   

//init next state generator
always@(init_state or job_done or tag_status or uac_len)
begin: INITIAL_NEXT_STATE_GENERATOR 
    case(init_state)  
        INIT_RDY :      
            init_next = RD_KS                   ;
        RD_KS    : 
            if(job_done)
	              if(tag_status)
                    init_next = INIT_END        ;
				        else
					          init_next = RD_LS           ;
            else
                init_next = RD_KS               ;                          
        RD_LS    :
            if(job_done)                    
                init_next = RD_KLPWD            ;
            else
                init_next = RD_LS               ;                 
        RD_KLPWD :
            if(job_done)
                init_next = RD_RWPWD            ;
            else
                init_next = RD_KLPWD            ;
		    RD_RWPWD :
            if(job_done)
                init_next = RD_LEN              ;
            else
                init_next = RD_RWPWD            ;
        RD_LEN   :
            if(job_done)
                if(uac_len == 8'b0000_0000)
                    init_next = RD_BUFF         ;
                else
                    init_next = RD_UAC          ;
			      else
                init_next = RD_LEN              ;			
        RD_UAC   :
            if(job_done)
                init_next = RD_BUFF             ;
            else
                init_next = RD_UAC              ;	
        RD_BUFF  :
            init_next = INIT_END                ;
        INIT_END :
            init_next = INIT_END                ;
        default  :
            init_next = INIT_RDY                ;
	endcase
end    

//Generate init_done
//always @(negedge init_clk or negedge rst_n)
//begin: INIT_DONE_GENGRATOR
//    if(!rst_n)                                         
//        init_done <= #`UDLY 1'b0          ;
//    else if(init_done)                                 //init_done signal last one init_clk
//        init_done <= #`UDLY 1'b0          ;
//    else if(init_state == RD_BUFF)
//        init_done <= #`UDLY 1'b1          ;
//    else
//        init_done <= #`UDLY 1'b0          ;
//end

//init_done singal is generated when all the UAC numbers have been read
assign init_done = (init_state == RD_BUFF)?1'b1:1'b0;


//control the rd_clk and switch on the rd_clk if need to read memory
//always @(posedge DOUB_BLF or negedge rst_n)
always @(negedge init_clk or negedge rst_n)   
begin: RD_EN_GENGRATOR
    if(!rst_n)
        rd_en <= #`UDLY 1'b0              ;
    else if(init_state == RD_KS   ||
            init_state == RD_LS   ||
            init_state == RD_KLPWD||
		      	init_state == RD_RWPWD||
            init_state == RD_LEN  ||
           (init_state == RD_UAC  && job_done  == 1'b0))
            rd_en <= #`UDLY 1'b1          ;
    else
        rd_en <= #`UDLY 1'b0              ;
end

//assign read clock
assign rd_clk = init_clk & rd_en          ;

//only be as a flag and be used to assist to generate rd_pulse
always @(negedge rd_clk or negedge rst_n)
begin: RD_FLG_GENERATOR
    if(!rst_n)
        rd_flg <= #`UDLY 1'b0             ;
    else
        rd_flg <= #`UDLY ~ flg_ctrl       ;
end

//generate a pulse for reading memory
always @(posedge rd_clk or negedge rst_n)           
begin: INIT_RD_PULSE_GENERATOR
    if(!rst_n)
        read_en_init  <= #`UDLY 1'b0      ;
    else
        read_en_init  <= #`UDLY ~ rd_flg  ;
end
    	
//be derived from rd_done and be used to assist to generate rd_pulse
always @(posedge init_clk or negedge rst_n)
begin: FLG_CTRL_GENERATOR
    if(!rst_n)
        flg_ctrl <= #`UDLY 1'b0           ;
    else
        flg_ctrl <= #`UDLY word_done      ;
end

//--------------------------------------------------------
//Operation for EEPROM
//--------------------------------------------------------
//prepare the address to be read for IE
always@(init_state)   
begin: ADDRESSING_E2_CONTROLLING_POINTER
    case (init_state) 
        INIT_RDY,
        INIT_END :                       
            pointer_init = 6'b0_0000      ;      
        RD_KS    :             
            pointer_init = 6'b1_1110      ;
        RD_LS    :    
            pointer_init = 6'b1_1101      ;		
        RD_KLPWD :              
            pointer_init = 6'b1_1001      ;
        RD_RWPWD   :              
            pointer_init = 6'b1_01000     ;
        RD_LEN   :
            pointer_init = 6'b0_1000      ; 
        RD_UAC   :
            pointer_init = 6'b0_1001      ; 
        default  :
            pointer_init = 6'b0_0000      ; 
    endcase  
end			

//prepare the length of words need to be read
always@(init_state or uac_len)   
begin: ADDRESSING_E2_CONTROLLING_LENGTH
    case (init_state) 
        INIT_RDY,
        INIT_END :
            length_init  = 6'b0_0000      ;            
        RD_KS    :                 
            length_init  = 6'b0_0001      ;
        RD_LS    :
            length_init  = 6'b0_0001      ;		
        RD_LEN   :
            length_init  = 6'b0_0001      ;  
        RD_KLPWD :
            length_init  = 6'b0_0100      ;  
        RD_RWPWD :	
            length_init  = 6'b0_0100      ; 
        RD_UAC   :
            length_init  = uac_len        ;
        default  :
            length_init  = 6'b0_0000      ;   
    endcase
end 
			
//count the words that have been read			
always @(posedge init_clk or negedge rst_n)
begin: WORD_NUM_CNT
    if(!rst_n)
        word_cnt <= #`UDLY 5'b0           ;
    else if(job_done)
        word_cnt <= #`UDLY 5'b0           ;
    else if(word_done)
        word_cnt <= #`UDLY word_cnt + 1'b1;
    else
        word_cnt <= #`UDLY word_cnt       ;
end			
			
//judge the tag state -killed or not		
always@(posedge word_done or negedge rst_n)  
begin: KILL_STATE_GENERATOR
    if(!rst_n)
        tag_status <= #`UDLY 1'b0         ;         
    else if(init_state == RD_KS) 
        tag_status <= #`UDLY MEM_BUF[15]  ;   
    else
        tag_status <= #`UDLY tag_status   ;
end			
			
//judge the lock state -locked or not			
always@(posedge word_done or negedge rst_n)  
begin: LOCK_STATE_GENERATOR
    if(!rst_n)
        lock_state <= #`UDLY 8'b0000_0000 ;         
    else if(init_state == RD_LS)             
        lock_state <= #`UDLY MEM_BUF[15:8];                  
    else
        lock_state <= #`UDLY lock_state   ;
end 			
			
//kill pwd status judge,if kill pwd is 32'b0,kill_pwd_status =0			
always @(posedge word_done or negedge rst_n)
begin: KILL_PWD_JUDGE
    if(!rst_n)
        kill_pwd <= #`UDLY 32'h0000_0000               ;
    else if(init_state == RD_KLPWD)
        if(word_cnt < 5'd2)
            kill_pwd <= #`UDLY {kill_pwd[15:0],MEM_BUF};
        else
            kill_pwd <= #`UDLY kill_pwd                ;
    else
        kill_pwd <= #`UDLY kill_pwd                    ;
end		
			
assign kill_pwd_status = (|kill_pwd);     //kill_pwd!=32'h0000_0000;			
			
//lock pwd status judge,if lock pwd is 32'b0,lock_pwd_status =0			
always @(posedge word_done or negedge rst_n)
begin: LOCK_PWD_JUDGE
    if(!rst_n)
        lock_pwd <= #`UDLY 32'h0000_0000               ;
    else if(init_state == RD_KLPWD)
        if(word_cnt > 5'd1)
            lock_pwd <= #`UDLY {lock_pwd[15:0],MEM_BUF};
        else
            lock_pwd <= #`UDLY lock_pwd                ;
    else
        lock_pwd <= #`UDLY lock_pwd                    ;
end			
			
assign lock_pwd_status = (|lock_pwd);    //lock_pwd!=32'h0000_0000;			
			
//read pwd status judge,if read pwd is 32'b0,read_pwd_status =0			
always @(posedge word_done or negedge rst_n)
begin: READ_PWD_JUDGE
    if(!rst_n)
        read_pwd <= #`UDLY 32'h0000_0000               ;
    else if(init_state == RD_RWPWD)
        if(word_cnt < 5'd2)
            read_pwd <= #`UDLY {read_pwd[15:0],MEM_BUF};
        else
            read_pwd <= #`UDLY read_pwd                ;
    else
        read_pwd <= #`UDLY read_pwd                    ;
end			
			
assign read_pwd_status = (|read_pwd);    //read_pwd!=32'h0000_0000;	

//write pwd status judge,if write pwd is 32'b0,write_pwd_status =0			
always @(posedge word_done or negedge rst_n)
begin: WRITE_PWD_JUDGE
    if(!rst_n)
        write_pwd <= #`UDLY 32'h0000_0000               ;
    else if(init_state == RD_RWPWD)
        if(word_cnt > 5'd1)
            write_pwd <= #`UDLY {write_pwd[15:0],MEM_BUF};
        else
            write_pwd <= #`UDLY write_pwd                ;
    else
        write_pwd <= #`UDLY write_pwd                    ;
end			
			
assign write_pwd_status = (|write_pwd);    //write_pwd!=32'h0000_0000;		
			
//receive the length of UAC from EEPROM
always@(posedge word_done or negedge rst_n)  
begin: UAC_LEN_GENERATOR
    if(!rst_n)
        uac_len <= #`UDLY 8'b0                         ;         
    else if(init_state == RD_LEN)
        uac_len <= #`UDLY MEM_BUF[15:8]                ;           
    else
        uac_len <= #`UDLY uac_len                      ;
end			
			
//Filter the data from memory.   
always @(init_state or mtp_data)
begin: FILTER_MTP_DATA
    case(init_state)
    RD_KS :
        if(mtp_data == 16'hAAAA)     
            MEM_BUF = 16'h8000                         ;
        else
            MEM_BUF = 16'h0000                         ;
    RD_LS :
        if(mtp_data[7:0] == 8'b1010_1010)
            MEM_BUF = mtp_data                         ;
        else
            MEM_BUF = 16'h0000                         ;
    RD_LEN:
        if(mtp_data[15:8] > 8'b0001_0000)
            MEM_BUF = {8'b0001_0000,mtp_data[7:0]}     ;
        else
            MEM_BUF = mtp_data                         ;        
    default:
        MEM_BUF = mtp_data                             ;
    endcase
end 	
		
//--------------------------------------------------------
//CRC16 for EPC
//--------------------------------------------------------			
//Enable CRC16 Checks.
always @(negedge init_clk or negedge rst_n)
begin: CRC_ENABLE
    if(!rst_n)
        crc_en <= #`UDLY 1'b0;
    else if(init_state == RD_UAC || init_state == RD_LEN)
        crc_en <= #`UDLY 1'b1;
    else
        crc_en <= #`UDLY 1'b0;
end			
			
assign crc_data  = MEM_BUF   ;
    
assign crc_calc  = ~CRC16    ;

//caculator the 16 bits value of CRC 
assign crc_xor00 = crc_data[0] ^ crc_xor16;
assign crc_xor01 = crc_data[1] ^ crc_xor17;
assign crc_xor02 = crc_data[2] ^ crc_xor18;
assign crc_xor03 = crc_data[3] ^ crc_xor19;
assign crc_xor04 = crc_data[4] ^ crc_xor26;    
assign crc_xor05 = crc_xor00   ^ crc_xor20;
assign crc_xor06 = crc_xor01   ^ crc_xor21;
assign crc_xor07 = crc_xor02   ^ crc_xor22;
assign crc_xor08 = crc_xor03   ^ crc_xor23;
assign crc_xor09 = crc_xor04   ^ crc_xor24;    
assign crc_xor10 = crc_xor20   ^ crc_xor25;
assign crc_xor11 = crc_xor21   ^ crc_xor27;
assign crc_xor12 = crc_data[0] ^ crc_xor16   ^ crc_xor22 ^ crc_data[12] ^ CRC16[12];
assign crc_xor13 = crc_data[1] ^ crc_xor17   ^ crc_xor23 ^ crc_data[13] ^ CRC16[13];
assign crc_xor14 = crc_data[2] ^ crc_xor18   ^ crc_xor24 ^ crc_data[14] ^ CRC16[14];
assign crc_xor15 = crc_data[3] ^ crc_xor19   ^ crc_xor25 ^ crc_data[15] ^ CRC16[15];

//just used for reducing the area of circuit
assign crc_xor16 = crc_data[4] ^ crc_xor26   ^ crc_xor27 ^ CRC16[0] ;
assign crc_xor17 = crc_xor20   ^ crc_data[12]^ CRC16[12] ^ CRC16[1] ;
assign crc_xor18 = crc_xor21   ^ crc_data[13]^ CRC16[13] ^ CRC16[2] ;
assign crc_xor19 = crc_xor22   ^ crc_data[14]^ CRC16[14] ^ CRC16[3] ;
assign crc_xor20 = crc_data[5] ^ crc_xor24   ^ CRC16[5]             ;
assign crc_xor21 = crc_data[6] ^ crc_xor25   ^ CRC16[6]             ;
assign crc_xor22 = crc_data[7] ^ crc_xor27   ^ CRC16[7]             ;
assign crc_xor23 = crc_data[8] ^ crc_data[12]^ CRC16[12] ^ CRC16[8] ;
assign crc_xor24 = crc_data[9] ^ crc_data[13]^ CRC16[13] ^ CRC16[9] ;
assign crc_xor25 = crc_data[10]^ crc_data[14]^ CRC16[14] ^ CRC16[10];
assign crc_xor26 = crc_xor23   ^ crc_data[15]^ CRC16[15] ^ CRC16[4] ;
assign crc_xor27 = crc_data[11]^ crc_data[15]^ CRC16[15] ^ CRC16[11];			
			
//value of CRC16 
always @(posedge word_done or negedge rst_n)
begin: CRC16_GENERATOR
    if(!rst_n)
        CRC16 <= #`UDLY 16'hffff;
    else if(crc_en)
        CRC16 <= #`UDLY {crc_xor15,crc_xor14,crc_xor13,crc_xor12,crc_xor11,crc_xor10,crc_xor09,crc_xor08,
                        crc_xor07,crc_xor06,crc_xor05,crc_xor04,crc_xor03,crc_xor02,crc_xor01,crc_xor00};
    else
        CRC16 <= #`UDLY CRC16   ;
end			
			
endmodule		
			
			
			
			
			





