#!/usr/bin/env rdmd

import devolve.treeGA;
import devolve.selector;
import devolve.tree.mutator;
import devolve.tree.generator;
import devolve.tree.crossover;

immutable auto primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29];

/*
 * All inputs and function argument and return types
 * must be of the same type. Here we create an alias
 * to facilitate this.
 */
alias geneType = uint;

//Input for the grown function
geneType x;

//Fitness: How many consecutive primes are generated for consecutive integer input
auto fitness(ref Tree!geneType algorithm) {
    double total = 0;
    foreach(uint i, prime; primes) {
        x = i+1;
        if (algorithm.eval() == prime) {
            total += 1;
        }
        else {
            break;
        }
    }
    return total;
}

void main() {

    //Generator: Class used to generate trees from the registered functions
    TreeGenerator!geneType gen;

    with(gen) {
        //Register simple functions, only parameter names of 'a' and 'b' are supported
        register!("-a", "negative");
        register!("a*a", "square");
        register!("a+b", "sum");
        register!("a-b", "difference");
        register!("a*b", "product");

        //Lambdas can also be used with any number of arguements and complex expressions
        register!((geneType i, geneType j, geneType k, geneType l) {return ((i < j) ? k : j);}, "if <");
        register!((geneType a, geneType b) {return ((a < b) ? a : b);}, "min");
        register!((geneType a, geneType b) {return ((a > b) ? a : b);}, "max");
    
        //Use overload for delegates
        geneType ifGreater (geneType i, geneType j, geneType k, geneType l) {
            return ((i > j) ? k : j);
        }
        register(&ifGreater, "if >");

        //Register an input value. This is effectivly a shorthand for
        // 'gen.register(delegate(){return x;}, "x");'
        registerInput!x;

        //Register a range of random constants which may appear in the generated algorithm
        registerConstantRange(0, 10);

        //Or an individual value
        registerConstant!2;
    }
    
    auto ga = new TreeGA!(geneType,

                          //Population size
                          1000,

                          //Maximum depth of tree
                          5,

                          //Fitness: the above fitness function
                          fitness,

                          /*
                           * Selector: Select the top 100 members by evalutating each
                           * member in parallel.
                           */
                          topPar!(100, fitness),

                          /*
                           * Crossover: Copy one of the parents, and replace a random 
                           * node with a subtree from the other parent
                           */
                          singlePoint,

                          //Mutator: Replace a random node with a new random subtree
                          randomBranch)(gen);

    //Set a mutation rate
    ga.mutationRate = 0.25;
    
    //Print statistics every 20 generations
    ga.statFrequency = 20;

    //Stop if any individual has the termination value
    ga.terminationValue = primes.length;

    //Automatically output a graphviz 'dot' file to 'best.dot' upon termination
    ga.autoGenerateGraph = true;
    
    /*
     * Grow for 600 generations. Takes approximately 45 seconds on quad core 
     * laptop to generate function with 60% fitness. That is, a funtion which
     * will yeild the first 6 primes on consecutive integer input
     */
    ga.evolve(600);
}
