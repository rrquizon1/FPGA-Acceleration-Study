`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.04.2019 15:57:43
// Design Name: 
// Module Name: top_sim
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: 
// 
//////////////////////////////////////////////////////////////////////////////////

`include "../source/impl_1/include.v"
//`include "include.v"
`define MaxTestSamples 500

module top_sim(

    );
    
    reg reset;
    reg clock;
    reg [`dataWidth-1:0] in;
    reg in_valid;
    //reg [`dataWidth-1:0] in_mem [784:0];
    reg [7:0] fileName[23:0];
    reg s_axi_awvalid;
    reg [31:0] s_axi_awaddr;
    wire s_axi_awready;
    reg [31:0] s_axi_wdata;
    reg s_axi_wvalid;
    wire s_axi_wready;
    wire s_axi_bvalid;
    reg s_axi_bready;
    wire intr;
    reg [31:0] axiRdData;
    reg [31:0] s_axi_araddr;
    wire [31:0] s_axi_rdata;
    reg s_axi_arvalid;
    wire s_axi_arready;
    wire s_axi_rvalid;
    reg s_axi_rready;
    reg [`dataWidth-1:0] expected;

    wire [31:0] numNeurons[31:1];
    wire [31:0] numWeights[31:1];
    
    assign numNeurons[1] = 30;
    assign numNeurons[2] = 30;
    assign numNeurons[3] = 10;
    assign numNeurons[4] = 10;
    
    assign numWeights[1] = 784;
    assign numWeights[2] = 30;
    assign numWeights[3] = 30;
    assign numWeights[4] = 10;
    
    integer right=0;
    integer wrong=0;
    
    zyNet dut(
    .s_axi_aclk(clock),
    .s_axi_aresetn(reset),
    .s_axi_awaddr(s_axi_awaddr),
    .s_axi_awprot(0),
    .s_axi_awvalid(s_axi_awvalid),
    .s_axi_awready(s_axi_awready),
    .s_axi_wdata(s_axi_wdata),
    .s_axi_wstrb(4'hF),
    .s_axi_wvalid(s_axi_wvalid),
    .s_axi_wready(s_axi_wready),
    .s_axi_bresp(),
    .s_axi_bvalid(s_axi_bvalid),
    .s_axi_bready(s_axi_bready),
    .s_axi_araddr(s_axi_araddr),
    .s_axi_arprot(0),
    .s_axi_arvalid(s_axi_arvalid),
    .s_axi_arready(s_axi_arready),
    .s_axi_rdata(s_axi_rdata),
    .s_axi_rresp(),
    .s_axi_rvalid(s_axi_rvalid),
    .s_axi_rready(s_axi_rready),
    .axis_in_data(in),
    .axis_in_data_valid(in_valid),
    .axis_in_data_ready(),
    .intr(intr)
    );
    
            
    initial
    begin
        clock = 1'b0;
        s_axi_awvalid = 1'b0;
        s_axi_bready = 1'b0;
        s_axi_wvalid = 1'b0;
        s_axi_arvalid = 1'b0;
    end
        
    always
        #5 clock = ~clock;
    
    function [7:0] to_ascii;
      input integer a;
      begin
        to_ascii = a+48;
      end
    endfunction
    
    always @(posedge clock)
    begin
        s_axi_bready <= s_axi_bvalid;
        s_axi_rready <= s_axi_rvalid;
    end
    
    task writeAxi(
    input [31:0] address,
    input [31:0] data
    );
    begin
        @(posedge clock);
        s_axi_awvalid <= 1'b1;
        s_axi_awaddr <= address;
        s_axi_wdata <= data;
        s_axi_wvalid <= 1'b1;
        wait(s_axi_wready);
        @(posedge clock);
        s_axi_awvalid <= 1'b0;
        s_axi_wvalid <= 1'b0;
        @(posedge clock);
    end
    endtask
    
    task readAxi(
    input [31:0] address
    );
    begin
        @(posedge clock);
        s_axi_arvalid <= 1'b1;
        s_axi_araddr <= address;
        wait(s_axi_arready);
        @(posedge clock);
        s_axi_arvalid <= 1'b0;
        wait(s_axi_rvalid);
        @(posedge clock);
        axiRdData <= s_axi_rdata;
        @(posedge clock);
    end
    endtask
    
  /*  task configWeights();
    integer i,j,k,t;
    integer neuronNo_int;
    reg [`dataWidth:0] config_mem [783:0];
    begin
        @(posedge clock);
        for(k=1;k<=`numLayers;k=k+1)
        begin
            writeAxi(12,k);//Write layer number
            for(j=0;j<numNeurons[k];j=j+1)
            begin
                neuronNo_int = j;
                fileName[0] = "f";
                fileName[1] = "i";
                fileName[2] = "m";
                fileName[3] = ".";
                if(j > 9)
                begin
                    fileName[4] = 48;
                    fileName[5] = 48;
                    i=0;
                    while(neuronNo_int != 0)
                    begin
                        fileName[i+4] = to_ascii(neuronNo_int%10);
                        neuronNo_int = neuronNo_int/10;
                        i=i+1;
                    end 
                    fileName[6] = "_";
                    fileName[7] = to_ascii(k);
                    fileName[8] = "_";
                    fileName[9] = "w";
                end
                else
                begin
                    fileName[4] = 48;
                    i=0;
                    while(neuronNo_int != 0)
                    begin
                        fileName[i+4] = to_ascii(neuronNo_int%10);
                        neuronNo_int = neuronNo_int/10;
                        i=i+1;
                    end 
                    fileName[5] = "_";
                    fileName[6] = to_ascii(k);
                    fileName[7] = "_";
                    fileName[8] = "w";
                end
                $readmemb(fileName, config_mem);
                writeAxi(16,j);//Write neuron number
                for (t=0; t<numWeights[k]; t=t+1) begin
                    writeAxi(0,{15'd0,config_mem[t]});
                end 
            end
        end
    end
    endtask*/
	task configWeights;
    integer i, j, k, t;
    integer neuronNo_int;
    reg [`dataWidth:0] config_mem [0:783];
    reg [8*20:1] fileName;  // fixed-size filename buffer (20 chars)
    reg [7:0] ascii_digit;
    integer tens, ones;
