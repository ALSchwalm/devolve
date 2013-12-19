
import devolve.treeGA;
import devolve.selector;
import devolve.tree.mutator;
import devolve.tree.generator;
import devolve.tree.crossover;

immutable auto primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29];

int x;

//Fitness: For how many numbers 0..primes.length is individual(num) = primes[num]
double fitness(ref BaseNode!int individual) {
    uint total = 0;
    foreach(uint i, uint prime; primes) {
        x = i;
        if (individual.eval() == prime) {
            total += 1;
        }
    }
    return total;
}

void main() {

    //Generator: Class used to generate trees from the registered functions
    TreeGenerator!int gen;

    //Register simple functions
    gen.register(function(){return 2;} , "2");
    gen.register(function(int i) {return i*i;}, "square");
    gen.register(function(int i, int j) {return i+j;}, "sum");
    gen.register(function(int i, int j) {if (i < j) return i; else return j;}, "min");
    gen.register(function(int i, int j) {if (i > j) return i; else return j;}, "max");
    gen.register(function(int i, int j, int k, int l) {if (i > j) return k; else return j;}, "if >");
    gen.register(function(int i, int j) {return i-j;}, "difference");
    gen.register(function(int i, int j){return i*j;} , "product");
    gen.register(function(){return x;}, "x");

    //Register a range of random constants which may appear in the generated algorithm
    gen.registerRandomConstant(0, 10);

    auto ga = new TreeGA!(int,

                          //Population size
                          10,

                          //Maximum depth of tree
                          5,

                          //Fitness: the above fitness function
                          fitness,

                          /*
                           * Selector: Select the top 2 members by evalutating each
                           * member in parallel.
                           */
                          topPar!(BaseNode!int, 2, fitness),

                          /*
                           * Crossover: Copy one of the parents, and replace a random 
                           * node with a subtree from the other parent
                           */
                          singlePoint!int,

                          //Mutator: Replace a random node with a new random subtree
                          randomBranch!int)(gen);

    ga.setMutationRate(0.2);
    
    //Print statistics every 50 generations
    ga.setStatFrequency(500);
    
    ga.evolve(40000);
}
