// *******************************************************************
// COPYRIGHT, Xi'an XDU Radio-frequency IC Co.,Ltd 
// All rights reserved.
//
// IP NAME      :  RFID
// File name    :  ocu.v
// Module name  :  OCU
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

module OCU(
           //INPUTs
		       DOUB_BLF       ,
           rst_n          ,
           ocu_en         ,
           delimiter      ,
		       init_done      ,
           dec_done6      ,
           T2_judge_en    ,     //from scu, used to judge T2 is overstep or not
           word_done      , 
           job_done       ,
           TRext          ,
           bsc            ,
           membank        ,
           pointer        ,
           length         ,
           m_value        ,
		       lock_state     ,
		       lock_action    ,
		       data_buffer    ,
           mtp_data       ,
           handle         ,
           rn16           ,
		       uac_len        ,
		       addr_over      ,

		       //OUTPUTs
		       dout           ,
           T2_overstep    ,
           pointer2mem    ,
           length2mem     ,
           wr_data        ,
		       addr_ie_req    ,
		       wr_pulse       ,
		       read_pulse     ,
		       ocu_done       ,
		       crc5_back      ,
		       kill_tag       ,
		       clk_sel        ,
		       data_clk       ,
		       tid_tag        //add in 11.5
		   
		       );

// ************************                     
// DEFINE PARAMETER(s)                          
// ************************

//define parameters for main ocu FSM:
parameter  OCU_RDY         = 4'b0000 ;  // if tag have no data to backscatter,stay in OCU_RDY.
parameter  READ_MEM        = 4'b0001 ;  // execute the issued read MEM cmd.
parameter  WRITE_CHK       = 4'b0010 ;  
parameter  WRITE_MEM       = 4'b0011 ;  // execute the issued write MEM cmd.
parameter  SEND_DATA       = 4'b0100 ;
parameter  RD_ADDR_JUDGE   = 4'b0101 ;
parameter  WR_ADDR_JUDGE   = 4'b0111 ;
parameter  PRE_DATA        = 4'b1000 ; 
parameter  NOP_ONE         = 4'b1001 ;
parameter  NOP_TWO         = 4'b1100 ;
parameter  NOP_THR         = 4'b1101 ;
parameter  NOP_FOR         = 4'b1110 ;
parameter  KILL_TAG        = 4'b1011 ;
parameter  LOCK_TAG        = 4'b1010 ;
parameter  OCU_END         = 4'b1111 ;
		   
//define parameters for bs FSM;
parameter  BS_READY        = 3'b000  ;  
parameter  BS_PILOT_MILLER = 3'b001  ;  //denotes the state of send first four zeros of miller's pilot
parameter  BS_PILOT        = 3'b011  ;  
parameter  BS_HEAD         = 3'b010  ;  
parameter  BS_DATA         = 3'b110  ;
parameter  BS_CRC          = 3'b100  ;   
parameter  BS_DUM          = 3'b101  ;  

//states for encoder
parameter ENC_RDY          =3'b000   ;
parameter POS_ZERO         =3'b001   ;
parameter POS_ONE          =3'b010   ;
parameter NEG_ZERO         =3'b011   ;
parameter NEG_ONE          =3'b100   ;

// ************************
// DEFINE INPUT(s)
// ************************
input		       DOUB_BLF        ;
input          rst_n           ;
input          ocu_en          ;
input          delimiter       ;
input		       init_done       ;
input          dec_done6       ;
input          T2_judge_en     ;
input          word_done       ;
input          job_done        ;
input          TRext           ;
input [ 3:0]   bsc             ;
input [ 1:0]   membank         ;
input [ 5:0]   pointer         ;
input [ 5:0]   length          ;
input [ 1:0]   m_value         ;
input [ 7:0]   lock_state      ;
input [ 1:0]   lock_action     ;
input [15:0]   data_buffer     ;
input [15:0]   mtp_data        ;
input [15:0]   handle          ;
input [15:0]   rn16            ;
input [ 7:0]   uac_len         ;  
input          addr_over       ;

// ************************                       
// DEFINE OUTPUT(s)                               
// ************************
output		     dout            ;
output         T2_overstep     ;
output[ 5:0]   pointer2mem     ;
output[ 5:0]   length2mem      ;
output[15:0]   wr_data         ;
output		     addr_ie_req     ;
output		     wr_pulse        ;
output		     read_pulse      ;
output[ 4:0]   crc5_back       ;
output		     kill_tag        ;
output		     ocu_done        ;
output         clk_sel         ;
output         data_clk        ;
output         tid_tag         ;

// ***************************                    
// DEFINE OUTPUT(s) ATTRIBUTE                     
// ***************************
reg  		       dout            ;
reg            T2_overstep     ;
reg   [ 5:0]   pointer2mem     ;
reg   [ 5:0]   length2mem      ;
reg   [15:0]   wr_data         ;
reg 		       addr_ie_req     ;
reg  		       wr_pulse        ;
reg   [ 4:0]   crc5_back       ;
reg 		       kill_tag        ;
reg            ocu_done        ;
reg            clk_sel         ;
reg            data_clk        ;
reg            read_pulse      ;
reg            tid_tag         ;

// *************************
// INNER SIGNAL DECLARATION
// *************************
//REG(s)
//reg            gate_ctrl       ;
reg   [ 3:0]   ocu_cur_state   ;
reg   [ 3:0]   ocu_nxt_state   ;
reg            addr_lock       ;
reg            addr_rw_err     ;
reg            pc_err          ;
reg            oper_end        ;
reg            lock_temp_err   ;
reg            rd_chk_pulse    ;
reg            wr_chk_pulse    ;
reg   [ 7:0]   lock_bak        ;
reg   [ 7:0]   lock_temp       ;
reg            lock_flag       ;
reg            write_en        ;
reg            wr_flg          ;
reg   [10:0]   send_cnt        ;
reg            enc_go          ;
reg            BLF_clk         ;
reg            HALF_BLF        ;
reg            FOURTH_BLF      ;
reg            EIGHTH_BLF      ;
reg   [ 2:0]   mlr_pilot_cnt   ;
reg   [ 7:0]   oper_status     ;
reg   [ 2:0]   bs_cur_state    ;
reg   [ 2:0]   bs_nxt_state    ;
reg            pilot_done      ;
reg            head_done       ;
reg            data_done       ;
reg            crc_done        ;
reg            dummy           ;
reg   [31:0]   bs_buf          ;
reg   [10:0]   bit_len         ;
reg   [ 7:0]   head            ;
reg            calc_crc5       ;
reg            calc_crc16      ;
reg   [15:0]   crc             ;
reg            uac_valid       ;
reg   [ 7:0]   head_int        ;
reg            send_done       ;
reg   [ 3:0]   crc_cnt         ;
reg            dummy_delay     ;
reg            dout_go_pre     ;
reg            dout_go         ;
reg            phase_v1        ;
reg            data_go         ;
reg            data_clk_dly1   ;
reg            data_clk_dly2   ;
reg            data_clk_dly3   ;
reg   [ 6:0]   half_tpri_cnt   ;
reg            bit             ;
reg   [ 3:0]   pilot_cnt       ;
reg            crc5_get        ;
reg            head_en         ;
reg            lk_vee_err      ;
reg            wr_vee_err      ;
reg   [ 2:0]   enc_state       ;
 
