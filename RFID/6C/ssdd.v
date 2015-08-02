`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   16:37:40 05/29/2013
// Design Name:   OPTIM_TOP
// Module Name:   D:/PRJDIR/ISEPRJ/S_6C_512/ssdd.v
// Project Name:  S_6C_512
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: OPTIM_TOP
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module ssdd;

	// Inputs
	reg clk_50m;
	reg rst_p;
	reg rd_data;

	// Outputs
	wire tag_data;


	// Instantiate the Unit Under Test (UUT)
	OPTIM_TOP uut (
		.clk_50m(clk_50m), 
		.rst_p(rst_p), 
		.rd_data(rd_data), 
		.tag_data(tag_data)
		
	);

	initial begin
		// Initialize Inputs
		clk_50m = 0;
		rst_p = 0;
		rd_data = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
      
endmodule

