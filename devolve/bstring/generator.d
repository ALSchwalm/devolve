module devolve.bstring.generator;
import devolve.bstring.bitset;

import std.random;

/**
 * Create the initial population using some preset value.
 * Examples:
 * --------------------
 * import devolve.bstring;
 * auto ga = new BStringGA!(5, 50, fitness,
 *                          generator.preset!(0, 1, 0, 0, 1));
 * --------------------
 * --------------------
 * //An empty preset is equivalent to filling in all zeros
 * auto ga = new BStringGA!(5, 50, fitness,
 *                          generator.preset!());
 * --------------------
 */
template preset (Alleles...) {
    ///
    auto preset(BString)() {
        BString a;

        foreach(i, allele; Alleles) {
            a[i] = cast(bool)(allele);
        }
        return a;
    }
}

unittest {
    BitSet!5 a;
    alias empty = preset!();
    assert(empty!(typeof(a)) == a);

    a = BitSet!5([0, 0, 1, 1, 0]);
    alias two = preset!(0, 0, 1, 1, 0);
    assert(a == two!(typeof(a)));
    assert(a != empty!(typeof(a)));
}

/**
 * Generate a random set of bits.
 * NOTE: The size paramter will be inferred by the GA
 */
auto random(BString)() {
    BString a;

    foreach(i, ref bit; a) {
        bit = cast(bool)(uniform(0, 2));
    }

    return a;
}

version(unittest) {
    double fitness(in BitSet!5 a) {return 1.0;}

    unittest {
        import devolve.bstring;
        auto ga = new BStringGA!(5, 50, fitness, random);

        BitSet!5 a = random!(BitSet!5);
        assert(!__traits(compiles, a = random!(BitSet!6)));
    }
}
