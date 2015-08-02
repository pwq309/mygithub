// *******************************************************************
// COPYRIGHT, Xi'an XDU Radio-frequency IC Co.,Ltd 
// All rights reserved.
//
// IP NAME      :  RFID
// File name    :  ocu.v
// Module name  :  OCU
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
`include "./macro.v"
`include "./timescale.v"

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
		       //lock_pwd_status,
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
		       data_clk
		   
		       );

// ************************                     
// DEFINE PARAMETER(s)                          
// ************************

//define parameters for main ocu FSM:
parameter  OCU_RDY         = 4'b0000 ;  // if tag have no data want to backscatter,stay in OCU_RDY.
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
input [ 5:0]   membank         ;
input [ 5:0]   pointer         ;
input [ 5:0]   length          ;
input [ 1:0]   m_value         ;
input [ 7:0]   lock_state      ;
input [ 1:0]   lock_action     ;
//input		       lock_pwd_status ;
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
reg 		       read_pulse      ;
reg   [ 4:0]   crc5_back       ;
reg 		       kill_tag        ;
reg            ocu_done        ;
reg            clk_sel         ;
reg            data_clk        ;

// *************************
// INNER SIGNAL DECLARATION
// *************************
//REG(s)
reg            gate_ctrl       ;
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
reg            pilot_flag      ;
reg            enc_go          ;
reg            BLF_clk         ;
reg            HALF_BLF        ;
reg            FOURTH_BLF      ;
reg            EIGHTH_BLF      ;
//reg   [ 3:0]   ocu_en_cnt      ;
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
reg            phase_v2        ;
reg            phase_v         ;
reg            bs_flag_FM0     ;
reg            FM0_dout        ;
reg            data_go         ;
reg            flag1_pre       ;
reg            flag1_delay     ;
reg            cnt0            ;
reg            data_clk_delay  ;
reg            flag0_pre       ;
reg            flag0_delay     ;
reg            Miller_dout     ;
//reg            enc_done        ;
reg   [6:0]   half_tpri_cnt   ;
reg            bit             ;
reg            bsc_done        ;
reg            T2_clk_en       ;

//WIRE(s)
wire           ocu_clk         ;
wire           rst_del         ;
wire           addr_chk_pulse  ;
wire           wr_clk          ;
wire           enc_clk_sel     ;
wire           mlr_pilot_cnt0  ; 
wire           mlr_pilot_cnt1  ;
wire           mlr_pilot_cnt2  ;
wire           send_cnt0       ;
wire           send_cnt1       ;
wire           send_cnt2       ;
wire           send_cnt3       ;  
wire           send_cnt4       ;
wire           send_cnt5       ;
wire           send_cnt6       ;
wire           send_cnt7       ;
wire           send_cnt8       ;
wire           send_cnt9       ;
wire           send_cnt10      ;
wire           use_pilot       ;
//wire           calc_crc        ;
wire           head_clk        ;
wire           head_rst        ;
wire           flag1           ;
wire           flag0           ;
wire           bs_flag_miller  ;
wire           T2_CLK          ;
wire           crc_xor0        ;
wire           crc_xor1        ;
wire           crc_xor2        ;
wire           crc_xor3        ;
wire           lock_init       ;
wire           is_bs_head      ;

// ************************
// MAIN CODE
// ************************

always @(posedge DOUB_BLF or negedge rst_n)
begin
    if(!rst_n)
        gate_ctrl <=#`UDLY 1'b0               ;
    else if(ocu_en)
        gate_ctrl <=#`UDLY 1'b1               ;
    else
        gate_ctrl <=#`UDLY 1'b0               ; 
end

assign ocu_clk = DOUB_BLF & ocu_en & gate_ctrl;

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
always @(bsc or ocu_cur_state or oper_end or addr_over or addr_lock or lock_temp_err or addr_rw_err or pc_err or bsc_done) 
begin
    case(ocu_cur_state)
	  OCU_RDY      :
	      case(bsc)
        `NO_BACK    :
		         ocu_nxt_state = OCU_END          ;
        `BACK_HANDLE       ,
        `BACK_RN11_CRC5    ,
        `BACK_CHECK_RESULT1,
        `BACK_CHECK_RESULT ,
        `NO_AUTHORITY      ,
        `NO_AUTHORITY_P    ,
	    	`BACK_ACC_PWD_ERR  ,
		    `LOCK_ERROR        ,
		    `KILL_ERROR        :
            ocu_nxt_state = PRE_DATA          ; 
        `BACK_UAC   ,  
        `BACK_READ  :
            ocu_nxt_state = READ_MEM          ;
        `BACK_WRITE ,
        `BACK_ERASE :
            ocu_nxt_state = WRITE_CHK         ;
        `KILL_EVENT :
            ocu_nxt_state = KILL_TAG          ;
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
	      if(bsc_done)
		        ocu_nxt_state = OCU_END           ;
		    else	
            ocu_nxt_state = SEND_DATA         ;
	  OCU_END      :
	      ocu_nxt_state = OCU_END               ;
    default      :
        ocu_nxt_state = OCU_RDY               ;
    endcase 
end 

//a level denoting that back-scattering has finished.
always @(posedge ocu_done or negedge rst_del)
begin
    if(!rst_del)
        bsc_done <= #`UDLY 1'b0               ;
    else
        bsc_done <= #`UDLY 1'b1               ;
