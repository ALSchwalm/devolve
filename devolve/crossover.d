module devolve.crossover;
import std.random;
import std.algorithm;

/*
 * Create a new individual by taking all of the elements
 * from one individual after a randomly chosen point and
 * appending them to all of the values before that point
 * from another individual. The resulting individual
 * will have a length no longer than the longest of the
 * parent individuals.
 * 
 * ind1 =   1111111111111
 * ind2 =   2222222222222
 * point =        *
 *
 * result = 1111111222222
 */
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


/*
 * Same as singlePoint but without size guarantees. 
 * WARNING: individuals sizes may grow rapidly with
 * this crossover method.
 */

individual singlePointVariable(individual)(ref const individual ind1,
                                           ref const individual ind2) {
    individual newInd;
    auto val1 = uniform(0, ind1.length);
    auto val2 = uniform(0, ind2.length);
    
    foreach(uint index; 0..val1) {
        newInd ~= ind1[index];
    }

    foreach(uint index; val2..ind2.length) {
        newInd ~= ind2[index];
    }
    
    return newInd;
};


/*
 * Create a new individual by taking all of the alleles
 * from one individual after a randomly chosen point and
 * before a different randomly chosen point and
 * appending them to the alleles from the other individual
 * which are within that range. The resulting individual
 * will have a length no longer than the longest of the
 * parent individuals.
 *
 * ind1 =    1111111111111
 * ind2 =    2222222222222
 * point1 =    *
 * point2 =         *
 *
 * result =  1122222111111
 */
individual twoPoint(individual)(ref const individual ind1,
                                ref const individual ind2) {

    individual newInd;
    auto start = uniform(0, ind1.length);
    auto end = uniform(0, ind1.length);

    foreach(uint index; 0..min(ind1.length, ind2.length)) {
        if (index < start || index > end) {
            newInd ~= ind1[index];
        }
        else {
            newInd ~= ind2[index];
        }
    }
    return newInd;
}


/*
 * The new individual is a copy of one of the parents
 * selected at random.
 */
individual randomCopy(individual)(ref const individual ind1,
                                  ref const individual ind2) {
    individual newInd;

    if (uniform(0, 2)) {
        newInd.length = ind1.length;
        newInd[] = ind1[];
    }
    else {
        newInd.length = ind2.length;
        newInd[] = ind2[];
    }
    
    return newInd;
}
