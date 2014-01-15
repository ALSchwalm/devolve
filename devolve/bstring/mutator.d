module devolve.bstring.mutator;
import std.random;
import std.bitmanip;

/**
 * For each bit in the individual, flip the 
 * bit with 50% probability. Resulting individual
 * length is unaffected.
 */
void randomFlip(ref BitArray ind) {

    foreach(ref bit; ind) {
        if (uniform(0, 2)) {
            bit = !bit;
        }
    }
}
