`timescale 1ns/1ns
`define UDLY #5

module DECODER_MILLIER(
                //inputs
                base_clk,
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
            
            
    //parameters
    parameter MAX_CNT=4'd7;                            //count from first one in preamble.
    
    //inputs
    input            base_clk;
    input            rst_n;
    input  [1:0]     m_value;
    input            tag_data;
    input            miller_en;
                
    //outputs
    output           miller_data;
    output           miller_clk;
    output [7:0]     miller_bltc;
    output           miller_start;
    output           miller_done;
    
    //regs
    reg              miller_data;    
    reg              miller_done;
    ////////
    reg              bl_buf_a;
    reg              bl_buf_b;
    reg              bl_buf_c;
    reg              bl_buf_d;
    reg              bl_buf_e;
    reg              bl_buf_f;
    reg    [7:0]     level_cnt;
    reg              cnt_en;
    reg              phase_pulse;
    reg    [7:0]     pulse_cnt;
    reg              bit_flg;
    reg              data_ctrl;
    reg    [3:0]     data_cnt;
    reg              miller_clk_en;
    reg    [7:0]     half_tpri;
    reg              cnt_pulse_en;
    reg    [1:0]     init_cnt;
    reg              start_ctrl;
    
    //wires
    wire             dec_clk;
    wire             rec_clk;
    wire             miller_clk;
    wire             miller_start;
    wire             fst_pulse;
    wire             thd_pulse;
    wire             fou_pulse;
    wire             cnt_pulse;
    wire             rst_done;
    ////////
    wire   [3:0]     pivot;
    wire   [7:0]     pivot_1;
    wire   [7:0]     pivot_2;
    wire   [7:0]     pivot_3;
    wire   [7:0]     HATPRI_0_5;
    wire   [7:0]     HATPRI_1_5;
    wire   [7:0]     HATPRI_2_5;
    wire             new_pulse;
    
    
    assign dec_clk=base_clk&miller_en;
    
    assign rst_done=rst_n&~miller_done;
    
    assign miller_bltc=half_tpri;
    
    always @(posedge dec_clk or negedge rst_n)
    begin
        if(!rst_n)
            bl_buf_a<=`UDLY 1'b0;
        else if(tag_data)
            bl_buf_a<=`UDLY 1'b1;
        else
            bl_buf_a<=`UDLY 1'b0;    
    end
    
    always @(negedge dec_clk or negedge rst_n)
    begin
        if(!rst_n)
            bl_buf_b<=`UDLY 1'b0;
        else if(bl_buf_a)
            bl_buf_b<=`UDLY 1'b1;
        else
            bl_buf_b<=`UDLY 1'b0;    
    end
    
    always @(posedge dec_clk or negedge rst_n)
    begin
        if(!rst_n)
            bl_buf_c<=`UDLY 1'b0;
        else if(bl_buf_b)
            bl_buf_c<=`UDLY 1'b1;
        else
            bl_buf_c<=`UDLY 1'b0;    
    end
    
    always @(negedge dec_clk or negedge rst_n)
    begin
        if(!rst_n)
            bl_buf_d<=`UDLY 1'b0;
        else if(bl_buf_c)
            bl_buf_d<=`UDLY 1'b1;
        else
            bl_buf_d<=`UDLY 1'b0;    
    end
    
    always @(posedge dec_clk or negedge rst_n)
    begin
        if(!rst_n)
            bl_buf_e<=`UDLY 1'b0;
        else if(bl_buf_d)
            bl_buf_e<=`UDLY 1'b1;
        else
            bl_buf_e<=`UDLY 1'b0;    
    end
    
    always @(negedge dec_clk or negedge rst_n)
    begin
        if(!rst_n)
            bl_buf_f<=`UDLY 1'b0;
        else if(bl_buf_e)
            bl_buf_f<=`UDLY 1'b1;
        else
            bl_buf_f<=`UDLY 1'b0;    
    end
    
    assign fst_pulse=bl_buf_a^bl_buf_b;
    assign sec_pulse=bl_buf_b^bl_buf_c;
    assign thd_pulse=bl_buf_c^bl_buf_d;
    assign fou_pulse=bl_buf_d^bl_buf_e;
    assign fif_pulse=bl_buf_e^bl_buf_f;
    
    always @(posedge fou_pulse or negedge rst_done)
    begin
        if(!rst_done)
            cnt_en<=`UDLY 1'b0;
        else
            cnt_en<=`UDLY 1'b1;
    end
    
    assign cnt_clk=dec_clk&cnt_en;
        
    always @(posedge cnt_clk or posedge fou_pulse or negedge rst_done)
    begin
        if(!rst_done)
            level_cnt<=`UDLY 8'd0;
        else if(fou_pulse)
            level_cnt<=`UDLY 8'd0;
        else
            level_cnt<=`UDLY level_cnt+1'b1;
    end
    
    always @(posedge fou_pulse or negedge rst_done)
    begin
        if(!rst_done)
            init_cnt<=`UDLY 2'd0;
        else if(init_cnt==2'd3)
            init_cnt<=`UDLY init_cnt;
        else
            init_cnt<=`UDLY init_cnt+1'd1;
    end
    
    always @(posedge thd_pulse or negedge rst_done)
    begin
        if(!rst_done)
            half_tpri<=`UDLY 8'hff;
        else if(init_cnt==2'd2)
            half_tpri<=`UDLY level_cnt;
        else
            half_tpri<=`UDLY half_tpri; 
    end
    
    assign HATPRI_0_5={1'b0,half_tpri[7:1]};    
    assign HATPRI_1_5=HATPRI_0_5+half_tpri;
    assign HATPRI_2_5={half_tpri[6:0],1'b0}+HATPRI_0_5;
    
    
    always @(posedge sec_pulse or posedge fou_pulse or negedge rst_n)
    begin
        if(!rst_n)
            phase_pulse<=`UDLY 1'b0;
        else if(fou_pulse)
            phase_pulse<=`UDLY 1'b0;
        else if(level_cnt>HATPRI_1_5)
            phase_pulse<=`UDLY 1'b1;
        else
            phase_pulse<=`UDLY 1'b0;
    end
    
    always @(posedge phase_pulse or negedge rst_done)
    begin
        if(!rst_done)
            cnt_pulse_en<=`UDLY 1'b0;
        else
            cnt_pulse_en<=`UDLY 1'b1;
    end
    
    assign cnt_pulse=fst_pulse&cnt_pulse_en;
    assign new_pulse=cnt_pulse&fou_pulse;
    //count for pulse.
    always @(posedge new_pulse or negedge rst_done)
    begin
        if(!rst_done)
            pulse_cnt<=`UDLY 8'd0;
        else if(fou_pulse)
            if(phase_pulse)
                pulse_cnt<=`UDLY 8'd0;
            else
                pulse_cnt<=`UDLY pulse_cnt;
        else
            pulse_cnt<=`UDLY pulse_cnt+1'b1;
    end
    
    assign pivot=(m_value==2'b01)? 4'd2 :
                 (m_value==2'b10)? 4'd4 : 
                 (4'd8          )       ;
    
    assign pivot_1={3'b000,pivot,1'b0}-'b1;
    assign pivot_3={2'b00,pivot,2'b00}-'b1;
    
    assign pivot_2={3'b000,pivot,1'b0};
    
    always @(posedge thd_pulse or negedge rst_done)
    begin
        if(!rst_done)
            miller_data<=`UDLY 1'b0;
        else if(phase_pulse)        
            if(pulse_cnt==pivot_1)
                if(bit_flg)
                    miller_data<=`UDLY 1'b1;
                else
                    miller_data<=`UDLY 1'b0;
            else if(pulse_cnt==pivot_3)
                miller_data<=`UDLY 1'b1;
            else
                if(bit_flg)
                    miller_data<=`UDLY 1'b0;
                else
                    miller_data<=`UDLY 1'b1;
        else if(pulse_cnt==pivot_2)
            if(bit_flg)
                miller_data<=`UDLY 1'b0;
            else
                miller_data<=`UDLY miller_data;
        else
            miller_data<=`UDLY miller_data;        
    end
    
    always @(posedge thd_pulse or negedge rst_done)
    begin
        if(!rst_done)
            bit_flg<=`UDLY 1'b1;
        else if(phase_pulse)        
            if(pulse_cnt==pivot_1)
                if(bit_flg)
                    bit_flg<=`UDLY 1'b1;
                else
                    bit_flg<=`UDLY 1'b0;
            else if(pulse_cnt==pivot_3)
                bit_flg<=`UDLY 1'b1;
            else
                if(bit_flg)
                    bit_flg<=`UDLY 1'b0;
                else
                    bit_flg<=`UDLY 1'b1;
        else
            bit_flg<=`UDLY bit_flg;        
    end
    
    always @(posedge thd_pulse or negedge rst_n)
    begin
        if(!rst_n)
            data_ctrl<=`UDLY 1'b0;
        else if(fif_pulse)
            data_ctrl<=`UDLY 1'b0;
        else if(phase_pulse)            
            data_ctrl<=`UDLY 1'b1;
        else if(pulse_cnt==pivot_2)
            if(bit_flg)
                data_ctrl<=`UDLY 1'b1;
            else
                data_ctrl<=`UDLY data_ctrl;
        else
            data_ctrl<=`UDLY data_ctrl;        
    end
    
    assign rec_clk=fou_pulse&data_ctrl;
    
    always @(posedge rec_clk or negedge rst_done)
    begin
        if(!rst_done)
            data_cnt<=`UDLY 4'd0;
        else if(data_cnt<MAX_CNT)
            data_cnt<=`UDLY data_cnt+1'b1;
        else
            data_cnt<=`UDLY data_cnt;
    end
    
    always @(negedge rec_clk or negedge rst_done)
    begin
        if(!rst_done)
            miller_clk_en<=`UDLY 1'b0;
        else if(data_cnt==MAX_CNT)
            miller_clk_en<=`UDLY 1'b1;
        else
            miller_clk_en<=`UDLY 1'b0;
    end
    
    assign miller_clk=rec_clk&miller_clk_en;
    
    always @(negedge base_clk or negedge rst_n)
    begin
        if(!rst_n)
            miller_done<=`UDLY 1'b0;
        else if(level_cnt==HATPRI_2_5)
            miller_done<=`UDLY 1'b1;
        else
            miller_done<=`UDLY 1'b0;
    end
    
    always @(posedge thd_pulse or negedge rst_done)
    begin
        if(!rst_done)
            start_ctrl<=`UDLY 1'b1;
        else
            start_ctrl<=`UDLY 1'b0;
    end
    
    assign miller_start=fst_pulse&start_ctrl;
    
endmodule
    