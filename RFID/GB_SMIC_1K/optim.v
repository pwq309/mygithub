// *******************************************************************
// COPYRIGHT, Xi'an XDU Radio-frequency IC Co.,Ltd 
// All rights reserved.
//
// IP NAME      :  RFID
// File name    :  optim.v
// Module name  :  OPTIM
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

module OPTIM(
             //inputs   
             clk_1_92m        , 
             rst_n            ,     
             din              , 
             DATA_RD          ,   
             READY            ,     
                        
             //outputs  
             dout             , 
             A                ,         
             CEN              ,       
             OEN              ,       
             WEN              ,       
             CHER             ,      
             CHWR             ,      
             RD_CLK           ,    
             PCH              ,       
             ERFL             ,      
             OPT              ,       
             PT               ,         
             ET               ,         
             EXCP             ,       
             DATA_WR          ,    
             WSEN             ,       
             WS               ,         
             ITEST       

             );

//define input ports:
//inputs                          
input              clk_1_92m   ;     
input              rst_n       ;         
input              din         ;     
input    [15:0]    DATA_RD     ;       
input              READY       ;         
                                  
//outputs                         
output             dout        ;     
output   [ 5:0]    A           ;             
output             CEN         ;           
output             OEN         ;           
output             WEN         ;           
output             CHER        ;          
output             CHWR        ;          
output             RD_CLK      ;        
output   [2:0]     PCH         ;           
output             ERFL        ;            
output             OPT         ;             
output   [1:0]     PT          ;              
output   [1:0]     ET          ;              
output             EXCP        ;            
output   [15:0]    DATA_WR     ;         
output             WSEN        ;            
output             WS          ;              
output             ITEST       ;         

//define output attributes:
wire               dout        ; 
wire     [5:0]     A           ;          
wire               CEN         ;        
wire               OEN         ;        
wire               WEN         ;        
wire               CHER        ;       
wire               CHWR        ;       
wire               RD_CLK      ;     
wire     [2:0]     PCH         ;        
wire               ERFL        ;       
wire               OPT         ;        
wire     [1:0]     PT          ;         
wire     [1:0]     ET          ;         
wire               EXCP        ;       
wire     [15:0]    DATA_WR     ;    
wire               WSEN        ;       
wire               WS          ;         
wire               ITEST       ;      

//define input attributes:
wire           clk_1_92m       ;
wire           rst_n           ;    
wire           din             ; 
wire  [15:0]   DATA_RD         ;  
wire           READY           ;    

//inner signal declarations:
//decoder outputs
wire         tpp_clk           ;
wire [1:0]   tpp_data          ;
wire         delimiter         ; 
wire         dec_done          ;
wire         dec_done3         ;
wire         dec_done4         ;
wire         dec_done5         ;
wire         dec_done6         ;

//cmd_parse outputs
wire         parse_done        ;
wire         parse_iereq       ;
wire         rn1_update        ;
wire         divide_position   ;
wire [5:0]   membank           ;
wire [5:0]   pointer_par       ;
wire [5:0]   length_par        ;
//wire         read_en           ;
wire [7:0]   cmd_head          ;
wire         mask_match        ;
wire         rn_match          ;
wire         parse_err         ;
wire         addr_over         ;
wire [3:0]   DR                ;
wire [1:0]   M                 ;
wire [15:0]  data_buffer       ;
wire         cmd_end           ;
wire         set_m             ;
wire         trext             ;
wire         head_finish       ;
wire [1:0]   lock_action       ;
wire [1:0]   lock_deploy       ;
wire         killpwd1_match    ;
wire         killpwd2_match    ;
wire         lockpwd1_match    ;
wire         lockpwd2_match    ;
wire [3:0]   acc_pwd           ;
wire         killpwd_match     ;
wire         lockpwd_match     ;
wire         rd_pwd1_match     ;
wire         rd_pwd2_match     ;
wire         wr_pwd1_match     ;
wire         wr_pwd2_match     ;
wire         rd_pwd_match      ;
wire         wr_pwd_match      ;
wire         session_match     ;
wire         flag_match        ;
wire         SL_match          ;

//scu outputs
wire [3:0]   tag_state         ;
wire [3:0]   bsc               ;
wire         T2_judge_en       ;
wire         scu_done          ;
wire         handle_update     ;
wire         rn16_update       ;

