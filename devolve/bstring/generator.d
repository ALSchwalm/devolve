module devolve.bstring.generator;
import devolve.bstring.bitset;

/**
 * Create the initial population using some preset value.
 */
template preset (alias val) {
    ///
    auto preset(uint size)() {
        BitSet!size a = val;
        return a;
    }
}

