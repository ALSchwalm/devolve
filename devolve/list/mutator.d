module devolve.list.mutator;
import std.random;
import std.algorithm;


/**
 * Mutate an individual by randomly swapping alleles
 */
void randomSwap(individual)(ref individual ind) {
    auto one = uniform(0, ind.length);
    auto two = uniform(0, ind.length);
    std.algorithm.swap(ind[one], ind[two]);
};

/**
 * Mutate an individual by replaceing a random allele
 * with a random value in the range [low, high)
 */
void randomRange(allele : allele[], allele low, allele high)(ref allele[] ind) {
    auto i = uniform(0, ind.length);
    ind[i] = cast(allele)(uniform(low, high));
}

