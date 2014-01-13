module devolve.bstring.crossover;
import std.random;
import std.bitmanip;


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
auto singlePoint(BitArray ind1,
                 BitArray ind2)
in {
    assert(ind1.length == ind2.length);
}
out (child){
    assert(child.length == ind1.length &&
           child.length == ind2.length);
}
body{
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
