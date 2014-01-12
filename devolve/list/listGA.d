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

/**
 * Genetic algorithm for genomes in the form of a list. This includes
 * dynamic and statically sized arrays.
 *
 * Params:
 *    T = Type representing the genome. Should be a dynamic or statically sized array
 *    PopSize = The size of the population
 *    fitness = User defined fitness function. Must return double
 *    generator = Function used to create new members of the population
 *    selector = Selection method used to pick parents of next generation. 
 *    crossover = Used to crossover individuals to create the new generation. 
 *    mutator = Used to alter the population. 
 *    comp = Used to determine whether a larger or smaller fitness is better.
 *
 * Examples:
 * --------------------
 *
 * //Grow individual with greatest sum
 * import devolve, std.algorithm;
 * alias genomeType = int[4];
 *
 * double fitness(genomeType ind) {return reduce!"a+b"(ind)}
 *
 * void main() {
 *
 *     auto ga = new ListGA!(genomeType, 10, fitness, preset!(1, 2, 3, 4));
 *     //converges rapidly on [4, 4, 4, 4]
 *     ga.evolve(100);
 * }
 * --------------------
 */
class ListGA(T,
             uint PopSize,
             alias fitness,
             alias generator,
             alias selector = topPar!2,
             alias crossover = singlePoint,
             alias mutator = randomSwap,
             alias comp = "a > b") : BaseGA!(T, PopSize, comp)
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

        /**
         * Evolution function works as follows.
         *
         * $(OL
         *   $(LI The population is created using the supplied `generator`)
         *   $(LI Crossing-over is preformed to created missing population)
         *   $(LI The population is mutated with probability `mutation_rate`)
         *   $(LI The parents of the next generation are selected)
         *   $(LI Statistics are recorded for the best individual)
         *   $(LI Terminate if criteria is met, otherwise go to 2.)) 
         */
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

                //if the user has defined their own selector, just cal it
                static if (isCallable!selector) {
                    population = selector(population); 
                }
                else {
                    population = selector!(fitness, comp)(population);
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

version(unittest) {
    double fitness(int[4] ind) {return reduce!"a+b"(ind);}
    
    unittest {
        import devolve;
        auto ga = new ListGA!(int[4], 10, fitness, preset!(1, 2, 3, 4));
    }
}
