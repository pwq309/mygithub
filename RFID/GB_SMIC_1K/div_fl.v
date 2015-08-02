`timescale 1ns/1ns
`define UDLY #5

module DIV_FL(
                //inputs
                base_clk,
                rst_n,
                M,
                N,
                div_en,
                
                //outputs
                doub_flc,
                clk_50k
            );
            
    //inputs
    input             base_clk;
    input             rst_n;
    input    [9:0]    M;
    input             N;
    input             div_en;
    
    //outputs
    output            doub_flc;
    output            clk_50k;
    
    //regs
    reg               clk_50k;
    reg               div_clk_en;
    reg      [9:0]    div_cnt;                                    //The count for doub_flc.
    reg      [7:0]    k50_cnt;
    reg               clk_buf_a;
    reg               clk_buf_b;
    reg               clk_buf_c;    
   
    wire              div_clk;                                    //The clock for doub_flc.
    wire     [9:0]    max_cnt;                                    //determine the point that the div_cnt reset.
    wire     [9:0]    high_range;                                 //the range of a high level.
    wire     [9:0]    low_range;                                  //the range of a low level. 
        
    //********************************************************//
    
    always @(negedge base_clk or negedge rst_n)
    begin
        if(!rst_n)
            div_clk_en<=`UDLY 1'b0;
        else if(div_en)
            div_clk_en<=`UDLY 1'b1;
        else if(div_cnt==6'd0)
            div_clk_en<=`UDLY 1'b0;
        else
            div_clk_en<=`UDLY div_clk_en;
    end
    
    assign div_clk=base_clk&div_clk_en;
    
    //Generate the clock doub_flc.
    assign doub_flc=N?(clk_buf_a|clk_buf_c):(clk_buf_a|clk_buf_b);
    
    assign high_range={1'b0,M[9:1]}+M[0];           //(M+1)/2
    assign low_range=M+N+high_range-M[0];           //2*[M/2+N/2]
    
    assign max_cnt={M[8:0],1'b0}+N-1'b1;
    
        
    //Count for the doub_flc.
    always @(posedge div_clk or negedge rst_n)
    begin
        if(!rst_n)
            div_cnt<=`UDLY 10'd0;
        else if(div_cnt==max_cnt)
            div_cnt<=`UDLY 10'd0;
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
    
    //********************************************************//
    
    always @(posedge div_clk or negedge rst_n)
    begin
        if(!rst_n)
            k50_cnt<=`UDLY 8'd0;
        else if(k50_cnt==8'd99)
            k50_cnt<=`UDLY 8'd0;
        else
            k50_cnt<=`UDLY k50_cnt+1'b1;
    end
    
    always @(negedge div_clk or negedge rst_n)
    begin
        if(!rst_n)
            clk_50k<=`UDLY 1'b0;
        else if(k50_cnt==0)
            clk_50k<=`UDLY ~clk_50k;
        else
            clk_50k<=`UDLY clk_50k;
    end
       
endmodule

