module devolve.selector;

import std.algorithm, std.parallelism, std.functional;
import std.range, std.random, std.traits, std.array;
import std.typecons;

/**
 * Select the 'num' most fit individuals from the population
 * by evaluating their fitnesses in parallel. The direction
 * of the sorting may be set with 'comp'.
 */
template topPar(uint num) if (num > 0) {

    ///
    individual[] topPar(alias fitness, alias comp = "a > b", individual, statRecord)
        (individual[] population, statRecord record) {

        alias binaryFun!(comp) compFun;

        auto fitnessVals = taskPool.amap!fitness(population);
        auto popFitRange = zip(fitnessVals, population);
        sort!((a, b) => compFun(a[0], b[0]))(popFitRange);

        record.registerGeneration(popFitRange);
        return population[0..num];
    }
}

unittest {
    import devolve.statistics;

    double[][] pop = [[1, 2, 4], [8, 2, 2], [4, 1, 1], [2, 3, 3]];
    auto stat = new StatCollector!(typeof(pop[0]));

    alias bestTwo = topPar!2;
    auto best = bestTwo!"a[0]"(pop, stat);
    assert(best == [[8, 2, 2], [4, 1, 1]]);

    auto stat2 = new StatCollector!(typeof(pop[0]), "a < b");
    best = bestTwo!("a[0]", "a < b")(pop, stat2);
    assert(best == [[1, 2, 4], [2, 3, 3]]);
}

/**
 * The population is sorted by the fitness function and the 'num'
 * most fit members are selected. The direction of the sort may
 * be set with comp, default is highest fitness first.
 */
template top(uint num) if (num > 0) {

    ///
    individual[] top(alias fitness, alias comp = "a > b", individual, statRecord)
        (individual[] population, statRecord record) {

        alias binaryFun!(comp) compFun;
        
        auto fitnessVals = array(map!fitness(population));
        auto popFitRange = zip(fitnessVals, population);
        popFitRange.sort!((a, b) => compFun(a[0], b[0]));
        
        record.registerGeneration(popFitRange);
        return population[0..num];
    }
}

unittest {
    import devolve.statistics;
    
    double[][] pop = [[1, 2, 4], [8, 2, 2], [4, 1, 1], [2, 3, 3]];
    auto stat = new StatCollector!(typeof(pop[0]));
    
    alias bestTwo = top!2;
    auto best = bestTwo!"a[0]"(pop, stat);
    assert(best == [[8, 2, 2], [4, 1, 1]]);

    auto stat2 = new StatCollector!(typeof(pop[0]), "a < b");
    best = bestTwo!("a[0]", "a < b")(pop, stat2);
    assert(best == [[1, 2, 4], [2, 3, 3]]);
}

/**
 * Select 'numberOfTournaments' individuals from the population by
 * dividing it into 'numberOfTournament' pools of size 'tournamentSize'.
 * The pools are then sorted by their fitness. The top-most member
 * is selected with probability 'probability', the next with
 * probability 'probability * (1 - probability)' the next with
 * probability 'probability * (1 - probability)^2', etc. This process
 * is preformed on each pool in parallel. If the individual has a
 * 'clone' method it will be invoked when copying.
 */
