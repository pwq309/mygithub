// *******************************************************************
// COPYRIGHT, Xi'an XDU Radio-frequency IC Co.,Ltd 
// All rights reserved.
//
// IP NAME      :  RFID
// File name    :  DIV.v
// Module name  :  div
//
// Author       :  
// Email        : 
// Data         :  
// Version      :  v1.0 
// 
// Tech Info    :  
//
// Abstract     :  Acorrding to the NUDT protocol,the length of TC and one of the parameters of query
//                 command decided the BLF(Tpri) frequency,in order to get clk BLF,this module design an
//                 algorithm to divide 1.92M to DOUB_BLF
// Called by    :  RFID_TOP
// 
// Modification history
// -------------------------------------------------------------------
// $Log$
// VERSION             MOD CONTENT                 DATE              TIME                 NAME
//  
// *******************************************************************
`define UDLY 0
`timescale 1ns/1ns

module DIV (
            //inupts
            rst_n         ,   //gobal reset!
            clk_1_92m     , 	//Main clk!		
            div_en        ,   //from init			       
						TC_val        ,   //from cmd_parse						
						set_m         ,   //from cmd_parse
						DR            ,   //from cmd_parse
						
						//outupts
						DOUB_BLF     			//to most of module						
						);
						

input						rst_n        ;
input						clk_1_92m    ;
input		[7:0]	  TC_val       ; //TC length calculated by 1.92M    
input           div_en       ; //when to divide!
input           set_m        ; //set the time to get divide parameter M and N
input  [1:0]    DR           ; //divide rate,a parameter of query,DR=4,2,4/3,1              
 
output          DOUB_BLF     ; //double BLF(Tpri)

//output
reg             DOUB_BLF     ; 

//reg
reg     [4:0]   clk_cnt      ;
reg             clk_pre1     ;
reg             clk_pre2     ;
//reg             clk_3        ; 
//reg             clk_6        ; 
//reg             clk_12       ; 
reg             clk_pre1_dly ;
reg     [3:0]   M            ;
reg             N            ;
reg             L            ;
reg             div_clk_en   ;
//reg     [3:0]   clk_cnt      ;
//wire
//wire            clk_1_5      ; 
wire            div_clk      ;
//wire            clk_3_en     ; 
//wire            clk_6_en     ; 
//wire            clk_12_en    ; 
wire   [4:0]    max_cnt      ;
wire   [4:0]    clk1_flag    ;
wire   [4:0]    clk2_flag    ;


