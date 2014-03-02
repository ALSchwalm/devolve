module devolve.bstring.bstringGA;
import devolve.simpleGA;
import devolve.selector;
import devolve.bstring.crossover;
import devolve.bstring.generator;
import devolve.bstring.mutator;
import devolve.bstring.bitset;

import std.conv;

/**
 * Genetic algorithm for genomes taking the form of binary strings.
 *
 * Params:
 *    length = Fixed size of the binary string. 
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
                alias selector = topPar!(to!uint(PopSize*0.1)),
                alias crossover = singlePoint,
                alias mutator = randomFlip,
                alias comp = "a > b") : SimpleGA!(BitSet!length, PopSize, comp,
                                                fitness,
                                                generator,
                                                selector,
                                                crossover,
                                                mutator)
{
    /**
     * Default constructor. No statistics will be printed, 
     * and mutation will be set at 1%, crossover rate at 80%
     */
    this(){}

    /**
     * Convienience constructor, equivilant to default constructing
     * and setting mutation rate and statistic frequency
     */
    this(float mutRate, float crossoverRate, uint statFreq) {
        m_mutationRate = mutRate;
        m_statFrequency = statFreq;
        m_crossoverRate = crossoverRate;
    }
}