//ocu outputs
wire         T2_overstep       ;
wire         wr_pulse          ;
wire [4:0]   crc5_back         ;
wire         kill_tag          ;
wire         ocu_done          ;
wire         clk_sel           ;
wire         data_clk          ;

//pmu outputs
wire         dec_en            ;
wire         init_en           ;
wire         ie_en             ;
wire         scu_en            ;
wire         ocu_en            ;
wire         div_en            ;

//div outputs
wire         DOUB_BLF          ;

//rng outputs
wire [14:0]  slot_val          ;
wire [15:0]  handle            ;
wire [15:0]  rn16              ;

//ie outputs
wire         word_done         ;
wire         job_done          ;
wire [15:0]  mtp_data          ;

//init outputs
wire         init_done         ;
wire [7:0]   lock_state        ;
wire [15:0]  crc_calc          ;
wire [7:0]   uac_len           ;
wire         tag_status        ;
wire [5:0]   pointer_init      ;
wire [5:0]   length_init       ;
wire         kill_pwd_status   ;
wire         lock_pwd_status   ;
wire         read_pwd_status   ;
wire         write_pwd_status  ;
wire         read_en_init      ;

wire         read_en_OCU       ;
wire [5:0]   pointer_OCU       ;
wire [5:0]   length_OCU        ;
wire         read_en_par       ;
wire         ocu_iereq         ;          



DECODER U_DECODER(
                  //input ports:
                  .clk_1_92m  (clk_1_92m  ),
                  .DOUB_BLF   (DOUB_BLF   ),
                  .rst_n      (rst_n      ),
                  .dec_en     (dec_en     ),
                  .din        (din        ),
                  .cmd_end    (cmd_end    ), 
                  .cmd_head   (cmd_head   ),
                  .head_finish(head_finish),                 
                  
                  //output ports:
                  .tpp_data  (tpp_data) ,
                  .tpp_clk   (tpp_clk)  ,
                  .delimiter (delimiter),
                  .dec_done  (dec_done) ,
                  .dec_done3 (dec_done3),
                  .dec_done4 (dec_done4),
                  .dec_done5 (dec_done5),
                  .dec_done6 (dec_done6)
                  );
                  
CMD_PARSE U_CMD_PARSE(
                      //input ports:
                      .DOUB_BLF          (DOUB_BLF),
                      .rst_n             (rst_n),
                      .tpp_clk           (tpp_clk),
                      .tpp_data          (tpp_data),
                      .delimiter         (delimiter),
                      .dec_done          (dec_done),
                      .dec_done3         (dec_done3),
                      .dec_done6         (dec_done6),
                      .mtp_data          (mtp_data),
                      .handle            (handle),
                      .rn16              (rn16)  ,                                
                      .tag_state         (tag_state),
                      .crc5_back         (crc5_back), 
					            .read_pwd_status   (read_pwd_status),
					            .write_pwd_status  (write_pwd_status),
  
                      //output ports:
                      .parse_done        (parse_done),
                      .parse_iereq       (parse_iereq), 
                      .rn1_update        (rn1_update),
                      .divide_position   (divide_position),
                      .membank           (membank),
                      .pointer_par       (pointer_par),
                      .length_par        (length_par),
                      .read_en           (read_en_par ),
                      //.rule              (rule),
                      .cmd_head          (cmd_head),
                      .mask_match        (mask_match),
                      .rn_match          (rn_match),
                      .parse_err         (parse_err),
					            .addr_over         (addr_over),
                      .DR                (DR),
                      .M                 (M),
                      .data_buffer       (data_buffer),
                      .cmd_end           (cmd_end),
                      .set_m             (set_m),
                      .trext             (trext),
                      .head_finish       (head_finish),
                      .lock_action       (lock_action),
					            .lock_deploy       (lock_deploy),
                      .killpwd1_match    (killpwd1_match) ,
                      .killpwd2_match    (killpwd2_match) ,
                      .lockpwd1_match    (lockpwd1_match) ,
                      .lockpwd2_match    (lockpwd2_match) ,
					            .acc_pwd           (acc_pwd),
                      .killpwd_match     (killpwd_match),
                      .lockpwd_match     (lockpwd_match),
					            .rd_pwd1_match     (rd_pwd1_match),
					            .rd_pwd2_match     (rd_pwd2_match),
					            .wr_pwd1_match     (wr_pwd1_match),
					            .wr_pwd2_match     (wr_pwd2_match),
					            .rd_pwd_match      (rd_pwd_match),
					            .wr_pwd_match      (wr_pwd_match),
					            .session_match     (session_match),
					            .flag_match        (flag_match),
					            .SL_match          (SL_match)

                      );
                      
