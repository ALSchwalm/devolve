module devolve.net.generator;

import std.typecons;
import std.random;
import std.conv;
import std.math;

///Convenience alias
alias HiddenLayer = HiddenNeuron[];

///Convenience alias
alias InputLayer = InputNeuron[];

///Convenience alias
alias OutputLayer = OutputNeuron[];

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
            assert(!isNaN(total));
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
        assert(!isNaN(val));
        return val;
    }

    override InputNeuron clone() const {
        auto input = new InputNeuron;
        input.val = val;
        return input;
    }

    double val;
}

/**
 * Class for neurons  which return the values
 */
class OutputNeuron : Neuron {
    override double eval() const {
        double total = 0;
        foreach(connection; connections) {
            total += connection.neuron.eval() * connection.weight;
            assert(!isNaN(total));
        }
        return tanh(total);
    }

    ///Create a new deep copy of the neuron
    override OutputNeuron clone() const {
        auto n = new OutputNeuron;
        n.connections = cloneConnections();
        return n;
    }
}

/**
 * Genome used with netGA. Represents a simple layered
 * neural network with inputs and outputs as doubles
 */
class Network
{
    ///Evaluate this network using the given inputs
    double[] opCall(in double[] inputs)
    in {
        assert(inputLayer.length == inputs.length);
    }
    body {
        foreach(i, ref neuron; inputLayer) {
            neuron.val = inputs[i];
        }

        double[] outputs;
        foreach(node; outputLayer) {
            outputs ~= node.eval();
        }
        return outputs;
    }

    ///Preform a deep copy of an existing network
    Network clone() const
    out (cloned) {
        assert(cloned.hiddenLayers.length == hiddenLayers.length);
        foreach(i, layer; hiddenLayers) {
            assert(cloned.hiddenLayers[i].length == layer.length);
        }
        assert(cloned.inputLayer.length == inputLayer.length);
        assert(cloned.outputLayer.length == outputLayer.length);
    }
    body {
        auto n = new Network();
        foreach(i, neuron; inputLayer) {
            n.inputLayer ~= neuron.clone();
        }

        n.hiddenLayers.length = hiddenLayers.length;
        foreach(i, layer; hiddenLayers) {
            foreach(neuron; layer) {
                n.hiddenLayers[i] ~= neuron.clone();
            }
        }

        foreach(i, neuron; outputLayer) {
            n.outputLayer ~= neuron.clone();
        }
        return n;
    }

    ///Array of inner layers
    HiddenLayer[] hiddenLayers;

    ///Layer of input neurons
    InputLayer inputLayer;

    ///Array of output neurons
    OutputLayer outputLayer;
}


/**
 * Generator to create neural net based genomes.
 * Params:
 *    inputLayerSize = Number of neurons in the input layer
 *    outputLayerSize = Number of neurons in the output layer
 *    hiddenLayers = Number of 'hidden' inner layers
 *    hiddenLayerMaxSize = Maximum number of neurons in each hidden layer
 *    maxConnections = Maximum number of connections for each neurons, minimum is
 *                     set to 1
 */
Network randomConnections( uint inputLayerSize, uint outputLayerSize,
                           uint hiddenLayers, uint hiddenLayerMaxSize,
                           uint maxConnections)()
out (net){
    assert(net.inputLayer.length == inputLayerSize);
    assert(net.hiddenLayers.length == hiddenLayers);
    assert(net.outputLayer.length == outputLayerSize);
    foreach(i; 0..hiddenLayers) {
        assert(net.hiddenLayers.length < hiddenLayerMaxSize);
    }
}
body {
    auto n = new Network;
        
    //Add input layer
    foreach(i; 0..inputLayerSize) {
        n.inputLayer ~= new InputNeuron;
    }
        
    //Add hidden layers
    foreach(i; 0..hiddenLayers) {
        HiddenLayer hidden;

        //There must be at least 1 neuron in a layer
        auto numLayerNeurons = uniform(1, hiddenLayerMaxSize);
            
        foreach(j; 0..numLayerNeurons)
        {
            auto hiddenNeuron = new HiddenNeuron;
            auto numConnections = uniform(0, maxConnections);
                
            foreach(_; 0..numConnections) {
                auto weight = uniform(-2.0, 2.0);
                Neuron connection;
                if (i == 0) {
                    connection = n.inputLayer[uniform(0, $)];
                }
                else {
                    connection = n.hiddenLayers[$-1][uniform(0, $)];
                }
                hiddenNeuron.connections ~= Neuron.Connection(weight, connection);
            }

            hidden ~= hiddenNeuron;
        }
        n.hiddenLayers ~= hidden;
    }

    //Add output layer
    foreach(i; 0..outputLayerSize) {
        auto outputNeuron = new OutputNeuron;

        foreach(j; 0..maxConnections) {
            auto weight = uniform(-2.0, 2.0);
            auto connection = n.hiddenLayers[$-1][uniform(0, $)];
            outputNeuron.connections ~= Neuron.Connection(weight, connection);
        }

        n.outputLayer ~= outputNeuron;
    }
    return n;
}
