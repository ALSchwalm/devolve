module devolve.bstring.crossover;
import devolve.bstring.bitset;
import std.random;

/**
 * Create a new individual by taking all of the elements
 * from one individual after a randomly chosen point and
 * appending them to all of the values before that point
 * from another individual.
 * 
 * ind1 =   1001010110110 $(BR)
 * ind2 =   0010101010010 $(BR)
 * point =  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*
 *
 * child =  1001101010010
 * NOTE: len will be inferred by the GA
 */
auto singlePoint(size_t len)(in BitSet!len parent1,
                             in BitSet!len parent2) {

    auto point = uniform(0, len);

    BitSet!len child;

    foreach(i, ref bit; child) {
        if (i > point) {
            bit = parent1[i];
        }
        else {
            bit = parent2[i];
        }
    }
    return child;
}


version(unittest) {
    double fitness(in BitSet!5) {return 1.0;}

    unittest {
        BitSet!10 a;
        BitSet!10 b;
        auto c = singlePoint(a, b);

        BitSet!11 d;
        assert(!__traits(compiles, singlePoint(a, d)));

        import devolve.bstring;
        auto ga = new BStringGA!(5, 50, fitness,
                                 generator.random,
                                 selector.topPar!2,
                                 singlePoint);
    }
}

/**
 * Create a new individual by taking all of the alleles
 * from one individual after a randomly chosen point and
 * before a different randomly chosen point and
 * trading them with the alleles from the other individual
 * which are within that range. 
 *
 * ind1 =    0000000000000 $(BR)
 * ind2 =    1111111111111 $(BR)
 * point1 =  &nbsp;&nbsp;* $(BR)
 * point2 =  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*
 *
 * result =  0011110000000
 * NOTE: len will be inferred by the GA
 */
auto twoPoint(size_t len)(in BitSet!len parent1,
                          in BitSet!len parent2) {

    auto point1 = uniform(0, len);
    auto point2 = uniform(0, len);
    BitSet!len child;

    foreach(i, ref bit; child) {
        if (i >= point1 && i < point2) {
            bit = parent1[i];
        } else {
            bit = parent2[i];
        }
    }

    return child;
}

unittest {
    BitSet!10 a;
    BitSet!10 b;
    auto c = twoPoint(a, b);

    BitSet!11 d;
    assert(!__traits(compiles, twoPoint(a, d)));

    import devolve.bstring;
    auto ga = new BStringGA!(5, 50, fitness,
                             generator.random,
                             selector.topPar!2,
                             twoPoint);
}
