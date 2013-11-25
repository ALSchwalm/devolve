
module Selector;
import std.algorithm;

void top(individual, int num)(ref individual[] population,
                          double function(ref const individual) fitness) {
    sort!((a, b)=> fitness(a) > fitness(b))( population);
    population.length = num;
};

