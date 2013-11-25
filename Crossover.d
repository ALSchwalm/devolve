
module Crossover;
import std.random;
import std.algorithm;

individual SinglePoint(individual)(ref const individual ind1,
                                   ref const individual ind2) {
    individual newInd;
    auto val = uniform(0, ind1.length);

    for(auto index=0; index < min(ind1.length, ind2.length); index++) {
        if (index < val) {
            newInd ~= ind1[index];
        }
        else {
            newInd ~= ind2[index];
        }
    }
    return newInd;
};


