module devolve.list.listGA;
import devolve.baseGA;
import devolve.list.crossover;
import devolve.list.mutator;
import devolve.selector;

import std.stdio, std.random, std.algorithm;
import std.conv, std.traits, std.typetuple, std.math;

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
    override const(T) evolve(uint generations){

        generation();

        //Perform evolution
        foreach(generation; 0..generations) {

            crossingOver();
            mutation();
            selection();

            showStatistics(generation);

            if (!isNaN(m_termination) &&
                !compFun(m_termination, statRecord.last.best.fitness)) {

                writeln("\n(Termination criteria met) Score: ", statRecord.last.best.fitness,
                        ", Individual: ", statRecord.last.best.individual );
                break;
            }
        }

        writeln("\n(Historical best) Score: ", statRecord.historicalBest.fitness,
                ", Individual: ", statRecord.historicalBest.individual);

        return statRecord.historicalBest.individual;
    }

protected:

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
    ///after selection
    override void crossingOver() {
        while(population.length < PopSize) {
            population ~= crossover(population[uniform(0, population.length)],
                                    population[uniform(0, population.length)]);
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
        //if the user has defined their own selector, just cal it
        static if (isCallable!selector) {
            population = selector(population); 
        }
        else {
            population = selector!(fitness, comp)(population, m_statRecord);
        }
    }
}

version(unittest) {
    double fitness(int[4] ind) {return reduce!"a+b"(ind);}
    
    unittest {
        import devolve.list;
        auto ga = new ListGA!(int[4], 10, fitness, generator.preset!(1, 2, 3, 4));
        
        auto ga2 = new ListGA!(int[4], 10, fitness,
                               generator.preset!(1, 2, 3, 4),
                               selector.roulette!2,
                               crossover.randomCopy,
                               Join!(mutator.randomSwap, mutator.randomRange!(0, 10)));
    }
}
