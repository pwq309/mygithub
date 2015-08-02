//-------------------------------------------------------
//Verilog simulation model for SMIC ee1k EEPMEM IP
//STATEMENT OF USE AND CONFIDENTIALITY:
//All comments included in this file are for SMIC reference only. SMIC
//has no obligation to guarantee its accuracy to customer.  
//History:
//2011-5-13  preliminary

`timescale 1ns / 1ns
`define UDLY #0

`define WIDTH   16		// width of memory
`define XDEP    6 		// width of x decoder
`define DEP     (`XDEP)		// depth of memory
`define SIZE    (2<<(`DEP-1 ))	// size of memory
`define LINES   (2<<(`XDEP-1))

module S018EE1KX16 (
                A,		    // I; address input
                RSTN,		// I; reset signal
                CEN,		// I; chip enable 
                OEN,		// I; output enable
                WEN,		// I; write enable
                CHER,		// I; chip erase
                CHWR,		// I; chip write
                EXCP,		// I; external program voltage input [Y/N]
                CLK1D92,    // I; write clock,1.92Mhz
                RD_CLK,     // I; read clock
                PCH,		// I; test option
                ERFL,		// I; test opition
                OPT,        // I; test option
                PT,		    // I; program time select; 
                ET,         // I; erase time select;
                WS,		    // I; signal to start write
                WSEN,		// I; enable/disable WS
                ITEST,      // I; test option
                //REF_BIAS,   // I, reference bias
                DBI,		// I; data input
                //IOUT,       // I/O; test pin
                //VPP0,       // I/O; high voltage in/out
                DBO,		// O; data output
                READY		// O; signal to show write ready or not
            );
            	
//inputs
input    [(`XDEP-1):0]     A;		
input                      RSTN;		
input                      CEN;		 
input                      OEN;		
input                      WEN;		
input                      CHER;		
input                      CHWR;		
input                      EXCP;		
input    		           CLK1D92;      
input                      RD_CLK;       
input    [2:0]             PCH;		
input                      ERFL;		
input                      OPT;          
input    [1:0]		       PT;		 
input    [1:0]	           ET;           
input    			       WS;		
input    			       WSEN;		
input    			       ITEST;        
//input                      REF_BIAS;     
input    [(`WIDTH-1):0]    DBI;		
//inout                      IOUT;         
//inout                      VPP0;

//outputs         
output   [(`WIDTH-1):0]    DBO;		
output                     READY;		

//regs         
reg      [(`WIDTH-1):0]    DBO;		
reg                        READY;
////////////////
reg      [(`WIDTH-1):0]    DMEM[`SIZE-1:0];
////////////////
//reg      [12:0]            wr_cnt;
wire                       wr_en;
reg                        wr_start;
//reg                        wr_end;

reg      [13:0]            clk1d92_count;
//wires
wire                       wr_clk;
//wire                       cen_clk;
//
integer                    k;

//always @(posedge wr_end or negedge RSTN)
//assign cen_clk = CEN&CLK1D92;

// initial
  // begin
      // DMEM[0] = 16'h0000;         //TBI.region of tag information, 8 words
      // DMEM[1] = 16'h0514;
      // DMEM[2] = 16'h0514;
      // DMEM[3] = 16'h0514;
      // DMEM[4] = 16'h0514;
      // DMEM[5] = 16'h0000;
      // DMEM[6] = 16'h0514;
      // DMEM[7] = 16'h0514;
	  
      // DMEM[8] = 16'h0301;         //UII, 17 words, EPC length is 3
      // DMEM[9] = 16'h0301;
      // DMEM[10] = 16'h0000;
      // DMEM[11] = 16'h0514;
      // DMEM[12] = 16'h0514;
      // DMEM[13] = 16'h0514;
      // DMEM[14] = 16'h0000;     
      // DMEM[15] = 16'h0000;
      // DMEM[16] = 16'h0514;
      // DMEM[17] = 16'h0514;
      // DMEM[18] = 16'h0514;
      // DMEM[19] = 16'h0000;
      // DMEM[20] = 16'h0000;
      // DMEM[21] = 16'h0000;
      // DMEM[22] = 16'h0000;
      // DMEM[23] = 16'h0000;
      // DMEM[24] = 16'h0000;
      // DMEM[25] = 16'h0514;       //kill pwd 
      // DMEM[26] = 16'h0514;     
      // DMEM[27] = 16'hFFFF;       //lock pwd
      // DMEM[28] = 16'hFFFF;
      // DMEM[29] = 16'hFFFF;       //lock state
	    // DMEM[30] = 16'hFFFF;       //kill state
	    // DMEM[31] = 16'h0000;
	    // DMEM[32] = 16'h0000;
	    // DMEM[33] = 16'h0000;
	    // DMEM[34] = 16'h0000;
	    // DMEM[35] = 16'h0000;
	    // DMEM[36] = 16'h0000;
	    // DMEM[37] = 16'h0000;
	    // DMEM[38] = 16'h0000;
	    // DMEM[39] = 16'h0000;
	    // DMEM[40] = 16'h1111;      //read pwd
	    // DMEM[41] = 16'h1111;
	    // DMEM[42] = 16'h2222;      //write pwd
	    // DMEM[43] = 16'h2222;
      // for(k=44; k<`SIZE;k=k+1)
        // DMEM[k]=16'h0000;
  // end



always @(posedge RD_CLK or negedge RSTN)
begin
    if(!RSTN)
        DBO<=`UDLY 16'h0000;
    else if(~CEN&~OEN)
        DBO<=`UDLY DMEM[A];
    else
        DBO<=`UDLY 16'h0000;
end

always @(negedge WEN or negedge RSTN)
begin
    if(!RSTN)
    begin
      DMEM[0] <=`UDLY 16'h0000;         //TBI.region of tag information, 8 words
      DMEM[1] <=`UDLY 16'h0514;
      DMEM[2] <=`UDLY 16'h0514;
      DMEM[3] <=`UDLY 16'h0514;
      DMEM[4] <=`UDLY 16'h0514;
      DMEM[5] <=`UDLY 16'h0000;
      DMEM[6] <=`UDLY 16'h0514;
      DMEM[7] <=`UDLY 16'h0514;
	  
      DMEM[8] <=`UDLY 16'h0301;         //UII, 17 words, EPC length is 3
      DMEM[9] <=`UDLY 16'h0301;
      DMEM[10] <=`UDLY 16'h0000;
      DMEM[11] <=`UDLY 16'h0514;
      DMEM[12] <=`UDLY 16'h0514;
      DMEM[13] <=`UDLY 16'h0514;
      DMEM[14] <=`UDLY 16'h0000;     
      DMEM[15] <=`UDLY 16'h0000;
      DMEM[16] <=`UDLY 16'h0514;
      DMEM[17] <=`UDLY 16'h0514;
      DMEM[18] <=`UDLY 16'h0514;
      DMEM[19] <=`UDLY 16'h0000;
      DMEM[20] <=`UDLY 16'h0000;
      DMEM[21] <=`UDLY 16'h0000;
      DMEM[22] <=`UDLY 16'h0000;
      DMEM[23] <=`UDLY 16'h0000;
      DMEM[24] <=`UDLY 16'h0000;
		
      DMEM[25] <=`UDLY 16'h0514;       //kill pwd 
      DMEM[26] <=`UDLY 16'h0514;     
      DMEM[27] <=`UDLY 16'hFFFF;       //lock pwd
      DMEM[28] <=`UDLY 16'hFFFF;
      DMEM[29] <=`UDLY 16'hFFFF;       //read pwd
	    DMEM[30] <=`UDLY 16'hFFFF;      
	    DMEM[31] <=`UDLY 16'h0000;      //write pwd
	    DMEM[32] <=`UDLY 16'h0000;
	    DMEM[33] <=`UDLY 16'h0000;      //lock state
	    DMEM[34] <=`UDLY 16'h0000;      //kill state
	    DMEM[35] <=`UDLY 16'h0000;
	    DMEM[36] <=`UDLY 16'h0000;
	    DMEM[37] <=`UDLY 16'h0000;
	    DMEM[38] <=`UDLY 16'h0000;
	    DMEM[39] <=`UDLY 16'h0000;
	    DMEM[40] <=`UDLY 16'h1111;      
	    DMEM[41] <=`UDLY 16'h1111;
	    DMEM[42] <=`UDLY 16'h2222;     
	    DMEM[43] <=`UDLY 16'h2222;
      for(k=44; k<`SIZE;k=k+1)
        DMEM[k]<=`UDLY 16'h0000;
    end
    else
	    DMEM[A]<=`UDLY DBI;
