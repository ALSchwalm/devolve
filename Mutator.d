
module Mutator;
import std.random;
import std.algorithm;

void swap(individual)(ref individual ind) {
    auto one = uniform(0, ind.length);
    auto two = uniform(0, ind.length);
    std.algorithm.swap(ind[one], ind[two]);
};
