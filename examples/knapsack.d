#!/usr/bin/env rdmd

import devolve.bstring;
import std.bitmanip;

immutable weights = [1, 4, 5, 12, 8, 3, 9, 10, 2, 4];
immutable capacity = 27;

double fitness(in BitArray ind) {
    auto total = 0;
    foreach(i, bit; ind ) {
        if (bit) {
            total += weights[i];
        }
    }
    if (total > capacity) {
        return 0;
    }
    return total;
}


void main() {

    auto ga = new BStringGA!(

            //One bit for each item
            weights.length,

            //Population of 10 individuals
            10,

            //Fitness: The above fitness function
            fitness,

            //Generator: The initial population will zero'd
            //   NOTE: equivalent to preset!([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
            generator.preset!([]),

            //Selector: Select the top 2 individuals each generation
            selector.top!2,

            //Crossover: Just copy one of the parents
            crossover.singlePoint,

            //Mutation: Randomly make a few new choices
            mutator.randomFlip);

    //Set a 10% mutation rate
    ga.mutationRate = 0.1f;

    //Score cannot be better than capacity
    ga.terminationValue = capacity;

    //Print statistics every 5 generations
    ga.statFrequency = 5;

    // Run for 30 generations. Converges rapidly on 27
    ga.evolve(30);
}
