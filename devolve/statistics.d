module devolve.statistics;

import std.typecons, std.traits, std.math, std.conv;

/**
 * Class to hold statistics about each generation during an evolution.
 * An instance of this type is passed to the selector, which should
 * call 'addGeneration' with a sorted range of individuals and doubles
 * representing the fitness of each individual.
 */
class StatCollector(T, alias comp) {

    ///Convienience alias
    alias individualFit = Tuple!(double, "fitness", T, "individual");
    
    ///Object holding statistics for a single generation
    struct Statistics {
        double averageFit;
        individualFit best;
        individualFit worst;

        string toString()  {
            return "Fitness - High: " ~ to!string(best.fitness) ~
                ", Low: " ~ to!string(worst.fitness) ~ 
                ", Average: " ~ to!string(averageFit);
        }
    }

    
    @property {
        ///Get the most recent generation statistics
        Statistics last() {
            return stats[$-1];
        }

        ///Get statistics for the first generation
        Statistics first() {
            return stats[0];
        }

        ///Get the best recorded individual
        individualFit historicalBest() {
            return m_historicalBest;
        }
    }

    ///Get a list of all recorded statistics
    const(Statistics[]) opSlice() {
        return stats;
    }

    ///Get a list of all recorded statistics in the range [x..y]
    const(Statistics[]) opSlice(size_t x, size_t y) {
        return stats[x..y];
    }

    /**
     * Add the generation to the statistical history.
     * 'popFitRange' must be in sorted order.
     */
    void registerGeneration(popFitRange)(popFitRange range)
        if (is(typeof(range[0][0]) == double) &&
            is(typeof(range[0][1]) == T)) {

        Statistics stat;
        double total = 0;
        
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
        
        foreach (ref pair; range) {
            total += pair[0];
        }
        stat.averageFit = total / range.length;
        stats ~= stat;
    }
    
protected:
    Statistics[] stats;

    individualFit m_historicalBest;

    bool function(double, double) compFun = &comp!(double, double);
}
