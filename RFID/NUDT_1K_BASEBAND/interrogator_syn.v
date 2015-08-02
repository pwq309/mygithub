//`include "./include/macro.v"
//`include "./timescale.v"
`include "D:/xilinx/12.4/xlinx_work/NUDT_1K_BASEBAND/timescale.v"
`include "D:/xilinx/12.4/xlinx_work/NUDT_1K_BASEBAND/macro.v"

module INTERROGATOR_SYN(
                //inputs
                clk_10m,
                rst_n,
                tag_data,
                        
                //outputs
                rd_data
								// led_sort,
								// led_query,
								// led_ack,
								// led_read,
			   			  // led_write,
								// led_done
                );
            
    //parameters
    //states for reader
    parameter RD_RDY   =2'b00;
    parameter PRE_SD   =2'b01;
    parameter DT_SND   =2'b10;
    parameter DT_REC   =2'b11;
    //commands
    parameter CH_NONE  =6'd0;
    parameter QUERYREP =6'd1;
    parameter ACK      =6'd2;    
    parameter QUERY    =6'd3;
    parameter ERASE    =6'd4;
    parameter SORT     =6'd5;    
    parameter NAK      =6'd6;
    parameter GET_RN   =6'd7;
    parameter GET_RN1  =6'd8;
    parameter WRITE    =6'd9;
    parameter WRITE1   =6'd10;
    parameter KILL     =6'd11;
    parameter LOCK     =6'd12;
    parameter CH_END   =6'd13;
    parameter ACCESS   =6'd14;//read code( high 16bits)
    parameter ACCESS1  =6'd15;//read code (low 16bits)
    parameter ACCESS2  =6'd16;//write code (high 16bits)
    parameter ACCESS3  =6'd17;//write code (low 16bits)
    parameter ACCESS4  =6'd18;//lock code (high 16bits)
    parameter ACCESS5  =6'd19;//lock code (low 16bits)
    parameter ACCESS6  =6'd20;//kill code (high 16bits)
    parameter ACCESS7  =6'd21;//kill code (low 16bits)
    parameter HAKL     =6'd22;
    parameter READ1    =6'd23;
    parameter READ2    =6'd24;
    parameter READ3    =6'd25;
   // parameter VERIFY   =5'd20;
    parameter HACS     =6'd26;

  	parameter DIVIDE   =6'd27;
  	parameter DISPERSE =6'd28;
  	parameter SHRINK   =6'd29;
  	
  	parameter TIDWRITE   =6'd30;//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  	parameter TIDWRITE1  =6'd31;//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  	parameter TIDDONE    =6'd32;//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  	parameter GET_RN2    =6'd33;//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    parameter GET_RN3    =6'd34;//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    parameter TIDWRITE2  =6'd35;//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    parameter ACCESS8    =6'd36;//wrong read code (low 16bits)
    parameter ACCESS9    =6'd37;//wrong read code (low 16bits)
    parameter GET_RN4    =6'd38;//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    parameter GET_RN5    =6'd39;//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    parameter READ4      =6'd40;
    //states for tpp encoder
    parameter ENC_RDY  =4'b0000;
    parameter DELIM    =4'b0001;
    parameter TCAL1    =4'b0010;
    parameter TCAL2    =4'b0011;
    parameter DATA00   =4'b0100;
    parameter DATA01   =4'b0101;
    parameter DATA11   =4'b0110;
    parameter DATA10   =4'b0111;
    parameter ENC_END  =4'b1000;
    ////////////////WAIT
    parameter MAX_WT=8'd40;
    ////////////////TARI
    parameter DIV_M=10'd62;//[1.28M]//10'd125;//[1.92M]
    parameter DIV_N=1'b1;
    ////////////////QUERY
    parameter DR=2'b10;//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    parameter m_value=2'b00;
    parameter CONDITION=2'b00;
    //parameter SESSION=2'b00;//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    parameter TARGET_QUERY=1'b0;

    ////////////////SORT
    parameter MASK_PTR   =16'b0000_0000_0010_0000;
	  parameter MASK_LEN   =8'b0010_0000;
    parameter MBANK_SORT =2'b00;//??????????????????/
	  parameter TARGET_SORT=4'b0000;//??????????????????/
  	parameter RULE       =2'b00;
    parameter MASK_VAL   =32'h0514_0514;
    ////////////////READ
    parameter MBANK_RD   =2'b00;
    parameter PTR_RD     =16'd03;
    parameter LEN_RD     =16'd01;
    ////////////////TIDWRITE
	  parameter MBANK_TID_WR   =2'b01;//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    parameter PTR_TID_WR     =16'd06;//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    //parameter LEN_TID_WR     =16'd01;//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    parameter DATA_TID_WR    =16'hcccc;//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ////////////////TIDDONE        //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    
    
    
    ////////////////WRITE
	  parameter MBANK_WR   =6'b01;
    parameter PTR_WR     =16'd06;
    parameter LEN_WR     =16'd01;
    parameter DATA_WR    =16'hcccc;
	  ////////////////ERASE
	  parameter MBANK_ER   =2'b01;
    parameter PTR_ER     =16'd06;
    parameter LEN_ER     =16'd01;

    //parameter handle = 16'b1110_1110_0100_1111;
	 parameter handle = 16'b0111_0111_0011_1001;
	
    //inputs
    input             clk_10m;
    input             rst_n;
    input             tag_data;
    
    //outputs
    output            rd_data;
    
	  // output            led_sort;
    // output            led_query;
    // output            led_ack;
    // output            led_read;
    // output            led_write;
    // output            led_done;
    
    //regs
    reg               rd_data;
    reg      [1:0]    rd_state;
    reg      [1:0]    nx_state;
    ////////////////DIV_FL
    //reg               div_en;        
    ////////////////ENCODER
    reg               tpp_pre_pulse;
    reg               tpp_en;
    reg      [3:0]    enc_state;
    reg      [15:0]   enc_buf;
    reg               data_end;
    reg      [3:0]    st_cnt;
    reg      [3:0]    bit_cnt;
    reg      [3:0]    frm_cnt;
    reg      [3:0]    max_cnt;
    //reg               sos_pulse;
    //reg               sof_pulse;
    //reg               cnt_pulse;
    reg               flg_buf_a;
    reg               flg_buf_b;
    reg               enc_end_ctrl;
    reg               enc_end;    
    ////////////////DECODER
    reg               fm0_en;
    reg               miller_en;
    reg      [1:0]    dec_cnt;
    reg               dec_end;
    ////////////////
    reg      [5:0]    cmd_head;
    //reg      [15:0]   handle;
    reg      [15:0]   rn16;
    reg      [15:0]   rec_buf;
    reg      [7:0]    rec_cnt;
    reg      [15:0]   rec_bit_cnt;
    ////////////////CRC
    reg      [15:0]   CRC16;
