
//`include "./timescale.v"
`include "D:/xilinx/12.4/xlinx_work/NUDT_1K_BASEBAND/timescale.v"
`include "D:/xilinx/12.4/xlinx_work/NUDT_1K_BASEBAND/macro.v"

module ANATENNA(
                //inputs

                clk_50m,
                tag_data,
                rst_p,

                //outputs             
                rd_data,
                rst_n,
                clk_1_92m
					  // led_sort,
					 // led_query,
					 // led_ack,
					 // led_read,
					 // led_write,
					 // led_done                        
            );
            
    //inputs
 
    input    tag_data;
    input      clk_50m;
    input     rst_p;

    //outputs  
    output   rd_data;
    output   rst_n;
    output   clk_1_92m;

	 // output  led_sort;
    // output  led_query;
    // output  led_ack;
    // output  led_read;
    // output  led_write;
    // output  led_done;

// wire    led_sort;
// wire    led_query;
// wire    led_ack;
// wire    led_read;
// wire    led_write;
// wire    led_done;
    wire     rd_data;
    wire     clk_1_92m;
    wire     clk_10m;
	  wire     rst_n;
   


	assign  rst_n=~rst_p;
	 
	
	 
    CLK_GEN U_CLK_GEN(
                //inputs
                .clk_50m(clk_50m),
                .rst_n(rst_n),
                
                //outputs
                .clk_10m(clk_10m),
                .clk_1_92m(clk_1_92m)
            );
        

    
    INTERROGATOR_SYN U_INTERROGATOR_SYN(
                //inputs
                .clk_10m(clk_10m),
                .rst_n(rst_n),
                .tag_data(tag_data),
                        
                //outputs
                .rd_data(rd_data)
					 // .led_sort(led_sort),
					 // .led_query(led_query),
					 // .led_ack(led_ack),
					 // .led_read(led_read),
					 // .led_write(led_write),
					 // .led_done(led_done)
            );
   

	
	
endmodule