template tournament(uint numberOfTournaments, uint tournamentSize, double probability)
    if (numberOfTournaments > 0 &&
        tournamentSize > 0 &&
        probability > 0 &&
        probability <= 1.0) {
    
    ///
    individual[] tournament(alias fitness, alias comp = "a > b", individual, statRecord)
        (individual[] population, statRecord record) {

        alias binaryFun!(comp) compFun;
        
        Tuple!(double, individual) winners[numberOfTournaments];
        auto gen = rndGen; //Keep the rndGen for custom seeds
                           //TODO: determine if this is safe

        foreach(i; parallel(iota(numberOfTournaments))) {
            rndGen = gen;

            individual tournamentPool[tournamentSize];
            foreach(j; 0..tournamentSize) {
                static if (hasMember!(individual, "clone")) {
                    tournamentPool[j] = population[uniform(0, $)].clone();
                }
                else {
                    tournamentPool[j] = population[uniform(0, $)];
                }
            }

            auto choice = uniform(0.0f, 1.0f);
            bool found = false;
            
            auto fitnessVals = array(map!fitness(tournamentPool[]));
            auto poolFitRange = zip(fitnessVals, tournamentPool[]);
            poolFitRange.sort!((a, b) => compFun(a[0], b[0]));

            foreach(j; 0..tournamentSize) {
                if (choice < probability * (1-probability)^^j) {
                    winners[i] = poolFitRange[j];
                    found = true;
                    break;
                }
                choice -= probability * (1-probability)^^j;
            }

            //In the unlikely event that the choice was not in the range of any
            //individual, select the most fit
            if (!found) {
                winners[i] = poolFitRange[0];
            }
        }

        sort!((a, b) => compFun(a[0], b[0]))(winners[]);
        record.registerGeneration(winners[]);
        
        foreach(int i, ref winner; winners) {
            population[i] = winner[1];
        }
        return population[0..numberOfTournaments];
    }
}

unittest {
    import devolve.statistics, devolve.utils, std.random;
    rndGen.seed(testSeed);

    double[][] pop = [[1, 2, 4], [8, 2, 2], [4, 1, 1], [2, 3, 3]];
    auto stat = new StatCollector!(typeof(pop[0]));

    alias bestTwo = tournament!(2, 3, 0.7);
    auto best = bestTwo!"a[0]"(pop, stat);

    assert(best.length == 2);
    assert(best == [[8, 2, 2], [8, 2, 2]]);
}


/**
 * Select 'num' individuals from the population by sorting by fitness
 * and randomly choosing individuals with probability weighted by the
 * individual's fitness. The evaluation of fitness is done in
 * parallel. If 'individual' has a 'clone' method it will be invoked
 * when copying.
 */
template roulette(uint num) if (num > 0) {
    ///
    individual[] roulette(alias fitness, alias comp = "a > b", individual, statRecord)
        (individual[] population, statRecord record) {
    
        alias binaryFun!(comp) compFun;
        individual[num] winners;

        auto fitnessVals = taskPool.amap!fitness(population);
        auto popWithFitness = zip(fitnessVals, population);
        sort!((a, b) => compFun(a[0], b[0]))(popWithFitness);

        record.registerGeneration(popWithFitness);

        immutable auto total = taskPool.reduce!"a+b"(fitnessVals);

        foreach(i; 0..num) {
            auto choice = uniform(0.0f, 1.0f);
            bool found = false;

            foreach(j; 0..population.length) {
                if (choice < popWithFitness[j][0] / total) {
                    found = true;
                    static if (hasMember!(individual, "clone")) {
                        winners[i] = popWithFitness[j][1].clone();
                    }
                    else {
                        winners[i] = popWithFitness[j][1];
                    }
                    break;
                }
                choice -= popWithFitness[j][0] / total;
            }
            if (!found) {
                static if (hasMember!(individual, "clone")) {
                    winners[i] = popWithFitness[0][1].clone();
                }
                else {
                    winners[i] = popWithFitness[0][1];
                }
            }
        }
        population[0..num] = winners[];
        return population[0..num];
    }
}

unittest {
    import devolve.statistics, devolve.utils;
    rndGen.seed(testSeed);

    double[][] pop = [[1, 2, 4], [8, 2, 2], [4, 1, 1], [2, 3, 3]];
    auto stat = new StatCollector!(typeof(pop[0]));

    alias bestTwo = roulette!2;
    auto best = bestTwo!"a[0]"(pop, stat);

    assert(best.length == 2);
    assert(best == [[8, 2, 2], [4, 1, 1]]);
}
