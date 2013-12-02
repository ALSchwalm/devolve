module devolve.listGA;
import std.stdio;
import std.random;
import std.algorithm;
import std.conv;
import std.traits;
import std.functional;

struct ListGA(T, uint PopSize) if (PopSize > 0 && isArray!T) {
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
        compFun = function(double a, double b) {return a > b;};
    }

    void setMutationRate(float rate) {
        mutationRate = rate;
    }

    void setStatFrequency(uint freq) {
        statFrequency = freq;
    }

    void setStatCompare(alias comp = "a > b")() {
        alias binaryFun!(comp) _compFun;
        compFun = &_compFun!(double, double);
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

            if (statFrequency && generation % statFrequency == 0) {
                writeln("(gen ", generation, ") ",
                        "Top Score: ", fitness(population[0]),
                        ", Individual: ", population[0]);
            }
            if (generation == 0 || compFun(fitness(population[0]), fitness(best))) {
                static if (isDynamicArray!T) {
                    best.length = population[0].length;
                }
                best[] = population[0][];
            }
        }

        writeln("(Historical best) Score: ", fitness(best),
                ", Individual: ", best);
    }

    immutable mutateFunc mutate;
    immutable fitnessFunc fitness;
    immutable selectorFunc selector;
    immutable crossoverFunc crossover;
    immutable generatorFunc generator;
    bool function(double, double) compFun;

    float mutationRate = 0.1f;
    uint statFrequency = 0;

    T population[];
    T best;
}
