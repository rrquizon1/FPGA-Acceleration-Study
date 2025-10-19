`timescale 1ns / 1ps
//`define DEBUG
`include "include.v"
module neuron #(parameter layerNo=0,neuronNo=0,numWeight=784,dataWidth=16,sigmoidSize=10,weightIntWidth=4,actType="relu",biasFile="",weightFile="")(
    input           clk, //clk
    input           rst,//reset
    input [dataWidth-1:0]    myinput,
    input           myinputValid,//for inferencing
    input           weightValid,//for weight setting
    input           biasValid,//for bias setting
    input [31:0]    weightValue,
    input [31:0]    biasValue,
    input [31:0]    config_layer_num,
    input [31:0]    config_neuron_num,
    output[dataWidth-1:0]    out,
    output reg      outvalid   
    )/* synthesis syn_hier = "hard" */;
	
	parameter addressWidth=$clog2(numWeight);
	
	reg         wen;							//write enable 
	reg [addressWidth-1:0] w_addr;              // Write address for weight memory
    reg [addressWidth:0]   r_addr;              // Read address (1 bit wider to reach numWeight count)
    reg [dataWidth-1:0]    w_in;                // Data input for weights
    wire [dataWidth-1:0]   w_out;               // Data output (weight value) from memory
    (* use_dsp = "yes" *) reg [2*dataWidth-1:0]  mul;                 // Result of input ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚? weight multiplication
    reg [2*dataWidth-1:0]  sum;                 // Accumulator for summing multiplications
    reg [2*dataWidth-1:0]  bias;                // Bias term applied to the neuron output
    reg [31:0]             biasReg[0:0];        // Register array holding bias values
    reg                    weight_valid;        // Flag indicating weights are valid/loaded
    reg                    mult_valid;          // Flag indicating multiplier result is valid
    wire                   mux_valid;           // Flag for valid mux output (timing alignment)
    reg                    sigValid;            // Signal validity flag (general-purpose)
    wire [2*dataWidth:0]   comboAdd;            // Combined adder result (sum + mul, before bias)
    wire [2*dataWidth:0]   BiasAdd;             // Final adder result after adding bias
    reg  [dataWidth-1:0]   myinputd;            // Current input data value
    reg                    muxValid_d;          // Delayed version of mux_valid (pipeline stage 1)
    reg                    muxValid_f;          // Further delayed mux_valid (pipeline stage 2)
    reg                    addr=0;              // Control/addressing helper (possibly FSM flag)
	//Loading Weight Values into the memory
	
	always@(posedge clk)
	begin 
		if(rst)
			begin
				w_addr<={addressWidth{1'b1}};// makes w_addr all 1s
				wen<=0;
			end
		else if(weightValid & (config_layer_num==layerNo) &(config_neuron_num==neuronNo))//load the weights
			begin
				w_in<=weightValue;
				w_addr<=w_addr+1;
				wen<=1;
			end
				
			else begin
				wen<=0;
			end
	end

	assign mux_valid = mult_valid;
    assign comboAdd = mul + sum;
    assign BiasAdd = bias + sum;
    assign ren = myinputValid;

	`ifdef pretrained
		initial 
		begin
			$readmemb(biasFile,biasReg);//load bias via memory file
		end
		
		always@(posedge clk)
		begin
			bias<={biasReg[addr][dataWidth-1:0],{dataWidth{1'b0}}};
		end
		
	`else 
		always@(posedge clk)// load bias via circuit
			begin
				if(biasValid & (config_layer_num==layerNo) &(config_neuron_num==neuronNo))
					begin
						bias<={biasValue[dataWidth-1:0],{dataWidth{1'b0}}};
					end
			end
	`endif
	
    
    always @(posedge clk)
    begin
        if(rst|outvalid)
            r_addr <= 0;
        else if(myinputValid)
            r_addr <= r_addr + 1;
    end
    
    always @(posedge clk)
    begin
        mul  <= $signed(myinputd) * $signed(w_out); //input times weight
    end
    
	
	//*MACmultiply accumulate phase
	always @(posedge clk)
		begin
			if(rst|outvalid) begin
				sum<=0;
			end
			else if((r_addr==numWeight) & muxValid_f)
				begin	
					if(!bias[2*dataWidth-1] &!sum[2*dataWidth-1]&BiasAdd[2*dataWidth-1])begin ///If bias and sum are positive and after adding bias to sum, if sign bit becomes 1, saturate
						sum[2*dataWidth-1]<=1'b0;
						sum[2*dataWidth-2:0]<={2*dataWidth-1{1'b1}};
					end
					
					else if(bias[2*dataWidth-1] &sum[2*dataWidth-1]&!BiasAdd[2*dataWidth-1])begin
							sum[2*dataWidth-1]<=1'b1;
							sum[2*dataWidth-2:0]<={2*dataWidth-1{1'b0}};
					end
					
					else begin
						sum<=BiasAdd;	
					end
				end
		
			else if(mux_valid)
				begin	
					if(!mul[2*dataWidth-1] &!sum[2*dataWidth-1]&comboAdd[2*dataWidth-1])begin ///If combo and sum are positive and after adding bias to sum, if sign bit becomes 1, saturate
						sum[2*dataWidth-1]<=1'b0;
						sum[2*dataWidth-2:0]<={2*dataWidth-1{1'b1}};
					end
					
					else if(mul[2*dataWidth-1] &sum[2*dataWidth-1]&!comboAdd[2*dataWidth-1])begin
							sum[2*dataWidth-1]<=1'b1;
							sum[2*dataWidth-2:0]<={2*dataWidth-1{1'b0}};
					end
					
					else begin
						sum<=comboAdd;	
					end
						
				end
				
				
			

	end
	
	always @(posedge clk) 
	begin
		myinputd   <= myinput;                                // delay the input by 1 cycle to align with weight read
		weight_valid <= myinputValid;                         // delay input-valid by 1 cycle (aligns with weight fetched)
		mult_valid   <= weight_valid;                         // delay again by 1 cycle (aligns with multiplier result ready)
		sigValid     <= ((r_addr == numWeight) & muxValid_f)  // signal goes high when last input processed and bias added
                     ? 1'b1 : 1'b0;
		outvalid     <= sigValid;                             // final output is valid when sigValid is high
		muxValid_d   <= mux_valid;                            // store current mux_valid (delayed version for edge detection)
		muxValid_f   <= !mux_valid & muxValid_d;              // pulse high for 1 cycle when mux_valid falls (end of accumulation)
		
	end

    //Instantiation of Memory for Weights
    Weight_Memory #(.numWeight(numWeight),.neuronNo(neuronNo),.layerNo(layerNo),.addressWidth(addressWidth),.dataWidth(dataWidth),.weightFile(weightFile)) WM(
        .clk(clk),
        .wen(wen),
        .ren(ren),
        .wadd(w_addr),
        .radd(r_addr),
        .win(w_in),
        .wout(w_out)
    );
    

	generate 
		if (actType=="sigmoid")
		begin:siginst
			//instantiaton of ROM for sigmoid
			Sig_ROM #(.inWidth(sigmoidSize),.dataWidth(dataWidth)) s1(
			.clk(clk),
			.x(sum[2*dataWidth-1-:sigmoidSize]),
			.out(out)
			);
		end
		
		else 
		begin:ReLUinst
			ReLU #(.dataWidth(dataWidth),.weightIntWidth(weightIntWidth)) s1(
				.clk(clk),
				.x(sum),
				.out(out)
			);
		end
	endgenerate

	`ifdef DEBUG
	always@(posedge clk)
		begin
			if(outvalid)
				$display(neuronNo,,,"%b",out);
			end
		end
	`endif

endmodule