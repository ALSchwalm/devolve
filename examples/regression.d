#!/usr/bin/env rdmd

import devolve.tree;

import std.math, std.conv, std.range;
import std.typecons, std.algorithm;
  
//Points taken from the equation `x^2 + 2x + sin(x)^2 - 23`
double f(double x) {return x*x + 2*x+sin(x)*sin(x)-23;}

immutable Tuple!(double, double)[] points;
static this() {
    points = array(zip(iota(-10, 10, 0.5),
                       map!f(iota(-10, 10, 0.5)))).idup;
}

//Input variable for the grown function
double x;

/*
 * Evaluate function `g`. Fitness is the cumulative difference between g(x)
 * and a given point (x, y).
 */
double fitness(in Tree!double algorithm) {
    double fit = 1;

    foreach(ref pair; points) {
        x = pair[0];
        fit += abs(algorithm.eval() - pair[1]);
    }
    return fit;
}

void main() {

    //Generator: Class used to generate trees from the registered functions
    TreeGenerator!double gen;

    //Register simple functions, only parameter names of 'a' and 'b' are supported
    gen.register!"-a"("negative");
    gen.register!"a*a"("square");
    gen.register!"a+b"("sum");
    gen.register!"a-b"("difference");
    gen.register!"a*b"("product");

    //Lambdas can also be used and support any number of arguments
    gen.register!((double a) {return to!double(sin(a));})("sin");
    gen.register!((double a) {return to!double(cos(a));})("cos");

    double div(double a, double b) {
        if (!isInfinity(a/b) && b != 0) {
            return a/b;
        }
        else {
            return 0;
        }
    }
    gen.register(&div, "div");

    //Register an input value. This is effectivly a shorthand for
    //  'gen.register(function(){return x;}, "x");'
    gen.registerInput!x;

    //Register a range of random constants which may appear in the generated algorithm
    gen.registerConstantRange(-10.0f, 10.0f);
    
    auto ga = new TreeGA!(double,

                          //Population size
                          1500,

                          //Maximum depth of tree
                          5,

                          //Fitness: the above fitness function
                          fitness,

                          /*
                           * Selector: Select the top 100 members by evalutating each
                           * member in parallel.
                           */
                          selector.topPar!50,

                          /*
                           * Crossover: Copy one of the parents, and replace a random 
                           * node with a subtree from the other parent
                           */
                          crossover.singlePoint,

                          //Mutator: Replace a random node with a new random subtree
                          mutator.randomBranch,

                          //More fit values are smaller
                          "a < b")(gen);

    //Set a mutation rate
    ga.mutationRate = 0.07;
    
    //Print statistics every 20 generations
    ga.statFrequency = 20;

    //Stop if any individual has the termination value (or lower due to the above comp function)
    ga.terminationValue = 0;

    //Automatically output a graphviz 'dot' file to 'best.dot' upon termination
    ga.autoGenerateGraph = true;
    
    /*
     * Preform symbolic regression, grow for 600 generations. Takes approximately 
     * 60 seconds on quad core laptop to generate a function with a fitness of ~10.
     */
    ga.evolve(600);

}
