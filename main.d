
import SimpleGA;
import Crossover;
import Selector;
import Mutator;
import Generator;
import std.algorithm;


alias individual = int[];

void main() {

    auto fitness = function(ref const individual ind) {
        return cast(double)(reduce!"a+b"(0.0L, ind));
    };

    auto selector = &Selector.top!(individual, 3);
    auto crossover = &Crossover.SinglePoint!individual;
    auto mutator = &Mutator.swap!individual;
    auto generator = &Generator.randRang!(individual, 10, 0, 10);

    auto ga = SimpleGA.SimpleGA!(individual, 5)(fitness,
                                                mutator,
                                                selector,
                                                crossover,
                                                generator);
    ga.evolve(1);
}
