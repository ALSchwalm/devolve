module devolve.selector;
import std.algorithm;
import std.parallelism;
import std.functional;
import std.range;

/*
 * Select 'num' individuals from the population by dividing it into
 * 'num' pools and sorting those pools by the fitness function
 * concurrently. The most fit individuals in each pool are selected.
 * The direction of the sort may be set with comp, default is
 * highest fitness first.
 */
void topPar(individual, uint num, alias fitness, alias comp = "a > b")
    (ref individual[] population) if (num > 0) {

    alias binaryFun!(comp) compFun;

    auto fitnessVals = taskPool.amap!fitness(population);
    sort!((a, b) => compFun(a[0], b[0]))(zip(fitnessVals, population));
    population.length = num;
}

/*
 * The population is sorted by the fitness function and the 'num'
 * most fit members are selected. The direction of the sort may
 * be set with comp, default is highest fitness first.
 */
void top(individual, uint num, alias fitness, alias comp = "a > b")
    (ref individual[] population) if (num > 0) {
    
    alias binaryFun!(comp) compFun;
    sort!((a, b) => compFun(fitness(a), fitness(b)))(population);
    population.length = num;
}
