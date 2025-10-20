This repository is a replication of the tutorial regarding FPGA AI accelerator from this [Youtube Playlist](https://www.youtube.com/watch?v=rw_JITpbh3k&list=PLJePd8QU_LYKZwJnByZ8FHDg5l1rXtcIq)

This whole sample project is an implementation of a simple neural network for classification of MNIST dataset. 

The neuron circuit is described by the image below taken from the original tutorial:

<img width="1000" height="900" alt="image" src="https://github.com/user-attachments/assets/9b3fffa8-1204-4b08-a235-52b2930571d7" />


The jupyter notebook trainNN generates the following:

    1. Generation of sigmoid memory file for sigmoid implementation in the neural network
    
    2. Generation of network weights and biases
    
    3. Generation of test data



The neural network for this example is structured like below:

<img width="1056" height="552" alt="image" src="https://github.com/user-attachments/assets/c162758b-f8a6-4116-99f1-eda727374f1e" />



The network accepts flattened inputs of the MNIST images with the first two layers having 30 neurons while the third and fourth have 10 neurons and a max finder at the final output.

The RTL files include the following:

* neuron.v- contains the neuron implementation
* include.v-contains all the defining variables including, datawidth, numLayers, activation,etc.
* Weight_Memory.v- memory module used for loading of weights
* Sig_ROM.v- memory module used for loading of sigmoid implementation
* Layer_x- modules for each layers
* zynet.v-top level of the neural network interfaced to an AXI4 lite bus
* relu.v- ReLU implementation, you can select this if youre using relu as activation
* tb.v- testbench for simulation
