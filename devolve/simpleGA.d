module devolve.simpleGA;
import devolve.baseGA;

import std.traits, std.random, std.conv;

/**
 * An abstract class providing some default implimentations for 
 * the phases of evolution.
 */
class SimpleGA(T, uint PopSize,
               alias comp,
               alias fitness,
               alias generator,
               alias selector,
               alias crossover,
               alias mutator) : BaseGA!(T, PopSize, comp) {


    ///Add initial population using generator
    override void generation() {
        //Add initial population
        foreach(i; 0..PopSize) {
            static if (isCallable!generator) {
                population ~= generator();
            }
            else {
                population ~= generator!T();
            }
        }
    }

    ///Preform add new members by crossing-over the population left
    ///after selection, keeping 'crossoverRate' precent in the population.
    override void crossingOver() {
        T[] nextPopulation;

        nextPopulation.length = cast(ulong)(population.length*m_crossoverRate);
        nextPopulation[] = population[0..nextPopulation.length];

        while(nextPopulation.length < PopSize) {
            nextPopulation ~= crossover(population[uniform(0, population.length)],
                                        population[uniform(0, population.length)]);
        }

        population = nextPopulation;
    }

    ///Preform mutation on members of the population
    override void mutation() {
        //If multiple mutations are used
        static if (__traits(compiles, mutator.joined)) {
            foreach(mutatorFun; mutator.joined) {
                foreach(i; 0..to!uint(PopSize*m_mutationRate/mutator.joined.length)) {
                    mutatorFun(population[uniform(0, PopSize)]);
                }
            }
        }
        else {
            foreach(i; 0..to!uint(PopSize*m_mutationRate)) {
                mutator(population[uniform(0, PopSize)]);
            }
        }
    }

    ///Select the next members of the population
    override void selection() {
        //if the user has defined their own selector, just cal it
        static if (isCallable!selector) {
            population = selector(population); 
        }
        else {
            population = selector!(fitness, comp)(population, m_statRecord);
        }
    }
}
