module devolve.tree.treeGA;

import devolve.baseGA;
import devolve.tree.mutator;
import devolve.tree.crossover;
import devolve.tree.generator;
import devolve.selector;

import std.random;
import std.typetuple;
import std.traits;
import std.conv;
import std.stdio;
import std.file;

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

        @disable this() {}

        ///Create a tree GA with the given generator.
        ///NOTE: additional functions may still be registered with the generator after this point
        this(TreeGenerator!T gen) {
            generator = gen;
        }

        ///Whether to generate a graph of the tree after 'evolution' completes
        @property bool autoGenerateGraph(bool generate) {
            return m_generateGraph = generate;
        }

        ///ditto
        @property bool autoGenerateGraph() {
            return m_generateGraph;
        }

        /**
         * Generate a a Graphviz dot file named filename with additional description
         * 'description' using node
         */
        void generateGraph(BaseNode!T node, string filename="output.dot", string description="") {

            string file = "digraph G{ graph [ordering=\"out\"];\n";
            file ~= "node0 [ label = \"" ~ node.name ~ "\"];\n";
            uint currentNodeNumber = 0;
            file ~= graphSubTree(node, currentNodeNumber);
            
            file ~= "labelloc=\"t\"; label=\"" ~ description ~ "\"}";
            std.file.write(filename, file);
        }

        /**
         * Evolution function works as follows.
         *
         * $(OL
         *   $(LI The population is created using the supplied `generator`)
         *   $(LI Crossing-over is preformed to created missing population)
         *   $(LI The population is mutated with probability `mutation_rate`)
         *   $(LI The parents of the next generation are selected)
         *   $(LI Statistics are recorded for the best individual)
         *   $(LI Terminate if criteria is met, otherwise go to 2.)) 
         */
        override BaseNode!T evolve(uint generations) {
            
            foreach(i; 0..PopSize) {
                population ~= generator(depth);
            }
            
            //Perform evolution
            foreach(generation; 0..generations) {
                auto selectedSize = population.length;
                while(population.length < PopSize) {
                    population ~= crossover(population[uniform(0, selectedSize)],
                                            population[uniform(0, selectedSize)]);
                }

                foreach(i; 0..to!uint(PopSize*mutationRate)) {
                    mutator(population[uniform(0, PopSize)], generator);
                }

                //if the user has defined their own selector
                static if (isCallable!selector) {
                    population = selector(population); 
                }
                else {
                    population = selector!(fitness, comp)(population);
                }

                if (statFrequency && generation % statFrequency == 0) {
                    writeln("(gen ", generation, ") ",
                            "Top Score: ", fitness(population[0]),
                            ", Individual: ", population[0]);
                }
                if (generation == 0 || compFun(fitness(population[0]), fitness(best))) {
                    best = population[0].clone();

                    if (m_termination != double.nan && (m_termination == fitness(best) ||
                                                        compFun(fitness(best), m_termination))) {
                        break;
                    }
                }
            }

            writeln("\n(Historical best) Score: ", fitness(best),
                    ", Individual: ", best);

            if (m_generateGraph) {
                string description = "Fitness = " ~ to!string(fitness(best)) ~
                    " / Over " ~ to!string(generations) ~ " generations";
                generateGraph(best, "best.dot", description);
            }

            return best;

        }

    private:
        bool m_generateGraph = false;
        TreeGenerator!T generator;

        string graphSubTree(BaseNode!T node, ref uint num) {
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
