module devolve.net.generator;

import std.typecons;
import std.random;
import std.conv;
import std.math;
import std.algorithm;

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

    ///Get the value of neuron.
    abstract double eval() const;

    ///Create a copy of this node. The new node will be unconnected
    abstract Neuron clone() const;

    ///Convenience alias
    alias Tuple!(double, "weight", Neuron, "neuron") Connection;
    
    ///Connected nodes
    Connection[] connections;
}

/**
 * Class for neurons which exist on the hidden, inner layers
 * of the net.
 */
class HiddenNeuron : Neuron {

    ///Find the value of the neuron by calculating the weighted sum of the connections
    override double eval() const {
        double total = 0;
        foreach(connection; connections) {
            total += connection.neuron.eval() * connection.weight;
        }
        return total;
    }

    ///Create a new copy of the neuron
    override HiddenNeuron clone() const {
        return new HiddenNeuron;
    }
}

/**
 * Class for neurons which exist on the input side of the graph
 */
class InputNeuron : Neuron {

    ///Returns the input neurons current value
    override double eval() const {
        return val;
    }

    ///Create a copy of the input neuron with its current value
    override InputNeuron clone() const {
        auto input = new InputNeuron;
        input.val = val;
        return input;
    }

    ///The current value of the input
    double val;
}

/**
 * Class for neurons  which return the values
 */
class OutputNeuron : Neuron {

    ///Evaluate the net by calculating the weighted sum of the connections.
    ///Hyperbolic tangent is called on the sum to map it onto the range (-1, 1)
    override double eval() const {
        double total = 0;
        foreach(connection; connections) {
            total += connection.neuron.eval() * connection.weight;
        }
        return tanh(total);
    }

    ///Create a new copy of the neuron
    override OutputNeuron clone() const {
        return new OutputNeuron;
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
                auto newNeuron = neuron.clone();
                
                const(Neuron)[] target;
                ulong index;
                Neuron newTarget;
                
                foreach(connection; neuron.connections) {
                    if (i > 0) {
                        target = find(hiddenLayers[i-1], connection.neuron);
                        index = hiddenLayers[i-1].length - target.length;
                        newTarget = n.hiddenLayers[i-1][index];
                    }
                    else {
                        target = find(inputLayer, connection.neuron);
                        index = inputLayer.length - target.length;
                        newTarget = n.inputLayer[index];
                    }
                    newNeuron.connections ~= Neuron.Connection(connection.weight,
                                                               newTarget);
                }

                n.hiddenLayers[i] ~= newNeuron;
            }
        }

        foreach(i, neuron; outputLayer) {
            auto newNeuron = neuron.clone();
            
            foreach(connection; neuron.connections) {
                auto target = find(hiddenLayers[$-1], connection.neuron);
                auto index = hiddenLayers[$-1].length - target.length;

                auto newTarget = n.hiddenLayers[$-1][index];
                newNeuron.connections ~= Neuron.Connection(connection.weight, newTarget);
            }
            n.outputLayer ~= newNeuron;
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
            auto numConnections = uniform(1, maxConnections);
                
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
