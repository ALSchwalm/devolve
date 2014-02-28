module devolve.net.mutator;

import devolve.net.network;
import std.random;

///Select a random node in each inner layer and set its
///connects to random weights in the range [lower, upper).
void randomWeight(double lower=-2.0, double upper=2.0)(Network n) {

    foreach(layer; n.hiddenLayers) {
        auto neuron = layer[uniform(0, $)];
        foreach(ref connection; neuron.connections) {
            connection.weight  = uniform(lower, upper);
        }
    }
}
