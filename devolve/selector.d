module devolve.selector;
import std.algorithm;
import std.parallelism;
import std.functional;

/*
 * Select 'num' individuals from the population by dividing it into
 * 'num' pools and sorting those pools by the fitness function
 * concurrently. The most fit individuals in each pool are selected.
 * The direction of the sort may be set with comp, default is
 * highest fitness first.
 */
void topPool(individual, uint num, alias comp = "a > b")
    (ref individual[] population,
     double function(ref const individual) fitness)
    if (num > 0) {

    alias binaryFun!(comp) compFun;
    individual[num] result;
    individual[][] populationPools;

    foreach(uint i; 0..num) {
        populationPools ~= population[ ($/num)*i..($/num)*i+$/num ];
    }

    foreach(i, ref individual[] pool; parallel(populationPools)) {
        sort!((a, b) => compFun(fitness(a),  fitness(b)))(pool);
        result[i] = pool[0];
    }

    foreach(i, individual ind; result) {
        population[i] = ind;
    }

    population.length = num;
}

/*
 * The population is sorted by the fitness function and the 'num'
 * most fit members are selected. The direction of the sort may
 * be set with comp, default is highest fitness first.
 */
void top(individual, uint num, alias comp = "a > b")
    (ref individual[] population,
     double function(ref const individual) fitness)
    if (num > 0) {
    
    alias binaryFun!(comp) compFun;
    sort!((a, b) => compFun(fitness(a), fitness(b)))(population);
    population.length = num;
}
