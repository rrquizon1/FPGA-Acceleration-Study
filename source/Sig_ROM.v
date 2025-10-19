module Sig_ROM #(parameter inWidth=10,dataWidth=16) (
	input clk,
	input [inWidth-1:0] x,//address input size for the rom
	output [dataWidth-1:0] out// output
);


	reg [dataWidth-1:0] mem[2**inWidth-1:0];
	reg [inWidth-1:0] y;
	
	initial begin 
		$readmemb("sigContent.mif",mem);
	end
	
	always @(posedge clk) begin
		if($signed(x) >=0) begin
			y<=x+(2**(inWidth-1));// if input is positive
		end
		
		else begin
			y<=x-(2**(inWidth-1)); // if input is negative
		end
	
	end
	
	assign out=mem[y];

endmodule