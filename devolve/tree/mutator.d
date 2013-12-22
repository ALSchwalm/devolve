module devolve.tree.mutator;
import devolve.tree.generator;
import std.random;
import std.algorithm;

/*
 * Replace a random node with a new random subtree. The height of the tree
 * will not increase.
 */
void randomBranch(T)(ref BaseNode!T ind, ref TreeGenerator!T gen) {
    uint depth = uniform(0, ind.getHeight());

    BaseNode!T* current = &ind;
    foreach(uint i; 0..depth) {
        if (!current.getNumChildren()) {
            break;
        }

        uint choice = uniform(0, current.getNumChildren());
        current = &current.getChild(choice);
    }

    if (!current.getNumChildren()) {
        auto newTerm = gen.getRandomTerminator();
        current = &newTerm;
        return;
    }

    uint choice = uniform(0, current.getNumChildren());
    current.setChild(gen.getRandomTree(current.getHeight()-1), choice);
}
