module devolve.net.netGA;

import devolve.net.network;
import devolve.net.mutator;
import devolve.net.crossover;
import devolve.selector;
import devolve.baseGA;

import std.conv, std.file, std.algorithm;

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
             alias comp = "a > b") : BaseGA!(Network, PopSize, comp,
                                             fitness,
                                             generator,
                                             selector,
                                             crossover,
                                             mutator)
{
    /**
     * Default constructor. No statistics will be printed, 
     * and mutation will be set at 1%, crossover rate at 80%
     */
    this(){
        if (find(terminationCallbacks, &generateGraphCallback) == [])
            terminationCallbacks ~= &generateGraphCallback;
    }

    /**
     * Convienience constructor, equivilant to default constructing
     * and setting mutation rate and statistic frequency
     */
    this(float mutRate, float crossoverRate, uint statFreq) {
        m_mutationRate = mutRate;
        m_statFrequency = statFreq;
        m_crossoverRate = crossoverRate;
    }
    
    ///Whether to generate a graph of the net after 'evolution' completes
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
    void generateGraph(const(Network) net,
                       string filename="output.dot",
                       string description="") const {

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

protected:

    bool m_generateGraph = true;

    void generateGraphCallback(uint generations) {
        if (m_generateGraph) {
            string description = "Fitness = "
                ~ to!string(statRecord.historicalBest.fitness) ~
                " / Over "  ~ to!string(generations) ~ " generations";

            generateGraph(statRecord.historicalBest.individual, "best.dot", description);
        }
    }
}

unittest {
    import devolve.net;

    alias gaType = NetGA!(100,
                          testFitness,
                          generator.denseNet!(10, 10, 1, 10),
                          selector.roulette!7,
                          crossover.randomMerge);
    auto ga = new gaType(0.01, 0.9, 5);
}
