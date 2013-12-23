#!/usr/bin/env rdmd

import devolve.treeGA;
import devolve.selector;
import devolve.tree.mutator;
import devolve.tree.generator;
import devolve.tree.crossover;

immutable auto primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29];

int x;

//Fitness: How many consecutive primes are generated for consecutive integer input
double fitness(ref BaseNode!int algorithm) {
    uint total = 0;
    foreach(uint i, uint prime; primes) {
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
    TreeGenerator!int gen;

    //Register simple functions
    gen.register(function(int i) {return -i;}, "negative");
    gen.register(function(int i) {return i*i;}, "square");
    gen.register(function(int i, int j) {return i+j;}, "sum");
    gen.register(function(int i, int j) {if (i < j) return i; else return j;}, "min");
    gen.register(function(int i, int j) {if (i > j) return i; else return j;}, "max");
    gen.register(function(int i, int j, int k, int l) {if (i > j) return k; else return j;}, "if >");
    gen.register(function(int i, int j) {return i-j;}, "difference");
    gen.register(function(int i, int j){return i*j;} , "product");

    //Register an input value. This is effectivly a shorthand for
    //  'gen.register(function(){return x;}, "x");'
    gen.registerInput!x;

    //Register a range of random constants which may appear in the generated algorithm
    gen.registerConstantRange(0, 10);

    auto ga = new TreeGA!(int,

                          //Population size
                          70,

                          //Maximum depth of tree
                          5,

                          //Fitness: the above fitness function
                          fitness,

                          /*
                           * Selector: Select the top 10 members by evalutating each
                           * member in parallel.
                           */
                          topPar!(BaseNode!int, 10, fitness),

                          /*
                           * Crossover: Copy one of the parents, and replace a random 
                           * node with a subtree from the other parent
                           */
                          singlePoint!int,

                          //Mutator: Replace a random node with a new random subtree
                          randomBranch!int)(gen);

    //Set a 20% mutation rate
    ga.mutationRate = 0.20;
    
    //Print statistics every 500 generations
    ga.statFrequency = 500;

    //Automatically output a graphviz 'dot' file to 'best.dot' upon termination
    ga.autoGenerateGraph = true;
    
    /*
     * Grow for 20000 generations. Takes approximately 45 seconds on quad core 
     * laptop to generate function with 60% fitness. That is, a funtion which
     * will yeild the first 6 primes on consecutive integer input
     */
    ga.evolve(20000);
}
