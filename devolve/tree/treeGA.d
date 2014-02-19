module devolve.tree.treeGA;

import devolve.baseGA;
import devolve.tree.mutator;
import devolve.tree.crossover;
import devolve.tree.generator;
import devolve.selector;

import std.random, std.typetuple, std.traits;
import std.conv, std.stdio, std.file, std.math;
import std.algorithm;

///Convenience alias
alias Tree = BaseNode;

/**
 * Genetic algorithm for genomes in the form of a tree. Particularly well suited
 * for growing algorithms.
 *
 * Params:
 *    T = Type of the tree. Should be the return type and parameter type of the functions composing the tree
 *    PopSize = The size of the population
 *    depth = Maximum depth of the tree
 *    fitness = User defined fitness function. Must return double
 *    selector = Selection method used to pick parents of next generation. 
 *    crossover = Used to crossover individuals to create the new generation. 
 *    mutator = Used to alter the population. 
 *    comp = Used to determine whether a larger or smaller fitness is better.
 */
class TreeGA(T,
             uint PopSize,
             uint depth,
             alias fitness,
             alias selector = top!(2, fitness),
             alias crossover = singlePoint!T,
             alias mutator = randomBranch!T,
             alias comp = "a > b") : BaseGA!(BaseNode!T, PopSize, comp)
if (PopSize > 0 && depth > 0) {

    ///Create a tree GA with the given generator.
    this(TreeGenerator!T gen) {
        if (find(terminationCallbacks, &generateGraphCallback) == [])
            terminationCallbacks ~= &generateGraphCallback;

        generator = gen;
    }

    ///Whether to generate a graph of the tree after 'evolution' completes
    @property bool autoGenerateGraph(bool generate) {
        return m_generateGraph = generate;
    }

    ///ditto
    @property bool autoGenerateGraph() const {
        return m_generateGraph;
    }

    /**
     * Generate a a Graphviz dot file named filename with additional description
     * 'description' using node
     */
    void generateGraph(const(BaseNode!T) node,
                       string filename="output.dot",
                       string description="") const {

        string file = "digraph G{ graph [ordering=\"out\"];\n";
        file ~= "node0 [ label = \"" ~ node.name ~ "\"];\n";
        uint currentNodeNumber = 0;
        file ~= graphSubTree(node, currentNodeNumber);
            
        file ~= "labelloc=\"t\"; label=\"" ~ description ~ "\"}";
        std.file.write(filename, file);
    }

protected:

    ///Add initial population using generator
    override void generation() {
        foreach(i; 0..PopSize) {
            population ~= generator(depth);
        }
    }

    ///Preform add new members by crossing-over the population left
    ///after selection
    override void crossingOver() {
        auto selectedSize = population.length;
        while(population.length < PopSize) {
            population ~= crossover(population[uniform(0, selectedSize)],
                                    population[uniform(0, selectedSize)]);
        }
    }

    ///Preform mutation on members of the population
    override void mutation() {
        //If multiple mutations are used
        static if (__traits(compiles, mutator.joined)) {
            foreach(mutatorFun; mutator.joined) {
                foreach(i; 0..to!uint(PopSize*m_mutationRate/mutator.joined.length)) {
                    mutatorFun(population[uniform(0, PopSize)], generator);
                }
            }
        }
        else {
            foreach(i; 0..to!uint(PopSize*m_mutationRate)) {
                mutator(population[uniform(0, PopSize)], generator);
            }
        }
    }

    ///Select the most fit members of the population
    override void selection() {
        //if the user has defined their own selector
        static if (isCallable!selector) {
            population = selector(population); 
        }
        else {
            population = selector!(fitness, comp)(population, m_statRecord);
        }
    }

private:
    bool m_generateGraph = false;
    const TreeGenerator!T generator;

    string graphSubTree(const(BaseNode!T) node, ref uint num) const {
        string output = "";
        uint parent = num;
        foreach(i; 0..node.getNumChildren()) {
            num += 1;
            auto childNode = node.getChild(i);
            output ~= "node" ~ to!string(num) ~ " [ label = \"" ~ childNode.name ~ "\"];\n";
            output ~= "node" ~ to!string(parent) ~ " -> node" ~ to!string(num) ~ ";\n";
            output ~= graphSubTree(childNode, num);
        }
        return output;
    }

    void generateGraphCallback(uint generations) {
        if (m_generateGraph) {
            string description = "Fitness = "
                ~ to!string(statRecord.historicalBest.fitness) ~
                " / Over "  ~ to!string(generations) ~ " generations";

            generateGraph(statRecord.historicalBest.individual, "best.dot", description);
        }
    }
}

version(unittest) {
    double fitness(Tree!int ind) {return 0;}
    
    unittest {
        import devolve;

        TreeGenerator!int gen;
        gen.register!"-a"("negative");
        
        auto ga = new TreeGA!(int, 100, 4, fitness, top!10)(gen);
        auto ga2 = new TreeGA!(int, 100, 4, fitness, top!10, singlePoint)(gen);
        auto ga3 = new TreeGA!(int, 100, 4, fitness, top!10, singlePoint, randomBranch)(gen);
    }
}
