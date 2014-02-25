module devolve.bstring.bstringGA;
import devolve.baseGA;
import devolve.selector;
import devolve.bstring.generator;
import devolve.bstring.bitset;

import std.stdio, std.random, std.algorithm;
import std.traits,  std.traits, std.conv, std.math;

/**
 * Genetic algorithm for genomes taking the form of binary strings.
 *
 * Params:
 *    length = Fixed size of the binary string. Used to determine the underlying numeric type
 *    PopSize = The size of the population
 *    fitness = User defined fitness function. Must return double
 *    selector = Selection method used to pick parents of next generation. 
 *    crossover = Used to crossover individuals to create the new generation. 
 *    mutator = Used to alter the population. 
 *    comp = Used to determine whether a larger or smaller fitness is better.
 */
class BStringGA(uint length,
                uint PopSize,
                alias fitness,
                alias generator,
                alias selector = topPar!2,
                alias crossover = randomSwap,
                alias mutator = randomFlip,
                alias comp = "a > b") : BaseGA!(BitSet!length, PopSize, comp)
{

    /**
     * Default constructor. No statistics will be printed, 
     * and mutation will be set at 1%
     */
    this(){}

    /**
     * Convienience constructor, equivilant to default constructing
     * and setting mutation rate and statistic frequency
     */
    this(float mutRate, uint statFreq) {
        m_mutationRate = mutRate;
        m_statFrequency = statFreq;
    }


protected:

    ///Add initial population using generator
    override void generation() {
        foreach(i; 0..PopSize) {
            static if (isCallable!generator) {
                population ~= generator();
            }
            else {
                population ~= generator!length();
            }       
        }
    }

    ///Preform add new members by crossing-over the population left
    ///after selection
    override void crossingOver() {
        while(population.length < PopSize) {
            auto parent1 = population[uniform(0, population.length)];
            auto parent2 = population[uniform(0, population.length)];
            static if (isCallable!crossover) {
                population ~= crossover(parent1, parent2);
            }
            else {
                population ~= crossover!length(parent1, parent2);
            }
        }
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

    ///Select the most fit members of the population
    override void selection() {

        //if the user has defined their own selector, just call it
        static if (isCallable!selector) {
            population = selector(population); 
        }
        else {
            population = selector!(fitness, comp)(population, m_statRecord);
        }
    }
}
