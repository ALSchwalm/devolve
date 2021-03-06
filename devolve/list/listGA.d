module devolve.list.listGA;
import devolve.simpleGA;
import devolve.list.crossover;
import devolve.list.mutator;
import devolve.selector;

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
             alias selector = topPar!(cast(uint)(PopSize*0.1)),
             alias crossover = singlePoint,
             alias mutator = randomSwap,
             alias comp = "a > b") : SimpleGA!(T, PopSize, comp,
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

unittest {
    import devolve.list, std.stdio;
    auto ga = new ListGA!(int[4], 10, testFitness, generator.preset!(1, 2, 3, 4));
    ga.randomSeed = testSeed;
    ga.showFinalStats = false;

    assert(ga.evolve(10) == [1, 2, 3, 4]);
    
    auto ga2 = new ListGA!(int[4], 10, testFitness,
                           generator.preset!(1, 2, 3, 4),
                           selector.roulette!2,
                           crossover.randomCopy,
                           Join!(mutator.randomSwap, mutator.randomRange!(0, 10)));
}
