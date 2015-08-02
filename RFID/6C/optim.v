`timescale 1ns/1ns
`define UDLY #5

module OPTIM(
                //inputs
                clk_1_92m,
                rst_n,
                rd_data,
                vee_rdy,
                DBO,
                READY,                
                clk_10m,                               
                //outputs
                tag_data,                
                vee_req,
                vchk_en,
                MRGSEL, 
                MRGEN,  
                DRT,   
                NVSTR, 
                PROG,   
                SE,          
                RECALL, 
                FE,     
                FUSEADR,
                DATA_WR,
                ////////
                DOUB_BLF,  
                dec_en,    
                scu_en,    
                ocu_en,    
                rd_done,   
                wr_done,   
                cmd_head,  
                tag_state
            );
            
    //inputs
    input              clk_1_92m;
    input              rst_n;
    input              rd_data;
    input              vee_rdy;
    input    [15:0]    DBO;
    input              READY;
    input              clk_10m;                                           
    //outputs
    output             tag_data;
    output             vee_req;
    output             vchk_en;
    output             MRGSEL;
    output             MRGEN;
    output             DRT;
    output             NVSTR;
    output             PROG;
    output             SE;
    output             RECALL;
    output             FE;
    output    [4:0]    FUSEADR;
    output    [15:0]   DATA_WR;
    ////////////////TEST 
    output             DOUB_BLF;
    output             dec_en;
    output             scu_en;
    output             ocu_en;
    output             rd_done;
    output             wr_done;
    output   [4:0]     cmd_head;
    output   [3:0]     tag_state;
    
    //wires
    wire               clk_1_92m;
    wire               rst_n;
    wire               rd_data;
    wire     [15:0]    DBO;
    wire               READY;
	 wire               clk_10m;
    ////////////////INIT
    wire               init_done;
    wire     [9:0]     lock_state;
    wire     [15:0]    CRC16_EPC;
    wire     [15:0]    pc_val;
    wire               tag_status;
    wire     [4:0]     init_pointer;
    wire               init_rd_pulse;
    wire     [31:0]    pwd_kill;
    wire     [31:0]    pwd_acs;
    wire               init_srd_pulse; 
    ////////////////DECODER
    wire               new_cmd;
    wire               pie_clk;
    wire               pie_data;
    wire     [9:0]     TRcal;
    wire               CRC_FLG;
    wire               dec_done;
    ////////////////CMD_PARSE
    wire               parse_done;
    wire               par_div_req;
    wire               par_div_off;
    wire               Q_update;
    wire     [3:0]     Q;
    wire               slot_update;
    wire     [1:0]     membank;
    wire     [4:0]     par_pointer;
    wire     [2:0]     target;
    wire     [2:0]     action;
    wire     [4:0]     cmd_head;
    wire     [13:0]    pointer;
    wire     [7:0]     length;
    wire               session_match;
    wire     [1:0]     session_val;
    wire               flg_match;
    wire               mask_match;
    wire               trunc;
    wire     [4:0]     EPC_SOA;
    wire               rn_match;
    wire               pwd_match;
    wire               acs_status;
    wire               kill_status;
    wire               parse_err;
    wire               DR;
    wire               TRext;
    wire     [1:0]     m_value;
    wire     [19:0]    data_buffer;
    wire               cmd_end;
    wire               blc_update;
    wire               ver_pulse;
    wire               par_srd_pulse;
    ////////////////SCU
    wire               scu_done;
    wire     [3:0]     tag_state;
    wire     [3:0]     bsc;
    wire               rn16_update;
    wire               handle_update;
    wire     [1:0]     SADR;
    wire               SUPD;
    wire               SS0;
    wire               SS1;
    wire               SS2;
    wire               SS3;
    wire               SSL;    
    wire               T2_CHK_EN;    
    ////////////////OCU
    wire               ocu_done;
    wire     [4:0]     ocu_pointer;
    wire               ocu_rd_pulse;
    wire               wr_pulse;
    wire     [15:0]    DATA_WR;
    wire               T2_OT_PULSE;
    //wire               DR;
    wire               tag_data;
    ////////////////PMU
    wire               dec_en;
    wire               scu_en;
    wire               ocu_en;
    wire               init_en;
    wire               div_en;
    wire               vee_req;
    wire               vchk_en;
    wire               vee_err;
    wire               K60_EN;
    ////////////////DIV
    wire               DOUB_BLF;
    wire               clk_60k;
    wire     [8:0]     Tpri_10;
    ////////////////IE
    wire                ie_div_req;
    wire                ie_div_off;
    wire                ie_60k_req;
    wire                ie_60k_off;
    wire    [15:0]      mtp_data;
    wire                rd_done;
    wire                wr_done;
    wire                MRGSEL;
    wire                MRGEN;
    wire                DRT;
    wire                NVSTR;
    wire                PROG;
    wire                SE;
    wire                RECALL;
    wire                FE;
    wire    [4:0]       FUSEADR;
    ////////////////RNG
    wire               slot_valid;
    wire     [15:0]    rn16;
    wire     [15:0]    handle;
    ////////////////VERIFY
    wire     [7:0]     ver_code;
    wire               ver_done;
    ////////////////SCTRL
    wire               SRD;
    wire               S1UPD;
    wire               SXUPD;
    ////////////////SFLG
    wire               S1;
    wire               S2;
    wire               S3;
    wire               SL;
    
    //********************************************************// 
            
    INIT U_INIT(
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
                init_srd_pulse
            );
            
            
    DECODER U_DECODER(
                //inputs
                clk_1_92m,
                rst_n,
                dec_en,
                rd_data,
                cmd_end,
                Tpri_10,
                
                //outputs
                new_cmd,
                pie_clk,
                pie_data,
                TRcal,
                CRC_FLG,
                dec_done
            );
            
    CMD_PARSE U_CMD_PARSE(
                //inputs
                rst_n,
                DOUB_BLF,
                pie_clk,
                pie_data,
                CRC_FLG,
                new_cmd,
                dec_done,
                mtp_data,
                rd_done,
                rn16,
                handle,
                tag_state,
                pc_val[15:11],
                pwd_kill,
                pwd_acs,
                SS0,
                S1,
                SS2,
                SS3,
                SSL,
                
                //outputs
                parse_done,
                par_div_req,
                par_div_off,
                Q_update,
                Q,
                slot_update,
                membank,
                par_pointer,
                par_rd_pulse,
                target,
                action,
                cmd_head,
                pointer,
                length,
                session_match,
                session_val,
                flag_match,
                mask_match,
                trunc,
                EPC_SOA,
                rn_match,
                pwd_match,
                acs_status,
                kill_status,
                parse_err,
                DR,
                TRext,
                m_value,
                data_buffer,
                cmd_end,
                blc_update,
                ver_pulse,
                par_srd_pulse
            );
            
    SCU U_SCU(
                //inputs
                DOUB_BLF,
                rst_n,
                scu_en,
                target,
                action,
                cmd_head,
                session_match,
                flag_match,
                mask_match,
                trunc,
                rn_match,
                slot_valid,
                init_done,
                pwd_match,
                acs_status,
                kill_status,
                new_cmd,
                T2_OT_PULSE,
                session_val,
                S1,
                S2,
                S3,
                SL,
                
                //outpus
                scu_done,
                tag_state,
                bsc,
                rn16_update,
                handle_update,
                SADR,
                SUPD,
                SS0,
                SS1,
                SS2,
                SS3,
                SSL,                
                T2_CHK_EN
            );
            
    OCU U_OCU(
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
                DATA_WR,
                T2_OT_PULSE,
                tag_data
            );
            
    PMU U_PMU(
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
            
    DIV U_DIV(
                //inputs
                clk_1_92m,
                rst_n,
                TRcal,
                div_en,
                K60_EN,
                blc_update,
                DR,
					 clk_10m,
                
                //outputs
                DOUB_BLF,
                Tpri_10,
                clk_60k
            );
            
    IE U_IE(
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
                DBO,
                READY,
                
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
            
    RNG U_RNG(
                //inputs
                DOUB_BLF,
                rst_n,
                Q_update,
                Q,
                slot_update,
                handle_update,
                rn16_update,
                CRC16_EPC,
                init_done,
                
                //outputs
                slot_valid,
                rn16,
                handle
            );
            
    VERIFY U_VERIFY(
                //inputs
                DOUB_BLF,
                rst_n,
                new_cmd,
                ver_pulse,
                handle,
                
                //outputs
                ver_code,
                ver_done
            );
            
    SCTRL U_SCTRL(
                //inputs
                init_srd_pulse,
                par_srd_pulse,
                SUPD,
                SADR,
                
                //outputs
                SRD,
                S1UPD,
                SXUPD
            );
            
    SFLG U_SFLG(
                //inputs
                rst_n,
                SRD,
                SS1,
                SS2,
                SS3,
                SSL,
                S1UPD,
                SXUPD,
                
                //outputs
                S1,
                S2,
                S3,
                SL
            );
            
    
            
endmodule