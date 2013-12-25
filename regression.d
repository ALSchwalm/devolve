#!/usr/bin/env rdmd

import devolve.treeGA;
import devolve.selector;
import devolve.tree.mutator;
import devolve.tree.generator;
import devolve.tree.crossover;

import std.math;
import std.typecons;
import std.stdio;
import std.conv;
import std.range;
import std.algorithm;
import std.array;
  
//Points taken from the equation `x^2 + 2x + sin(x)^2 - 23`
double f(double x) {return x*x + 2*x+sin(x)*sin(x)-23;}

immutable Tuple!(double, double)[] points;
static this() {
    points = cast(typeof(points))array(zip(iota(-10, 10, 0.5),
                                           map!f(iota(-10, 10, 0.5))));
}

double x;

double fitness(ref Tree!double algorithm) {
    double fit = 0;

    foreach(ref immutable(Tuple!(double, double)) pair; points) {
        x = pair[0];
        fit += abs(algorithm.eval() - pair[1]);
    }
    return fit;
}

void main() {

    //Generator: Class used to generate trees from the registered functions
    TreeGenerator!double gen;

    //Register simple functions, only parameter names of 'a' and 'b' are supported
    gen.register!("-a", "negative");
    gen.register!("a*a", "square");
    gen.register!("a+b", "sum");
    gen.register!("a-b", "difference");
    gen.register!("a*b", "product");

    //Lambdas can also be used and support any number of arguments
    gen.register!(function(double a) {return to!double(sin(a));}, "sin");
    gen.register!(function(double a) {return to!double(cos(a));}, "cos");

    double div(double a, double b) {
        if (b == 0) {
            return 0;
        }
        else {
            return a/b;
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
                          topPar!(Tree!double, 50, fitness, "a < b"))(gen);

    //Set a mutation rate
    ga.mutationRate = 0.07;
    
    //Print statistics every 20 generations
    ga.statFrequency = 20;

    //Stop if any individual has the termination value
    ga.terminationValue = 0;

    //Terminate if any fitness is less than the termination value
    ga.setCompFun!("a < b");
    
    //Automatically output a graphviz 'dot' file to 'best.dot' upon termination
    ga.autoGenerateGraph = true;
    
    /*
     * Grow for 600 generations. Takes approximately 45 seconds on quad core 
     * laptop to generate function with 60% fitness. That is, a funtion which
     * will yeild the first 6 primes on consecutive integer input
     */
    ga.evolve(600);

}
