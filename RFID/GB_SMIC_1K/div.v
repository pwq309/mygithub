// ************************************************************** 
// COPYRIGHT, Xi'an XDU Radio-frequency IC Co.,Ltd 
// All rights reserved. 
// 
// IP LIB INDEX : 
// IP Name      : DIV
//
// File name    : div.v
// Module name  : DIV
// Full name    : DIV UNIT 
// 
// Author       : PanWanqiang
// Email        : pwq309@gmail.com
// Data         : 2013/6/21
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
`include "./macro.v"
`include "./timescale.v"

module DIV (
            //INPUTs
            rst_n         ,    //global reset!
            clk_1_92m     ,    //Main clk!		
            div_en        ,    //from init
		        set_m         ,    //from cmd_parse
		        DR            ,    //from cmd_parse
		   
		        //OUTPUTs
		        DOUB_BLF      

		        );

// ************************
// DEFINE INPUT(s)
// ************************
input       rst_n         ;
input       clk_1_92m     ;
input       div_en        ;
input       set_m         ;
input[ 3:0] DR            ;

// ************************                       
// DEFINE OUTPUT(s)                               
// ************************
output      DOUB_BLF	    ;

// ***************************                    
// DEFINE OUTPUT(s) ATTRIBUTE                     
// *************************** 
reg         DOUB_BLF	    ;

// *************************
// INNER SIGNAL DECLARATION
// *************************
reg  [ 4:0] M             ;
reg         N             ;
reg  [ 5:0] div_cnt       ;
reg         div_clk_en    ;
reg         clk_1         ;
reg         clk_2         ;
reg         clk_1_delay   ;

wire [ 5:0] max_cnt       ;
wire        div_clk       ;
wire [ 5:0] clk1_flag     ;
wire [ 5:0] clk2_flag     ;

// ************************
// MAIN CODE
// ************************

always @ (posedge set_m or negedge rst_n)
begin
    if(!rst_n)
	      begin
            M <= #`UDLY 5'd3     ;
		    	  N <= #`UDLY 1'b0     ;
		    end
    else
		    case(DR[2:0])
        3'b000:
			      begin
				        M <= #`UDLY 5'd15;
				        N <= #`UDLY 1'b0 ;
			      end
		    3'b001:
			      begin
				        M <= #`UDLY 5'd7 ;
				        N <= #`UDLY 1'b0 ;
			      end
        3'b010:
			      begin
				        M <= #`UDLY 5'd5 ;
				        N <= #`UDLY 1'b1 ;
			      end
        3'b011:
			      begin
				        M <= #`UDLY 5'd3 ;
				        N <= #`UDLY 1'b0 ;
			      end
        3'b100:
			      begin
				        M <= #`UDLY 5'd7 ;
				        N <= #`UDLY 1'b1 ;
			      end
        3'b101:
			      begin
				        M <= #`UDLY 5'd3 ;
				        N <= #`UDLY 1'b1 ;
			      end
		    3'b110:                   //divide 3
			      begin
				        M <= #`UDLY 5'd3 ;
				        N <= #`UDLY 1'b0 ;
			      end
        3'b111:
			      begin
				        M <= #`UDLY 5'd1 ;
				        N <= #`UDLY 1'b1 ;
			      end
		    default:
			      begin
				        M <= #`UDLY 5'd3 ;
				        N <= #`UDLY 1'b0 ;
			      end
        endcase
end
			
			
assign max_cnt = N?{M,1'b0}:(M-1'b1)     ;
	    
always @(negedge clk_1_92m or negedge rst_n)
begin
    if(!rst_n) 
        div_clk_en <= #`UDLY 1'b0        ;
    else if(div_en)
        div_clk_en <= #`UDLY 1'b1        ;
    else if(div_cnt == 6'd0)                     //Ensure that DOUB_BLF ends with neg-edge
        div_clk_en <= #`UDLY 1'b0        ;
    else
        div_clk_en <= #`UDLY div_clk_en  ;
end   

assign div_clk = clk_1_92m & div_clk_en  ;

//count for the DOUB_BLF.
always @(posedge div_clk or negedge rst_n)
begin
    if(!rst_n)
        div_cnt <= #`UDLY 6'd0           ;
    else if(div_cnt==max_cnt)
        div_cnt <= #`UDLY 6'd0           ;
    else
        div_cnt <= #`UDLY div_cnt+1'b1   ;
end

//signals that used for integer div or half-integer division
assign clk1_flag = N?(M[4:1]+1'b1):M[4:1];    //both used for integer or half-integer division
assign clk2_flag = M + clk1_flag + 1'b1  ;    //only used for half-integer division

//generate clk_1
always @(negedge div_clk or negedge rst_n)
begin
    if(!rst_n)
	    clk_1 <= #`UDLY 1'b0               ;
    else if(div_cnt < clk1_flag)
	    clk_1 <= #`UDLY 1'b1               ;
	else
	    clk_1 <= #`UDLY 1'b0               ;
end
	
//clk_1 delay half clk_1_92m and generate clk_1_delay
always @(posedge div_clk or negedge rst_n )
begin
    if(!rst_n)
	    clk_1_delay <= #`UDLY 1'b0         ;
	else
	    clk_1_delay <= #`UDLY clk_1        ;
end

//generate clk_2
always @(negedge div_clk or negedge rst_n)
begin
    if(!rst_n)
	    clk_2 <= #`UDLY 1'b0               ;
    else if((div_cnt > M)&&(div_cnt < clk2_flag))
	    clk_2 <= #`UDLY 1'b1               ;
	else
	    clk_2 <= #`UDLY 1'b0               ;
end

//generate DOUB_BLF
always @(N or clk_1 or clk_1_delay or clk_2)
begin
    if(!N)
	    DOUB_BLF = clk_1 | clk_1_delay     ;
	else
	    DOUB_BLF = clk_1_delay | clk_2     ;
end

endmodule












