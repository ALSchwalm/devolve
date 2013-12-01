
import devolve;
import std.algorithm;

alias individual = char[];

immutable uint[const char[]] distances;

static this() {
    distances = [
        ['a', 'b']: 20u,
        ['a', 'c']: 42u,
        ['a', 'd']: 35u,
        ['b', 'c']: 30u,
        ['b', 'd']: 34u,
        ['c', 'd']: 12u
        ];
}

double fitness(ref const individual ind) {
    double total = 0;

    for(uint i=0; i < ind.length-1; ++i) {
        char lower = min(ind[i], ind[i+1]);
        char higher = max(ind[i], ind[i+1]);
        total += distances[[lower,  higher]];
    }
    return total;
};

void main() {
    auto selector = &topPool!(individual, 2, "a < b");
    auto crossover = &randomCopy!individual;
    auto mutator = &randomSwap!individual;
    auto generator = &preset!(individual, ['c', 'b', 'a', 'd']);

    auto ga = SimpleGA!(individual, 10)(&fitness,
                                        mutator,
                                        selector,
                                        crossover,
                                        generator);
    ga.setMutationRate(0.1f);
    ga.setStatFrequency(5);
    ga.evolve(30);
}
