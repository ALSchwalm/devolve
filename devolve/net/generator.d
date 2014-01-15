module devolve.net.generator;

import std.typecons;
import std.random;
import std.conv;

///Convenience alias
alias Layer = Neuron[];


/**
 * Abstract class used to describe the neurons which make up 
 * the net.
 */
class Neuron {
    abstract double eval() const;
    abstract Neuron clone() const;

    ///Convenience alias
    alias Tuple!(double, "weight", Neuron, "neuron") Connection;
    
    ///Connected nodes
    Connection[] connections;

    protected Connection[] cloneConnections() const {
        Connection[] c;
        foreach(connection; connections) {
            c ~= Connection(connection.weight, connection.neuron.clone());
        }
        return c;
    }
}

/**
 * Class for neurons which exist on the hidden, inner layers
 * of the net.
 */
class HiddenNeuron : Neuron {
    override double eval() const {
        double total = 0;
        foreach(connection; connections) {
            total += connection.neuron.eval() * connection.weight;
        }
        return total;
    }

    ///Create a new deep copy of the neuron
    override HiddenNeuron clone() const {
        auto n = new HiddenNeuron;
        n.connections = cloneConnections();
        return n;
    }
}

/**
 * Class for neurons which exist on the input side of the graph
 */
class InputNeuron : Neuron {
    
    override double eval() const {
        return val;
    }

    override InputNeuron clone() const {
        return new InputNeuron;
    }

    double val;
}

/**
 * Class for neurons  which return the values
 */
class OutputNeuron : HiddenNeuron {}

class Network
{
    ///Evaluate this network using the given inputs
    double[] opCall(double[] inputs)
    in {
        assert(inputs.length == layers[0].length);
    }
    body {
        auto inputNeurons = to!(InputNeuron[])(layers[0]);
        foreach(i, neuron; inputNeurons) {
            neuron.val = inputs[i];
        }

        double[] outputs;
        foreach(node; layers[$-1]) {
            outputs ~= node.eval();
        }
        return outputs;
    }
    
    ///Preform a deep copy of an existing network
    Network clone() const
    out (cloned) {
        assert(cloned.layers.length == layers.length);
        foreach(i, layer; layers) {
            assert(cloned.layers[i].length == layer.length);
        }
    }
    body {
        auto n = new Network();
        foreach(i, layer; layers) {
            n.layers.length = layer.length;
            foreach(neuron; layer) {
                n.layers[i] ~= neuron.clone();
            }
        }
        return n;
    }

    ///Array of layers which make up the network, including input and output
    Layer[] layers;
}


/**
 * Generator to create neural net based genomes.
 */
struct NetGenerator {    
    /**
     * Constructor
     * Params:
     *    inputLayerSize = Number of neurons in the input layer
     *    outputLayerSize = Number of neurons in the output layer
     *    hiddenLayers = Number of 'hidden' inner layers
     *    hiddenLayerMaxSize = Maximum number of neurons in each hidden layer
     *    maxConnections = Maximum number of connections for each neurons, minimum is
     *                     set to 1
     */
    this(uint _inputLayerSize, uint _outputLayerSize,
         uint _hiddenLayers, uint _hiddenLayerMaxSize,
         uint _maxConnections) {
        inputLayerSize = _inputLayerSize;
        outputLayerSize = _outputLayerSize;
        hiddenLayerMaxSize = _hiddenLayerMaxSize;
        hiddenLayers = _hiddenLayers;
        maxConnections = _maxConnections;
    }

    ///Construct a Network using this generator
    auto opCall()
    out (net){
        assert(net.layers.length == hiddenLayers + 2);
        assert(net.layers[0].length == inputLayerSize);
        assert(net.layers[$-1].length == outputLayerSize);
        foreach(i; 1..net.layers.length-2) {
            assert(net.layers[i].length < hiddenLayerMaxSize);
        }
    }
    body {
        auto n = new Network;
        
        //Add input layer
        Layer input;
        foreach(i; 0..inputLayerSize) {
            input ~= new InputNeuron;
        }
        n.layers ~= input;

        //Add hidden layers
        foreach(i; 0..hiddenLayers) {
            Layer hidden;

            //There must be at least 1 neuron in a layer
            auto numLayerNeurons = uniform(1, hiddenLayerMaxSize);
            
            foreach(j; 0..numLayerNeurons)
            {
                auto hiddenNeuron = new HiddenNeuron;

                auto numConnections = uniform(0, maxConnections);
                foreach(k; 0..numConnections) {
                    auto weight = uniform(0.0, 2.0);
                    auto connection = n.layers[$-1][uniform(0, n.layers[$-1].length)];
                    hiddenNeuron.connections ~= Neuron.Connection(weight, connection);
                }

                hidden ~= hiddenNeuron;
            }
            n.layers ~= hidden;
        }

        //Add output layer
        Layer output;
        foreach(i; 0..outputLayerSize) {
            auto outputNeuron = new OutputNeuron;

            foreach(j; 0..maxConnections) {
                auto weight = uniform(0.0, 2.0);
                auto connection = n.layers[$-1][uniform(0, n.layers[$-1].length)];
                outputNeuron.connections ~= Neuron.Connection(weight, connection);
            }

            output ~= outputNeuron;
        }
        n.layers ~= output;
        return n;
    }

    ///
    immutable {
        uint hiddenLayers;
        uint hiddenLayerMaxSize;
        uint inputLayerSize;
        uint outputLayerSize;
        uint maxConnections;
    }
}