end

// always @(negedge WEN or negedge wr_end or negedge RSTN)
// begin
    // if(!RSTN)
        // wr_en<=`UDLY 1'b0;
    // else if(~WEN)
        // wr_en<=`UDLY 1'b1;
    // else
        // wr_en<=`UDLY 1'b0;
// end

// assign wr_clk=CLK1D92&wr_en;

// always @(posedge wr_clk or negedge RSTN)
// begin
    // if(!RSTN)
        // wr_cnt<=`UDLY 13'd0;
    // else
        // wr_cnt<=`UDLY wr_cnt+1'b1;
// end

// always @(negedge wr_clk or negedge RSTN)
// begin
    // if(!RSTN)
        // wr_start<=`UDLY 1'b0;
    // else if(wr_cnt==13'd127)
        // wr_start<=`UDLY 1'b1;
    // else 
        // wr_start<=`UDLY 1'b0;
// end

// always @(negedge wr_clk or negedge RSTN)
// begin
    // if(!RSTN)
        // wr_end<=`UDLY 1'b0;
    // else if(wr_cnt==13'd8191)
        // wr_end<=`UDLY 1'b1;
    // else 
        // wr_end<=`UDLY 1'b0;
// end


always @(negedge WEN or negedge RSTN)
begin
	  if(!RSTN)
	      wr_start<=`UDLY 1'b0;
	  else 
	      wr_start<=`UDLY 1'b1;
end
	
assign wr_en = wr_start&WEN;
	
assign wr_clk = wr_en&CLK1D92;

always @(posedge wr_clk or negedge RSTN)
begin
    if(!RSTN)
	    clk1d92_count<=`UDLY 14'd0;
	else
	    clk1d92_count<=`UDLY clk1d92_count+1'b1;
end

// always @(clk1d92_count)     //there may be a glitch
// begin
	// if((clk1d92_count>14'd300)&&(clk1d92_count<14'd9000))
	    // READY<=`UDLY 1'b0;
	// else
	    // READY<=`UDLY 1'b1;
// end	

always @(posedge CLK1D92 or negedge RSTN)
begin
    if(!RSTN)
	    READY<=`UDLY 1'b1;
	else if((clk1d92_count>14'd300)&&(clk1d92_count<14'd9000))
	    READY<=`UDLY 1'b0;
	else
	    READY<=`UDLY 1'b1;
end	


endmodule