end

//Generate ocu_done, which tell PMU that OCU has finished performing			
//assign ocu_done = enc_done;
//always @(negedge ocu_clk or negedge rst_del)
//begin
//    if(!rst_del)
//        ocu_done <= #`UDLY 1'b0               ;
//    else if(ocu_done)
//        ocu_done <= #`UDLY 1'b0               ;
//    else if(ocu_cur_state == OCU_END)
//        ocu_done <= #`UDLY 1'b1               ;
//    else
//        ocu_done <= #`UDLY 1'b0               ;
//end
		
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
	    case(membank[5:4])
		2'b00:
            if(lock_bak[1] == 1'b1)       //lock_bak is a backup of lock_state
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
		
//Check if the value of pc to write is valid.
always @(posedge wr_chk_pulse or negedge rst_del)
begin
    if(!rst_del)
        pc_err <= #`UDLY 1'b0;
    else if(membank[5:4] == 2'b01)
        if(pointer == 10'h8)
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
        case(membank[5:4])
        2'b00:                      //TID membank is read_only      
            if(bsc == `BACK_WRITE || bsc == `BACK_ERASE)
                addr_rw_err <= #`UDLY 1'b1; 
            else 
                addr_rw_err <= #`UDLY 1'b0;             
        2'b10:                      //SECURED membank is write_only   
            if(bsc == `BACK_READ)
                addr_rw_err <= #`UDLY 1'b1;
            else if(pointer == 10'd29 || pointer == 10'd30)       
                addr_rw_err <= #`UDLY 1'b1;
            else
                addr_rw_err <= #`UDLY 1'b0;
        default:
            addr_rw_err <= #`UDLY 1'b0;
    endcase 
end 

//lock_temp generation:
always@(bsc or membank or lock_bak or lock_action)
begin
    if(bsc == `LOCK_EVENT)
        case(membank[5:4])
        2'b00:
            begin                                         //if lock region is TID, then assign the value of lock_action to lock_temp[1:0]
                lock_temp[1:0] = lock_action;
                lock_temp[7:2] = lock_bak[7:2];
            end 
        2'b01:
            begin
                lock_temp[1:0] = lock_bak[1:0];
                lock_temp[3:2] = lock_action;
                lock_temp[7:4] = lock_bak[7:4];
            end 
        2'b10:
            begin
                lock_temp[3:0] = lock_bak[3:0];
                lock_temp[5:4] = lock_action;
                lock_temp[7:6] = lock_bak[7:6];
            end 
        2'b11:
            begin
                lock_temp[5:0] = lock_bak[5:0];
                lock_temp[7:6] = lock_action;
            end 
        default:
            lock_temp = 8'b00;
        endcase 
    else
        lock_temp = 8'b00;
end 

always@(bsc or ocu_en or lock_action or membank)
begin
    if(ocu_en == 1'b1)
        if(bsc == `LOCK_EVENT)
            // if(lock_pwd_status == 1'b0)
                // lock_temp_err = 1'b1;
            // else
            case(membank[5:4])
            2'b00:
                if(lock_action[0] == 1'b0)
                    lock_temp_err = 1'b1;
                else
                    lock_temp_err = 1'b0;
            2'b01:
                if(lock_action[1] == 1'b1)
                    lock_temp_err = 1'b1;
                else
                    lock_temp_err = 1'b0;
            2'b10:
                if(lock_action[1] == 1'b0)
                    lock_temp_err = 1'b1;
                else
                    lock_temp_err = 1'b0;
            2'b11:
                lock_temp_err = 1'b0;
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
        lock_flag <= #`UDLY 1'b0;
    else if(bsc == `LOCK_EVENT && ocu_cur_state == WRITE_MEM)
        lock_flag <= #`UDLY 1'b1;
    else
        lock_flag <= #`UDLY lock_flag;
end  

assign lock_init=lock_flag&init_done;

always@(posedge lock_init or negedge rst_n)
begin
    if(!rst_n) 
        lock_bak <= #`UDLY 8'b0;
    else if(init_done == 1'b1)
        lock_bak <= #`UDLY lock_state;
    else 
        lock_bak <= #`UDLY lock_temp;
end 

// judge the tag be killed or not
always @(posedge job_done or negedge rst_n)
begin: KILL_2_PMU
    if(!rst_n)
        kill_tag <= #`UDLY 1'b0;                 
    else if(ocu_en)
        if(kill_tag == 1)
            kill_tag <= #`UDLY kill_tag;
        else if(bsc == `KILL_EVENT)
            kill_tag <= #`UDLY 1'b1;
        else
            kill_tag <= #`UDLY 1'b0;
    else
        kill_tag <= #`UDLY kill_tag;
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
        else if(bsc == `KILL_EVENT)
            wr_data <= #`UDLY 16'hAAAA;                         //16'hAAAA mean the tag has been killed
        else if(bsc == `BACK_WRITE)
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
        `BACK_READ:
            if((send_cnt - 9) % 16 == 0 && pilot_flag == 1'b0)
                read_pulse <= #`UDLY 1'b1;
            else if((send_cnt - 5) % 16 == 0 && send_cnt > 11'd20 && pilot_flag == 1'b1)
                read_pulse <= #`UDLY 1'b1;
            else
                read_pulse <= #`UDLY 1'b0;
        `BACK_UAC:
            if((send_cnt - 1) % 16 == 0 && pilot_flag == 1'b0)        //7.13 revised.Pan
                read_pulse <= #`UDLY 1'b1;
            else if((send_cnt + 3) % 16 == 0 && pilot_flag == 1'b1 && send_cnt > 11'd12)
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
		      pointer2mem <= #`UDLY 6'd29;       //the address of lockstate,in safe region
		  `KILL_EVENT:
		      pointer2mem <= #`UDLY 6'd30;       //the address of killstate,in safe region
	  	`BACK_UAC:
		      pointer2mem <= #`UDLY 6'd8;
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
        `LOCK_EVENT:                             
		        length2mem <= #`UDLY 6'd1;      
		    `KILL_EVENT:
		        length2mem <= #`UDLY 6'd1;      
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
        clk_sel <= #`UDLY 1'b0;       //clk_pro  =clk_sel?data_clk:DOUB_BLF
    else if(bsc == `BACK_READ || bsc == `BACK_UAC)         
        clk_sel <= #`UDLY 1'b1;
    else
        clk_sel <= #`UDLY 1'b0;
end

// *************************************************
// define counter
// *************************************************

//always @(posedge ocu_clk or negedge rst_del)  
//begin
//    if(!rst_del)
//        ocu_en_cnt <= #`UDLY 4'd0;
//    else if(ocu_en_cnt<4'd8)                 
//        ocu_en_cnt <= #`UDLY ocu_en_cnt +1'b1;
//    else
//        ocu_en_cnt <= #`UDLY ocu_en_cnt;        
//end

//mlr_pilot_cnt:
always@(posedge data_clk or negedge rst_del)
begin
    if(!rst_del)
        mlr_pilot_cnt[0] <= #`UDLY 1'b0;             
    else if(bs_cur_state == BS_PILOT_MILLER) 
        mlr_pilot_cnt[0] <= #`UDLY ~mlr_pilot_cnt[0];
    else
        mlr_pilot_cnt[0] <= #`UDLY mlr_pilot_cnt[0];
end 

assign mlr_pilot_cnt0 = mlr_pilot_cnt[0];

always@(negedge mlr_pilot_cnt0 or negedge rst_del)
begin
    if(!rst_del)
        mlr_pilot_cnt[1] <= #`UDLY 1'b0;
    else
        mlr_pilot_cnt[1] <= #`UDLY ~mlr_pilot_cnt[1];
end 

assign mlr_pilot_cnt1 = mlr_pilot_cnt[1];

always@(negedge mlr_pilot_cnt1 or negedge rst_del)
begin
    if(!rst_del)
        mlr_pilot_cnt[2] <= #`UDLY 1'b0;
    else
        mlr_pilot_cnt[2] <= #`UDLY ~mlr_pilot_cnt[2];
end 

assign mlr_pilot_cnt2 = mlr_pilot_cnt[2];

always@(posedge data_clk or negedge rst_del)
begin
    if(!rst_del)                              
        send_cnt[0] <= #`UDLY 1'b0;
    else if(bs_cur_state != BS_PILOT_MILLER && bs_nxt_state != BS_PILOT_MILLER)
        send_cnt[0] <= #`UDLY ~send_cnt[0];
    else
        send_cnt[0] <= #`UDLY send_cnt[0];
end 

assign send_cnt0 = send_cnt[0];

always@(negedge send_cnt0 or negedge rst_del)     
begin
    if(!rst_del)
        send_cnt[1] <= #`UDLY 1'b0;
    else
        send_cnt[1] <= #`UDLY ~send_cnt[1];
end 

assign send_cnt1 = send_cnt[1];

always@(negedge send_cnt1 or negedge rst_del)
begin
    if(!rst_del)
        send_cnt[2] <= #`UDLY 1'b0;
    else
        send_cnt[2] <= #`UDLY ~send_cnt[2];
end 

assign send_cnt2 = send_cnt[2];
                                    
always@(negedge send_cnt2 or negedge rst_del)
begin
    if(!rst_del)
        send_cnt[3] <= #`UDLY 1'b0;
    else
        send_cnt[3] <= #`UDLY ~send_cnt[3];
end 

assign send_cnt3 = send_cnt[3];  

always@(negedge send_cnt3 or negedge rst_del)
begin
    if(!rst_del)
        send_cnt[4] <= #`UDLY 1'b0;
    else
        send_cnt[4] <= #`UDLY ~send_cnt[4];
end 

assign send_cnt4 = send_cnt[4];     

always@(negedge send_cnt4 or negedge rst_del)
begin
    if(!rst_del)
        send_cnt[5] <= #`UDLY 1'b0;
    else
        send_cnt[5] <= #`UDLY ~send_cnt[5];
end 

assign send_cnt5 = send_cnt[5];  

always@(negedge send_cnt5 or negedge rst_del)
begin
    if(!rst_del)
        send_cnt[6] <= #`UDLY 1'b0;
    else
        send_cnt[6] <= #`UDLY ~send_cnt[6];
end 

assign send_cnt6 = send_cnt[6];     

always@(negedge send_cnt6 or negedge rst_del)
begin
    if(!rst_del)
        send_cnt[7] <= #`UDLY 1'b0;
    else
        send_cnt[7] <= #`UDLY ~send_cnt[7];
end 

assign send_cnt7 = send_cnt[7]; 

always@(negedge send_cnt7 or negedge rst_del)
begin
    if(!rst_del)
        send_cnt[8] <= #`UDLY 1'b0;
    else
        send_cnt[8] <= #`UDLY ~send_cnt[8];
end 

assign send_cnt8 = send_cnt[8]; 

always@(negedge send_cnt8 or negedge rst_del)
begin
    if(!rst_del)
        send_cnt[9] <= #`UDLY 1'b0;
    else
        send_cnt[9] <= #`UDLY ~send_cnt[9];
end 

assign send_cnt9 = send_cnt[9]; 

always@(negedge send_cnt9 or negedge rst_del)
begin
    if(!rst_del)
        send_cnt[10] <= #`UDLY 1'b0;
    else
        send_cnt[10] <= #`UDLY ~send_cnt[10];
end 

assign send_cnt10 = send_cnt[10]; 

// ********************************************************
// prepare the data to be backscattered
// ********************************************************

//Prepare the operate status if an error has occurred.
always @(bsc or lock_temp_err or addr_rw_err or addr_over or pc_err or addr_lock)
begin         
    case(bsc)
	  `NO_AUTHORITY,
	  `NO_AUTHORITY_P,
	  `LOCK_ERROR,
	  `KILL_ERROR:
        oper_status = 8'b1000_0001;        //the cmd access the unauthorized region
	  `LOCK_EVENT:
	      if(lock_temp_err == 1'b1)
		        oper_status = 8'b1000_0001;
		    else
		        oper_status = 8'b0000_0000;
    `BACK_WRITE:
	      if(addr_rw_err)
		        oper_status = 8'b1000_0001;
		    else if(addr_over|pc_err)
		        oper_status = 8'b1000_0010;    //the address is overflowed
		    else if(addr_lock)
		        oper_status = 8'b1000_0101;    //the address has been locked,shouldn't be read or write
		    else
		        oper_status = 8'b0000_0000;
	  `BACK_READ,
	  `BACK_ERASE:
	      if(addr_rw_err)
		        oper_status = 8'b1000_0001;
		    else if(addr_over)
		        oper_status = 8'b1000_0010;
		    else if(addr_lock)
		        oper_status = 8'b1000_0101;
		    else
		        oper_status = 8'b0000_0000;
    `BACK_ACC_PWD_ERR:
	      oper_status = 8'b1000_0110;
	  default:
	      oper_status = 8'b0000_0000;       //the operation is successful
	  endcase
end

//judge whether the data to be back scattered need the pilot 0
assign use_pilot = (TRext||bsc==`BACK_WRITE||bsc==`BACK_ERASE||bsc==`LOCK_EVENT||bsc==`KILL_EVENT||bsc==`KILL_ERROR||bsc==`LOCK_ERROR||bsc==`NO_AUTHORITY_P);

//Tell the type of data to be back-scattered
always @(negedge data_clk or negedge rst_n)         
begin: BS_STAT_TRAN
    if(!rst_n)
	      bs_cur_state <= #`UDLY BS_READY;
  	else	
        bs_cur_state <= #`UDLY bs_nxt_state;
end

always @(bs_cur_state or ocu_cur_state or send_done or use_pilot or m_value or mlr_pilot_cnt or 
         pilot_done or head_done or data_done or crc_done or dummy)
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
	      if(use_pilot)
		        if(mlr_pilot_cnt == 3'b011)     
                bs_nxt_state = BS_PILOT;
            else
                bs_nxt_state = bs_cur_state;
		    else if(mlr_pilot_cnt ==3'b011)    
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
            //if(calc_crc)
                bs_nxt_state = BS_CRC;
            //else
                //bs_nxt_state = BS_DUM;
        else
            bs_nxt_state = bs_cur_state;
    BS_CRC:
        if(crc_done)          
            bs_nxt_state = BS_DUM;
        else
            bs_nxt_state = bs_cur_state;
    BS_DUM:
        if(dummy)       
            bs_nxt_state = BS_READY;
        else
            bs_nxt_state = bs_cur_state;
	default:
	    bs_nxt_state = bs_cur_state;
	endcase
end

//generate the bs_buf
always@(negedge data_clk or negedge rst_n)
begin
    if(!rst_n) 
        bs_buf <= #`UDLY 32'b0;
    else if(bsc == `BACK_UAC)
        if(word_done == 1'b1)
            if(uac_valid == 1'b0)
//			          if(m_value != 2'b00)
//                    bs_buf <= #`UDLY {2'b00,uac_len,mtp_data[7:0],14'b0};   
//				        else
					          bs_buf <= #`UDLY {2'b00,uac_len,mtp_data[7:0],14'b0};   //7.13 revised.Pan
            else
                bs_buf <= #`UDLY {mtp_data,16'b0};
        else if(bs_cur_state == BS_DATA)
            bs_buf <= #`UDLY {bs_buf[30:0], 1'b0};
        else 
            bs_buf <= #`UDLY bs_buf;
    else if((bsc == `BACK_READ) && addr_over == 1'b0 && addr_rw_err == 1'b0 && addr_lock == 1'b0)
        if(word_done == 1'b1)
		        if(m_value!=2'b00)
                bs_buf <= #`UDLY {2'b00,mtp_data, 14'b0};
			      else
			          bs_buf <= #`UDLY {mtp_data, 16'b0};
        else if(send_cnt == 11'd8 && pilot_flag == 1'b0)
            bs_buf <= #`UDLY 32'b0;
        else if(send_cnt == 11'd20 && pilot_flag == 1'b1)
            bs_buf <= #`UDLY 32'b0;
        else if((send_cnt == 11'd16 + bit_len) && pilot_flag == 1'b0)
            bs_buf <= #`UDLY {handle[15:5], crc5_back, 16'b0};
        else if((send_cnt == 11'd28 + bit_len) && pilot_flag == 1'b1)
            bs_buf <= #`UDLY {handle[15:5], crc5_back, 16'b0};
        else if(bs_cur_state == BS_DATA)
            bs_buf <= #`UDLY {bs_buf[30:0], 1'b0};
        else
            bs_buf <= #`UDLY bs_buf;             
    else if(bs_cur_state == BS_HEAD && bs_nxt_state == BS_DATA)
	      if(bsc == `BACK_WRITE || bsc == `BACK_ERASE  || bsc == `LOCK_EVENT      || bsc == `KILL_EVENT        || bsc == `LOCK_ERROR || bsc == `KILL_ERROR || bsc == `NO_AUTHORITY_P ||
		       bsc == `BACK_READ  || bsc == `NO_AUTHORITY|| bsc == `BACK_ACC_PWD_ERR|| bsc == `BACK_CHECK_RESULT1|| bsc == `BACK_CHECK_RESULT)
	          bs_buf <= #`UDLY {oper_status, handle[15:5], crc5_back, 8'b0};
		    else if(bsc == `BACK_HANDLE)
            bs_buf <= #`UDLY {handle[15:5], crc5_back, 16'b0};
		    else if(bsc == `BACK_RN11_CRC5)
            bs_buf <= #`UDLY {rn16, handle[15:5], crc5_back};       
        else
            bs_buf <= #`UDLY bs_buf;            
    else if(bs_cur_state == BS_DATA)
            bs_buf <= #`UDLY {bs_buf[30:0], 1'b0};
    else 
        bs_buf <= #`UDLY bs_buf;
end

//bit generated for coding
always@(posedge data_clk or negedge rst_del)
begin
    if(!rst_del)
        bit <= #`UDLY 1'b0;
    else if(bs_cur_state == BS_READY && bs_nxt_state == BS_HEAD && m_value == 2'b00)
        bit <= #`UDLY 1'b1;
    else if(bs_cur_state == BS_HEAD && m_value == 2'b00)
        if(pilot_flag == 1'b0)
            bit <= #`UDLY head[6];
        else
            bit <= #`UDLY head[7]; 
    else if(bs_cur_state == BS_HEAD && m_value != 2'b00)
        bit <= #`UDLY head[7];
    else if(bs_cur_state == BS_DATA)
//        if(bsc == `BACK_UAC)                            //7.13 revised.Pan
//            if(pilot_flag == 1'b0)
//                if(send_cnt == 11'd8)
//                    bit <= #`UDLY 1'b0;
//                else if(send_cnt == 11'd9)
//                    bit <= #`UDLY 1'b0;
//                else
//                    bit <= #`UDLY bs_buf[31];
//            else if(send_cnt == 11'd20)
//                bit <= #`UDLY 1'b0;
//            else if(send_cnt == 11'd21)
//                bit <= #`UDLY 1'b0;
//            else
//                bit <= #`UDLY bs_buf[31]; 	
//        else 
            bit <= #`UDLY bs_buf[31];
    else if(bs_cur_state == BS_CRC)
        if(calc_crc5 == 1'b1)
            bit <= #`UDLY crc[15];
        else
            bit <= #`UDLY ~crc[15];
    else if(bs_cur_state == BS_DUM)
        bit <= #`UDLY 1'b1;
    else
        bit <= #`UDLY 1'b0;
end 

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
assign is_bs_head=(bs_cur_state == BS_HEAD)?1'b1:1'b0;
assign head_clk = data_clk & is_bs_head;

always@(negedge head_clk or negedge head_rst)
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
        if(pilot_flag == 1'b1 && send_cnt == 11'd19)
            head_done <= #`UDLY 1'b1;
        else if(pilot_flag == 1'b0 && send_cnt == 11'd7)
            head_done <= #`UDLY 1'b1;
        else
            head_done <= #`UDLY 1'b0;            
    else 
        head_done <= #`UDLY 1'b0;
end 

//send_done generation:
always@(negedge data_clk or negedge rst_del)
begin
    if(!rst_del)
        send_done <= #`UDLY 1'b0;
    else if(data_done == 1'b1)
        send_done <= #`UDLY 1'b1;
    else
        send_done <= #`UDLY send_done;
end 
 
//pilot_done 
always@(posedge data_clk or negedge rst_del)
begin
    if(!rst_del)
        pilot_done <= #`UDLY 1'b0;
    else if(pilot_flag == 1'b1 && send_cnt == 11'd11)
        pilot_done <= #`UDLY 1'b1;
    else
        pilot_done <= #`UDLY 1'b0;
end 
 
//pilot_flag generation:
always@(posedge data_clk or negedge rst_del)
begin 
    if(!rst_del)
        pilot_flag <= #`UDLY 1'b0;
    else if(bs_nxt_state == BS_PILOT)
        pilot_flag <= #`UDLY 1'b1;
    else
        pilot_flag <= #`UDLY pilot_flag;
end 
 
//data_done generation:
always@(posedge data_clk or negedge rst_n)
begin
    if(!rst_n)
        data_done <= #`UDLY 1'b0;
    else if(pilot_flag == 1'b1)   
        case(bsc)
        `BACK_HANDLE: //pilot(12bit) + head(8bit) + rn11(11bit)                
            if(send_cnt == 11'd30)
                data_done <= #`UDLY 1'b1;
            else
                data_done <= #`UDLY 1'b0; 
        `BACK_RN11_CRC5: //pilot(12bit) + head(8bit) + rn16(16bit) + handle(16bit), respond to `GET_RN
            if(send_cnt == 11'd51)
                data_done <= #`UDLY 1'b1;
            else
                data_done <= #`UDLY 1'b0;    
        `BACK_UAC:  //pilot(12bit) + head(8bit) + sec_mode(2bit) + uac_contents(bit_len) + crc16(16bit)
            if(send_cnt == 11'd21 + bit_len)
                data_done <= #`UDLY 1'b1;
            else
                data_done <= #`UDLY 1'b0;
        `BACK_WRITE,
        `BACK_ERASE,
        `LOCK_EVENT,
        `LOCK_ERROR,
        `KILL_EVENT,
	      `KILL_ERROR,
	      `NO_AUTHORITY, 
	      `NO_AUTHORITY_P,
	      `BACK_ACC_PWD_ERR,
        `BACK_CHECK_RESULT1,
        `BACK_CHECK_RESULT:
            if(send_cnt == 11'd43) //pilot(12bit) + head(8bit) + operation state(8bit) + handle(16bit)
                data_done <= #`UDLY 1'b1;
            else
                data_done <= #`UDLY 1'b0;                                  
        `BACK_READ:
			      if(addr_over == 1'b0 && addr_rw_err == 1'b0 && addr_lock == 1'b0)
                if(send_cnt == 11'd43 + bit_len) //pilot(12bit) + head(8bit) + operation state(8bit) + read contents(bit_len) + handle(16bit)
                    data_done <= #`UDLY 1'b1;
                else
                    data_done <= #`UDLY 1'b0;
			      else
			 	        if(send_cnt == 11'd43) //pilot(12 bit) + head (8 bit) + operation state(8 bit) + handle (16bit)
                    data_done <= #`UDLY 1'b1;
                else
                    data_done <= #`UDLY 1'b0; 
            default:
                data_done <= #`UDLY 1'b0;
        endcase 
    else //if(pilot_flag == 1'b0)
        case(bsc)
        `BACK_HANDLE:
            if(send_cnt == 11'd18)
                data_done <= #`UDLY 1'b1;
            else
                data_done <= #`UDLY 1'b0;
        `BACK_RN11_CRC5: //head(8bit) + rn16(16bit) + handle(16bit)
            if(send_cnt == 11'd39)
                data_done <= #`UDLY 1'b1;
            else
                data_done <= #`UDLY 1'b0;                         
        `BACK_UAC:
            if(send_cnt == 11'd9 + bit_len)
                data_done <= #`UDLY 1'b1;
            else
                data_done <= #`UDLY 1'b0;
        `BACK_WRITE,       //head(8bit) + operation state(8bit) + handle(16bit)
        `BACK_ERASE,
        `LOCK_EVENT,
        `LOCK_ERROR,
        `KILL_EVENT,
	      `KILL_ERROR,
	      `NO_AUTHORITY,
	      `NO_AUTHORITY_P, 
	      `BACK_ACC_PWD_ERR,
        `BACK_CHECK_RESULT1,
        `BACK_CHECK_RESULT:
            if(send_cnt == 11'd31)
                data_done <= #`UDLY 1'b1;
            else
                data_done <= #`UDLY 1'b0;
        `BACK_READ:
			      if(addr_over == 1'b0 && addr_rw_err == 1'b0 && addr_lock == 1'b0)
                if(send_cnt == 11'd31 + bit_len)
                    data_done <= #`UDLY 1'b1;
                else
                    data_done <= #`UDLY 1'b0;
	          else
				        if(send_cnt == 11'd31) //head(8bit) + operation state(8bit) + handle(16bit)
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
            if(crc_cnt == 4'd4)
                crc_done <= #`UDLY 1'b1;
            else
                crc_done <= #`UDLY 1'b0;
        else if(calc_crc16 == 1'b1)
            if(crc_cnt == 4'd15)
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
            if(crc_cnt < 4'd4)
                crc_cnt <= #`UDLY crc_cnt + 1'b1;
            else
                crc_cnt <= #`UDLY crc_cnt       ;
        else 
            if(crc_cnt < 4'd15)
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

//assign calc_crc = calc_crc5 | calc_crc16;

//always@(negedge data_clk or negedge rst_del)
//begin
//    if(!rst_del)
//        crc <= #`UDLY 16'h0000;
//    else if(bs_cur_state == BS_HEAD)
//        if(calc_crc16 == 1'b1)
//            crc <= #`UDLY 16'hFFFF;
//        else if(calc_crc5 == 1'b1)
//            crc <= #`UDLY {5'b0_1001, 11'b0};    
//        else
//            crc <= #`UDLY 16'h0;        
//    else if(bs_cur_state == BS_DATA)
//        if(calc_crc16 == 1'b1)
//            begin
//                crc[0]     <= #`UDLY bit ^ crc[15];
//                crc[4:1]   <= #`UDLY crc[3:0];
//                crc[5]     <= #`UDLY bit ^ crc[15] ^ crc[4];
//                crc[11:6]  <= #`UDLY crc[10:5];
//                crc[12]    <= #`UDLY bit ^ crc[15] ^ crc[11];
//                crc[15:13] <= #`UDLY crc[14:12]; 
//            end 
//        else if(calc_crc5 == 1'b1)
//            begin
//                crc[11]    <= #`UDLY bit ^ crc[15];
//                crc[13:12]  <= #`UDLY crc[12:11];
//                crc[14]    <= #`UDLY bit ^ crc[15] ^ crc[13];
//                crc[15]    <= #`UDLY crc[14];
//                crc[10:0] <= #`UDLY crc[10:0];
//            end    
//        else
//            crc <= #`UDLY crc;
//    else if(bs_cur_state == BS_CRC)
//        crc <= #`UDLY {crc[14:0], 1'b0};
//    else
//        crc <= #`UDLY crc;
//end                   

assign crc_xor0 = bit^crc[15];
    
assign crc_xor1 = crc_xor0^crc[4];
    
assign crc_xor2 = crc_xor0^crc[11];

assign crc_xor3 = crc_xor0^crc[13];

always@(negedge data_clk or negedge rst_del)
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

always@(negedge data_done or negedge rst_n)
begin
	  if(!rst_n)
	      crc5_back <= #`UDLY 5'b0      ;
    else if(calc_crc5 == 1'b1)
        crc5_back <= #`UDLY crc[15:11];
    else
        crc5_back <= #`UDLY crc5_back ; 
end 

// ********************************************************
// ENCODER
// ********************************************************

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

always@(posedge data_clk or negedge rst_del)
begin
    if(!rst_del)
        dout_go_pre <= #`UDLY 1'b0;
    else if(dummy_delay == 1'b1)
        dout_go_pre <= #`UDLY 1'b0;
    else
        dout_go_pre <= #`UDLY 1'b1;
end

always@(negedge ocu_clk or negedge rst_del)
begin
    if(!rst_del)
        dout_go <= #`UDLY 1'b0;
    else if(dummy_delay == 1'b1)
        dout_go <= #`UDLY 1'b0;
    else if(dout_go_pre == 1'b1)
        dout_go <= #`UDLY 1'b1;
    else
        dout_go <= #`UDLY dout_go;
end

always @(negedge data_clk or negedge rst_n)   
begin : TRANSF_V
    if(!rst_n)
        phase_v1 <= #`UDLY 1'b0;
    else if(m_value==2'b00)
        if(pilot_flag) 
            if(send_cnt == 11'd16 || send_cnt == 11'd19)
                phase_v1 <= #`UDLY 1'b1;
            else
                phase_v1 <= #`UDLY 1'b0;
        else
            if(send_cnt == 11'd4 || send_cnt == 11'd7)
                phase_v1 <= #`UDLY 1'b1;
            else
                phase_v1 <= #`UDLY 1'b0;
    else
        phase_v1 <= #`UDLY 1'b0;        
end

always @(posedge data_clk or negedge rst_n)
begin
    if(!rst_n)
        phase_v2 <= #`UDLY 1'b0;
    else
        phase_v2 <= #`UDLY phase_v1;
end

always @(phase_v1 or phase_v2)
begin
    if(phase_v1 == 1'b1 && phase_v2 == 1'b1)  
        phase_v = 1'b1;
    else
        phase_v = 1'b0;
end

always @(negedge ocu_clk or negedge rst_del)   
begin : ENC_WORK_EN
    if(!rst_del)
        enc_go <= #`UDLY 1'b0;
    else if(ocu_cur_state == SEND_DATA /*&& ocu_en_cnt == 4'd8*/) 
        enc_go <= #`UDLY 1'b1;
    else
        enc_go <= #`UDLY 1'b0;    
end

always @(posedge enc_clk_sel or negedge rst_n)
begin
    if(!rst_n)
        bs_flag_FM0 <= #`UDLY 1'b0;           
    else if(m_value==2'b00)
        if(bit)
            bs_flag_FM0 <= #`UDLY ~bs_flag_FM0;
        else
            bs_flag_FM0 <= #`UDLY 1'b0;
    else
        bs_flag_FM0 <= #`UDLY 1'b0;
end

always @(posedge enc_clk_sel or negedge rst_n)   
begin : GEN_FM_OUT
    if(!rst_n)
        FM0_dout <= #`UDLY 1'b0;
    else if(m_value == 2'b00) 
        if(dout_go) 
            if(phase_v == 1'b1)
                FM0_dout <= #`UDLY FM0_dout;
            else if(bs_flag_FM0 == 1'b1)
                FM0_dout <= #`UDLY FM0_dout;
            else
                FM0_dout <= #`UDLY ~FM0_dout;
        else
            FM0_dout <= #`UDLY 1'b0;
    else
        FM0_dout <= #`UDLY 1'b0;
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

always @(negedge data_clk or negedge rst_del)
begin
    if(!rst_del)
        flag1_pre <= #`UDLY 1'b0;
    else if(m_value!=2'b00 && data_go)
        if(bit)
            flag1_pre <= #`UDLY ~flag1_pre;
        else
            flag1_pre <= #`UDLY flag1_pre;
    else
        flag1_pre<= #`UDLY 1'b0;
end

always @(posedge enc_clk_sel or negedge rst_del)
begin
    if(!rst_del)
        flag1_delay <= #`UDLY 1'b0;
    else if(m_value!=2'b00 && data_go)
        flag1_delay <= #`UDLY flag1_pre;
    else  
        flag1_delay <= #`UDLY 1'b0;       
end
    
assign flag1= flag1_pre ^flag1_delay ;

always @(negedge data_clk or negedge rst_del)
begin
    if(!rst_del)
        cnt0 <= #`UDLY 1'b0;
    else if(m_value!=2'b00 && data_go)
        if(bit)
            cnt0 <= #`UDLY 1'b0;
        else 
            cnt0 <= #`UDLY 1'b1;
    else
        cnt0 <= #`UDLY 1'b0;
end             

always @(negedge enc_clk_sel or negedge rst_n)
begin
    if(!rst_n)
        data_clk_delay <= #`UDLY 1'b0;
    else
        data_clk_delay <= #`UDLY data_clk;
end  

always @(posedge data_clk_delay or negedge rst_del)
begin
    if(!rst_del)
        flag0_pre <= #`UDLY 1'b0;
    else if(m_value!=2'b00 && data_go)
        if(cnt0== 1'b1)
            if(bit==1'b0)
                flag0_pre <= #`UDLY ~flag0_pre;
            else
                flag0_pre <= #`UDLY flag0_pre;
        else
            flag0_pre <= #`UDLY flag0_pre;
    else
        flag0_pre<= #`UDLY 1'b0;
end

always @(negedge enc_clk_sel or negedge rst_del)
begin
    if(!rst_del)
        flag0_delay <= #`UDLY 1'b0;
    else if(m_value!=2'b00 && data_go)
        flag0_delay <= #`UDLY flag0_pre;
    else  
        flag0_delay <= #`UDLY 1'b0;       
end
    
assign flag0= flag0_pre ^flag0_delay ;

assign bs_flag_miller = flag0|flag1;

always @(posedge enc_clk_sel or negedge rst_n)
begin
    if(!rst_n)
        Miller_dout <= #`UDLY 1'b0;
    else if(dout_go && m_value!=2'b00)
        if(bs_flag_miller)
            Miller_dout<= #`UDLY Miller_dout;
        else
            Miller_dout<= #`UDLY ~Miller_dout; 
    else 
        Miller_dout <= #`UDLY 1'b0;   
end        

always @(m_value or FM0_dout or Miller_dout)
begin
    if(m_value == 2'b00)
        dout = FM0_dout;
    else
        dout = Miller_dout;
end

always@(negedge data_clk or negedge rst_del)
begin
    if(!rst_del)
        ocu_done <= #`UDLY 1'b0;
    else if(dummy_delay == 1'b1)
        ocu_done <= #`UDLY 1'b1;
    else
        ocu_done <= #`UDLY 1'b0;
end 

// ********************************************************
// T2_JUDGE
// ********************************************************

//always @(negedge T2_overstep or posedge ocu_done or negedge rst_del)
always @(posedge ocu_done or negedge rst_del)
begin
    if(!rst_del)
        T2_clk_en <= #`UDLY 1'b0;
    else if(ocu_done)
        T2_clk_en <= #`UDLY T2_judge_en;
    else
        T2_clk_en <= #`UDLY 1'b0;
end

assign T2_CLK = DOUB_BLF & T2_clk_en;


//always @(posedge T2_CLK or negedge rst_del)  
//begin
//		if(!rst_del)
//				half_tpri_cnt <= #`UDLY 7'd0;
//		else if(T2_judge_en)                       
//		    if(ocu_done)
//				    half_tpri_cnt <= #`UDLY half_tpri_cnt + 1;
//			else
//			    half_tpri_cnt <= #`UDLY 7'd0;
//		else
//		    half_tpri_cnt <= #`UDLY 7'd0;		
//end

always @(posedge T2_CLK or negedge rst_del)
begin
		if(!rst_del)
				half_tpri_cnt <= #`UDLY 7'd0;
		else                     
				half_tpri_cnt <= #`UDLY half_tpri_cnt + 1'b1;	
end

always @(negedge T2_CLK or negedge rst_del)  
begin
		if(!rst_del)
				T2_overstep <= #`UDLY 1'b0;
		else if(half_tpri_cnt == 7'd65) 
				T2_overstep <= #`UDLY 1'b1 ;   
		else
				T2_overstep <= #`UDLY 1'b0 ;
end

endmodule













