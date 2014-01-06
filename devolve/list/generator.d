
module devolve.list.generator;
import std.random;

/**
 * Create the initial population by creating 'num' random
 * allels in the range [low, high).
 */
auto randRange(allele : allele[], uint num, allele low, allele high)() {
    allele[num] ind;
    foreach (i; 0..num) {
        ind[i] = cast(allele)(uniform(low, high));
    }
    return ind;
}

/**
 * Create the initial population using some preset value.
 */
auto preset(Alleles...)() {
    typeof(Alleles[0])[Alleles.length] ind;

    foreach(i, allele; Alleles) {
        ind[i] = allele;
    }
    
    return ind;
}
