#!/usr/bin/env rdmd

import devolve.net;

import std.stdio, std.algorithm, std.conv;
import std.range, std.math;

const(double[][26]) trainingData;
const(double[][7])  testData;

//Load data from a PBM file containing 'numCharacters' characters
double[][] loadPBM(string fileName, uint numCharacters){
    double[][] data;
    
    auto file = File(fileName);
    
    auto range = file.byLine().drop(2);
    auto dimensionLine = to!string(range.front());
    range.drop(1);
    auto dimensions = to!(uint[])(split(dimensionLine, " "));

    auto charWidth = dimensions[0] / numCharacters;
    data.length = numCharacters;

    uint i=0;
    foreach(line; range) {
        foreach(bit; line) {
            data[i/charWidth] ~= bit - 48;
            ++i;
            if (i == dimensions[0]) {i = 0;}
        }
    }

    return data;
}

shared static this() {
    trainingData = loadPBM("examples/assets/mono.pbm", 26);
    testData = loadPBM("examples/assets/arial.pbm", 7);
}

//Fitness: total number of correct letters output
double fitness(Network individual) {
    double total = 0;

    foreach(i, pointList; trainingData) {
        auto result = individual(pointList);
        auto pos = minPos!"a > b"(result);
        if (result.length - pos.length == i) {total += 1;}
    }
    return total;
}

void main() {

    auto ga = new NetGA!(//Population of 150 individuals
                         150,

                         //The above fitness function
                         fitness,

                         /*
                          *Generator: create random networks with the following properties
                          *  inputLayerSize:     number of nodes (in this case pixels) inputed
                          *  outputLayerSize:    number of outputs (in this case a value for each letter
                          *                      of the alphabet.
                          *  hiddenLayers:       number of 'hidden' inner layers
                          *  hiddenLayerMaxSize: the maxium number of nodes in each hidden layer
                          *  maxConnections:     maximum number of connections from each node to the
                          *                      previous layer
                          */
                         generator.randomConnections!(11*14, 26, 1, 110, 10),

                         //Select the top 10 individuals in parallel
                         selector.topPar!10,

                         //Randomly copy the weights and connections from each parent
                         //to create the child
                         crossover.randomMerge)
        //Set the mutation rate to 20% and output statistics every 10 generations
        (0.2, 10);

    //Generate a graph of the neural net as output.dot
    ga.autoGenerateGraph=true;

    //Grow for 1000 generations
    auto best = ga.evolve(1000);

    char[] str;
    foreach(pointList; testData) {
        auto result = best(pointList);
        writeln(result, "\n");
        auto pos = minPos!"a > b"(result);
        str ~= to!char(result.length - pos.length + 97);
    }

    //Write the output string. With sufficient evolution, should print something
    //like 'devolve'
    writeln(str);
}
