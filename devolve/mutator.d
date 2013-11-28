module devolve.mutator;
import std.random;
import std.algorithm;

void randomSwap(individual)(ref individual ind) {
    auto one = uniform(0, ind.length);
    auto two = uniform(0, ind.length);
    std.algorithm.swap(ind[one], ind[two]);
};

void randomRange(allele : allele[], allele low, allele high)(ref allele[] ind) {
    auto i = uniform(0, ind.length);
    ind[i] = cast(allele)(uniform(low, high));
}

