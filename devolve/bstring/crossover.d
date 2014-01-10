module devolve.bstring.crossover;
import std.random;
import std.bitmanip;

auto singlePoint(BitArray ind1,
                 BitArray ind2) {
    auto point = uniform(0, ind1.length);

    BitArray child;
    child.length = ind1.length;

    foreach(i, ref bit; child) {
        if (i > point) {
            bit = ind1[i];
        }
        else {
            bit = ind2[i];
        }
    }
    
    return child;
}
