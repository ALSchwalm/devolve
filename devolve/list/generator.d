
module devolve.list.generator;
import std.random;

/*
 * Create the initial population by creating 'num' random
 * allels in the range [low, high).
 */
allele[] randRange(allele : allele[], uint num, allele low, allele high)() {
    allele[] i;
    foreach (x; 0..num) {
        i ~= cast(allele)(uniform(low, high));
    }
    return i;
}

/*
 * Create the initial population using some preset value.
 */
individual preset(individual, individual i)() {
    return i;
}
