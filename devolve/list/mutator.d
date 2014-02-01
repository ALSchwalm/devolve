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

unittest {
    auto ind = [1, 2, 3, 4];
    auto prev = ind.dup;
    randomSwap(ind);
    assert(sort(prev) == sort(ind));
}

/**
 * Mutate an individual by replaceing a random allele
 * with a random value in the range [low, high)
 */
template randomRange(alias low, alias high) {

    ///
    void randomRange(individual)(ref individual ind) {
        alias allele = typeof(ind[0]);
        auto i = uniform(0, ind.length);
        ind[i] = cast(allele)(uniform(low, high));
    }
}

unittest {
    auto ind = [1, 2, 3, 4];
    auto prev = ind.dup;
    randomRange!(typeof(ind), 0, 10)(ind);
}
