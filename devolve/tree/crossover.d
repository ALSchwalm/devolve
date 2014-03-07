module devolve.tree.crossover;
import devolve.tree.generator;
import std.random;

/**
 * Create a new individual by cloning ind1 and copying a random
 * subtree of ind2 into ind1. The height of the resulting
 * individual will be equal to ind1's height.
 */
BaseNode!T singlePoint(T)(in BaseNode!T ind1,
                          in BaseNode!T ind2)
out (child) {
    assert(child.getHeight() == ind1.getHeight());
}
body {
    BaseNode!T newNode = ind1.clone();

    BaseNode!T* currentNew = &newNode;
    const(BaseNode!T)* currentRight = &ind2;

    foreach(i; 0..ind2.getHeight()) {
        if (currentRight.getHeight() == currentNew.getHeight() && i != 0) {
            auto n = currentRight.clone();
            *currentNew = n;
            return newNode;
        }

        if (currentNew.getNumChildren()) {
            uint choiceNew = uniform(0, currentNew.getNumChildren());
            currentNew = &currentNew.getChild(choiceNew);
        }
        if (currentRight.getNumChildren()) {
            uint choiceRight = uniform(0, currentRight.getNumChildren());
            currentRight = &currentRight.getChild(choiceRight);
        }
    }

    return newNode;

}
