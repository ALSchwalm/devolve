module devolve.bstring.bstringGA;
import std.string : format;

private template integralType(uint size) if (size > 0) {
    static if (size <= 8) {
        alias integralType = ubyte;
    }
    else static if (size <= 16) {
        alias integralType = ushort;
    }
    else static if (size <= 32) {
        alias integralType = uint;
    }
    else static if (size <= 64) {
        alias integralType = ulong;
    }
    else {
        static assert(false, format("Value %d to large for integral type. "
                                    "Arbitrary length bstring not yet supported", size));
    }
}


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
                alias crossover = singlePoint,
                alias mutator = randomSwap,
                alias comp = "a > b") : BaseGA!(integralType(length), PopSize, comp)
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
                    best = population[0];

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
