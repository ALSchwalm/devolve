
module Mutator;
import std.random;

void swap(individual)(ref individual ind) {
    auto val = uniform(0, ind.length);
    ind[val]=uniform(0, 20);
};
