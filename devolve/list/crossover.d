module devolve.list.crossover;
import std.random;
import std.algorithm;
import std.traits;

/**
 * Create a new individual by taking all of the elements
 * from one individual after a randomly chosen point and
 * appending them to all of the values before that point
 * from another individual. The resulting individual
 * will have a length no longer than the shortest of the
 * parent individuals.
 * 
 * ind1 =   1111111111111
 * ind2 =   2222222222222
 * point =        *
 *
 * result = 1111111222222
 */
individual singlePoint(individual)(in individual ind1,
                                   in individual ind2)
    if (isArray!individual) {
        
    individual newInd;

    static if (isStaticArray!individual) {
        auto val = uniform(0, individual.length);
    }
    else {
        newInd.length = min(ind1.length, ind2.length);
        auto val = uniform(0, newInd.length);
    }
    newInd[0..val] = ind1[0..val];
    newInd[val..$] = ind2[val..newInd.length];

    return newInd;
};


/**
 * Same as singlePoint but without size guarantees. 
 * WARNING: individuals sizes may grow rapidly with
 * this crossover method.
 */
individual singlePointVariable(individual)(in individual ind1,
                                           in individual ind2)
    if (isDynamicArray!individual) {
        
    individual newInd;
    auto val1 = uniform(0, ind1.length);
    auto val2 = uniform(0, ind2.length);
    
    newInd.length = val1 + (ind2.length - val2);
    newInd[0..val1] = ind1[0..val1];
    newInd[val1..$] = ind2[val2..$];

    return newInd;
};


/**
 * Create a new individual by taking all of the alleles
 * from one individual after a randomly chosen point and
 * before a different randomly chosen point and
 * appending them to the alleles from the other individual
 * which are within that range. The resulting individual
 * will have a length no longer than the shortest of the
 * parent individuals.
 *
 * ind1 =    1111111111111
 * ind2 =    2222222222222
 * point1 =    *
 * point2 =         *
 *
 * result =  1122222111111
 */
individual twoPoint(individual)(in individual ind1,
                                in individual ind2)
    if (isArray!individual) {
        
    individual newInd;
    auto start = uniform(0, min(ind1.length, ind2.length));
    auto end = uniform(start, min(ind1.length, ind2.length));

    newInd.length = min(ind1.length, ind2.length);
    newInd[0..start] = ind1[0..start];
    newInd[start..end] = ind2[start..end];
    newInd[end..$] = ind1[end..$];
    
    return newInd;
}


/**
 * The new individual is a copy of one of the parents
 * selected at random.
 */
individual randomCopy(individual)(in individual ind1,
                                  in individual ind2)
    if (isArray!individual) {
        
    individual newInd;

    if (uniform(0, 2)) {
        static if (isDynamicArray!individual) {
            newInd.length = ind1.length;
        }
        newInd[] = ind1[];
    }
    else {
        static if (isDynamicArray!individual) {
            newInd.length = ind2.length;
        }
        newInd[] = ind2[];
    }
    return newInd;
}
