`timescale 1ns/1ns
`define UDLY #5

module DECODER_FM0(
                //inputs
                base_clk,
                rst_n,                
                tag_data,
                fm0_en,
                cmd_head,
                
                //outputs
                fm0_data,
                fm0_clk,
                fm0_bltc,
                fm0_start,
                fm0_done
            );
            
    //parameters
    parameter MAX_CNT_0=6'd11;       
    parameter MAX_CNT_1=6'd35; 
    //inputs
    input            base_clk;
    input            rst_n;
    input            tag_data;
    input            fm0_en;
    input  [4:0]     cmd_head;
                
    //outputs
    output           fm0_data;
    output           fm0_clk;
    output [7:0]     fm0_bltc;
    output           fm0_start;
    output           fm0_done;
    
    //regs
    reg              fm0_data;
    reg              fm0_done;
    ////////
    reg              bl_buf_a;
    reg              bl_buf_b;
    reg              bl_buf_c;
    reg              bl_buf_d;
    reg              bl_buf_e;
    reg              cnt_en;
    reg    [5:0]     data_cnt;
    reg    [7:0]     level_cnt;
    reg              zero_flg;
    reg              fm0_clk_en;
    reg              fm0_clk_en2;
    reg    [6:0]     fm0_clk_cnt;
    reg    [7:0]     half_tpri;
    reg              start_ctrl;
    
    //wires
    wire             dec_clk;
    wire             cnt_clk;
    wire             fm0_start;
    wire             valid_data;
    wire             fst_pulse;
    wire             sec_pulse;
    wire             thd_pulse;
    wire             rst_pulse;    
    wire             fm0_clk;
    wire             fm0_clk1;
    wire             rst_done;
    wire   [7:0]     pivot;
    wire   [7:0]     HATPRI_2_5;   
    
    assign dec_clk=base_clk&fm0_en;
    
    assign fm0_bltc=half_tpri;
    
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
    
    assign fst_pulse=bl_buf_a^bl_buf_b;
    assign sec_pulse=bl_buf_b^bl_buf_c;
    assign thd_pulse=bl_buf_c^bl_buf_d;
    assign rst_pulse=bl_buf_d^bl_buf_e;

    assign rst_done=rst_n&~fm0_done;
    assign cnt_clk=dec_clk&cnt_en;
    
    always @(posedge rst_pulse or negedge rst_done)
    begin
        if(!rst_done)
            cnt_en<=`UDLY 1'b0;
        else
            cnt_en<=`UDLY 1'b1;
    end
    
    always @(posedge cnt_clk or posedge rst_pulse or negedge rst_done)
    begin
        if(!rst_done)
            level_cnt<=`UDLY 8'd2;
        else if(rst_pulse)
            level_cnt<=`UDLY 8'd2;
        else
            level_cnt<=`UDLY level_cnt+1'b1;
    end
    
//    always @(posedge sec_pulse or negedge rst_n)
//    begin
//        if(!rst_n)
//            half_tpri<=`UDLY 8'd0;
//        else if(data_cnt==6'd1)
//            half_tpri<=`UDLY {1'b0,level_cnt[7:1]};//level_cnt[7:0]
//        else
//            half_tpri<=`UDLY half_tpri;
//    end

    always @(posedge sec_pulse or negedge rst_n)
    begin
        if(!rst_n)
            half_tpri<=`UDLY 8'd100;
        else if(data_cnt==4'd1)
            case(cmd_head)
            5'd9,
            5'd10,
            5'd4,
            5'd11,
            5'd12:
                half_tpri<=`UDLY level_cnt[7:0];
            default:
                half_tpri<=`UDLY {1'b0,level_cnt[7:1]};
            endcase
        else
            half_tpri<=`UDLY half_tpri;
    end


    assign pivot=half_tpri+{1'b0,half_tpri[7:1]};
    assign HATPRI_2_5={half_tpri[6:0],1'b0}+{1'b0,half_tpri[7:1]}+4;
    
    always @(posedge thd_pulse or negedge rst_done)
    begin
        if(!rst_done)
            data_cnt<=`UDLY 6'd0;
        else 
            case(cmd_head)
            5'd9,
            5'd10,
            5'd4,
            5'd11,
            5'd12:
                if(data_cnt<MAX_CNT_1)
                    data_cnt<=`UDLY data_cnt+1'b1;
                else
                    data_cnt<=`UDLY data_cnt;
            default:
                if(data_cnt<MAX_CNT_0)
                    data_cnt<=`UDLY data_cnt+1'b1;
                else
                    data_cnt<=`UDLY data_cnt;
            endcase
    end
    
    assign valid_data=(cmd_head==5'd9||cmd_head==5'd10||cmd_head==5'd4||cmd_head==5'd11||cmd_head==5'd12)?(data_cnt==MAX_CNT_1):(data_cnt==MAX_CNT_0);
    
    always @(posedge fst_pulse or negedge rst_n)
    begin
        if(!rst_n)
            zero_flg=1'b0;
        else if(zero_flg)
            zero_flg=1'b0;
        else if(valid_data)
            if(level_cnt<pivot)
                zero_flg=1'b1;
            else
                zero_flg=1'b0;            
        else
            zero_flg=1'b0;            
    end
    
    always @(posedge sec_pulse or negedge rst_done)
    begin
        if(!rst_done)
            fm0_data<=`UDLY 1'b0;
        else if(zero_flg)
            fm0_data<=`UDLY fm0_data;
        else if(valid_data)
            if(level_cnt>pivot)
                fm0_data<=`UDLY 1'b1;
            else
                fm0_data<=`UDLY 1'b0;
        else
            fm0_data<=`UDLY fm0_data;
    end
    
    always @(posedge rst_pulse or negedge rst_done)
    begin
        if(!rst_done)
            fm0_clk_en<=`UDLY 1'b0;
        else if(valid_data)
            fm0_clk_en<=`UDLY 1'b1;
        else
            fm0_clk_en<=`UDLY 1'b0;
    end

    assign fm0_clk1=thd_pulse&fm0_clk_en&~zero_flg;
    assign fm0_clk=fm0_clk1&fm0_clk_en2;
    
    always @(posedge fm0_clk1 or negedge rst_done)
    begin
    	  if(!rst_done)
    	      fm0_clk_cnt<=`UDLY 7'd0;
    	  else 
    	      fm0_clk_cnt<=`UDLY fm0_clk_cnt+1'b1;
    end
    
    always @(posedge fm0_clk1 or negedge rst_done)
    begin
    	  if(!rst_done)
    	      fm0_clk_en2<=`UDLY 1'b0;
    	  else if(cmd_head==5'd3&&fm0_clk_cnt<7'd15)
    	      fm0_clk_en2<=`UDLY 1'b1;
    	  else if(cmd_head==5'd2&&fm0_clk_cnt<7'd65)
    	      fm0_clk_en2<=`UDLY 1'b1;
    	  else if((cmd_head==5'd7||cmd_head==5'd8)&&fm0_clk_cnt<7'd39)
    	      fm0_clk_en2<=`UDLY 1'b1;
    	  else if((cmd_head==5'd14||cmd_head==5'd15)&&fm0_clk_cnt<7'd39)
    	      fm0_clk_en2<=`UDLY 1'b1;
    	  else if((cmd_head==5'd17||cmd_head==5'd18||cmd_head==5'd19)&&fm0_clk_cnt<7'd77)
    	      fm0_clk_en2<=`UDLY 1'b1;
    	  else if((cmd_head==5'd9||cmd_head==5'd10)&&fm0_clk_cnt<7'd93)
    	      fm0_clk_en2<=`UDLY 1'b1;
    	  else 
    	      fm0_clk_en2<=`UDLY 1'b0; 
    end	      
    
    
    
    always @(negedge base_clk or negedge rst_n)
    begin
        if(!rst_n)
            fm0_done<=`UDLY 1'b0;            
        else if(valid_data)
            if(level_cnt==HATPRI_2_5)
                fm0_done<=`UDLY 1'b1;
            else
                fm0_done<=`UDLY 1'b0;
        else
            fm0_done<=`UDLY 1'b0;
    end
    
    always @(posedge thd_pulse or negedge rst_done)
    begin
        if(!rst_done)
            start_ctrl<=`UDLY 1'b1;
        else
            start_ctrl<=`UDLY 1'b0;
    end
    
    assign fm0_start=fst_pulse&start_ctrl;
    
endmodule