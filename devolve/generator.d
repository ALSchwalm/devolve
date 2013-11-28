
module devolve.generator;
import std.random;

allele[] randRange(allele : allele[], uint num, allele low, allele high)() {
    allele[] i;
    foreach (uint x; 0..num) {
        i ~= cast(allele)(uniform(low, high));
    }
    return i;
}
