
import devolve.simpleGA;
import devolve.crossover;
import devolve.selector;
import devolve.mutator;
import devolve.generator;
import std.algorithm;
import std.array;


alias individual = int[];

void main() {

    auto fitness = function(ref const individual ind) {
        return cast(double)(array(filter!"a%2==0"(ind)).length);
    };

    auto selector = &topPool!(individual, 10);
    auto crossover = &singlePoint!individual;
    auto mutator = &randomSwap!(individual);
    auto generator = &randRange!(individual, 10, 0, 100);

    auto ga = SimpleGA!(individual, 1000)(fitness,
                                          mutator,
                                          selector,
                                          crossover,
                                          generator);
    ga.setMutationRate(0.1f);
    ga.evolve(1000);

}
