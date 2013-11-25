
module Generator;

import std.random;

allele[] randRang(allele : allele[], int num, allele low, allele high)() {
    allele[] i;
    foreach (uint x; 0..num) {
        i ~= cast(allele)(uniform(low, high));
    }
    return i;
}
