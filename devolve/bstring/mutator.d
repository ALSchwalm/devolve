module devolve.bstring.mutator;
import devolve.bstring.bitset;
import std.random;

/**
 * For each bit in the individual, flip the 
 * bit with 'probability' probability. 
 */
template randomFlip(float probability = 0.5) {
    void randomFlip(size_t len)(ref BitSet!len ind) {
        foreach(ref bit; ind) {
            if (uniform(0.0, 1.0) <= probability) {
                bit = !bit;
            }
        }
    }
}

unittest {
    BitSet!10 set;
    randomFlip(set);

    import devolve.bstring;
    auto ga = new BStringGA!(5, 50, testFitness,
                             generator.random,
                             selector.topPar!2,
                             crossover.singlePoint,
                             randomFlip!0.8);

}

void randomSwap(size_t len)(ref BitSet!len ind) {
    auto one = uniform(0, len);
    auto two = uniform(0, len);

    auto temp = ind[one];
    ind[one] = ind[two];
    ind[two] = temp;
}


unittest {
    BitSet!10 set;
    randomFlip(set);

    import devolve.bstring;
    auto ga = new BStringGA!(5, 50, testFitness,
                             generator.random,
                             selector.topPar!2,
                             crossover.singlePoint,
                             randomSwap);

}

