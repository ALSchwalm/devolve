module devolve.bstring.mutator;
import std.random;

void randomFlip(individual)(ref individual ind) {
    auto num = uniform(0, individual.max);
    ind^=num;
}
