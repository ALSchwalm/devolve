module devolve.bstring.crossover;
import devolve.bstring.bitset;
import std.random;

/**
 * Create a new individual by taking all of the elements
 * from one individual after a randomly chosen point and
 * appending them to all of the values before that point
 * from another individual. Both parents must be of equal
 * length.
 * 
 * ind1 =   1001010110110 $(BR)
 * ind2 =   0010101010010 $(BR)
 * point =  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*
 *
 * child =  1001101010010
 */
auto singlePoint(size_t len)(BitSet!len ind1,
                             BitSet!len ind2) {

    auto point = uniform(0, len);

    BitSet!len child;

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
