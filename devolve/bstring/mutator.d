module devolve.bstring.mutator;
import devolve.bstring.bitset;
import std.random;

/**
 * For each bit in the individual, flip the 
 * bit with 50% probability. Resulting individual
 * length is unaffected.
 */
void randomFlip(bitset)(ref bitset ind) {
    foreach(ref bit; ind) {
        if (uniform(0, 2)) {
            bit = !bit;
        }
    }
}
