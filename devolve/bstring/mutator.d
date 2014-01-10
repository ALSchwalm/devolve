module devolve.bstring.mutator;
import std.random;
import std.bitmanip;

void randomFlip(ref BitArray ind) {

    foreach(ref bit; ind) {
        if (uniform(0, 2)) {
            bit = !bit;
        }
    }
    
}
