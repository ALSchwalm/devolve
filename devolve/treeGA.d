module devolve.treeGA;
import devolve.tree.generator;
import devolve.tree.crossover;
import devolve.tree.mutator;

import std.random;
import std.typetuple;
import std.traits;
import std.conv;
import std.functional;
import std.stdio;

struct TreeGA(T,
              uint PopSize,
              uint depth,
              alias fitness,
              alias selector = top!(BaseNode!T, 2, fitness),
              alias crossover = singlePoint!T,
              alias mutator = randomBranch!T,
              alias comp = "a > b")
    if (PopSize > 0 &&
        is(ReturnType!mutator == void) &&
        is(ParameterTypeTuple!mutator == TypeTuple!(BaseNode!T, TreeGenerator!T)))
    {
    
        this(TreeGenerator!T g) {
            generator = g;
        }
        
        void setMutationRate(float rate) {
            mutationRate = rate;
        }

        void setStatFrequency(uint freq) {
            statFrequency = freq;
        }

        void evolve(uint generations) {
            
            foreach(uint i; 0..PopSize) {
                population ~= generator(depth);
            }
            
            //Perform evolution
            foreach(uint generation; 0..generations) {
            
                while(population.length < PopSize) {
                    population ~= crossover(population[uniform(0, population.length)],
                                            population[uniform(0, population.length)]);
                }

                foreach(uint i; 0..to!uint(PopSize*mutationRate)) {
                    mutator(population[uniform(0, PopSize)], generator);
                }

                selector(population);

                if (statFrequency && generation % statFrequency == 0) {
                    writeln("(gen ", generation, ") ",
                            "Top Score: ", fitness(population[0]),
                            ", Individual: ", population[0],
                            ", Height: ", population[0].getHeight());
                }
                if (generation == 0 || compFun(fitness(population[0]), fitness(best))) {
                    best = population[0];
                }
            }

            writeln("\n(Historical best) Score: ", fitness(best),
                    ", Individual: ", best);

        }


        alias binaryFun!(comp) _compFun;
        bool function(double, double) compFun = &_compFun!(double, double);

        float mutationRate = 0.1f;
        uint statFrequency = 0;

        TreeGenerator!T generator;
        BaseNode!T population[];
        BaseNode!T best;
}
