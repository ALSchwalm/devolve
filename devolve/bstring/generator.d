module devolve.bstring.generator;
import std.bitmanip;

/**
 * Create the initial population using some preset value.
 */
template preset (alias val) {
    auto preset(uint size)() {
        BitArray a;
        a.init(val);
        a.length = size;
        return a;
    }
}