SCU U_SCU(
          //input ports:
          .DOUB_BLF                   (DOUB_BLF),
          .scu_en                     (scu_en),
          .rst_n                      (rst_n),
          .delimiter                  (delimiter),
          .cmd_head                   (cmd_head),
          .rn_match                   (rn_match),
          .kill_pwd_status            (kill_pwd_status), 
		      .lock_pwd_status            (lock_pwd_status),
          .slot_val                   (slot_val),
		      .killpwd_match              (killpwd_match),
		      .lockpwd_match              (lockpwd_match),
		      .flag_match                 (flag_match),
		      .SL_match                   (SL_match),
		      .rd_pwd_match               (rd_pwd_match),
		      .wr_pwd_match               (wr_pwd_match),
		      .session_match              (session_match),
		      .T2_overstep                (T2_overstep),
		      .acc_pwd                    (acc_pwd),
		      .membank                    (membank),
		  
          //output ports:
          .tag_state                  (tag_state),
          .scu_done                   (scu_done),
          .bsc                        (bsc),
		      .T2_judge_en                (T2_judge_en),
          .handle_update              (handle_update),
          .rn16_update                (rn16_update) 

          );
          
OCU U_OCU(
          //input ports:
          .DOUB_BLF                    (DOUB_BLF),
          .rst_n                       (rst_n),
		      .ocu_en                      (ocu_en),
          .delimiter                   (delimiter),
          .init_done                   (init_done),
          .dec_done6                   (dec_done6),
          .T2_judge_en                 (T2_judge_en),
          .word_done                   (word_done),
          .job_done                    (job_done),
          .TRext                       (trext),
          .bsc                         (bsc),
          .membank                     (membank),
          .pointer                     (pointer_par),
          .length                      (length_par),
          .m_value                     (M),
          .lock_state                  (lock_state),
          .lock_action                 (lock_action),
          //.lock_pwd_status             (lock_pwd_status), 
          .data_buffer                 (data_buffer),
          .mtp_data                    (mtp_data),
          .handle                      (handle),
          .rn16                        (rn16),
          .uac_len                     (uac_len),
          .addr_over                   (addr_over),
          
          //output ports:
          .dout                        (dout),
          .T2_overstep                 (T2_overstep),
          .pointer2mem                 (pointer_OCU),
          .length2mem                  (length_OCU),
          .wr_data                     (DATA_WR),
		      .addr_ie_req                 (ocu_iereq),
		      .wr_pulse                    (wr_pulse),
          .read_pulse                  (read_en_OCU),
		      .ocu_done                    (ocu_done),
          .crc5_back                   (crc5_back),
          .kill_tag                    (kill_tag),
          .clk_sel                     (clk_sel),
          .data_clk                    (data_clk)
         
          );
          
 PMU      U_PMU  (
                  //INPUTs
                  .rst_n(rst_n)                        ,
                  .dec_done(dec_done)                  ,
                  .parse_done(parse_done)              ,
                  .parse_iereq(parse_iereq)            ,
                  //.mask_match(mask_match)              ,
                  .init_done(init_done)                ,
                  .tag_status(tag_status)              ,
                  .job_done(job_done)                  ,
                  .scu_done(scu_done)                  ,
				          .cmd_head(cmd_head)                  ,
				          .parse_err(parse_err)                ,
                  .ocu_iereq(ocu_iereq)                ,
                  .ocu_done(ocu_done)                  ,
                  .DOUB_BLF(DOUB_BLF)                  ,
                  .T2_overstep(T2_overstep)            ,
                  .new_cmd(delimiter)                  ,
                  
                  //OUTPUTs
                  .dec_en(dec_en)                      ,
                  .init_en(init_en)                    ,
                  .ie_en(ie_en)                        ,
                  .scu_en(scu_en)                      ,
                  .ocu_en(ocu_en)                      ,
                  .div_en(div_en)                      
                    
                 );          
                               
