Ddoc

<h1>devolve</h1>
devolve is a genetic programming framework designed to take advantage of
the D programming language's powerful template system and easy concurrency.

<dl><dl>

<h2>Basic Usage</h2>
Examples of usage can be found in the 'examples' folder. To use the library simply
`import devolve`. If only one genome representation is required, it may be sufficient
to `import devolve.tree`, for example. The general usage of the library is as follows:
<dl>
$(OL
  $(LI Select a genome representation (i.e.,
     <a href="list.listGA.html">list</a>,
     <a href="tree.treeGA.html">tree</a>, etc.). These should typically be
able to represent a solution to your problem easily.)

  $(LI Choose from one of the existing generators / mutators / crossover functions. For
example, mutators for the <a href="tree.treeGA.html">tree</a> representation live in
<a href="tree.mutator.html">devolve.tree.mutator</a>.)

  $(LI Write a fitness function for your application. This function should accept an individual
of the type chosen in step 1. (so for a `list`, a static or dynamically sized array).)

  $(LI Construct a Genetic Algorithm using the parts chosen or written in the above steps.
These follow the convention of 'NameGA', so for `list`, the class is named `ListGA`.)

  $(LI Set additional information such as the mutation rate / population ordering (is a
larger or smaller number more or less fit) or termination criteria.)

  $(LI Call `evolve()`, specifying the maximum number of generations over which the
algorithm should run.)

  $(LI You're finished. Sit back and wait while the algorithm runs.))

<dl>
  
<h2>Examples</h2>

These examples and others examples may be found in the
<a href="https://github.com/ALSchwalm/devolve/tree/master/examples">
examples folder.</a>

<h3>The Traveling Salesman</h3>
--------------
import devolve.list;

import std.algorithm;

immutable uint[char[2]] distances;

static this() {
    //Distances between every city
    distances = [
        "ab": 20u,
        "ac": 42u,
        "ad": 35u,
        "bc": 30u,
        "bd": 34u,
        "cd": 12u
        ];
}

//An individual is an ordering of these 'cities'
alias individual = char[4];

/* 
 * Basic fitness function. Fitness is the total distance
 * traveled by following the input path.
 */
double fitness(in individual ind) {
    double total = 0;

    for(uint i=0; i < ind.length-1; ++i) {
        char lower = min(ind[i], ind[i+1]);
        char higher = max(ind[i], ind[i+1]);
        total += distances[[lower,  higher]];
    }
    return total;
};

void main() {

    auto ga = new ListGA!(
        
            //Population of 10 individuals
            individual, 10,
            
            //Fitness: The above fitness function
            fitness,
            
            //Generator: The initial population will be copies of 'cbad'
            generator.preset!('c', 'b', 'a', 'd'),
            
            //Selector: Select the top 2 individuals each generation
            selector.topPar!2,

            //Crossover: Just copy one of the parents
            crossover.randomCopy,

            //Mutation: Swap the alleles (cities)
            mutator.randomSwap,

            //Statistics must also know to record the historically lowest value
            //and selector should order with lowest value first (shortest distance)
            "a < b");

    //Set a 10% mutation rate
    ga.mutationRate = 0.1f;

    //Print statistics every 5 generations
    ga.statFrequency = 5;

    // Run for 30 generations. Converges rapidly on abcd or dcba
    ga.evolve(30);
}
---------------

<h3>Symbolic Regression</h3>
---------------
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

double x;

/*
 * Evaluate function `g`. Fitness is the cumulative difference between g(x)
 * and a given point (x, y).
 */

double fitness(ref Tree!double algorithm) {
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
-----------
