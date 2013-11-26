
import SimpleGA;
import Crossover;
import Selector;
import Mutator;
import Generator;
import std.algorithm;
import std.array;


alias individual = int[];

void main() {

    auto fitness = function(ref const individual ind) {
        return cast(double)(array(filter!"a%2==0"(ind)).length);
    };

    auto selector = &Selector.top!(individual, 3);
    auto crossover = &Crossover.SinglePoint!individual;
    auto mutator = &Mutator.swap!individual;
    auto generator = &Generator.randRange!(individual, 10, 0, 100);

    auto ga = SimpleGA.SimpleGA!(individual, 10)(fitness,
                                                 mutator,
                                                 selector,
                                                 crossover,
                                                 generator);
    ga.setMutationRate(0.3f);
    ga.evolve(1000);

}
