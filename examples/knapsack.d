#!/usr/bin/env rdmd

import devolve.bstring;
import devolve.selector;

immutable weights = [1, 4, 5, 12, 8, 3, 9, 10, 2, 4];
immutable capacity = 27;

double fitness(ulong ind) {
    auto total = 0;
    foreach(i; 0..weights.length) {
        if (ind & 1) {
            total += weights[i];
        }
        ind >>= 1;
    }
    if (total > capacity) {
        return 0;
    }
    return total;
}


void main() {

    auto ga = new BStringGA!(
        
            //Population of 10 individuals
            weights.length, 10,
            
            //Fitness: The above fitness function
            fitness,
            
            //Generator: The initial population will zero'd
            preset!0,
            
            //Selector: Select the top 2 individuals each generation
            topPar!2,

            //Crossover: Just copy one of the parents
            XOR,

            //Mutation: Swap the alleles (cities)
            randomFlip);

    //Set a 10% mutation rate
    ga.mutationRate = 0.1f;

    //Print statistics every 5 generations
    ga.statFrequency = 5;

    // Run for 30 generations. Converges rapidly on abcd or dcba
    ga.evolve(30);
}
