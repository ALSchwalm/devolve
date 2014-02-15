module devolve.net.netGA;

import devolve.net.generator;
import devolve.net.mutator;
import devolve.net.crossover;
import devolve.selector;
import devolve.baseGA;

import std.algorithm, std.random, std.stdio;
import std.conv, std.traits, std.file, std.math;

/**
 * Genetic algorithm for genomes in the form of artificial neural nets
 *
 * Params:
 *    PopSize = The size of the population
 *    fitness = User defined fitness function. Must return double
 *    selector = Selection method used to pick parents of next generation. 
 *    crossover = Used to crossover individuals to create the new generation. 
 *    mutator = Used to alter the population. 
 *    comp = Used to determine whether a larger or smaller fitness is better.
 */
class NetGA( uint PopSize,
             alias fitness,
             alias generator,
             alias selector = topPar!2,
             alias crossover = randomCopy,
             alias mutator = randomWeight,
             alias comp = "a > b") : BaseGA!(Network, PopSize, comp)
{
    ///Default constructor
    this(){}
        
    /** 
     * Convienience constructor, equivilant to default constructing
     * and setting mutation rate and statistic frequency
     */
    this(float mutRate, uint statFreq) {
        m_mutationRate = mutRate;
        m_statFrequency = statFreq;
    }

    ///Whether to generate a graph of the net after 'evolution' completes
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
    void generateGraph(Network net, string filename="output.dot", string description="") {

        string file = "graph G{ concentrate = true; graph [];\n";

        uint currentNum = 0;
        uint prevLayerNum = 0;
        foreach(neuron; net.inputLayer) {
            file ~= "neuron" ~ to!string(currentNum) ~ " [ label=\"InputNeuron\"];\n";
            ++currentNum;
        }
        
        foreach(i, layer; net.hiddenLayers) {
            if (i != 0) {prevLayerNum = currentNum;}
            
            foreach(j, neuron; layer) {
                file ~= "neuron" ~ to!string(currentNum) ~ " [ label=\"HiddenNeuron\" ];\n";
                ulong index;

                if (i == 0) {
                    foreach(connection; neuron.connections) {
                        auto target = find(net.inputLayer, connection.neuron);
                        index = net.inputLayer.length - target.length;
                        file ~= "neuron" ~ to!string(currentNum) ~ " -- neuron" ~
                            to!string(prevLayerNum + index) ~ " [ label=\"" ~
                            to!string(connection.weight) ~ "\"];\n";
                    }
                }
                ++currentNum;
            }
        }

        foreach(neuron; net.outputLayer) {
            file ~= "neuron" ~ to!string(currentNum) ~ " [ label=\"OutputNeuron\" ];\n";
            foreach(connection; neuron.connections) {
                auto target = find(net.hiddenLayers[$-1], connection.neuron);
                auto index = net.hiddenLayers[$-1].length - target.length;
                file ~= "neuron" ~ to!string(currentNum) ~ " -- neuron" ~
                    to!string(prevLayerNum + index) ~ " [ label=\"" ~
                    to!string(connection.weight) ~ "\"];\n";
            }
            ++currentNum;
        }
        
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
    override Network evolve(uint generations){

        generation();

        //Perform evolution
        foreach(generation; 0..generations) {

            crossingOver();
            mutation();
            selection();

            if (m_statFrequency && generation % m_statFrequency == 0) {
                writeln("(gen ", generation, ") ",
                        "Top Score: ", fitness(population[0]),
                        ", Individual: ", population[0]);
            }
            if (generation == 0 || compFun(fitness(population[0]), fitness(best))) {
                best = population[0].clone();

                if (!isNaN(m_termination) && !compFun(m_termination, fitness(best))) {
                    writeln("\n(Termination criteria met) Score: ", fitness(best),
                            ", Individual: ", best);
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

protected:
    
    ///Add initial population using generator
    void generation() {
        //Add initial population
        foreach(i; 0..PopSize) {
            population ~= generator();
        }
    }

    ///Preform add new members by crossing-over the population left
    ///after selection
    void crossingOver() {
        while(population.length < PopSize) {
            population ~= crossover(population[uniform(0, population.length)],
                                    population[uniform(0, population.length)]);
        }
    }

    ///Preform mutation on members of the population
    void mutation() {
        foreach(i; 0..to!uint(PopSize*m_mutationRate)) {
            mutator(population[uniform(0, PopSize)]);
        }
    }

    ///Select the most fit members of the population
    void selection() {
        //if the user has defined their own selector, just call it
        static if (isCallable!selector) {
            population = selector(population); 
        }
        else {
            population = selector!(fitness, comp)(population);
        }
    }

    bool m_generateGraph = false;

}

