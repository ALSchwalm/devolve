module devolve.net.network;

import std.typecons, std.algorithm, std.math;

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