always @(posedge set_m or negedge rst_n)
begin 
    if(!rst_n)
    begin
        M<= #`UDLY 4'd12  ;
        N<= #`UDLY 1'b0   ;
        L<= #`UDLY 1'b1   ;
    end   
    else if(TC_val<8'd18)
		    case (DR)
		        2'b00:    
                begin
                    M<= #`UDLY 4'd1   ;
                    N<= #`UDLY 1'b1   ;
                    L<= #`UDLY 1'b0   ;
                end   
		        2'b01:   
                begin
                    M<= #`UDLY 4'd3   ;
                    N<= #`UDLY 1'b0   ;
                    L<= #`UDLY 1'b0   ;
                end   
		        2'b10:  
                begin
                    M<= #`UDLY 4'd6   ;
                    N<= #`UDLY 1'b0   ;
                    L<= #`UDLY 1'b1   ;
                end   
		        default: 
                begin
                    M<= #`UDLY 4'd12  ;
                    N<= #`UDLY 1'b0   ;
                    L<= #`UDLY 1'b1   ;
                end   
		    endcase
		else
		    case (DR)
		        2'b00:    
                begin
                    M<= #`UDLY 4'd3   ;
                    N<= #`UDLY 1'b0   ;
                    L<= #`UDLY 1'b0   ;
                end   
		        2'b01:     
                begin
                    M<= #`UDLY 4'd6   ;
                    N<= #`UDLY 1'b0   ;
                    L<= #`UDLY 1'b1   ;
                end   
		        2'b10:   
                begin
                    M<= #`UDLY 4'd12  ;
                    N<= #`UDLY 1'b0   ;
                    L<= #`UDLY 1'b1   ;
                end   
		        default: 
                begin
                    M<= #`UDLY 4'd12  ;
                    N<= #`UDLY 1'b0   ;
                    L<= #`UDLY 1'b1   ;
                end   
		    endcase
end	   

assign max_cnt = N?{M,1'b0}:(M-1'b1)     ;

assign div_clk = clk_1_92m & div_clk_en  ; 

always @(posedge clk_1_92m or negedge rst_n)
begin
    if(!rst_n) 
        div_clk_en <= #`UDLY 1'b0        ;
    else if(div_en)
        div_clk_en <= #`UDLY 1'b1        ;
    else if(clk_cnt == max_cnt)                     //Ensure that DOUB_BLF ends with neg-edge
        div_clk_en <= #`UDLY 1'b0        ;
    else
        div_clk_en <= #`UDLY div_clk_en  ;
end    

always @(posedge div_clk or negedge rst_n)
begin
	  if (!rst_n)
		    clk_cnt<=#`UDLY 5'b0          ;
		else if (clk_cnt==max_cnt) 
        clk_cnt<=#`UDLY 5'b0          ;	
		else
        clk_cnt<=#`UDLY clk_cnt+1'b1 ;		
end

//signals that used for integer div or half-integer division
assign clk1_flag = N?(M[3:1]+1'b1):M[3:1];    //both used for integer or half-integer division

assign clk2_flag = M + clk1_flag + 1'b1  ;    //only used for half-integer division

always @(posedge div_clk or negedge rst_n)
begin
	  if (!rst_n)
		    clk_pre1<=#`UDLY 1'b0          ;
		else if (clk_cnt < clk1_flag) 
        clk_pre1<=#`UDLY 1'b1         ;	
		else
        clk_pre1<=#`UDLY 1'b0         ;		
end	
	
always @(posedge div_clk or negedge rst_n)
begin
	  if (!rst_n)
		    clk_pre2<=#`UDLY 1'b0          ;
		else if ((clk_cnt > M)&&(clk_cnt < clk2_flag)) 
        clk_pre2<=#`UDLY 1'b1         ;	
		else
        clk_pre2<=#`UDLY 1'b0         ;		
end		

always @(negedge div_clk or negedge rst_n)
begin
	  if (!rst_n)
		    clk_pre1_dly <=#`UDLY 1'b0    ;
		else
        clk_pre1_dly <=#`UDLY clk_pre1;		
end		

always@(L or N or clk_pre1 or clk_pre1_dly or clk_pre2)
begin
	  if(N)
	      DOUB_BLF = clk_pre2 | clk_pre1_dly  ;
	  else if(L)
	      DOUB_BLF = clk_pre1 ;
	  else
	      DOUB_BLF = clk_pre1 | clk_pre1_dly;  
end

//assign clk_1_5=clk_pre1|clk_pre2          ;
//
//	
//assign clk_3_en=clk_1_5 & (M>2'd0)        ;
//assign clk_6_en=clk_3 &   (M>2'd1)        ;
//assign clk_12_en=clk_6 & (M>2'd2)       ;
//
//always @ (posedge clk_3_en or negedge rst_n)
//    begin
//	    if (!rst_n)
//		    clk_3<=#`UDLY 1'b0   ;
//		else
//            clk_3<=#`UDLY ~clk_3 ;	
//	end		
//	
//always @ (posedge clk_6_en or negedge rst_n)
//    begin
//	    if (!rst_n)
//		    clk_6<=#`UDLY 1'b0   ;
//		else
//            clk_6<=#`UDLY ~clk_6 ;	
//	end
//
//always @ (posedge clk_12_en or negedge rst_n)
//    begin
//	    if (!rst_n)
//		    clk_12<=#`UDLY 1'b0    ;
//		else
//            clk_12<=#`UDLY ~clk_12 ;	
//	end	
//	
//assign DOUB_BLF=(clk_1_5&(M==2'd0))|(clk_3&(M==2'd1))|(clk_6&(M==2'd2))|(clk_12&(M==2'd3)) ;

endmodule	