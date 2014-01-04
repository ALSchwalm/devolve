module devolve.treeGA;
import devolve.baseGA;
import devolve.tree.generator;
import devolve.tree.crossover;
import devolve.tree.mutator;

import std.random;
import std.typetuple;
import std.traits;
import std.conv;
import std.stdio;
import std.file;

class TreeGA(T,
             uint PopSize,
             uint depth,
             alias fitness,
             alias selector = top!(2, fitness),
             alias crossover = singlePoint!T,
             alias mutator = randomBranch!T,
             alias comp = "a > b") : BaseGA!(BaseNode!T, PopSize, comp)
        if (PopSize > 0 && depth > 0) {

        this(TreeGenerator!T g) {
            generator = g;
        }

        @property bool autoGenerateGraph(bool generate) {
            return m_generateGraph = generate;
        }

        @property bool autoGenerateGraph() {
            return m_generateGraph;
        }

        void generateGraph(BaseNode!T node, string name="output.dot", string description="") {

            string file = "digraph G{ graph [ordering=\"out\"];\n";
            file ~= "node0 [ label = \"" ~ node.name ~ "\"];\n";
            uint currentNodeNumber = 0;
            file ~= graphSubTree(node, currentNodeNumber);
            
            file ~= "labelloc=\"t\"; label=\"" ~ description ~ "\"};";
            std.file.write(name, file);
        }

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

                selector(population);

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
