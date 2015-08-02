`timescale 1ns/1ns
`define UDLY #5

module OPTIM_TOP(
                //inputs
					 clk_50m,
               // clk_1_92m,
                rst_p,
					 rd_data,
                //outputs
               
                tag_data
               
            );
            
            
    //wires
	 input          clk_50m;
   // input          clk_1_92m;
	 input          rst_p;
	 input          rd_data;
   
    //outputs
    
    output            tag_data;
  

    ////////ANTENNA
	 wire              clk_50m;
    wire              rst_p;
    wire              rd_data;
    wire              clk_1_92m;
    wire              vee_rdy;
    wire              S1;
    wire              S2;
    wire              S3;
    wire              SL;
    wire              ECLK;
    wire              TCLK;
    ////////OPTIM
    wire             tag_data;
    wire             vee_req;
    wire             vchk_en;
    wire             MRGSEL;
    wire             MRGEN;
    wire             DRT;
    wire             NVSTR;
    wire             PROG;
    wire             SE;
    wire             RECALL;
    wire             FE;
    wire    [4:0]    FUSEADR;
    wire    [15:0]   DATA_WR;
    ////////////////TEST 
    wire             DOUB_BLF;
    wire             dec_en;
    wire             scu_en;
    wire             ocu_en;
    wire             rd_done;
    wire             wr_done;
    wire   [4:0]     cmd_head;
    wire   [3:0]     tag_state;
    ////////MTP18G32X16
    wire     [15:0]   DBO;		
    wire              READY;   
////////////////////////////////
    wire  clk_10m;
    wire  sys_rst;	 
    assign rst_n= ~rst_p;
  /*  
    V1_ALL U_ANA(
                //inputs
                tag_data,                
                vee_req,
                
                //outputs
                rst_n,                
                rd_data,
                clk_1_92m,
                REF_BIAS,
                VDD_OSC,
                VDD_RECT,
                VDD,                
                VDD2,
                VDD3,
                VSS      
            );
    */        
    OPTIM U_OPTIM(
                //inputs
                clk_1_92m,
                rst_n,
                rd_data,
                1'b1,
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
            
    MTP18G32X16 U_MEM(
                //inputs
                //rst_n,
                DATA_WR,
                FUSEADR,
                FE,
                RECALL,
                SE,
                PROG,
                NVSTR,
                DRT,
                MRGEN,
                MRGSEL,
                
                //outputs
                DBO,
                READY
            ); 
				
  CLK_GEN U_CLK_GEN(
                //inputs
                clk_50m,
                rst_n,
                
                //outputs
                clk_10m,
					 clk_1_92m
					 );
            
			
  RST  U_RST(
                //inputs
                clk_50m,
                rd_data,
                rst_n,
                
                //output
                sys_rst
            );       
endmodule 