module devolve.net.mutator;

import devolve.net.generator;
import std.random;

void randomWeight(Network n) {

    foreach(layer; n.hiddenLayers) {
        auto neuron = layer[uniform(0, $)];
        foreach(ref connection; neuron.connections) {
            connection.weight  = uniform(-2.0, 2.0);
        }
    }
}
