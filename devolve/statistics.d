module devolve.statistics;

import std.typecons, std.traits, std.math, std.string, std.functional;
import std.algorithm, std.range, std.file;

/**
 * Class to hold statistics about each generation during an evolution.
 * An instance of this type is passed to the selector, which should
 * call 'addGeneration' with a sorted range of individuals and doubles
 * representing the fitness of each individual.
 */
class StatCollector(T, alias comp = "a > b") {

    ///Convienience alias
    alias individualFit = Tuple!(double, "fitness", T, "individual");

    ///Object holding statistics for a single generation
    struct Statistics {
        double meanFit;
        double standardDeviation;
        individualFit best;
        individualFit worst;

        string toString() const {
            return format("Best: %g\tWorst: %g\tMean: %g\tSD: %g",
                          best.fitness, worst.fitness, meanFit, standardDeviation);
        }
    }
    
    @property {
        ///Get the most recent generation statistics
        const(Statistics) last() const {
            return  stats[$-1];
        }

        ///Get statistics for the first generation
        const(Statistics) first() const {
            return stats[0];
        }

        ///Get the best recorded individual
        const(individualFit) historicalBest() const {
            return m_historicalBest;
        }
    }

    /**
     * Add the generation to the statistical history.
     * 'popFitRange' must be in sorted order.
     */
    void registerGeneration(popFitRange)(popFitRange range)
        if (isForwardRange!popFitRange && 
            is(typeof(range[0][0]) == double) &&
            is(typeof(range[0][1]) == T))
        in {
            assert(range.isSorted!((a, b) => compFun(a[0], b[0])));
        } body {

        Statistics stat;

        if (isNaN(stat.best.fitness) || compFun(range[0][0], stat.best.fitness)) {
            stat.best.fitness = range[0][0];
            static if (hasMember!(T, "clone")) {
                stat.best.individual = range[0][1].clone();
            }
            else {
                stat.best.individual = range[0][1];
            }

            if (isNaN(m_historicalBest.fitness) ||
                compFun(stat.best.fitness, m_historicalBest.fitness)) {

                m_historicalBest = stat.best;
            }

        }
        if (isNaN(stat.worst.fitness) ||
            !compFun(stat.worst.fitness, range[$-1][0])) {

            stat.worst.fitness = range[$-1][0];
            static if (hasMember!(T, "clone")) {
                stat.worst.individual = range[$-1][1].clone();
            }
            else {
                stat.worst.individual = range[$-1][1];
            }
        }

        double total = 0;
        foreach (ref pair; range) {
            total += pair[0];
        }
        stat.meanFit = total / range.length;

        total = 0;
        foreach (ref pair; range) {
            total += (pair[0] - stat.meanFit)^^2;
        }
        stat.standardDeviation = sqrt(total / range.length);

        stats ~= stat;
    }


    ///Write data out as CSV file
    void writeCSV(string name = "data.csv") const {
        string contents = "Best, Worst, Mean, SD\n";

        foreach(ref stat; stats) {
            contents ~= format("%s, %s, %s, %s\n",
                              stat.best.fitness,
                              stat.worst.fitness,
                              stat.meanFit,
                              stat.standardDeviation);

        }
        std.file.write(name, contents);
    }

    //Assume all other calls are to the underlying statistics
    alias stats this;
    
protected:
    Statistics[] stats;

    alias _compFun = binaryFun!(comp);
    bool function(double, double) compFun = &_compFun!(double, double);

    individualFit m_historicalBest;
}
