module devolve.net.generator;
import devolve.net.network;

import std.random;

/**
 * Generator to create neural net based genomes with a random number of connections
 * and hidden layer neurons.
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
                           uint maxConnections)() if (inputLayerSize > 0 &&
                                                      outputLayerSize > 0 &&
                                                      hiddenLayerMaxSize > 0 &&
                                                      maxConnections > 0)
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

unittest {
    import devolve.net;

    alias generator = randomConnections!(10, 10, 2, 10, 3);
    auto ga = new NetGA!(10, testFitness, generator);
}

/**
 * Creates a neural net with the given number of layers. Every node has
 * a connection to each node in the previous layer.
 *
 * Params:
 *    inputLayerSize = Number of neurons in the input layer
 *    outputLayerSize = Number of neurons in the output layer
 *    hiddenLayers = Number of 'hidden' inner layers
 *    hiddenLayerSize = Number of neurons in each hidden layer
 */
Network denseNet( uint inputLayerSize, uint outputLayerSize,
                  uint hiddenLayers, uint hiddenLayerSize)()
    if (inputLayerSize > 0 &&
        outputLayerSize > 0 &&
        hiddenLayers > 0 &&
        hiddenLayerSize > 0)
{
    auto n = new Network;

    //Add input layer
    foreach(i; 0..inputLayerSize) {
        n.inputLayer ~= new InputNeuron;
    }

    foreach(i; 0..hiddenLayers) {
        HiddenNeuron[] layer;
        foreach(j; 0..hiddenLayerSize) {
            layer ~= new HiddenNeuron;
        }

        foreach(neuron; layer) {
            auto weight = uniform(-2.0, 2.0);
            if (i == 0) {
                foreach(prevNeuron; n.inputLayer) {
                    neuron.connections ~= Neuron.Connection(weight, prevNeuron);
                }
            }
            else {
                foreach(prevNeuron; n.hiddenLayers[i-1]) {
                    neuron.connections ~= Neuron.Connection(weight, prevNeuron);
                }
            }
        }

        n.hiddenLayers ~= layer;
    }

    foreach(i; 0..outputLayerSize) {
        auto neuron =  new OutputNeuron;
        foreach(prevNeuron; n.hiddenLayers[$-1]) {
            auto weight = uniform(-2.0, 2.0);
            neuron.connections ~= Neuron.Connection(weight, prevNeuron);
        }
        n.outputLayer ~= neuron;
    }
    return n;
}

unittest {
    import devolve.net, std.algorithm;

    alias generator = denseNet!(10, 10, 2, 10);
    auto ga = new NetGA!(10, testFitness, generator);

    Network n = generator();

    //Check that the network actually has all the connections
    foreach(inputNeuron; n.inputLayer) {
        foreach(hiddenNeuron; n.hiddenLayers[0]) {
            assert(find!((a, b) => a.neuron == b.neuron)
                   (hiddenNeuron.connections, Neuron.Connection(0.0, inputNeuron)) != []);
        }
    }

    foreach(i, hiddenLayer; n.hiddenLayers) {
        if (i == 0){continue;}

        foreach(rightLayerNeuron; hiddenLayer) {
            foreach(leftLayerNeuron; n.hiddenLayers[i-1]) {
                assert(find!((a, b) => a.neuron == b.neuron)
                       (rightLayerNeuron.connections,
                        Neuron.Connection(0.0, leftLayerNeuron)) != []);
            }
        }
    }

    foreach(outputNeuron; n.outputLayer) {
        foreach(hiddenNeuron; n.hiddenLayers[$-1]) {
            assert(find!((a, b) => a.neuron == b.neuron)
                   (outputNeuron.connections, Neuron.Connection(0.0, hiddenNeuron)) != []);
        }
    }
}
