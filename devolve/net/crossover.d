module devolve.net.crossover;
import devolve.net.generator;

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

