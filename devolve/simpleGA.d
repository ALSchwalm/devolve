module devolve.simpleGA;
import std.stdio;
import std.random;
import std.range;
import std.algorithm;
import std.math;
import std.conv;

struct SimpleGA(T, uint PopSize) {
    alias mutateFunc = void function(ref T);
    alias fitnessFunc = double function(ref const T);
    alias selectorFunc = void function(ref T[], fitnessFunc);
    alias crossoverFunc = T function(ref const T, ref const T);
    alias generatorFunc = T function();

    this(fitnessFunc _fitness,
         mutateFunc _mutate,
         selectorFunc _selector,
         crossoverFunc _crossover,
         generatorFunc _generator) {
        mutate=_mutate;
        fitness=_fitness;
        selector=_selector;
        crossover=_crossover;
        generator=_generator;
    }

    void setMutationRate(float rate) {
        mutationRate = rate;
    }

    void evolve(uint generations){
        
        //Add initial population
        foreach(uint i; 0..PopSize) {
            population ~= generator();
        }

        //Perform evolution
        foreach(uint generation; 0..generations) {
            
            while(population.length < PopSize) {
                population ~= crossover(population[uniform(0, population.length)],
                                        population[uniform(0, population.length)]);
            }

            foreach(uint i; 0..to!uint(PopSize*mutationRate)) {
                mutate(population[uniform(0, PopSize)]);
            }

            selector(population, fitness);
            
            writeln("Top Score: " ~ to!string(fitness(population[0])) ~
                    ", Individual: " ~ to!string(population[0]));
        }
    }

    immutable mutateFunc mutate;
    immutable fitnessFunc fitness;
    immutable selectorFunc selector;
    immutable crossoverFunc crossover;
    immutable generatorFunc generator;

    float mutationRate = 0.1f;

    T population[];
}
