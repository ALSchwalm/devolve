module devolve.crossover;
import std.random;
import std.algorithm;

individual singlePoint(individual)(ref const individual ind1,
                                   ref const individual ind2) {
    individual newInd;
    auto val = uniform(0, ind1.length);

    foreach(uint index; 0..min(ind1.length, ind2.length)) {
        if (index < val) {
            newInd ~= ind1[index];
        }
        else {
            newInd ~= ind2[index];
        }
    }
    return newInd;
};


