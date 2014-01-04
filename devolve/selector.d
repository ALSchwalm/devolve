module devolve.selector;
import std.algorithm;
import std.parallelism;
import std.functional;
import std.range;
import std.random;
import std.traits;
import std.stdio;

/*
 * Select 'num' individuals from the population by dividing it into
 * 'num' pools and sorting those pools by the fitness function
 * concurrently. The most fit individuals in each pool are selected.
 * The direction of the sort may be set with comp, default is
 * highest fitness first.
 */
template topPar(uint num, alias fitness, alias comp = "a > b") if (num > 0) {
    void topPar(individual) (ref individual[] population) {

        alias binaryFun!(comp) compFun;

        auto fitnessVals = taskPool.amap!fitness(population);
        sort!((a, b) => compFun(a[0], b[0]))(zip(fitnessVals, population));
        population.length = num;
    }
}

/*
 * The population is sorted by the fitness function and the 'num'
 * most fit members are selected. The direction of the sort may
 * be set with comp, default is highest fitness first.
 */
template top(uint num, alias fitness, alias comp = "a > b") if (num > 0) {
    void top(individual)(ref individual[] population) {
    
        alias binaryFun!(comp) compFun;
        sort!((a, b) => compFun(fitness(a), fitness(b)))(population);
        population.length = num;
    }
}

template tournament(uint numberOfTournaments, uint tournamentSize, double probability, alias fitness, alias comp = "a > b")
    if (numberOfTournaments > 0 &&
        tournamentSize > 0 &&
        probability > 0 &&
        probability <= 1.0) {
    void tournament(individual)(ref individual[] population) {

        alias binaryFun!(comp) compFun;
        individual winners[numberOfTournaments];

        foreach(i; parallel(iota(numberOfTournaments))) {
        
            individual tournamentPool[tournamentSize];
            foreach(j; 0..tournamentSize) {
                static if (hasMember!(individual, "clone")) {
                    tournamentPool[j] = population[uniform(0, population.length)].clone();
                }
                else {
                    tournamentPool[j] = population[uniform(0, population.length)];
                }
            }

            auto choice = uniform(0.0f, 1.0f);
            bool found = false;
            sort!((a, b) => compFun(fitness(a), fitness(b)))(tournamentPool[]);

            foreach(j; 0..tournamentSize) {
                if (choice < probability * (1-probability)^^j) {
                    winners[i] = tournamentPool[j];
                    found = true;
                    break;
                }
                choice -= probability * (1-probability)^^j;
            }

            //In the unlikely event that the choice was not in the range of any
            //individual, select the most fit
            if (!found) {
                winners[i] = tournamentPool[0];
            }
        }
        population.length = numberOfTournaments;
        population[] = winners[];
    }
}


template roulette(uint num, alias fitness, alias comp = "a > b") if (num > 0) {
    void roulette(individual)(ref individual[] population) {
    

        alias binaryFun!(comp) compFun;
        individual winners[num];

        auto fitnessVals = taskPool.amap!fitness(population);
        auto popWithFitness = zip(fitnessVals, population);
        sort!((a, b) => compFun(a[0], b[0]))(popWithFitness);

        immutable auto total = reduce!"a+b"(fitnessVals);

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
        population.length = num;
        population[] = winners[];
    }
}
