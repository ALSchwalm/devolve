module devolve.selector;
import std.algorithm;
import std.parallelism;

void topPool(individual, int num)(ref individual[] population,
                                  double function(ref const individual) fitness) {

    individual[num] result;
    individual[][] populationPools;

    foreach(uint i; 0..num) {
        populationPools ~= population[ ($/num)*i..($/num)*i+$/num ];
    }

    foreach(i, ref individual[] pool; parallel(populationPools)) {
        sort!((a, b) => fitness(a) > fitness(b))(pool);
        result[i] = pool[0];
    }

    foreach(i, individual ind; result) {
        population[i] = ind;
    }

    population.length = num;
}


void top(individual, int num)(ref individual[] population,
                               double function(ref const individual) fitness) {
    sort!((a, b) => fitness(a) > fitness(b))(population);
    population.length = num;
}