begin
    @(posedge clock);
    for (k = 1; k <= `numLayers; k = k + 1) begin
        writeAxi(12, k); // Write layer number

        for (j = 0; j < numNeurons[k]; j = j + 1) begin
            // Build filename like w_1_5.mif  (layer 1 neuron 5)
            // Start with all blanks
            fileName = {20{" "}};
            
            // Compose name manually (use rightmost chars)
            // Example: "w_1_5.mif"
            // We'll handle neuron number up to 2 digits and layer up to 9

            tens = j / 10;
            ones = j % 10;

            // Format manually: "w_" + layer + "_" + neuron + ".mif"
            fileName[8*1-:8]  = "w";
            fileName[8*2-:8]  = "_";
            fileName[8*3-:8]  = "0" + k;  // layer digit
            fileName[8*4-:8]  = "_";
            if (tens > 0)
                fileName[8*5-:8] = "0" + tens;
            else
                fileName[8*5-:8] = " ";
            fileName[8*6-:8]  = "0" + ones;
            fileName[8*7-:8]  = ".";
            fileName[8*8-:8]  = "m";
            fileName[8*9-:8]  = "i";
            fileName[8*10-:8] = "f";

            // Read MIF file
            $readmemb(fileName, config_mem);

            writeAxi(16, j); // Write neuron number
            for (t = 0; t < numWeights[k]; t = t + 1) begin
                writeAxi(0, {15'd0, config_mem[t]});
            end
        end
    end
end
endtask
    
/*    task configBias();
    integer i,j,k,t;
    integer neuronNo_int;
    reg [31:0] bias[0:0];
    begin
        @(posedge clock);
        for(k=1;k<=`numLayers;k=k+1)
        begin
            writeAxi(12,k);//Write layer number
            for(j=0;j<numNeurons[k];j=j+1)
            begin
                neuronNo_int = j;
                fileName[0] = "f";
                fileName[1] = "i";
                fileName[2] = "m";
                fileName[3] = ".";
                if(j>9)
                begin
                    fileName[4] = 48;
                    fileName[5] = 48;
                    i=0;
                    while(neuronNo_int != 0)
                    begin
                        fileName[i+4] = to_ascii(neuronNo_int%10);
                        neuronNo_int = neuronNo_int/10;
                        i=i+1;
                    end 
                    fileName[6] = "_";
                    fileName[7] = to_ascii(k);
                    fileName[8] = "_";
                    fileName[9] = "b";
                end
                else
                begin
                    fileName[4] = 48;
                    i=0;
                    while(neuronNo_int != 0)
                    begin
                        fileName[i+4] = to_ascii(neuronNo_int%10);
                        neuronNo_int = neuronNo_int/10;
                        i=i+1;
                    end 
                    fileName[5] = "_";
                    fileName[6] = to_ascii(k);
                    fileName[7] = "_";
                    fileName[8] = "b";               
                end
                $readmemb(fileName, bias);
                writeAxi(16,j);//Write neuron number
                writeAxi(4,{15'd0,bias[0]});
            end
        end
    end
    endtask*/
    task configBias;
    integer i, j, k;
    integer tens, ones;
    reg [31:0] bias [0:0];
    reg [8*20:1] fileName;  // fixed-size filename buffer
begin
    @(posedge clock);
    for (k = 1; k <= `numLayers; k = k + 1) begin
        writeAxi(12, k); // Write layer number

        for (j = 0; j < numNeurons[k]; j = j + 1) begin
            // Build filename like b_1_5.mif (layer 1 neuron 5)
            fileName = {20{" "}}; // initialize with blanks

            tens = j / 10;
            ones = j % 10;

            // Compose name: "b_" + layer + "_" + neuron + ".mif"
            fileName[8*1-:8]  = "b";
            fileName[8*2-:8]  = "_";
            fileName[8*3-:8]  = "0" + k;  // layer number
            fileName[8*4-:8]  = "_";
            if (tens > 0)
                fileName[8*5-:8] = "0" + tens;
            else
                fileName[8*5-:8] = " ";
            fileName[8*6-:8]  = "0" + ones;
            fileName[8*7-:8]  = ".";
            fileName[8*8-:8]  = "m";
            fileName[8*9-:8]  = "i";
            fileName[8*10-:8] = "f";

            // Optional: debug
            // $display("Reading bias file: %0s", fileName);

            // Read the bias value from MIF file
            $readmemb(fileName, bias);

            writeAxi(16, j); // Write neuron number
            writeAxi(4, {15'd0, bias[0]});
        end
    end
end
endtask

    /*reg [`dataWidth-1:0] in_mem [784:0];
    task sendData();
    //input [25*7:0] fileName;
    integer t;
    begin
        $readmemb(fileName, in_mem);
        @(posedge clock);
        @(posedge clock);
        @(posedge clock);
        for (t=0; t <784; t=t+1) begin
            @(posedge clock);
            in <= in_mem[t];
            in_valid <= 1;
            //@(posedge clock);
            //in_valid <= 0;
        end 
        @(posedge clock);
        in_valid <= 0;
        expected = in_mem[t];
    end
    endtask*/
	
reg [`dataWidth-1:0] in_mem [0:784];
//reg [8*20:1] fileName1;  // fixed-size filename buffer for input file
/*
task sendData;
    integer t;
begin
    // Read input data file
    $readmemb(fileName1, in_mem);

    // Optional debug
    // $display("Sending data from file: %0s", fileName);

    // Wait a few clock cycles before starting
    @(posedge clock);
    @(posedge clock);
    @(posedge clock);

    // Send 784 input values
    for (t = 0; t < 784; t = t + 1) begin
        @(posedge clock);
        in       <= in_mem[t];
        in_valid <= 1'b1;
    end

    @(posedge clock);
    in_valid <= 1'b0;

    // Last entry is the expected output
    expected = in_mem[784];
end
endtask*/

reg [8*64:1] fileName1; // 64 characters max

task sendData;
    integer t;
begin
    // Read input data file
    $readmemb(fileName1, in_mem);

    // Wait a few clock cycles before starting
    repeat(3) @(posedge clock);

    // Send 784 input values
    for (t = 0; t < 784; t = t + 1) begin
        @(posedge clock);
        in       <= in_mem[t];
        in_valid <= 1'b1;
    end

    @(posedge clock);
    in_valid <= 1'b0;

    // Last entry is the expected output
    expected = in_mem[784];
end
endtask
   
    integer i,j,layerNo=1,k;
    integer start;
    integer testDataCount;
    integer testDataCount_int;
    initial
    begin
        reset = 0;
        in_valid = 0;
        #100;
        reset = 1;
        #100
        writeAxi(28,0);//clear soft reset
        start = $time;
        `ifndef pretrained
            configWeights();
            configBias();
        `endif
        $display("Configuration completed",,,,$time-start,,"ns");
 for (testDataCount = 0; testDataCount < `MaxTestSamples; testDataCount = testDataCount + 1) begin
        // Generate filename like "test_data_0017.txt"
       // $sformatf(fileName1, "test_data_%04d.txt", testDataCount);
	   if (testDataCount<10) begin
	   $sformat(fileName1, "test_data_000%01d.txt", testDataCount);
	   end
	   
	   else if (testDataCount<100) begin
	   $sformat(fileName1, "test_data_00%02d.txt", testDataCount);
		end
		
	   else if (testDataCount<1000) begin
	   $sformat(fileName1, "test_data_0%03d.txt", testDataCount);
		end
        // Optional debug print
        $display("Loading input file: %0s", fileName1);

        // Send input data to DUT
        sendData();

        // Wait for computation to complete
        @(posedge intr);

        // Read classification result
        readAxi(8);

        // Compare output vs expected label
        if (axiRdData == expected)
            right = right + 1;

        // Display ongoing accuracy
        $display("%0d. Accuracy: %f%% | Detected: %0x | Expected: %0x",
                 testDataCount + 1,
                 right * 100.0 / (testDataCount + 1),
                 axiRdData, expected);

        /* Optional neuron output debug
        j = 0;
        repeat (10) begin
            readAxi(20);
            $display("Output of Neuron %d: %0x", j, axiRdData);
            j = j + 1;
        end
        */
    end

    // Final accuracy summary
    $display("Final Accuracy: %f%%", right * 100.0 / testDataCount);
    $stop;
	
    end
// Global Set/Reset (default internal connection to PUR)
  GSR GSR_INST (.GSR_N(1'b1),.CLK());

endmodule