//    reg      [4:0]    CRC5;
    reg               crc_en;
    reg      [15:0]   REC_CRC16;
    ////////////////INITIAL
    //reg      [7:0]    init_cnt;
    //reg               init_en;
    //reg               init_done;
    ////////////////WAIT
    reg      [7:0]    wt_cnt;
    reg               wt_en;
    reg               wt_ctrl;
    reg               wt_done;
    
    //wires
    wire              TRext;
    ////////////////DECODER
    wire              fm0_data;
    wire              fm0_clk;
    wire     [7:0]    fm0_bltc;
    wire              fm0_start;
    wire              fm0_done;
    wire              miller_data;
    wire              miller_clk;
    wire     [7:0]    miller_bltc;
    wire              miller_start;
    wire              miller_done;
    ////////          
    wire              dec_start;
    wire              dec_done;
    //wire     [7:0]    bltc;
    wire              dec_data;
    wire              rec_clk;    
    ////////////////ENCODER
    wire              doub_flc;
    wire              enc_clk;
    wire              st_pulse;
    wire              data_pulse;
    wire              bsh_pulse;
    wire     [1:0]    bit_in;
    wire              cnt_rst;
    wire              tpp_done;
    ////////////////INITIAL
    //wire              init_clk;
    ////////////////WAIT
    wire              wt_clk;
    wire              wt_rst;
    ////////////////CRC
    wire              crc_xor0;
    wire              crc_xor1;
    wire              crc_xor2;
    wire              crc_xor3;
    wire              crc_xor4;
    wire              crc_xor5; 
    wire              crc_xor6;
    wire              crc_xor7;
    wire              crc_xor8;
    
	  wire              led_sort;
    wire              led_query;
    wire              led_ack;
    wire              led_read;
    wire              led_write;
    wire              led_done;

    //********************************************************//
	 assign led_sort=(cmd_head==SORT);
	 assign led_query=(cmd_head==QUERY);
	 assign led_ack=(cmd_head==ACK);
	 assign led_read=(cmd_head==READ1||cmd_head==READ2||cmd_head==READ3);
	 assign led_write=(cmd_head==WRITE||cmd_head==WRITE1);
	 assign led_done=(cmd_head==CH_END);
	
    //********************************************************//
    
    DIV_FL U_DIV_FL(
                //inputs
                clk_10m,
                rst_n,
                DIV_M,
                DIV_N,
                1'b1,
                
                //outputs
                doub_flc,
                clk_50k
            );
    
    DECODER_FM0 U_DECODER_FM0(
                //inputs
                clk_10m,
                rst_n,                
                tag_data,
                fm0_en,
                cmd_head,
                
                //outputs
                fm0_data,
                fm0_clk,
                fm0_bltc,
                fm0_start,
                //tag_data_buffer,
                fm0_done
            );
            
    DECODER_MILLIER U_DECODER_MILLIER(
                //inputs
                clk_10m,
                rst_n,
                m_value,             
                tag_data,
                miller_en,
                
                //outputs
                miller_data,
                miller_clk,
                miller_bltc,
                miller_start,
                miller_done
            );
    
    //********************************************************//
            
    assign rd_clk=doub_flc;
    
    always @(posedge rd_clk or negedge rst_n)
    begin
        if(!rst_n)
            rd_state<=#`UDLY RD_RDY;
        else
            rd_state<=#`UDLY nx_state;
    end
    
    always @(enc_end or dec_end or wt_done or rd_state)
    begin
        case(rd_state)
        RD_RDY:
            if(wt_done)
                nx_state=PRE_SD;
            else
                nx_state=RD_RDY;
        PRE_SD:
            nx_state=DT_SND;
        DT_SND:
            if(enc_end)
                nx_state=DT_REC;
            else
                nx_state=DT_SND;
        DT_REC:
            if(dec_end)
                nx_state=PRE_SD;
            else if(wt_done)
                nx_state=PRE_SD;
            else
                nx_state=DT_REC;
        default:
            nx_state=RD_RDY;
        endcase
    end
    
    always @(posedge rd_clk or posedge dec_done or negedge rst_n)
    begin
        if(!rst_n)
            dec_cnt<=#`UDLY 2'd3;
        else if(dec_done)
            dec_cnt<=#`UDLY 2'd0;
        else if(dec_cnt==2'd3)
            dec_cnt<=#`UDLY dec_cnt;
        else
            dec_cnt<=#`UDLY dec_cnt+1'b1;         
    end
    
    always @(negedge rd_clk or negedge rst_n)
    begin
        if(!rst_n)
            dec_end<=#`UDLY 1'b0;
        else if(dec_cnt==2'd2)
            dec_end<=#`UDLY 1'b1;
        else
            dec_end<=#`UDLY 1'b0;
    end
    
    //********************************************************//
    //WAIT
    
    assign wt_rst=rst_n&~tpp_done;
    
    always @(negedge rd_clk or negedge rst_n)
    begin
        if(!rst_n)
            wt_en<=#`UDLY 1'b0;
        else if(rd_state==RD_RDY)
            wt_en<=#`UDLY 1'b1;
        else if(rd_state==DT_REC)
            if(cmd_head==SORT||cmd_head==QUERY||cmd_head==QUERYREP||cmd_head==TIDWRITE2)
                wt_en<=#`UDLY 1'b1;
            else
                wt_en<=#`UDLY 1'b0;
        else
            wt_en<=#`UDLY 1'b0;
    end
    
    always @(posedge dec_start or negedge wt_rst)
    begin
        if(!wt_rst)
            wt_ctrl<=#`UDLY 1'b1;
        else
            wt_ctrl<=#`UDLY 1'b0;
    end
    
    assign wt_clk=clk_50k&wt_en&wt_ctrl;
    
    always @(posedge wt_clk or negedge wt_rst)
    begin
        if(!wt_rst)
            wt_cnt<=#`UDLY 8'd0;
        else
            wt_cnt<=#`UDLY wt_cnt+1'b1;
    end
    
    //Generate a pulse, which denotes waiting overtime.
    always @(negedge wt_clk or negedge wt_rst)
    begin
        if(!wt_rst)
            wt_done<=#`UDLY 1'b0;
        else if(wt_cnt==MAX_WT)
            wt_done<=#`UDLY 1'b1;
        else
            wt_done<=#`UDLY 1'b0;        
    end
    
    //********************************************************//
    
    //a pulse for tpp-treating for tpp encoder.
    always @(negedge rd_clk or negedge rst_n)
    begin
        if(!rst_n)
            tpp_pre_pulse<=#`UDLY 1'b0;
        else if(rd_state==PRE_SD)
            tpp_pre_pulse<=#`UDLY 1'b1;
        else
            tpp_pre_pulse<=#`UDLY 1'b0;
    end
    
    //Prepare the command to be issued.
    always @(posedge tpp_pre_pulse or negedge rst_n)
    begin
        if(!rst_n)
            cmd_head<=#`UDLY CH_NONE;
        else
            case(cmd_head)
            CH_NONE:
               // cmd_head<=#`UDLY TIDWRITE;
           // TIDWRITE:
               // cmd_head<=#`UDLY TIDWRITE1;
           // TIDWRITE1:
               // cmd_head<=#`UDLY TIDDONE; 
          // TIDDONE:
               // cmd_head<=#`UDLY TIDWRITE2;
           // TIDWRITE2:
                cmd_head<=#`UDLY SORT;       
            SORT:
                cmd_head<=#`UDLY QUERY;
            QUERY:
                cmd_head<=#`UDLY ACK;                
            ACK:
                // cmd_head<=#`UDLY GET_RN;           
            // GET_RN:
//                cmd_head<=#`UDLY ACCESS6;
//            ACCESS6:
//                cmd_head<=#`UDLY GET_RN1;
//            GET_RN1:
//                cmd_head<=#`UDLY ACCESS7;
//            ACCESS7:
//                cmd_head<=#`UDLY READ4;
//            READ4:
//                cmd_head<=#`UDLY GET_RN4;
//            GET_RN4:    
                // cmd_head<=#`UDLY ACCESS;
            // ACCESS:
                // cmd_head<=#`UDLY GET_RN5;
            // GET_RN5:
                // cmd_head<=#`UDLY ACCESS1;
            // ACCESS1:
                // cmd_head<=#`UDLY READ1;
            // READ1:
//                cmd_head<=#`UDLY GET_RN2;           
//            GET_RN2:
//                cmd_head<=#`UDLY ACCESS2;
//            ACCESS2:
//                cmd_head<=#`UDLY GET_RN3;
//            GET_RN3:
//                cmd_head<=#`UDLY ACCESS3;
//            ACCESS3:
               // cmd_head<=#`UDLY KILL;
           // KILL:
                // cmd_head<=#`UDLY READ2;
            // READ2:
                cmd_head<=#`UDLY WRITE1;
            WRITE1:                ////////////////////write1
                cmd_head<=#`UDLY READ3;
            READ3:
                cmd_head<=#`UDLY CH_END;
            CH_END:
                cmd_head<=#`UDLY CH_END;
            default:
                cmd_head<=#`UDLY QUERY;
            endcase
    end
    
    assign TRext=(cmd_head==QUERY);
    
    assign tpp_rst=rst_n&~((rd_state==PRE_SD)&&tpp_pre_pulse);
    
    //********************************************************//
    //DT_REC & DT_SND
    
    //Enable sending data.
    always @(negedge rd_clk or negedge rst_n)
    begin
        if(!rst_n)
            tpp_en<=#`UDLY 1'b0;
        else if(rd_state==DT_SND)
            if(cmd_head==CH_NONE||cmd_head==CH_END)
                tpp_en<=#`UDLY 1'b0;
            else
                tpp_en<=#`UDLY 1'b1;
        else
            tpp_en<=#`UDLY 1'b0;
    end
    
    //Enable fm0 decoder when the code-mode of back-link is FM0[m_value=2'b00].
    always @(negedge rd_clk or negedge rst_n)
    begin
        if(!rst_n)
            fm0_en<=#`UDLY 1'b0;
        else if(rd_state==DT_REC&&m_value==2'b00)
            fm0_en<=#`UDLY 1'b1;
        else
            fm0_en<=#`UDLY 1'b0;
    end
    
    //Enable miller decoder when the code-mode of back-link is miller[m_value=2'b01,2'b10,2'b11].
    always @(negedge rd_clk or negedge rst_n)
    begin
        if(!rst_n)
            miller_en<=#`UDLY 1'b0;
        else if(rd_state==DT_REC&&m_value!=2'b00)
            miller_en<=#`UDLY 1'b1;
        else
            miller_en<=#`UDLY 1'b0;
    end
    
    //********************************************************//    
    //Receive data from decoder.
    
    assign dec_data=fm0_data|miller_data;
    assign rec_clk=fm0_clk|miller_clk;
    assign dec_start=fm0_start|miller_start;
    assign dec_done=fm0_done|miller_done;
    
    assign rec_rst=rst_n&~dec_done;
    
    //Receive the data from the output stream of fm0/miller decoder.
    always @(posedge rec_clk or negedge rst_n)
    begin
        if(!rst_n)
            rec_buf<=#`UDLY 16'h0000;
        else
            rec_buf<=#`UDLY {rec_buf[14:0],dec_data};
    end
    
    //count for the output of fm0/miller decoder
    always @(posedge rec_clk or negedge rec_rst)
    begin
        if(!rec_rst)
            rec_cnt<=#`UDLY 8'd0;
        else
            rec_cnt<=#`UDLY rec_cnt+1'b1;
    end
    
    //Get handle from the response of Query, QueryRep.
    // always @(negedge rec_clk or negedge rst_n)     //为了测试，把handle定为常量16'b1110_1110_0100_1111
    // begin
        // if(!rst_n)
            // handle<=#`UDLY 16'h0000;
        // else
            // case(cmd_head)
            // QUERY,
            // QUERYREP:
                // if(rec_cnt==8'd16)
                    // handle<=#`UDLY rec_buf;
                // else
                    // handle<=#`UDLY handle;
            // default:
                // handle<=#`UDLY handle;
            // endcase                
    // end
    
    //Get rn16 from the response of GET_RN.
    always @(negedge rec_clk or negedge rst_n)
    begin
        if(!rst_n)
            rn16<=#`UDLY 16'h0000;
        else
            if(cmd_head==GET_RN  ||
               cmd_head==GET_RN1 ||
               cmd_head==GET_RN2 ||
               cmd_head==GET_RN3 ||
               cmd_head==GET_RN4 ||
               cmd_head==GET_RN5 
              )
                if(rec_cnt==8'd16)
                    rn16<=#`UDLY rec_buf;
                else
                    rn16<=#`UDLY rn16;
            else
                rn16<=#`UDLY rn16;
    end
    
    assign crc_xor6=dec_data^REC_CRC16[15];
    assign crc_xor7=crc_xor6^REC_CRC16[4];
    assign crc_xor8=crc_xor6^REC_CRC16[11];
        
    //CRC16
    always @(posedge rec_clk or negedge rec_rst)
    begin
        if(!rec_rst)
            REC_CRC16<=#`UDLY 16'hffff;
        else if(crc_en&&~TRext)
            REC_CRC16<=#`UDLY {REC_CRC16[14:12],crc_xor8,REC_CRC16[10:5],crc_xor7,REC_CRC16[3:0],crc_xor6};
        else
            REC_CRC16<=#`UDLY REC_CRC16;
    end
    
    always @(posedge rec_clk or negedge rec_rst)
    begin
        if(!rec_rst)        
            rec_bit_cnt<=#`UDLY 16'd0;
        else
            rec_bit_cnt<=#`UDLY rec_bit_cnt+1'b1;
    end
    
    //********************************************************//
    //tpp encoder
    
    assign enc_clk=doub_flc&tpp_en;
    
    always @(negedge enc_clk or negedge tpp_rst)
    begin
       if(!tpp_rst)
           st_cnt<=#`UDLY 4'd0;
       else if(cnt_rst)
           st_cnt<=#`UDLY 4'd0;
       else
           st_cnt<=#`UDLY st_cnt+1'b1;
    end
    
    assign cnt_rst=(enc_state==DELIM &&st_cnt==4'd1 ) ||
                   (enc_state==TCAL1 &&st_cnt==4'd5 ) ||
                   (enc_state==TCAL2 &&st_cnt==4'd3 ) ||
                   (enc_state==DATA00&&st_cnt==4'd1 ) ||
                   (enc_state==DATA01&&st_cnt==4'd2 ) ||
                   (enc_state==DATA10&&st_cnt==4'd4 ) ||
                   (enc_state==DATA11&&st_cnt==4'd3 );
    
    always @(posedge enc_clk or negedge tpp_rst)
    begin
        if(!tpp_rst)
            flg_buf_a<=#`UDLY 1'b0;
        else if(st_cnt==4'd0)
            flg_buf_a<=#`UDLY 1'b1;
        else if(st_cnt==4'd1)
            flg_buf_a<=#`UDLY 1'b0;
        else
            flg_buf_a<=#`UDLY flg_buf_a;
    end
    
    always @(negedge enc_clk or negedge tpp_rst)
    begin
        if(!tpp_rst)
            flg_buf_b<=#`UDLY 1'b0;
        else if(flg_buf_a)
            flg_buf_b<=#`UDLY 1'b1;
        else
            flg_buf_b<=#`UDLY 1'b0;
    end
    
    //for the state jump.
    assign st_pulse=flg_buf_a&flg_buf_b;
    
    assign bit_in=enc_buf[15:14];
    
    always @(posedge st_pulse or negedge tpp_rst)
    begin
        if(!tpp_rst)
            enc_state<=#`UDLY ENC_RDY;
        else if(data_end)
            enc_state<=#`UDLY ENC_END;
        else
            case(enc_state)
            ENC_RDY:
                enc_state<=#`UDLY DELIM;
            DELIM:
                enc_state<=#`UDLY TCAL1;
            TCAL1:
                enc_state<=#`UDLY TCAL2;
            TCAL2,
            DATA00,
            DATA01,
            DATA10,
            DATA11:
                case(bit_in)
                2'b00:
                    enc_state<=#`UDLY DATA00;
                2'b01:
                    enc_state<=#`UDLY DATA01;
                2'b10:
                    enc_state<=#`UDLY DATA10;
                2'b11:
                    enc_state<=#`UDLY DATA11;
                endcase
            default:
                enc_state<=#`UDLY enc_state;
            endcase
    end
    
    //********************************************************//
    
    //a pulse for shifting enc_buf.
    assign bsh_pulse=~flg_buf_a&flg_buf_b;
    
    //Prepare the data to be encoded.
    always @(posedge bsh_pulse or posedge data_pulse or negedge rst_n)
    begin
        if(!rst_n)
            enc_buf<=#`UDLY 16'h0000;
        else if(data_pulse)
            case(cmd_head)
            TIDWRITE://TID insert
                if(frm_cnt==4'd1)
                    enc_buf<=#`UDLY 16'b10110000_00000000;
                else if(frm_cnt==4'd2)
                    enc_buf<=#`UDLY 16'b00_00000000000000;
                else if(frm_cnt==4'd3)
                    enc_buf<=#`UDLY 16'd01;
                //else if(frm_cnt==4'd4)
                   // enc_buf<=#`UDLY 16'd01;
                else if(frm_cnt==4'd4)
                    enc_buf<=#`UDLY 16'hCCCC;
                //else if(frm_cnt==4'd6)
                    //enc_buf<=#`UDLY handle;
                else
                    enc_buf<=#`UDLY ~CRC16;
            TIDWRITE1://TID insert
                if(frm_cnt==4'd1)
                    enc_buf<=#`UDLY 16'b10110000_00000000;
                else if(frm_cnt==4'd2)
                    enc_buf<=#`UDLY 16'b00_00000000000000;
                else if(frm_cnt==4'd3)
                    enc_buf<=#`UDLY 16'd02;
                //else if(frm_cnt==4'd4)
                   // enc_buf<=#`UDLY 16'd01;
                else if(frm_cnt==4'd4)
                    enc_buf<=#`UDLY 16'hDDDD;
                //else if(frm_cnt==4'd6)
                    //enc_buf<=#`UDLY handle;
                else
                    enc_buf<=#`UDLY ~CRC16;  
            TIDWRITE2://TID insert
                if(frm_cnt==4'd1)
                    enc_buf<=#`UDLY 16'b10110000_00000000;
                else if(frm_cnt==4'd2)
                    enc_buf<=#`UDLY 16'b00_00000000000000;
                else if(frm_cnt==4'd3)
                    enc_buf<=#`UDLY 16'd03;
                //else if(frm_cnt==4'd4)
                   // enc_buf<=#`UDLY 16'd01;
                else if(frm_cnt==4'd4)
                    enc_buf<=#`UDLY 16'hEEEE;
                //else if(frm_cnt==4'd6)
                    //enc_buf<=#`UDLY handle;
                else
                    enc_buf<=#`UDLY ~CRC16;          
            TIDDONE://TID insert finish
                enc_buf<=#`UDLY 16'b10111111_00000000;              
            SORT:
                if(frm_cnt==4'd1)
                    enc_buf<=#`UDLY 16'b10101010_00000000;
                else if(frm_cnt==4'd2)
                    enc_buf<=#`UDLY 16'b00_00_000000000000;
                else if(frm_cnt==4'd3)
                    enc_buf<=#`UDLY MASK_PTR;
                else if(frm_cnt==4'd4)
                    enc_buf<=#`UDLY {MASK_LEN,8'h00};
                else if(frm_cnt==4'd5)
                    enc_buf<=#`UDLY MASK_VAL[15:0];
                else if(frm_cnt==4'd6)
                    enc_buf<=#`UDLY MASK_VAL[31:16];
                else
                    enc_buf<=#`UDLY ~CRC16;                    
            QUERY:
                if(frm_cnt==4'd1)
                    enc_buf<=#`UDLY 16'b10100100_00000000;
                else if(frm_cnt==4'd2)
                    enc_buf<=#`UDLY {CONDITION,TARGET_QUERY,1'b0,DR,m_value,8'b00000000};
                else
                    enc_buf<=#`UDLY ~CRC16;
//            QUERYREP:
//                enc_buf<=#`UDLY 16'b00_00_000000000000;
            ACK:
                if(frm_cnt==4'd1)
                    enc_buf<=#`UDLY {2'b01,8'b0111_0111,6'b0};  //用于测试
                else
                    enc_buf<=#`UDLY {8'b0011_1001,8'b0};
//            NAK:
//                enc_buf<=#`UDLY 16'b1100_000000000000;
            GET_RN,
            GET_RN2,
            GET_RN3,
            GET_RN4,
            GET_RN5,
            GET_RN1:
                if(frm_cnt==4'd1)
                    enc_buf<=#`UDLY 16'b10110010_00000000;
                else if(frm_cnt==4'd2)
                    enc_buf<=#`UDLY handle;
                else
                    enc_buf<=#`UDLY ~CRC16;
//            VERIFY:
//                if(frm_cnt==4'd1)
//                    enc_buf<=#`UDLY 16'b11000111_00000000;                
//                else if(frm_cnt==4'd2)
//                    enc_buf<=#`UDLY handle;
//                else
//                    enc_buf<=#`UDLY ~CRC16;
//            HACS:
//                if(frm_cnt==4'd1)
//                    enc_buf<=#`UDLY 16'b11000110_00000000;
//                else if(frm_cnt==4'd2)
//                    enc_buf<=#`UDLY PWD_ACS_H^rn16;             
//                else if(frm_cnt==4'd3)
//                    enc_buf<=#`UDLY handle;
//                else
//                    enc_buf<=#`UDLY ~CRC16;
            ACCESS://read code (high 16bits)
                if(frm_cnt==4'd1)
                    enc_buf<=#`UDLY 16'b10100011_00000000;
                else if(frm_cnt==4'd2)
                    enc_buf<=#`UDLY 16'b0111_000000000000;
                else if(frm_cnt==4'd3)
                    enc_buf<=#`UDLY 16'hFFFF^rn16;
                else if(frm_cnt==4'd4)
                    enc_buf<=#`UDLY handle;
                else
                    enc_buf<=#`UDLY ~CRC16;
            ACCESS1://read code (low 16bits)
                if(frm_cnt==4'd1)
                    enc_buf<=#`UDLY 16'b10100011_00000000;
                else if(frm_cnt==4'd2)
                    enc_buf<=#`UDLY 16'b0110_000000000000;
                else if(frm_cnt==4'd3)
                    enc_buf<=#`UDLY 16'hFFFF^rn16;
                else if(frm_cnt==4'd4)
                    enc_buf<=#`UDLY handle;
                else
                    enc_buf<=#`UDLY ~CRC16;
            ACCESS2://write code (high 16bits)
                if(frm_cnt==4'd1)
                    enc_buf<=#`UDLY 16'b10100011_00000000;
                else if(frm_cnt==4'd2)
                    enc_buf<=#`UDLY 16'b0101_000000000000;
                else if(frm_cnt==4'd3)
                    enc_buf<=#`UDLY 16'h4444^rn16;
                else if(frm_cnt==4'd4)
                    enc_buf<=#`UDLY handle;
                else
                    enc_buf<=#`UDLY ~CRC16;
            ACCESS3://write code (low 16bits)
                if(frm_cnt==4'd1)
                    enc_buf<=#`UDLY 16'b10100011_00000000;
                else if(frm_cnt==4'd2)
                    enc_buf<=#`UDLY 16'b0100_000000000000;
                else if(frm_cnt==4'd3)
                    enc_buf<=#`UDLY 16'h3333^rn16;
                else if(frm_cnt==4'd4)
                    enc_buf<=#`UDLY handle;
                else
                    enc_buf<=#`UDLY ~CRC16; 
            ACCESS4://lock code (high 16bits)
                if(frm_cnt==4'd1)
                    enc_buf<=#`UDLY 16'b10100011_00000000;
                else if(frm_cnt==4'd2)
                    enc_buf<=#`UDLY 16'b0011_000000000000;
                else if(frm_cnt==4'd3)
                    enc_buf<=#`UDLY 16'h6666^rn16;
                else if(frm_cnt==4'd4)
                    enc_buf<=#`UDLY handle;
                else
                    enc_buf<=#`UDLY ~CRC16;
            ACCESS5://lock code (low 16bits)
                if(frm_cnt==4'd1)
                    enc_buf<=#`UDLY 16'b10100011_00000000;
                else if(frm_cnt==4'd2)
                    enc_buf<=#`UDLY 16'b0010_000000000000;
                else if(frm_cnt==4'd3)
                    enc_buf<=#`UDLY 16'h5555^rn16;
                else if(frm_cnt==4'd4)
                    enc_buf<=#`UDLY handle;
                else
                    enc_buf<=#`UDLY ~CRC16;  
            ACCESS6://kill code (high 16bits)
                if(frm_cnt==4'd1)
                    enc_buf<=#`UDLY 16'b10100011_00000000;
                else if(frm_cnt==4'd2)
                    enc_buf<=#`UDLY 16'b0001_000000000000;
                else if(frm_cnt==4'd3)
                    enc_buf<=#`UDLY 16'h8888^rn16;
                else if(frm_cnt==4'd4)
                    enc_buf<=#`UDLY handle;
                else
                    enc_buf<=#`UDLY ~CRC16;
            ACCESS7://kill code (low 16bits)
                if(frm_cnt==4'd1)
                    enc_buf<=#`UDLY 16'b10100011_00000000;
                else if(frm_cnt==4'd2)
                    enc_buf<=#`UDLY 16'b0000_000000000000;
                else if(frm_cnt==4'd3)
                    enc_buf<=#`UDLY 16'h7777^rn16;
                else if(frm_cnt==4'd4)
                    enc_buf<=#`UDLY handle;
                else
                    enc_buf<=#`UDLY ~CRC16;   
            ACCESS8://wrong read code (high 16bits)
                if(frm_cnt==4'd1)
                    enc_buf<=#`UDLY 16'b10100011_00000000;
                else if(frm_cnt==4'd2)
                    enc_buf<=#`UDLY 16'b0111_000000000000;
                else if(frm_cnt==4'd3)
                    enc_buf<=#`UDLY 16'hABCD^rn16;
                else if(frm_cnt==4'd4)
                    enc_buf<=#`UDLY handle;
                else
                    enc_buf<=#`UDLY ~CRC16;
            ACCESS9://wrong read code (low 16bits)
                if(frm_cnt==4'd1)
                    enc_buf<=#`UDLY 16'b10100011_00000000;
                else if(frm_cnt==4'd2)
                    enc_buf<=#`UDLY 16'b0110_000000000000;
                else if(frm_cnt==4'd3)
                    enc_buf<=#`UDLY 16'hDCBA^rn16;
                else if(frm_cnt==4'd4)
                    enc_buf<=#`UDLY handle;
                else
                    enc_buf<=#`UDLY ~CRC16;                  
            READ1:
                if(frm_cnt==4'd1)
                    enc_buf<=#`UDLY 16'b10100101_00000000;
                else if(frm_cnt==4'd2)
                    enc_buf<=#`UDLY {2'b01,14'b00000000000000};
                else if(frm_cnt==4'd3)
                    enc_buf<=#`UDLY 16'd01;
                else if(frm_cnt==4'd4)
                    enc_buf<=#`UDLY 16'd01;
                else if(frm_cnt==4'd5)
                    enc_buf<=#`UDLY handle;
                else
                    enc_buf<=#`UDLY ~CRC16;
            READ2:
                if(frm_cnt==4'd1)
                    enc_buf<=#`UDLY 16'b10100101_00000000;
                else if(frm_cnt==4'd2)
                    enc_buf<=#`UDLY {2'b01,14'b00000000000000};
                else if(frm_cnt==4'd3)
                    enc_buf<=#`UDLY 16'd00;
                else if(frm_cnt==4'd4)
                    enc_buf<=#`UDLY 16'd01;
                else if(frm_cnt==4'd5)
                    enc_buf<=#`UDLY handle;
                else
                    enc_buf<=#`UDLY ~CRC16;
            READ3:
                if(frm_cnt==4'd1)
                    enc_buf<=#`UDLY 16'b10100101_00000000;
                else if(frm_cnt==4'd2)
                    enc_buf<=#`UDLY {2'b01,14'b00000000000000};
                else if(frm_cnt==4'd3)
                    enc_buf<=#`UDLY 16'd10;
                else if(frm_cnt==4'd4)
                    enc_buf<=#`UDLY 16'd02;
                else if(frm_cnt==4'd5)
                    enc_buf<=#`UDLY handle;
                else
                    enc_buf<=#`UDLY ~CRC16;
            READ4:
                if(frm_cnt==4'd1)
                    enc_buf<=#`UDLY 16'b10100101_00000000;
                else if(frm_cnt==4'd2)
                    enc_buf<=#`UDLY {2'b01,14'b00000000000000};
                else if(frm_cnt==4'd3)
                    enc_buf<=#`UDLY 16'd01;
                else if(frm_cnt==4'd4)
                    enc_buf<=#`UDLY 16'd01;
                else if(frm_cnt==4'd5)
                    enc_buf<=#`UDLY handle;
                else
                    enc_buf<=#`UDLY ~CRC16;        
            WRITE:
                if(frm_cnt==4'd1)
                    enc_buf<=#`UDLY 16'b10100110_00000000;
                else if(frm_cnt==4'd2)
                    enc_buf<=#`UDLY 16'b01_00000000000000;
                else if(frm_cnt==4'd3)
                    enc_buf<=#`UDLY 16'd03;
                else if(frm_cnt==4'd4)
                    enc_buf<=#`UDLY 16'd01;
                else if(frm_cnt==4'd5)
                    enc_buf<=#`UDLY 16'hAAAA;
                else if(frm_cnt==4'd6)
                    enc_buf<=#`UDLY handle;
                else
                    enc_buf<=#`UDLY ~CRC16;
            WRITE1:
                if(frm_cnt==4'd1)
                    enc_buf<=#`UDLY 16'b10100110_00000000;
                else if(frm_cnt==4'd2)
                    enc_buf<=#`UDLY 16'b11_00000000000000;
                else if(frm_cnt==4'd3)
                    enc_buf<=#`UDLY 16'd02;
                else if(frm_cnt==4'd4)
                    enc_buf<=#`UDLY 16'd01;
                else if(frm_cnt==4'd5)
                    enc_buf<=#`UDLY 16'hBBBB;
                else if(frm_cnt==4'd6)
                    enc_buf<=#`UDLY handle;
                else
                    enc_buf<=#`UDLY ~CRC16;  
            LOCK:
                if(frm_cnt==4'd1)
                    enc_buf<=#`UDLY 16'b10101000_00000000;
                else if(frm_cnt==4'd2)
                    enc_buf<=#`UDLY 16'b1111_000000000000;
                else if(frm_cnt==4'd3)
                    enc_buf<=#`UDLY handle;
                else
                    enc_buf<=#`UDLY ~CRC16;
            KILL:
                if(frm_cnt==4'd1)
                    enc_buf<=#`UDLY 16'b10101001_00000000;
                else if(frm_cnt==4'd2)
                    enc_buf<=#`UDLY handle;
                else
                    enc_buf<=#`UDLY ~CRC16;
            default:
                enc_buf<=#`UDLY 16'h0000;
            endcase
        else
            enc_buf<=#`UDLY {enc_buf[13:0],2'b0};
    end
    
    //Prepare the length of frame to be encoded.
    always @(posedge data_pulse or negedge tpp_rst)
    begin
        if(!tpp_rst)
            max_cnt<=#`UDLY 4'd15;
        else if(frm_cnt==4'd0)
//            if(TRext)
//                max_cnt<=#`UDLY 4'd3;
//            else
                max_cnt<=#`UDLY 4'd2;
        else
            case(cmd_head)
            TIDWRITE,
            TIDWRITE2,
            TIDWRITE1:
                if(frm_cnt==4'd1)
                    max_cnt<=#`UDLY 4'd3;
                else if(frm_cnt==4'd2)
                    max_cnt<=#`UDLY 4'd0;
                else if(frm_cnt==4'd3)
                    max_cnt<=#`UDLY 4'd7;
                else if(frm_cnt==4'd4)
                    max_cnt<=#`UDLY 4'd7;
                else
                    max_cnt<=#`UDLY 4'd7;
            TIDDONE:
                    max_cnt<=#`UDLY 4'd3;       
            SORT:
                if(frm_cnt==4'd1)
                    max_cnt<=#`UDLY 4'd3;
                else if(frm_cnt==4'd2)
                    max_cnt<=#`UDLY 4'd1;
                else if(frm_cnt==4'd3) 
                    max_cnt<=#`UDLY 4'd7;
                else if(frm_cnt==4'd4)
                    max_cnt<=#`UDLY 4'd3;
                else if(frm_cnt==4'd5)
                    max_cnt<=#`UDLY 4'd7;
                else if(frm_cnt==4'd6)
                    max_cnt<=#`UDLY 4'd7;
                else
                    max_cnt<=#`UDLY 4'd7;
            QUERY:
                if(frm_cnt==4'd1)
                    max_cnt<=#`UDLY 4'd3;
                else if(frm_cnt==4'd2)
                    max_cnt<=#`UDLY 4'd3;
                else
                    max_cnt<=#`UDLY 4'd7;
//            QUERYREP:
//                max_cnt<=#`UDLY 4'd3;
            ACK:
                if(frm_cnt==4'd1)
                    max_cnt<=#`UDLY 4'd4;
                else
                    max_cnt<=#`UDLY 4'd3;
//            NAK:
//                max_cnt<=#`UDLY 4'd7;
            GET_RN,
            GET_RN2,
            GET_RN3,
            GET_RN4,
            GET_RN5,
            GET_RN1:
                if(frm_cnt==4'd1)
                    max_cnt<=#`UDLY 4'd3;
                else if (frm_cnt==4'd2)
                    max_cnt<=#`UDLY 4'd7;
                else    
                    max_cnt<=#`UDLY 4'd7;
            ACCESS,
            ACCESS1,
            ACCESS2,
            ACCESS3,
            ACCESS4,
            ACCESS5,
            ACCESS6,
            ACCESS7,
            ACCESS8,
            ACCESS9:
                if(frm_cnt==4'd1)
                    max_cnt<=#`UDLY 4'd3;
                else if(frm_cnt==4'd2)
                    max_cnt<=#`UDLY 4'd1;
                else if(frm_cnt==4'd3)
                    max_cnt<=#`UDLY 4'd7;
                else if(frm_cnt==4'd4)
                    max_cnt<=#`UDLY 4'd7;
                else
                    max_cnt<=#`UDLY 4'd7;
            READ1,
            READ2,
            READ3,
            READ4:
                if(frm_cnt==4'd1)
                    max_cnt<=#`UDLY 4'd3;
                else if(frm_cnt==4'd2)
                    max_cnt<=#`UDLY 4'd0;
                else if(frm_cnt==4'd3)
                    max_cnt<=#`UDLY 4'd7;
                else if(frm_cnt==4'd4)
                    max_cnt<=#`UDLY 4'd7;
                else if(frm_cnt==4'd5)
                    max_cnt<=#`UDLY 4'd7;
                else
                    max_cnt<=#`UDLY 4'd7;
            WRITE,        
            WRITE1:
                if(frm_cnt==4'd1)
                    max_cnt<=#`UDLY 4'd3;
                else if(frm_cnt==4'd2)
                    max_cnt<=#`UDLY 4'd0;
                else if(frm_cnt==4'd3)
                    max_cnt<=#`UDLY 4'd7;
                else if(frm_cnt==4'd4)
                    max_cnt<=#`UDLY 4'd7;
                else if(frm_cnt==4'd5)
                    max_cnt<=#`UDLY 4'd7;
                else if(frm_cnt==4'd6)
                    max_cnt<=#`UDLY 4'd7;
                else
                    max_cnt<=#`UDLY 4'd7;
            LOCK:
                if(frm_cnt==4'd1)
                    max_cnt<=#`UDLY 4'd3;
                else if(frm_cnt==4'd2)
                    max_cnt<=#`UDLY 4'd1;
                else if(frm_cnt==4'd3)
                    max_cnt<=#`UDLY 4'd7;
                else
                    max_cnt<=#`UDLY 4'd7;
            KILL:
                if(frm_cnt==4'd1)
                    max_cnt<=#`UDLY 4'd3;
                else if(frm_cnt==4'd2)
                    max_cnt<=#`UDLY 4'd7;
                else
                    max_cnt<=#`UDLY 4'd7;
            default:
                max_cnt<=#`UDLY 4'd7;
            endcase

    end
    
    //Judge if the current frame of data is finished sending.[Nf+1]
    always @(posedge data_pulse or negedge tpp_rst)
    begin
        if(!tpp_rst)
            data_end<=#`UDLY 1'b0;
        else
            case(cmd_head)
            TIDWRITE1,
            TIDWRITE2,
            TIDWRITE:
                if(frm_cnt==4'd6)
                    data_end<=#`UDLY 1'b1;
                else
                    data_end<=#`UDLY data_end;
            TIDDONE:
                if(frm_cnt==4'd2)
                    data_end<=#`UDLY 1'b1;
                else
                    data_end<=#`UDLY data_end;        
            SORT:
                if(frm_cnt==4'd8)
                    data_end<=#`UDLY 1'b1;
                else
                    data_end<=#`UDLY data_end;                           
            QUERY:
                if(frm_cnt==4'd4)
                    data_end<=#`UDLY 1'b1;
                else
                    data_end<=#`UDLY data_end; 
            GET_RN,
            GET_RN2,
            GET_RN3,
            GET_RN4,
            GET_RN5,
            GET_RN1:
                if(frm_cnt==4'd3)
                    data_end<=#`UDLY 1'b1;
                else
                    data_end<=#`UDLY data_end;
            ACCESS,
            ACCESS2,
            ACCESS3,
            ACCESS4,
            ACCESS5,
            ACCESS6,
            ACCESS7,
            ACCESS8,
            ACCESS9,
            ACCESS1:
                if(frm_cnt==4'd6)
                    data_end<=#`UDLY 1'b1;
                else
                    data_end<=#`UDLY data_end;
//            NAK,
//            QUERYREP:
//                if(frm_cnt==4'd2)
//                    data_end<=#`UDLY 1'b1;
//                else
//                    data_end<=#`UDLY data_end;
            ACK:
                if(frm_cnt==4'd3)
                    data_end<=#`UDLY 1'b1;
                else
                    data_end<=#`UDLY data_end;
            READ1,
            READ2,
            READ3,
            READ4:
                if(frm_cnt==4'd7)
                    data_end<=#`UDLY 1'b1;
                else
                    data_end<=#`UDLY data_end;
            WRITE,
            WRITE1:
                if(frm_cnt==4'd8)
                    data_end<=#`UDLY 1'b1;
                else
                    data_end<=#`UDLY data_end;
            LOCK:
                if(frm_cnt==4'd5)
                    data_end<=#`UDLY 1'b1;
                else
                    data_end<=#`UDLY data_end;
            KILL:
                if(frm_cnt==4'd4)
                    data_end<=#`UDLY 1'b1;
                else
                    data_end<=#`UDLY data_end;
            default:
                data_end<=#`UDLY data_end;
            endcase
    end
    
    //********************************************************//
    
    //Generate the data to be sended to tag.
    always @(posedge enc_clk or negedge rst_n)
    begin
        if(!rst_n)
            rd_data<=#`UDLY 1'b1;
        else if(enc_state==ENC_RDY||enc_state==ENC_END)
            rd_data<=#`UDLY 1'b1;
        else if(st_cnt==2'd1)
            rd_data<=#`UDLY 1'b1;
        else if(st_cnt==2'd0)
            rd_data<=#`UDLY 1'b0;
        else
            rd_data<=#`UDLY rd_data;
    end
    
    //a pulse serving for the frame and prepare somme data at the begin of the frame.
    assign data_pulse=(st_cnt==4'd0&&bit_cnt==4'd0)? (flg_buf_a&~flg_buf_b) : 1'b0;
    
    //a count in the frame for marking the count of bits has be sended.
    always @(posedge st_pulse or negedge tpp_rst)
    begin
        if(!tpp_rst)
            bit_cnt<=#`UDLY 4'd0;
        else if(bit_cnt==max_cnt)
            bit_cnt<=#`UDLY 4'd0;
        else
            bit_cnt<=#`UDLY bit_cnt+1'b1;
    end
    
    //a count of frame for marking the count of frame has be sended.
    always @(negedge data_pulse or negedge tpp_rst)
    begin
        if(!tpp_rst)
            frm_cnt<=#`UDLY 4'd0;
        else
            frm_cnt<=#`UDLY frm_cnt+1'b1;
    end
    
    //only for generating the tpp_done.
    always @(posedge enc_clk or negedge tpp_rst)
    begin
        if(!tpp_rst)
            enc_end_ctrl<=#`UDLY 1'b0;
        else if(enc_state==ENC_END)
            enc_end_ctrl<=#`UDLY 1'b1;
        else
            enc_end_ctrl<=#`UDLY enc_end_ctrl;
    end
    
    //only for generating the tpp_done.
    always @(negedge enc_clk or negedge tpp_rst)
    begin
        if(!tpp_rst)
            enc_end<=#`UDLY 1'b0;
        else if(enc_end_ctrl)
            enc_end<=#`UDLY 1'b1;
        else
            enc_end<=#`UDLY enc_end;
    end
        
    //a pulse for telling that encoding has finished.
    assign tpp_done=enc_end_ctrl&~enc_end;
    
    //********************************************************//
    //CRC
    
    //Enable calculating the CRC.
    always @(posedge data_pulse or negedge tpp_rst)
    begin
        if(!tpp_rst)
            crc_en<=#`UDLY 1'b0;
        else if(frm_cnt==4'd1)
            crc_en<=#`UDLY 1'b1;
        else
            crc_en<=#`UDLY crc_en;
    end
    
    //for CRC5
//    assign crc_xor0=bit_in^CRC5[4];
//    assign crc_xor1=crc_xor0^CRC5[2];

    //for CRC16
    assign crc_xor0 = bit_in[0] ^ CRC16[14]     ;         
    assign crc_xor1 = bit_in[1] ^ CRC16[15]     ;
    assign crc_xor2 = CRC16[3]    ^ crc_xor0      ;
    assign crc_xor3 = crc_xor1    ^ CRC16[4]      ;
    assign crc_xor4 = CRC16[10]   ^ crc_xor0      ;
    assign crc_xor5 = CRC16[11]   ^ crc_xor1      ;
    
//    assign crc_xor2=bit_in^CRC16[15];
//    assign crc_xor3=crc_xor2^CRC16[4];
//    assign crc_xor4=crc_xor2^CRC16[11];
    
    //CRC5
//    always @(posedge st_pulse or negedge tpp_rst)
//    begin
//        if(!tpp_rst)
//            CRC5<=#`UDLY 5'b01001;
//        else if(crc_en&&TRext)
//            CRC5<=#`UDLY {CRC5[3], crc_xor1, CRC5[1], CRC5[0], crc_xor0};
//        else
//            CRC5<=#`UDLY CRC5;
//    end    

    //CRC16
    always @(posedge st_pulse or negedge tpp_rst)
    begin
        if(!tpp_rst)
            CRC16<=#`UDLY 16'hffff;
        else if(crc_en)
            CRC16<= #`UDLY {CRC16[13:12],crc_xor5,crc_xor4,CRC16[9:5],crc_xor3,crc_xor2,CRC16[2:0],crc_xor1,crc_xor0} ;
        else
            CRC16<=#`UDLY CRC16;
    end    
    
endmodule





   