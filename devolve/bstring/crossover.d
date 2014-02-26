module devolve.bstring.crossover;
import devolve.bstring.bitset;
import std.random;

/**
 * Create a new individual by taking all of the elements
 * from one individual after a randomly chosen point and
 * appending them to all of the values before that point
 * from another individual. Both parents must be of equal
 * length.
 * 
 * ind1 =   1001010110110 $(BR)
 * ind2 =   0010101010010 $(BR)
 * point =  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*
 *
 * child =  1001101010010
 */
auto singlePoint(size_t len)(in BitSet!len ind1,
                             in BitSet!len ind2) {

    auto point = uniform(0, len);

    BitSet!len child;

    foreach(i, ref bit; child) {
        if (i > point) {
            bit = ind1[i];
        }
        else {
            bit = ind2[i];
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

