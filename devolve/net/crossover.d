module devolve.net.crossover;
import devolve.net.network;

import std.random;

/**
 * The new individual is a copy of one of the parents
 * selected at random.
 */
Network randomCopy(in Network ind1,
                   in Network ind2) {
    Network newInd;

    if (uniform(0, 2)) {
        newInd = ind1.clone();
    }
    else {
        newInd = ind2.clone();
    }
    return newInd;
}


unittest {
    import devolve.net;
    auto ga = new NetGA!(100,
                         testFitness,
                         generator.randomConnections!(11*14, 26, 1, 110, 10),
                         selector.roulette!2,
                         randomCopy);
}

/**
 * Create a new network by randomly copying the weights
 * of corresponding connections in ind2 to a clone of
 * ind1, maintaining the original connection with proability
 * 'probability'.
 */
Network randomMerge(float probability = 0.5)(in Network ind1,
                    in Network ind2) {
    
    Network newInd = ind1.clone();

    foreach(i, layer; newInd.hiddenLayers) {
        foreach(j, neuron; layer) {
            foreach(k, ref connection; neuron.connections) {
                if (ind2.hiddenLayers.length > i &&
                    ind2.hiddenLayers[i].length > j &&
                    ind2.hiddenLayers[i][j].connections.length > k &&
                    uniform(0, 2)) {
                    connection.weight = ind2.hiddenLayers[i][j].connections[k].weight;
                }
            }
        }
    }
    
    return newInd;
}

unittest {
    import devolve.net;
    auto ga = new NetGA!(100,
                         testFitness,
                         generator.randomConnections!(11*14, 26, 1, 110, 10),
                         selector.roulette!2,
                         randomMerge!0.8);
}