DIV  U_DIV(
          //input ports:
		      .rst_n    (rst_n),
          .clk_1_92m(clk_1_92m),
          .div_en   (div_en),
          .set_m    (set_m),
          .DR       (DR),
          
          //output ports:
          .DOUB_BLF   (DOUB_BLF)         
		  
          );             
          
 RNG    U_RNG  (
                 //input signals
                 //.DOUB_BLF         (DOUB_BLF)                   ,
                 .rst_n            (rst_n)                      ,
                 //.new_cmd          (delimiter)                  ,  
                 .cmd_head         (cmd_head)                   ,
                 .init_done        (init_done)                  , 
                 .crc_calc         (crc_calc)                   ,
                 .handle_update    (handle_update)              ,
                 .rn16_update      (rn16_update)                ,
                 .rn1_update       (rn1_update)                , 
                 .dec_done5        (dec_done5)                  , 
                 .divide_position  (divide_position)           ,
                 .tag_state        (tag_state)                  , 

                 //output signals                        
                 .slot_val         (slot_val)                   ,
                 .rn16             (rn16)                       ,
                 .handle           (handle)                     

                );
                 
 IE    U_IE  (
                 //inputs
                 .DOUB_BLF         (DOUB_BLF    )                ,                                        
                 .clk_1_92m        (clk_1_92m   )                ,                             
                 .rst_n            (rst_n       )                ,                             
                 .new_cmd          (delimiter   )                ,                             
                 .ie_en            (ie_en       )                ,                             
                 .pointer_init     (pointer_init)                ,                             
                 .length_init      (length_init )                ,                             
                 .read_en_init     (read_en_init)                ,                             
                 .pointer_par      (pointer_par )                ,                             
                 .length_par       (length_par  )                ,                             
                 .read_en_par      (read_en_par )                ,                             
                 .pointer_OCU      (pointer_OCU )                ,                             
                 .length_OCU       (length_OCU  )                ,                             
                 .read_en_OCU      (read_en_OCU )                ,                             
                 .wr_pulse         (wr_pulse    )                ,             
                 .DBO              (DATA_RD     )                ,
                 .READY            (READY       )                ,
                 .data_clk         (data_clk    )                ,                             
                 .clk_sel          (clk_sel     )                ,                             
                                                                                               
                 //outputs                                                                                            
                 .word_done        (word_done   )                ,                        
                 .job_done         (job_done    )                ,                        
                 .A                (A           )                ,                        
                 .CEN              (CEN         )                ,                        
                 .OEN              (OEN         )                ,                        
                 .WEN              (WEN         )                ,                        
                 .CHER             (CHER        )                ,                        
                 .CHWR             (CHWR        )                ,                        
                 .RD_CLK           (RD_CLK      )                ,                                
                 .PCH              (PCH         )                ,    
                 .ERFL             (ERFL        )                ,
                 .OPT              (OPT         )                ,                            
                 .PT               (PT          )                ,  
                 .ET               (ET          )                ,                     
                 .EXCP             (EXCP        )                ,                         
                 .mtp_data         (mtp_data    )                ,  
                 .WSEN             (WSEN        )                ,  
                 .WS               (WS          )                ,  
                 .ITEST            (ITEST       )                    

                 ); 


INIT    U_INIT  ( 
                 //inputs                                                                              
                 .DOUB_BLF    (DOUB_BLF )      ,  
                 .init_en     (init_en  )      ,				 
                 .rst_n       (rst_n    )      ,                                
                 .mtp_data    (mtp_data)       ,                                                           
                 .word_done   (word_done)      ,                                                           
                 .job_done    (job_done )      ,                                                            
                 
                 //outputs
                 .init_done           (init_done   ),
                 .lock_state          (lock_state  ),
                 .crc_calc            (crc_calc    ),
                 .uac_len             (uac_len     ),
                 .tag_status          (tag_status  ),
                 .kill_pwd_status     (kill_pwd_status ),                 
                 .lock_pwd_status     (lock_pwd_status ),
				         .read_pwd_status     (read_pwd_status),
				         .write_pwd_status    (write_pwd_status),
                 .pointer_init        (pointer_init),
                 .length_init         (length_init ),
                 .read_en_init        (read_en_init)

                ); 
                            
endmodule   


