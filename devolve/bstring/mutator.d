module devolve.bstring.mutator;
import devolve.bstring.bitset;
import std.random;

/**
 * For each bit in the individual, flip the 
 * bit with 50% probability. Resulting individual
 * length is unaffected.
 */
void randomFlip(size_t len)(ref BitSet!len ind) {
    foreach(ref bit; ind) {
        if (uniform(0, 2)) {
            bit = !bit;
        }
    }
}

version(unittest) {
    double fitness(in BitSet!5) {return 1.0;}

    unittest {
        BitSet!10 set;
        randomFlip(set);

        import devolve.bstring;
        auto ga = new BStringGA!(5, 50, fitness,
                                 generator.random,
                                 selector.topPar!2,
                                 crossover.singlePoint,
                                 randomFlip);

    }
}

void randomSwap(size_t len)(ref BitSet!len ind) {
    auto one = uniform(0, len);
    auto two = uniform(0, len);

    auto temp = ind[one];
    ind[one] = ind[two];
    ind[two] = temp;
}

version(unittest) {
    unittest {
        BitSet!10 set;
        randomFlip(set);

        import devolve.bstring;
        auto ga = new BStringGA!(5, 50, fitness,
                                 generator.random,
                                 selector.topPar!2,
                                 crossover.singlePoint,
                                 randomSwap);

    }
}
