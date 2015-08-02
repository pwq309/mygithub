// ************************************************************** 
// COPYRIGHT, Xi'an XDU Radio-frequency IC Co.,Ltd 
// All rights reserved. 
// 
// IP LIB INDEX : IP lib index just sa UTOPIA_B 
// IP Name      : DIV
//
// File name    : div.v
// Module name  : DIV
// Full name    : DIV UNIT 
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
`define UDLY #5

module DIV(
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
            
            
    //inputs
    input             clk_1_92m;
    input             rst_n;
    input    [9:0]    TRcal;
    input             div_en;
    input             K60_EN;
    input             blc_update;
    input             DR;
    input             clk_10m;
    //outputs
    output            DOUB_BLF;
    output   [8:0]    Tpri_10;
    output            clk_60k;
    
    //regs
    reg               DOUB_BLF;
    reg      [5:0]    M;
    reg               N;    
    reg               div_clk_en;
    reg      [6:0]    div_cnt;                                    //The count for DOUB_BLF.
    reg               clk_buf_a;
    reg               clk_buf_b;
    reg               clk_buf_c;
    ////////////////
    reg               clk_60k;
    reg               clk_120k;
    reg               clk_240k;
    reg               clk_480k;
    reg               clk_960k;
    reg               clk_flag;
    wire     [8:0]    Tpri_10;
    wire     [9:0]    TRA4;
    wire     [10:0]   TRM3;
    wire     [5:0]    MT;
    wire              MTO;
    wire              NT;
    wire              M1N0;
    wire              div_clk;                                    //The clock for DOUB_BLF.
    wire     [6:0]    max_cnt;                                    //determine the point that the div_cnt reset.
    wire     [6:0]    high_range;                                 //the range of a high level.
    wire     [6:0]    low_range;                                  //the range of a low level.
    wire              clk_buf_d;
    
    
    //********************************************************//
    
    //10*Tpril for T1.
    assign Tpri_10=({M[4:0],4'b0000}+{M[4:0],2'b00})+({N,3'b000}+{N,1'b0});
    
    //3*TRcal+32
    assign TRM3={TRcal[9:0],1'b0}+TRcal;//+6'd32;
    
    //TRcal+4
    assign TRA4=TRcal;//+4'd4;
    
    //The temperary value of M.
    assign MT=(DR? TRM3[10:7] : TRA4[9:4]);
    
    //if M=0.
    assign MTO=(MT==6'd0);
    
    //The temperary value of N.
    assign NT=(MTO? 1'b0 : (DR? (TRM3[6:0]>7'd64) : (TRA4[3:0]>4'd8)));
    
    //Calculate the value of M.
    always @(posedge blc_update or negedge rst_n)
    begin
        if(!rst_n)
            M<=`UDLY 6'd8;
        else if(MTO)
    	    M<=`UDLY 6'd1;
    	else
    	    M<=`UDLY MT;
    end
    
    //Caculate the value of N.
    always @ (posedge blc_update or negedge rst_n)
    begin
        if(!rst_n)
            N<=`UDLY 1'b0;
    	else 
    	    N<=`UDLY NT;
    end
    
    assign M1N0=(M==6'd1&&N==1'b0);                  //Divided by one only.  
    
    //********************************************************//
    
    always @(negedge clk_1_92m or negedge rst_n)
    begin
        if(!rst_n)
            div_clk_en<=`UDLY 1'b0;
        else if(div_en)
            div_clk_en<=`UDLY 1'b1;
        else if(div_cnt==6'd0)                      //Ensure that DOUB_BLF ends with neg-edge.
            div_clk_en<=`UDLY 1'b0;
        else
            div_clk_en<=`UDLY div_clk_en;
    end   
    
    assign div_clk=clk_1_92m&div_clk_en&~M1N0;      //Switch on if divided by values which is bigger than one.    
    
    assign high_range={1'b0,M[5:1]}+M[0];           //(M+1)/2
    
    assign low_range=M+N+high_range-M[0];           //2*[M/2+N/2]
    
    assign max_cnt={M[5:0],1'b0}+N-1'b1;
        
    //Count for the DOUB_BLF.
    always @(posedge div_clk or negedge rst_n)
    begin
        if(!rst_n)
            div_cnt<=`UDLY 6'd0;
        else if(div_cnt==max_cnt)
            div_cnt<=`UDLY 6'd0;
        else
            div_cnt<=`UDLY div_cnt+1'b1;
    end
    
    //Generate the prime clcok:clk_buf_a.
    always @(negedge div_clk or negedge rst_n)
    begin
        if(!rst_n)
            clk_buf_a<=`UDLY 1'b0;
        else if(div_cnt<low_range)
            clk_buf_a<=`UDLY 1'b0;
        else
            clk_buf_a<=`UDLY 1'b1;
    end 
    
    //Generate the prime clcok:clk_buf_b.
    always @(negedge div_clk or negedge rst_n)
    begin
        if(!rst_n)
            clk_buf_b<=`UDLY 1'b0;
        else if(div_cnt<M-high_range)
            clk_buf_b<=`UDLY 1'b0;
        else if(div_cnt>=M)
            clk_buf_b<=`UDLY 1'b0; 
        else
            clk_buf_b<=`UDLY 1'b1;
    end 
    
    //clk_buf_b delay and generate clk_buf_c.
    always @(posedge div_clk or negedge rst_n)
    begin
        if(!rst_n)
            clk_buf_c<=`UDLY 1'b0;
        else
            clk_buf_c<=`UDLY clk_buf_b;
    end
    
    assign clk_buf_d=clk_1_92m&div_clk_en&M1N0;       //Switch on if divided by one.  
    
    //Generate the clock DOUB_BLF.    
    always @(M1N0 or N or clk_buf_a or clk_buf_b or clk_buf_c or clk_buf_d)
    begin
        if(M1N0)
            DOUB_BLF=clk_buf_d;
        else if(N)
            DOUB_BLF=clk_buf_a|clk_buf_c;
        else
            DOUB_BLF=clk_buf_a|clk_buf_b;
    end
    
    //********************************************************//
    
    //960k clock
    always @(posedge clk_1_92m or negedge rst_n)
    begin
        if(!rst_n)
            clk_960k<=`UDLY 1'b0;
        else if(K60_EN)
            clk_960k<=`UDLY ~clk_960k;
        else
            clk_960k<=`UDLY 1'b0;
    end
    
    //480k clock
    always @(posedge clk_960k or negedge rst_n)
    begin
        if(!rst_n)
            clk_480k<=`UDLY 1'b0;
        else
            clk_480k<=`UDLY ~clk_480k;
    end
    
    //240k clock
    always @(posedge clk_480k or negedge rst_n)
    begin
        if(!rst_n)
            clk_240k<=`UDLY 1'b0;
        else
            clk_240k<=`UDLY ~clk_240k;
    end
    
    //120k clock
    always @(posedge clk_240k or negedge rst_n)
    begin
        if(!rst_n)
            clk_120k<=`UDLY 1'b0;
        else
            clk_120k<=`UDLY ~clk_120k;
    end
    
    //60k clock
    always @(posedge clk_120k or negedge rst_n)
    begin
        if(!rst_n)
            clk_60k<=`UDLY 1'b0;
        else
            clk_60k<=`UDLY ~clk_60k;
    end 
       
 always @(posedge clk_10m or negedge rst_n)
    begin
        if(!rst_n)
            clk_flag<=`UDLY 1'b0;
        else if(clk_1_92m)
            clk_flag<=`UDLY 1'b1;
		 else
		      clk_flag<= `UDLY clk_flag;
    end 
endmodule
