module ReLU #(parameter dataWidth=16, weightIntWidth=4)(// truncating
	input clk, 
	input [2*dataWidth-1:0] x,
	output reg [dataWidth-1:0] out


);

	always @(posedge clk)
	begin
		if ($signed (x)>=0) begin
			if (|x[2*dataWidth-1-:weightIntWidth+1]) begin//ooverflow to sign bit of integer part If first int width are 1s, it means voerflow
				out<={1'b0,{(dataWidth-1){1'b1}}};//turn all 1s datawidth
			end
			else begin
				out<=x[2*dataWidth-1-weightIntWidth-:dataWidth];//
			end
		
		
		end
		
		else begin
			out<=0;
		end
	
	
	
	end




endmodule