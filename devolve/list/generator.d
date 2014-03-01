module devolve.list.generator;
import std.random, std.traits;

/**
 * Create individuals as static arrays filled with 
 * allels in the range [low, high).
 */
template randomRange(alias low, alias high) {

    ///
    auto randomRange(individual)() if (isStaticArray!individual) {
        individual ind;
        alias allele = typeof(ind[0]);
        
        foreach (i; 0..individual.length) {
            ind[i] = cast(allele)(uniform(low, high));
        }
        return ind;
    }
}

unittest {
    alias individual = int[4];
    alias rangeOneTen = randomRange!(0, 10);

    auto ind = rangeOneTen!individual;
    foreach(allele; ind) {
        assert(allele < 10 && allele >= 0);
    }
}

/**
 * Create individuals as dynamic arrays filled with 
 * 'num' allels in the range [low, high).
 */
template randomRange(uint num, alias low, alias high) {

    ///
    auto randomRange(allele: allele[])() {
        allele[] ind;
        foreach (i; 0..num) {
            ind ~= cast(allele)(uniform(low, high));
        }
        return ind;
    }
}

unittest {
    alias individual = int[];
    alias rangeOneTen = randomRange!(5, 0, 10);

    auto ind = rangeOneTen!individual;
    assert (ind.length == 5);
    foreach(allele; ind) {
        assert(allele < 10 && allele >= 0);
    }
}



/**
 * Create the initial population using some preset value.
 */
auto preset(Alleles...)() {
    typeof(Alleles[0])[Alleles.length] ind;

    foreach(i, allele; Alleles) {
        ind[i] = allele;
    }
    
    return ind;
}

unittest {
    int[5] val = [5, 3, 2, 4, 2];
    assert(preset!(5, 3, 2, 4, 2) == val);
}
