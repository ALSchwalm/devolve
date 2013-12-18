module devolve.listGA;
import std.stdio;
import std.random;
import std.algorithm;
import std.conv;
import std.traits;
import std.functional;
import std.typetuple;

struct ListGA(T,
              alias mutate,
              alias fitness,
              alias selector,
              alias crossover,
              alias generator,
              uint PopSize)
    if (PopSize > 0 && isArray!T &&
        is(ReturnType!mutate == void) &&
        is(ParameterTypeTuple!mutate == TypeTuple!(T))
        &&
        is(ReturnType!fitness == double) &&
        is(ParameterTypeTuple!fitness == TypeTuple!(const T))
        &&
        is(ReturnType!selector == void) &&
        is(ParameterTypeTuple!selector == TypeTuple!(T[]))
        &&
        is(ReturnType!crossover == T) &&
        is(ParameterTypeTuple!crossover == TypeTuple!(const T, const T))
        &&
        is(ReturnType!generator == T))
    {

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

            selector(population);

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

    bool function(double, double) compFun;

    float mutationRate = 0.1f;
    uint statFrequency = 0;

    T population[];
    T best;
}