//WIRE(s)
wire           ocu_clk         ;
wire           rst_del         ;
wire           addr_chk_pulse  ;
wire           wr_clk          ;
wire           enc_clk_sel     ;
wire           T2_clk_en       ;
wire           use_pilot       ;
wire           head_clk        ;
wire           head_rst        ;
wire           T2_CLK          ;
wire           crc_xor0        ;
wire           crc_xor1        ;
wire           crc_xor2        ;
wire           crc_xor3        ;
wire           sos_pulse       ;
wire           mos_pulse       ;

// ************************
// MAIN CODE
// ************************

assign ocu_clk = DOUB_BLF & ocu_en ;

assign rst_del = rst_n & ~delimiter           ;

//Main state transition
always @(posedge ocu_clk or negedge rst_del)   
begin: OCU_STAT_TRAN
    if(!rst_del)
        ocu_cur_state <= #`UDLY OCU_RDY       ;
    else 
        ocu_cur_state <= #`UDLY ocu_nxt_state ;
end

//Prepare the next state
always @(bsc or ocu_cur_state or oper_end or addr_over or addr_lock or lock_temp_err or addr_rw_err or pc_err or dummy_delay) 
begin
    case(ocu_cur_state)
	  OCU_RDY      :
	      case(bsc)
        `NO_BACK    :
		         ocu_nxt_state = OCU_END          ;
        `BACK_HANDLE       ,
        `BACK_RN11_CRC5    ,
        `BACK_CHECK_RESULT ,
        `NO_AUTHORITY      ,
        `NO_AUTHORITY_P    ,
	    	`BACK_ACC_PWD_ERR  :
            ocu_nxt_state = PRE_DATA          ; 
        `BACK_UAC   ,  
        `BACK_READ  :
            ocu_nxt_state = READ_MEM          ;
        `BACK_WRITE ,
        `BACK_ERASE ,
        `BACK_TID_WR:
            ocu_nxt_state = WRITE_CHK         ;
        `BACK_TID_DO,
        `KILL_EVENT :
            ocu_nxt_state = KILL_TAG          ;  //here KILL_TAG just means an action that write a state into the pointed address
        `LOCK_EVENT :
            ocu_nxt_state = LOCK_TAG          ;
        default     :
            ocu_nxt_state = OCU_RDY           ;
        endcase
	  READ_MEM     :
        if(bsc == `BACK_UAC)
            ocu_nxt_state = PRE_DATA          ;
        else
            ocu_nxt_state = RD_ADDR_JUDGE     ;
    WRITE_CHK    :
        ocu_nxt_state = WR_ADDR_JUDGE         ;    
    RD_ADDR_JUDGE:
        ocu_nxt_state = PRE_DATA              ;
	  WR_ADDR_JUDGE:
	      if(bsc == `BACK_TID_WR)
	          if(addr_over)
	              ocu_nxt_state = PRE_DATA      ;
	          else
	              ocu_nxt_state = WRITE_MEM     ;
	      else 
	          if(addr_over|addr_lock|addr_rw_err|pc_err)       
		            ocu_nxt_state = PRE_DATA          ;
		        else
		            ocu_nxt_state = WRITE_MEM         ;
    WRITE_MEM    :
        if(oper_end == 1'b1)
            ocu_nxt_state = PRE_DATA          ;
        else
            ocu_nxt_state = WRITE_MEM         ;	
    KILL_TAG     :
            ocu_nxt_state = WRITE_MEM         ;
    LOCK_TAG     :
        if(lock_temp_err == 1'b1)             //indicate the region can't be locked
            ocu_nxt_state = PRE_DATA          ;
        else
            ocu_nxt_state = WRITE_MEM         ;
  	PRE_DATA     :
	      ocu_nxt_state = NOP_ONE               ;
	  NOP_ONE:                                  //4 idle clock, for writing/reading data to MTP, may reducing
	      ocu_nxt_state = NOP_TWO;
	  NOP_TWO:
	      ocu_nxt_state = NOP_THR;
	  NOP_THR:
	      ocu_nxt_state = NOP_FOR;
	  NOP_FOR:
	      ocu_nxt_state = SEND_DATA;
    SEND_DATA    :
	      if(dummy_delay) //revised in 11.6
		        ocu_nxt_state = OCU_END           ;
		    else	
            ocu_nxt_state = SEND_DATA         ;
	  OCU_END      :
	      ocu_nxt_state = OCU_END               ;
    default      :
        ocu_nxt_state = OCU_RDY               ;
    endcase 
end 

always@(posedge job_done or negedge rst_del)
begin
    if(!rst_del)
        oper_end <= #`UDLY 1'b0               ;
    else 
        oper_end <= #`UDLY 1'b1               ;
end 

//Generate a pulse for checking the address of read
always @(negedge ocu_clk or negedge rst_n)
begin
    if(!rst_n)
        rd_chk_pulse <= #`UDLY 1'b0           ;
    else if(ocu_cur_state == RD_ADDR_JUDGE)
        rd_chk_pulse <= #`UDLY 1'b1           ;
    else
        rd_chk_pulse <= #`UDLY 1'b0           ;
end

//Generate a pulse for checking the address of write
always @(negedge ocu_clk or negedge rst_n)
begin
    if(!rst_n)
        wr_chk_pulse <= #`UDLY 1'b0           ;
    else if(ocu_cur_state == WR_ADDR_JUDGE)
        wr_chk_pulse <= #`UDLY 1'b1           ;
    else
        wr_chk_pulse <= #`UDLY 1'b0           ;
end

assign addr_chk_pulse = rd_chk_pulse | wr_chk_pulse;

//Check if the address is locked
always @(posedge addr_chk_pulse or negedge rst_del)
begin
    if(!rst_del)
	    addr_lock <= #`UDLY 1'b0;
	  else
	      case(membank)
		    2'b00:
            if(lock_bak[1] == 1'b1)       //lock_bak is the up-to-date lock_state
                addr_lock <= #`UDLY 1'b1;         //TID membank cannot be read after being locked and it can never be written
            else
                addr_lock <= #`UDLY 1'b0;
        2'b01:            
            if(bsc == `BACK_READ)         //UAC membank can be read after being locked
                addr_lock <= #`UDLY 1'b0;                   
            else 
                if(lock_bak[2] == 1'b1)
                    addr_lock <= #`UDLY 1'b1;
                else
                    addr_lock <= #`UDLY 1'b0;
        2'b10:
            if(bsc == `BACK_WRITE || bsc == `BACK_ERASE)
                if(lock_bak[4] == 1'b1)
                    addr_lock <= #`UDLY 1'b1;
                else
                    addr_lock <= #`UDLY 1'b0;
            else
                addr_lock <= #`UDLY 1'b0;
        2'b11:
            if(bsc == `BACK_READ)
                if(lock_bak[7] == 1'b1)
                    addr_lock <= #`UDLY 1'b1;
                else
                    addr_lock <= #`UDLY 1'b0;
            else
                if(lock_bak[6] == 1'b1)
                    addr_lock <= #`UDLY 1'b1;
                else
                    addr_lock <= #`UDLY 1'b0;
        default:
		        addr_lock <= #`UDLY 1'b0;
        endcase 
end 

always@(posedge job_done or negedge rst_del)
begin
	  if(!rst_del)
	      wr_vee_err <= #`UDLY 1'b0;
	  else
	      case(bsc)
	      `BACK_WRITE,
	      `BACK_ERASE,
	      `BACK_TID_WR:
	          if(mtp_data==wr_data)
	              wr_vee_err <= #`UDLY 1'b0;
	          else
	              wr_vee_err <= #`UDLY 1'b1;
        default:
            wr_vee_err <= #`UDLY 1'b0;
        endcase
end

always@(posedge job_done or negedge rst_n)
begin
    if(!rst_n)
        tid_tag <= #`UDLY 1'b0;
    else if(tid_tag == 1'b1)  
        tid_tag <= #`UDLY 1'b1;
    else if(bsc==`BACK_TID_DO)
        if(mtp_data==wr_data)
            tid_tag <= #`UDLY 1'b1;
        else
            tid_tag <= #`UDLY 1'b0;
    else
        tid_tag <= #`UDLY 1'b0;
end

//Check if the value of pc to write is valid.
always @(posedge wr_chk_pulse or negedge rst_del)
begin
    if(!rst_del)
        pc_err <= #`UDLY 1'b0;
    else if(membank == 2'b01)
        if(pointer == 6'h8)
            if(wr_data[15:8] > 8'd16)     //the max length of UAC
                pc_err <= #`UDLY 1'b1;
            else
                pc_err <= #`UDLY 1'b0;
        else
            pc_err <= #`UDLY 1'b0;
    else
        pc_err <= #`UDLY 1'b0;   
end

//addr_rw_err generation: error code is 8'b1000_0001 errors related to read or write the region that cannot be read or written
always@(posedge addr_chk_pulse or negedge rst_del)         
begin
    if(!rst_del)
	    addr_rw_err <= #`UDLY 1'b0;
	else
        case(membank)
        2'b00:                      //TID membank is read_only      
            if(bsc == `BACK_WRITE || bsc == `BACK_ERASE)
                addr_rw_err <= #`UDLY 1'b1; 
            else 
                addr_rw_err <= #`UDLY 1'b0;             
        2'b10:                      //SECURED membank is write_only   
            if(bsc == `BACK_READ)
                addr_rw_err <= #`UDLY 1'b1;
            else if(pointer == 6'd33 || pointer == 6'd34)    //lock_state and kill_state can not be written   
                addr_rw_err <= #`UDLY 1'b1;
            else
                addr_rw_err <= #`UDLY 1'b0;
        default:
            addr_rw_err <= #`UDLY 1'b0;
    endcase 
end 

//lock_temp generation:
always@(bsc or membank or lock_bak or lock_action or lock_state)
begin
    if(bsc == `LOCK_EVENT)
        case(membank)
        2'b00:
            begin                                         //if lock region is TID, then assign the value of lock_action to lock_temp[1:0]
                lock_temp[1:0] = lock_action;
                lock_temp[7:2] = lock_bak[7:2];
            end 
        2'b01:
            begin
                lock_temp[1:0] = lock_bak[1:0];           //if lock region is UAC, then assign the value of lock_action to lock_temp[3:2]
                lock_temp[3:2] = lock_action;
                lock_temp[7:4] = lock_bak[7:4];
            end 
        2'b10:
            begin
                lock_temp[3:0] = lock_bak[3:0];          //if lock region is SAFE, then assign the value of lock_action to lock_temp[5:4]
                lock_temp[5:4] = lock_action;
                lock_temp[7:6] = lock_bak[7:6];
            end 
        2'b11:
            begin
                lock_temp[5:0] = lock_bak[5:0];          //if lock region is USER, then assign the value of lock_action to lock_temp[7:6]
                lock_temp[7:6] = lock_action;
            end 
        default:
            lock_temp = 8'b00;
        endcase 
    else
        lock_temp = lock_state;    //revised in 10/24/2013
end 

always@(bsc or ocu_en or lock_action or membank)
begin
    if(ocu_en == 1'b1)
        if(bsc == `LOCK_EVENT)
            case(membank)
            2'b00:
                if(lock_action[0] == 1'b0)  //TID can be locked to (read,not write) or (not read,not write),can't be locked to (read,write) or (not read,write)
                    lock_temp_err = 1'b1;
                else
                    lock_temp_err = 1'b0;
            2'b01:
                if(lock_action[1] == 1'b1)  //UAC can be locked to (read,write) or (read,not write),can't be locked to (not read,write) or (not read,not write)
                    lock_temp_err = 1'b1;
                else
                    lock_temp_err = 1'b0;
            2'b10:
                if(lock_action[1] == 1'b0)  //SAFE can be locked to (not read,write) or (not read,not write),can't be locked to (read,write) or (read,not write)
                    lock_temp_err = 1'b1;
                else
                    lock_temp_err = 1'b0;
            2'b11:
                lock_temp_err = 1'b0;      //USER can be locked to (read,not write),(not read,not write),(read,write) or (not read,write)
		        default:
			          lock_temp_err = 1'b0;
            endcase 
        else
            lock_temp_err = 1'b0;
    else
        lock_temp_err = 1'b0;
end 

always@(posedge job_done or negedge rst_del)
begin
    if(!rst_del)
        begin
            lock_flag <= #`UDLY 1'b0;
            lk_vee_err<= #`UDLY 1'b0;
        end
    else if(bsc == `LOCK_EVENT)// && ocu_cur_state == WRITE_MEM)
        if(mtp_data==wr_data)
            begin
                lock_flag <= #`UDLY 1'b1;     //lk_vee_err=1'b1 means lock operation fails.The cause is vee_err.The oper_status is 10000011.
                lk_vee_err<= #`UDLY 1'b0;
            end
        else
            begin
                lock_flag <= #`UDLY 1'b0;
                lk_vee_err<= #`UDLY 1'b1;
            end
    else
        begin
            lock_flag <= #`UDLY 1'b0;
            lk_vee_err<= #`UDLY 1'b0;
        end
end  

always@(posedge lock_flag or negedge rst_n)
begin
    if(!rst_n) 
        lock_bak <= #`UDLY 8'b0;
    else 
        lock_bak <= #`UDLY lock_temp;  //lock_bak is the up-to-date lockstate of the tag 
end 

// judge the tag be killed or not
always @(posedge job_done or negedge rst_n)
begin: KILL_2_PMU
    if(!rst_n)
        kill_tag <= #`UDLY 1'b0;                 
    else if(kill_tag == 1'b1)
        kill_tag <= #`UDLY kill_tag;
    else if(bsc == `KILL_EVENT)
        if(mtp_data==wr_data)
            kill_tag <= #`UDLY 1'b1; 
        else
            kill_tag <= #`UDLY 1'b0;
    else
        kill_tag <= #`UDLY 1'b0;
end

// *****************************************************
// WRITE_MTP
// *****************************************************

//wr_data: data to write in the memory
always@(posedge wr_pulse or negedge rst_n)
begin
    if(!rst_n)
        wr_data <= #`UDLY 16'b0;
    else if(ocu_cur_state == WRITE_MEM)
        if(bsc == `LOCK_EVENT)
            wr_data <= #`UDLY {lock_temp, 8'b10101010};         //8'b10101010 is the locked status
        else if(bsc == `KILL_EVENT||bsc == `BACK_TID_DO)
            wr_data <= #`UDLY 16'hAAAA;                         //16'hAAAA mean the tag has been killed
        else if(bsc == `BACK_WRITE||bsc == `BACK_TID_WR)
            wr_data <= #`UDLY data_buffer;
        else if(bsc == `BACK_ERASE)
            wr_data <= #`UDLY 16'b0;
        else
            wr_data <= #`UDLY 16'b0;
    else
        wr_data <= #`UDLY wr_data;
end  

//Enable operation of writing
always@(negedge ocu_clk or negedge rst_n)
begin
    if(!rst_n)
        write_en <= #`UDLY 1'b0;
    else if(job_done == 1'b1)
        write_en <= #`UDLY 1'b0;
    else if(ocu_cur_state == WRITE_MEM)
        write_en <= #`UDLY 1'b1;
    else
        write_en <= #`UDLY 1'b0;
end 

assign wr_clk = ocu_clk & write_en;

//used to generate wr_data
always @(negedge wr_clk or negedge rst_del)
begin
    if(!rst_del)
        wr_flg <= #`UDLY 1'b0;
    else
        wr_flg <= #`UDLY 1'b1;
end
    
//Start writing the MTP.
always @(posedge wr_clk or negedge rst_n)
begin
    if(!rst_n)
        wr_pulse <= #`UDLY 1'b0;
    else if(wr_flg)
        wr_pulse <= #`UDLY 1'b0;
    else
        wr_pulse <= #`UDLY 1'b1;
end

// *****************************************************
// READ_MTP
// *****************************************************

//read enable signal generate
always@(posedge data_clk or negedge rst_del)
begin
    if(!rst_del)
        read_pulse <= #`UDLY 1'b0; 
    else if(addr_over|addr_rw_err|addr_lock)
        read_pulse <= #`UDLY 1'b0;
    else if(oper_end == 1'b1)
        read_pulse <= #`UDLY 1'b0;
    else
        case(bsc)
        `BACK_READ,
        `BACK_UAC:
            if((bs_cur_state != BS_HEAD && bs_nxt_state == BS_HEAD) || (send_cnt - 11'd9) % 5'd16 == 0)
                read_pulse <= #`UDLY 1'b1;
            else
                read_pulse <= #`UDLY 1'b0;
        default:
            read_pulse <= #`UDLY 1'b0;
        endcase 
end 

// *************************************************
// Manage the address for reading/writing MTP
// *************************************************

always @(negedge ocu_clk or negedge rst_n)
begin
    if(!rst_n)
        addr_ie_req <= #`UDLY 1'b0;
    else if(ocu_cur_state==READ_MEM ||
	          ocu_cur_state==WRITE_CHK||
			      ocu_cur_state==LOCK_TAG ||
			      ocu_cur_state==KILL_TAG)
        addr_ie_req <= #`UDLY 1'b1;
    else
        addr_ie_req <= #`UDLY 1'b0;
end
	
//generate pointer2mem
always@(posedge addr_ie_req or negedge rst_n)
begin
    if(!rst_n)
	    pointer2mem <= #`UDLY 6'd0;
	  else
	    case(bsc)
      `LOCK_EVENT:                            //all the values below are temporary,should be revised according to MTP  
		      pointer2mem <= #`UDLY 6'd33;       //the address of lockstate,in safe region
		  `KILL_EVENT:
		      pointer2mem <= #`UDLY 6'd34;       //the address of killstate,in safe region
	  	`BACK_UAC:
		      pointer2mem <= #`UDLY 6'd8;
		  `BACK_TID_DO:
		      pointer2mem <= #`UDLY 6'd7;        //the address of TID state,in TID region
		  default:
		      pointer2mem <= #`UDLY pointer;
		  endcase
end

//generate length2mem
always@(posedge addr_ie_req or negedge rst_n)
begin
    if(!rst_n)
	    length2mem <= #`UDLY 6'd0;
	  else
	      case(bsc)
	      `BACK_TID_WR,
	      `BACK_TID_DO,
	      `BACK_WRITE,
	      `BACK_ERASE,
        `LOCK_EVENT,                             
//		        length2mem <= #`UDLY 6'd1;      
		    `KILL_EVENT:
		        length2mem <= #`UDLY 6'd2;      //change 6'd1 to 6'd2,revised in 11/4.pan
		    `BACK_UAC:
		        length2mem <= #`UDLY uac_len + 1'b1;
		    default:
		        length2mem <= #`UDLY length;
		    endcase
end

// *************************************************
// data_clk generate 
// *************************************************

assign enc_clk_sel = DOUB_BLF & enc_go;

always @(posedge enc_clk_sel or negedge rst_del)   
begin
    if(!rst_del)
        BLF_clk <= #`UDLY 1'b0;             //used for FM0 encoding
    else 
        BLF_clk <= #`UDLY ~BLF_clk;
end

always@(posedge BLF_clk or negedge rst_del)
begin
    if(!rst_del)
        HALF_BLF <= #`UDLY 1'b0;
    else if(m_value != 2'b00)             //used for miller encoding, subcarrier is 2
        HALF_BLF <= #`UDLY ~HALF_BLF;     
    else  
        HALF_BLF <= #`UDLY 1'b0;
end

always @(posedge HALF_BLF or negedge rst_del)
begin
    if(!rst_del)
        FOURTH_BLF <= #`UDLY 1'b0;
    else if(m_value == 2'b10 || m_value == 2'b11)   
        FOURTH_BLF <= #`UDLY ~FOURTH_BLF;      //used for miller encoding, subcarrier is 4
    else
        FOURTH_BLF <= #`UDLY 1'b0;
end

always @(posedge FOURTH_BLF or negedge rst_del)
begin
    if(!rst_del)
        EIGHTH_BLF <= #`UDLY 1'b0;
    else if(m_value == 2'b11)          
        EIGHTH_BLF <= #`UDLY ~EIGHTH_BLF;   //used for miller encoding, subcarrier is 8
    else
        EIGHTH_BLF <= #`UDLY 1'b0; 
end

always@(m_value or BLF_clk or HALF_BLF or FOURTH_BLF or EIGHTH_BLF or ocu_en)
begin
    case(m_value)
        2'b00:
            data_clk = BLF_clk & ocu_en;      
        2'b01:
            data_clk = HALF_BLF & ocu_en;
        2'b10:
            data_clk = FOURTH_BLF & ocu_en;
        2'b11:
            data_clk = EIGHTH_BLF & ocu_en;
        default:
            data_clk = 1'b0;
    endcase
end

always@(posedge data_clk or negedge rst_del)  
begin
    if(!rst_del)
        clk_sel <= #`UDLY 1'b0;       //clk_pro = clk_sel?data_clk:DOUB_BLF
    else if(bsc == `BACK_READ || bsc == `BACK_UAC)         
        clk_sel <= #`UDLY 1'b1;
    else
        clk_sel <= #`UDLY 1'b0;
end

// *************************************************
// define counter
// *************************************************

//mlr_pilot_cnt:
always@(posedge data_clk or negedge rst_del)
begin
    if(!rst_del)
        mlr_pilot_cnt <= #`UDLY 3'b0;             
    else if(bs_cur_state == BS_PILOT_MILLER) 
        mlr_pilot_cnt <= #`UDLY mlr_pilot_cnt + 1'b1;
    else
        mlr_pilot_cnt <= #`UDLY mlr_pilot_cnt;
end 

always@(posedge data_clk or negedge rst_del)
begin
    if(!rst_del)                              
        send_cnt <= #`UDLY 11'b0;
    else if(bs_cur_state == BS_DATA)
        send_cnt <= #`UDLY send_cnt + 1'b1;
    else
        send_cnt <= #`UDLY send_cnt;
end 

always@(posedge data_clk or negedge rst_del)
begin
    if(!rst_del)                              
        pilot_cnt <= #`UDLY 4'b0;
    else if(bs_cur_state == BS_PILOT)
        pilot_cnt <= #`UDLY pilot_cnt + 1'b1;
    else
        pilot_cnt <= #`UDLY pilot_cnt;
end 

// ********************************************************
// prepare the data to be backscattered
// ********************************************************

//Prepare the operate status if an error has occurred.
always @(bsc or lock_temp_err or addr_rw_err or addr_over or pc_err or addr_lock or lk_vee_err or kill_tag or wr_vee_err or tid_tag)
begin         
    case(bsc)
	  `NO_AUTHORITY,
	  `NO_AUTHORITY_P:
        oper_status = 8'b1000_0001;        //the cmd access the unauthorized region
	  `LOCK_EVENT:
	      if(lk_vee_err)
	          oper_status = 8'b1000_0011;
	      else if(lock_temp_err)
		        oper_status = 8'b1000_0001;
		    else
		        oper_status = 8'b0000_0000;
		`KILL_EVENT:
		    if(kill_tag)
		        oper_status = 8'b0000_0000;
		    else
		        oper_status = 8'b1000_0011;
    `BACK_WRITE:
        if(wr_vee_err)
            oper_status = 8'b1000_0011;
	      else if(addr_rw_err)
		        oper_status = 8'b1000_0001;
		    else if(addr_over|pc_err)
		        oper_status = 8'b1000_0010;    //the address is overflowed
		    else if(addr_lock)
		        oper_status = 8'b1000_0101;    //the address has been locked,shouldn't be read or write
		    else
		        oper_status = 8'b0000_0000;
	  `BACK_READ,
	  `BACK_ERASE:
	      if(wr_vee_err)
	          oper_status = 8'b1000_0011;
	      else if(addr_rw_err)
		        oper_status = 8'b1000_0001;
		    else if(addr_over)
		        oper_status = 8'b1000_0010;
		    else if(addr_lock)
		        oper_status = 8'b1000_0101;
		    else
		        oper_status = 8'b0000_0000;
    `BACK_ACC_PWD_ERR:
	      oper_status = 8'b1000_0110;
	  `BACK_TID_WR:
	      if(wr_vee_err)
	          oper_status = 8'b1000_0011;
	      else if(addr_over)
	          oper_status = 8'b1000_0010;
	      else
	          oper_status = 8'b0000_0000;
	  `BACK_TID_DO:
	      if(tid_tag)
	          oper_status = 8'b0000_0000;
	      else
	          oper_status = 8'b1000_0011;
	  default:
	      oper_status = 8'b0000_0000;       //the operation is successful
	  endcase
end

//judge whether the data to be back scattered need the pilot 0
assign use_pilot = (TRext||bsc==`BACK_WRITE||bsc==`BACK_ERASE||bsc==`LOCK_EVENT||bsc==`KILL_EVENT||bsc==`NO_AUTHORITY_P||bsc==`BACK_TID_WR||bsc==`BACK_TID_DO);

//Tell the type of data to be back-scattered
always @(posedge data_clk or negedge rst_n)     
begin: BS_STAT_TRAN
    if(!rst_n)
	      bs_cur_state <= #`UDLY BS_READY;
  	else	
        bs_cur_state <= #`UDLY bs_nxt_state;
end

always @(bs_cur_state or ocu_cur_state or send_done or use_pilot or m_value or mlr_pilot_cnt or 
         pilot_done or head_done or data_done or crc_done)
begin: BS_NXT_CAL
    case(bs_cur_state)
	  BS_READY:
	      if((ocu_cur_state == SEND_DATA) && send_done== 1'b0)  
            if(use_pilot)
			          if(m_value == 2'b00)
				            bs_nxt_state = BS_PILOT;
			          else
				            bs_nxt_state = BS_PILOT_MILLER;
			      else
			          if(m_value == 2'b00)
			              bs_nxt_state = BS_HEAD;
				        else
				            bs_nxt_state = BS_PILOT_MILLER;
		    else
		        bs_nxt_state = BS_READY;
    BS_PILOT_MILLER:
		    if(mlr_pilot_cnt == 3'b011)
		        if(use_pilot)    
                bs_nxt_state = BS_PILOT;
            else
                bs_nxt_state = BS_HEAD;
        else
            bs_nxt_state = bs_cur_state;
	  BS_PILOT:
        if(pilot_done)
            bs_nxt_state = BS_HEAD;
        else
            bs_nxt_state = bs_cur_state;
    BS_HEAD:
        if(head_done)       
            bs_nxt_state = BS_DATA;
        else
            bs_nxt_state = bs_cur_state;
    BS_DATA:
        if(data_done)
            bs_nxt_state = BS_CRC;
        else
            bs_nxt_state = bs_cur_state;
    BS_CRC:
        if(crc_done)          
            bs_nxt_state = BS_DUM;
        else
            bs_nxt_state = bs_cur_state;
    BS_DUM:  
        bs_nxt_state = BS_READY;
    default:
        bs_nxt_state = bs_cur_state;
	endcase
end

//generate the bs_buf
always@(posedge data_clk or negedge rst_del)
begin
    if(!rst_del) 
        bs_buf <= #`UDLY 32'b0;
    else if(bsc == `BACK_UAC)
        if(word_done == 1'b1 && uac_valid == 1'b0)
			      bs_buf <= #`UDLY {2'b00,uac_len,mtp_data[7:0],14'b0};  
        else if((send_cnt - 11'd1) % 5'd16 == 1'b0 && (send_cnt > 11'd16))
            bs_buf <= #`UDLY {mtp_data,16'b0};
        else if(bs_cur_state == BS_DATA)
            bs_buf <= #`UDLY {bs_buf[30:0], 1'b0};
        else 
            bs_buf <= #`UDLY bs_buf;
    else if(bsc == `BACK_READ )
        if(addr_over == 1'b0 && addr_rw_err == 1'b0 && addr_lock == 1'b0)
            if((send_cnt - 11'd7) % 5'd16 == 1'b0 && (send_cnt < 11'd7 + bit_len))
                bs_buf <= #`UDLY {mtp_data, 16'b0};
            else if(send_cnt == 11'd7 + bit_len)      //head(8bit) + operation state(8bit) + bit_len 
                bs_buf <= #`UDLY {handle[15:5], crc5_back, 16'b0};
            else if(bs_cur_state == BS_DATA)
                bs_buf <= #`UDLY {bs_buf[30:0], 1'b0};
            else
                bs_buf <= #`UDLY bs_buf; 
        else if(bs_cur_state == BS_HEAD)
            bs_buf <= #`UDLY {oper_status, handle[15:5], crc5_back, 8'b0};
        else if(bs_cur_state == BS_DATA)  
            bs_buf <= #`UDLY {bs_buf[30:0], 1'b0};
        else
            bs_buf <= #`UDLY bs_buf;
	  else if(bsc == `BACK_WRITE  || bsc == `BACK_ERASE  || bsc == `LOCK_EVENT || bsc == `KILL_EVENT || bsc == `NO_AUTHORITY_P ||
		        bsc == `NO_AUTHORITY|| bsc == `BACK_ACC_PWD_ERR|| bsc == `BACK_CHECK_RESULT)
	      if(bs_cur_state == BS_HEAD)
	          bs_buf <= #`UDLY {oper_status, handle[15:5], crc5_back, 8'b0};
	      else if(bs_nxt_state == BS_DATA)
	          bs_buf <= #`UDLY {bs_buf[30:0], 1'b0};
	      else
	          bs_buf <= #`UDLY bs_buf;
		else if(bsc == `BACK_HANDLE)
        if(bs_cur_state == BS_HEAD)
            bs_buf <= #`UDLY {handle[15:5], crc5_back, 16'b0};
	      else if(bs_nxt_state == BS_DATA)
	          bs_buf <= #`UDLY {bs_buf[30:0], 1'b0};
	      else
	          bs_buf <= #`UDLY bs_buf;
		else if(bsc == `BACK_RN11_CRC5)
        if(bs_cur_state == BS_HEAD)    
            bs_buf <= #`UDLY {rn16, handle[15:5], crc5_back};
	      else if(bs_nxt_state == BS_DATA)
	          bs_buf <= #`UDLY {bs_buf[30:0], 1'b0};
	      else
	          bs_buf <= #`UDLY bs_buf;   
	  else if(bsc == `BACK_TID_WR||bsc == `BACK_TID_DO)
	      if(bs_cur_state == BS_HEAD)
	          bs_buf <= #`UDLY {oper_status, 24'b0};
	      else if(bs_nxt_state == BS_DATA)
	          bs_buf <= #`UDLY {bs_buf[30:0], 1'b0};
	      else
	          bs_buf <= #`UDLY bs_buf;
    else 
        bs_buf <= #`UDLY bs_buf;
end

//****************************************************************************************//revised in 12/16.pan
//bit generated for coding
always@(bs_cur_state or head[7] or bs_buf[31] or crc[15] or calc_crc5)     //error in FPGA
begin
    if(bs_cur_state == BS_HEAD)
        bit = head[7];
    else if(bs_cur_state == BS_DATA)
        bit = bs_buf[31];
    else if(bs_cur_state == BS_CRC)
        if(calc_crc5 == 1'b1)
            bit = crc[15];
        else
            bit = ~crc[15];
    else if(bs_cur_state == BS_DUM)
        bit = 1'b1;
    else
        bit = 1'b0;
end

// always@(posedge data_clk or negedge rst_del)      //这是改后的
// begin
    // if(!rst_del)
        // bit <= #`UDLY 1'b0;
    // else if(bs_cur_state == BS_READY && bs_nxt_state == BS_HEAD && m_value == 2'b00)
        // bit <= #`UDLY 1'b1;
    // else if(bs_cur_state == BS_HEAD && m_value == 2'b00)
        // if(pilot_flag == 1'b0)
            // bit <= #`UDLY head[6];
        // else
            // bit <= #`UDLY head[7]; 
    // else if(bs_cur_state == BS_HEAD && m_value != 2'b00)
        // bit <= #`UDLY head[7];
    // else if(bs_cur_state == BS_DATA)
        // bit <= #`UDLY bs_buf[31];
    // else if(bs_cur_state == BS_CRC)
        // if(calc_crc5 == 1'b1)
            // bit <= #`UDLY crc[15];
        // else
            // bit <= #`UDLY ~crc[15];
    // else if(bs_cur_state == BS_DUM)
        // bit <= #`UDLY 1'b1;
    // else
        // bit <= #`UDLY 1'b0;
// end 
//****************************************************************************************//

//uac_valid: after reading uac_len, the uac_valid is set to high; when uac_valid == 1'b0,
//indicate the reading data is uac_len, when the uac_valid == 1'b1, the reading data is uac_value
always@(negedge word_done or negedge rst_del)
begin
    if(!rst_del)
        uac_valid <= #`UDLY 1'b0;
    else if(bsc == `BACK_UAC)
        uac_valid <= #`UDLY 1'b1;
    else
        uac_valid <= #`UDLY 1'b0;
end 

always@(length2mem)
begin
    bit_len = {length2mem,4'b0000};
end 

//head:
always @(m_value)
begin
    if(m_value == 2'b00)
        head_int = 8'b1110_0001;
    else
        head_int = 8'b0011_1101;
end 

assign head_rst = rst_n & ~dec_done6;
//assign head_clk = data_clk & (bs_cur_state == BS_HEAD);
assign head_clk = data_clk & head_en;

always@(posedge data_clk or negedge rst_n)
begin
    if(!rst_n)
        head_en <= #`UDLY 1'b0;
    else if(bs_cur_state == BS_HEAD)
        head_en <= #`UDLY 1'b1;
    else
        head_en <= #`UDLY 1'b0;
end

always@(posedge head_clk or negedge head_rst)
begin
    if(!head_rst)
        head <= #`UDLY head_int;
    else
        head <= #`UDLY {head[6:0], 1'b0};
end

//head_done generation:
always@(posedge data_clk or negedge rst_del)
begin
    if(!rst_del)
        head_done <= #`UDLY 1'b0;
    else if(bs_cur_state == BS_HEAD)
            if(head==8'b0100_0000)
                head_done <= #`UDLY 1'b1;
            else
                head_done <= #`UDLY 1'b0;
    else 
        head_done <= #`UDLY 1'b0;
end 

//send_done generation:
always@(posedge data_clk or negedge rst_del)
begin
    if(!rst_del)
        send_done <= #`UDLY 1'b0;
    else if(data_done == 1'b1)
        send_done <= #`UDLY 1'b1;
    else
        send_done <= #`UDLY send_done;
end 
 
always@(posedge data_clk or negedge rst_del)
begin
    if(!rst_del)
        crc5_get <= #`UDLY 1'b0;
    else if(data_done == 1'b1)
        crc5_get <= #`UDLY 1'b1;
    else
        crc5_get <= #`UDLY 1'b0;
end 
 
//pilot_done 
always@(posedge data_clk or negedge rst_del)
begin
    if(!rst_del)
        pilot_done <= #`UDLY 1'b0;
    else
        if(pilot_cnt == 4'd10)
            pilot_done <= #`UDLY 1'b1;
        else
            pilot_done <= #`UDLY 1'b0;      
end 
 
//data_done generation:
always@(posedge data_clk or negedge rst_n)
begin
    if(!rst_n)
        data_done <= #`UDLY 1'b0;
    else 
        case(bsc)
        `BACK_TID_DO,
        `BACK_TID_WR: //operation state(8bit)
            if(send_cnt == 11'd6)
                data_done <= #`UDLY 1'b1;
            else
                data_done <= #`UDLY 1'b0; 
        `BACK_HANDLE: //pilot(12bit) + head(8bit) + rn11(11bit)                
            if(send_cnt == 11'd9)
                data_done <= #`UDLY 1'b1;
            else
                data_done <= #`UDLY 1'b0; 
        `BACK_RN11_CRC5: //pilot(12bit) + head(8bit) + rn16(16bit) + handle(16bit), respond to `GET_RN
            if(send_cnt == 11'd30)
                data_done <= #`UDLY 1'b1;
            else
                data_done <= #`UDLY 1'b0;    
        `BACK_UAC:  //pilot(12bit) + head(8bit) + sec_mode(2bit) + uac_contents(bit_len) + crc16(16bit)
            if(send_cnt == bit_len)
                data_done <= #`UDLY 1'b1;
            else
                data_done <= #`UDLY 1'b0;
        `BACK_WRITE,
        `BACK_ERASE,
        `LOCK_EVENT,
        `KILL_EVENT,
	      `NO_AUTHORITY, 
	      `NO_AUTHORITY_P,
	      `BACK_ACC_PWD_ERR,
        `BACK_CHECK_RESULT:
            if(send_cnt == 11'd22) //pilot(12bit) + head(8bit) + operation state(8bit) + handle(16bit)
                data_done <= #`UDLY 1'b1;
            else
                data_done <= #`UDLY 1'b0;                                  
        `BACK_READ:
			      if(addr_over == 1'b0 && addr_rw_err == 1'b0 && addr_lock == 1'b0)
                if(send_cnt == 11'd22 + bit_len) //pilot(12bit) + head(8bit) + operation state(8bit) + read contents(bit_len) + handle(16bit)
                    data_done <= #`UDLY 1'b1;
                else
                    data_done <= #`UDLY 1'b0;
			      else
			 	        if(send_cnt == 11'd22) //pilot(12 bit) + head (8 bit) + operation state(8 bit) + handle (16bit)
                    data_done <= #`UDLY 1'b1;
                else
                    data_done <= #`UDLY 1'b0; 
            default:
                data_done <= #`UDLY 1'b0;
        endcase 
end 
 
// ********************************************************
// CRC
// ********************************************************

//crc_done generation:
always@(posedge data_clk or negedge rst_del)
begin
    if(!rst_del)
        crc_done <= #`UDLY 1'b0        ;
    else if(bs_cur_state == BS_CRC)
        if(calc_crc5 == 1'b1)
            if(crc_cnt == 4'd3)
                crc_done <= #`UDLY 1'b1;
            else
                crc_done <= #`UDLY 1'b0;
        else if(calc_crc16 == 1'b1)
            if(crc_cnt == 4'd14)
                crc_done <= #`UDLY 1'b1;
            else
                crc_done <= #`UDLY 1'b0;
        else
            crc_done <= #`UDLY 1'b0    ;
    else
        crc_done <= #`UDLY 1'b0        ;
end 

//crc_cnt:
always@(posedge data_clk or negedge rst_del)
begin
    if(!rst_del)
        crc_cnt <= #`UDLY 4'b0                  ;
    else if(bs_cur_state == BS_CRC)
        if(calc_crc5 == 1'b1)
            if(crc_cnt < 4'd3)
                crc_cnt <= #`UDLY crc_cnt + 1'b1;
            else
                crc_cnt <= #`UDLY crc_cnt       ;
        else 
            if(crc_cnt < 4'd14)
                crc_cnt <= #`UDLY crc_cnt + 1'b1;
            else
                crc_cnt <= #`UDLY crc_cnt       ;
    else
        crc_cnt <= #`UDLY 4'b0                  ;
end 
//calc_crc5 generation:
always@(bsc)
begin
    if(bsc == `BACK_HANDLE)
        calc_crc5 = 1'b1;
    else
        calc_crc5 = 1'b0;
end 

//calc_crc16 generation:
always@(bsc)
begin
    if(bsc != `BACK_HANDLE)
        calc_crc16 = 1'b1;
    else
        calc_crc16 = 1'b0;
end                

assign crc_xor0 = bit^crc[15];
    
assign crc_xor1 = crc_xor0^crc[4];
    
assign crc_xor2 = crc_xor0^crc[11];

assign crc_xor3 = crc_xor0^crc[13];

always@(posedge data_clk or negedge rst_del)
begin
    if(!rst_del)
        crc <= #`UDLY 16'h0000;
    else if(bs_cur_state == BS_HEAD)
        if(calc_crc16 == 1'b1)
            crc <= #`UDLY 16'hFFFF;
        else if(calc_crc5 == 1'b1)
            crc <= #`UDLY {5'b0_1001, 11'b0};    
        else
            crc <= #`UDLY 16'h0;        
    else if(bs_cur_state == BS_DATA)
        if(calc_crc16 == 1'b1)
            crc <= #`UDLY {crc[14:12],crc_xor2,crc[10:5],crc_xor1,crc[3:0],crc_xor0};
        else if(calc_crc5 == 1'b1)
            crc <= #`UDLY {crc[14],crc_xor3,crc[12:11],crc_xor0,crc[10:0]};
        else
            crc <= #`UDLY crc;
    else if(bs_cur_state == BS_CRC)
        crc <= #`UDLY {crc[14:0], 1'b0};
    else
        crc <= #`UDLY crc;
end 

always@(posedge data_clk or negedge rst_n)
begin
	  if(!rst_n)
	      crc5_back <= #`UDLY 5'b0      ;
	  else if(crc5_get)
	      if(calc_crc5)
            crc5_back <= #`UDLY crc[15:11];
        else
            crc5_back <= #`UDLY crc5_back ;
    else
        crc5_back <= #`UDLY crc5_back ;
end

// ********************************************************
// ENCODER
// ********************************************************
always @(negedge enc_clk_sel or negedge rst_n)
begin
    if(!rst_n)
        data_clk_dly1 <= #`UDLY 1'b0;
    else
        data_clk_dly1 <= #`UDLY data_clk;
end

always @(posedge enc_clk_sel or negedge rst_n)
begin
    if(!rst_n)
        data_clk_dly2 <= #`UDLY 1'b0;
    else
        data_clk_dly2 <= #`UDLY data_clk_dly1;
end

always @(negedge enc_clk_sel or negedge rst_n)
begin
    if(!rst_n)
        data_clk_dly3 <= #`UDLY 1'b0;
    else
        data_clk_dly3 <= #`UDLY data_clk_dly2;
end

assign sos_pulse=data_clk_dly1&~data_clk_dly3;                                //Denotes the mid-point of a symbol.
    
assign mos_pulse=~data_clk_dly1&data_clk_dly3;                                //Denotes the start of a symbol.

//dummy generation:
always@(posedge data_clk or negedge rst_del)
begin
    if(!rst_del)
        dummy <= #`UDLY 1'b0;
    else if(bs_cur_state == BS_DUM)
        dummy <= #`UDLY 1'b1;
    else
        dummy <= #`UDLY 1'b0;
end  

always@(posedge data_clk or negedge rst_del)
begin
    if(!rst_del)
        dummy_delay <= #`UDLY 1'b0;
    else if(dummy == 1'b1)
        dummy_delay <= #`UDLY 1'b1;
    else
        dummy_delay <= #`UDLY dummy_delay;
end

always @(posedge data_clk or negedge rst_n)   
begin : TRANSF_V
    if(!rst_n)
        phase_v1 <= #`UDLY 1'b0;
    else if(m_value==2'b00)
            if(head==8'b0000_1000||head==8'b0100_0000)
                phase_v1 <= #`UDLY 1'b1;
            else
                phase_v1 <= #`UDLY 1'b0;
    else
        phase_v1 <= #`UDLY 1'b0;        
end

//Prepare enc_state
always @(posedge data_clk or negedge rst_del)
begin
    if(!rst_del)
        enc_state<=#`UDLY ENC_RDY;
    else if(bs_cur_state != BS_READY)
        if(dummy)
            enc_state<=#`UDLY ENC_RDY;
        else
            case(enc_state)
            ENC_RDY:
                if(bit)
                    enc_state<=#`UDLY POS_ONE;
                else
                    enc_state<=#`UDLY POS_ZERO;
            POS_ZERO:
                if(bit)
                    if(phase_v1)
                        enc_state<=#`UDLY NEG_ONE;
                    else
                        enc_state<=#`UDLY POS_ONE;
                else if(data_go==1'b0||(m_value==2'b00&&phase_v1 == 1'b0))
                    enc_state<=#`UDLY POS_ZERO;
                else
                    enc_state<=#`UDLY NEG_ZERO;
            POS_ONE:
                if(bit)
                    enc_state<=#`UDLY NEG_ONE;
                else
                    enc_state<=#`UDLY NEG_ZERO;
            NEG_ZERO:
                if(bit)
                    enc_state<=#`UDLY NEG_ONE;
                else if(m_value==2'b00&&phase_v1 == 1'b0)
                    enc_state<=#`UDLY NEG_ZERO;
                else
                    enc_state<=#`UDLY POS_ZERO;
            NEG_ONE:
                if(bit)
                    enc_state<=#`UDLY POS_ONE;
                else
                    enc_state<=#`UDLY POS_ZERO;
            default:
                enc_state<=#`UDLY ENC_RDY;
            endcase
    else
        enc_state<=#`UDLY ENC_RDY;
end

always @(posedge enc_clk_sel or negedge rst_del)   
begin
    if(!rst_del)
        dout<=#`UDLY 1'b0;
    else if(enc_state==ENC_RDY)
        dout<=#`UDLY 1'b0;
    else if(sos_pulse)         
        case(enc_state)
        POS_ZERO,
        POS_ONE:
            dout<=#`UDLY 1'b1;
        default:
            dout<=#`UDLY 1'b0;
        endcase
    else if(mos_pulse)
        if(m_value==2'b00)
            case(enc_state)            
            POS_ONE,
            NEG_ZERO:
                dout<=#`UDLY 1'b1;
            default:
                dout<=#`UDLY 1'b0;
            endcase
        else          
            case(enc_state)               
            POS_ZERO,
            NEG_ONE:
                dout<=#`UDLY 1'b1;
            default:
                dout<=#`UDLY 1'b0;
            endcase
    else
        dout<=#`UDLY ~dout;
end

always @(posedge ocu_clk or negedge rst_del)   
begin : ENC_WORK_EN
    if(!rst_del)
        enc_go <= #`UDLY 1'b0;
    else if(ocu_cur_state == SEND_DATA) 
        enc_go <= #`UDLY 1'b1;
    else
        enc_go <= #`UDLY 1'b0;    
end

always @(posedge data_clk or negedge rst_del)
begin
    if(!rst_del)
        data_go <= #`UDLY 1'b0;
    else if(m_value!= 2'b00)
        if(bs_cur_state==BS_HEAD)
            data_go<= #`UDLY 1'b1;
        else
            data_go<= #`UDLY data_go;
    else
        data_go <= #`UDLY 1'b0;
end   

//Generate ocu_done, which tell PMU that OCU has finished performing		
always@(ocu_cur_state)
begin
	  if(ocu_cur_state == OCU_END)
	      ocu_done = 1'b1;
	  else
	      ocu_done = 1'b0;
end

// ********************************************************
// T2_JUDGE
// ********************************************************

assign T2_clk_en = ocu_done & T2_judge_en;

assign T2_CLK = DOUB_BLF & T2_clk_en;

always @(posedge T2_CLK or negedge rst_del)
begin
		if(!rst_del)
				half_tpri_cnt <= #`UDLY 7'd0;
		else                     
				half_tpri_cnt <= #`UDLY half_tpri_cnt + 1'b1;	
end

always @(posedge T2_CLK or negedge rst_del)  
begin
		if(!rst_del)
				T2_overstep <= #`UDLY 1'b0;
		else if(half_tpri_cnt == 7'd99) 
				T2_overstep <= #`UDLY 1'b1 ;   
		else
				T2_overstep <= #`UDLY 1'b0 ;
end

endmodule













