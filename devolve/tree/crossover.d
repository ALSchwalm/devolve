module devolve.tree.crossover;
import devolve.tree.generator;
import std.random;
import std.stdio;

BaseNode!T singlePoint(T)(ref const BaseNode!T ind1,
                          ref const BaseNode!T ind2) {

    BaseNode!T newNode = ind1.clone();

    BaseNode!T* currentNew = &newNode;
    const(BaseNode!T)* currentRight = &ind2;
    
    foreach(i; 0..ind2.getHeight()) {
        if (currentRight.getHeight() == currentNew.getHeight() && i != 0 ||
            !currentNew.getNumChildren() ||
            !currentRight.getNumChildren()) {

            auto n = currentRight.clone();
            *currentNew = n;
            return newNode;
        }
        
        uint choiceNew = uniform(0, currentNew.getNumChildren());
        uint choiceRight = uniform(0, currentRight.getNumChildren());
        currentNew = &currentNew.getChild(choiceNew);
        currentRight = &currentRight.getChild(choiceRight);
    }
    
    return newNode;
    
}
    
