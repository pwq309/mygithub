//`timescale 1ns/1ns
//`define UDLY #5

`include "./macro.v"

module ANATENNA(
                //inputs
               // JUMP_TO_W,
                clk_50m,
                tag_data,
                rst_p,

                //outputs             
                rd_data,
					  led_sort,
					 led_query,
					 led_ack,
					 led_read,
					 led_write,
					 led_done
					 //reader_s_en,
					// signal
               //CLK_1_92M

                             
            );
            
    //inputs
 
  input    tag_data;
   input      clk_50m;

    input     rst_p;

    
    //outputs
	 //output   rst_p;
    //output   RESET;    
    output   rd_data;
	 output  led_sort;
    output  led_query;
    output  led_ack;
    output  led_read;
    output  led_write;
    output  led_done;

    //regs
    //reg       clk_50m;
    //reg       rst_p;
    
    //wire
wire    led_sort;
wire    led_query;
wire    led_ack;
wire    led_read;
wire    led_write;
wire    led_done;
wire    clk_1_92m;
wire    clk_10m;
//wire    RESET;
    
    //********************************************************//
	 
	 //assign rst_ext=~rst_p;
	 //assign rst_n=~rst_p;//&~sys_rst;
	 
	// assign RESET=rst_n;
	 
	// assign S1=1'b0;
	// assign S2=1'b0;
	// assign S3=1'b0;
	// assign SL=1'b0;
	 
	// assign CEN=1'b1;
    
    //********************************************************//
    /*	 
    RST U_RST(
                //inputs
                clk_50m,
                MOD_IN,
                rst_ext,
                
                //output
                sys_rst
            );
    */
	 wire      rst_n;
	// wire       reader_s_en;
	// assign   signal=~rd_data;
	assign  rst_n=~rst_p;
	 
	
	 
    CLK_GEN U_CLK_GEN(
                //inputs
                clk_50m,
                rst_n,
                
                //outputs
                clk_10m,
                clk_1_92m
            );
        

    
    INTERROGATOR_SYN U_INTERROGATOR_SYN(
                //inputs
                clk_10m,
                rst_n,
                tag_data,
                        
                //outputs
                rd_data,
					 led_sort,
					 led_query,
					 led_ack,
					 led_read,
					 led_write,
					 led_done
            );
   

	
	
endmodule