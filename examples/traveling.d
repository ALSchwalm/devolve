#!/usr/bin/env rdmd

import devolve.list;

import std.algorithm;

immutable uint[char[2]] distances;

static this() {
    //Distances between every city
    distances = [
        "ab": 20u,
        "ac": 42u,
        "ad": 35u,
        "bc": 30u,
        "bd": 34u,
        "cd": 12u
        ];
}

//An individual is an ordering of these 'cities'
alias individual = char[4];

/* 
 * Basic fitness function. Fitness is the total distance
 * traveled by following the input path.
 */
double fitness(in individual ind) {
    double total = 0;

    for(uint i=0; i < ind.length-1; ++i) {
        char lower = min(ind[i], ind[i+1]);
        char higher = max(ind[i], ind[i+1]);
        total += distances[[lower,  higher]];
    }
    return total;
};

void main() {

    auto ga = new ListGA!(
        
            //Population of 10 individuals
            individual, 10,
            
            //Fitness: The above fitness function
            fitness,
            
            //Generator: The initial population will be copies of 'cbad'
            generator.preset!('c', 'b', 'a', 'd'),
            
            //Selector: Select the top 2 individuals each generation
            selector.topPar!2,

            //Crossover: Just copy one of the parents
            crossover.randomCopy,

            //Mutation: Swap the alleles (cities)
            mutator.randomSwap,

            //Statistics must also know to record the historically lowest value
            //and selector should order with lowest value first (shortest distance)
            "a < b");

    //Set a 10% mutation rate
    ga.mutationRate = 0.1f;

    //Print statistics every 5 generations
    ga.statFrequency = 5;

    // Run for 30 generations. Converges rapidly on abcd or dcba
    ga.evolve(30);
    ga.statRecord.write;
}
