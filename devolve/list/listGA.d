module devolve.list.listGA;
import devolve.baseGA;
import devolve.list.crossover;
import devolve.list.mutator;
import devolve.selector;

import std.stdio;
import std.random;
import std.algorithm;
import std.conv;
import std.traits;
import std.typetuple;

class ListGA(T,
             uint PopSize,
             alias fitness,
             alias generator,
             alias selector = top!(2, fitness),
             alias crossover = singlePoint!T,
             alias mutator = randomSwap!T,
             alias comp = "a > b") : BaseGA!(T, PopSize, comp)
    {
        this(){}

        this(float mutRate, uint statFreq) {
            m_mutationRate = mutRate;
            m_statFrequency = statFreq;
        }

        override T evolve(uint generations){

            //Add initial population
            foreach(i; 0..PopSize) {
                population ~= generator();
            }

            //Perform evolution
            foreach(generation; 0..generations) {

                while(population.length < PopSize) {
                    population ~= crossover(population[uniform(0, population.length)],
                                            population[uniform(0, population.length)]);
                }

                foreach(i; 0..to!uint(PopSize*m_mutationRate)) {
                    mutator(population[uniform(0, PopSize)]);
                }

                static if (isCallable!selector) {
                    selector(population); //if the user has defined their own selector
                }
                else {
                    selector!fitness(population);
                }


                if (m_statFrequency && generation % m_statFrequency == 0) {
                    writeln("(gen ", generation, ") ",
                            "Top Score: ", fitness(population[0]),
                            ", Individual: ", population[0]);
                }
                if (generation == 0 || compFun(fitness(population[0]), fitness(best))) {
                    static if (isDynamicArray!T) {
                        best.length = population[0].length;
                    }
                    best[] = population[0][];

                    if (m_termination != double.nan && compFun(fitness(best), m_termination)) {
                        writeln("\n(Termination criteria met) Score: ", fitness(best),
                                ", Individual: ", best);
                        break;
                    }
                }
            }

            writeln("\n(Historical best) Score: ", fitness(best),
                    ", Individual: ", best);
            return best;
        }
}
