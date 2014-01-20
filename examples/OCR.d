#!/usr/bin/env rdmd

import devolve.net;
import devolve.selector;
import std.stdio;
import std.algorithm;
import std.conv;
import std.range;
import std.math;

const(double[][26]) trainingData;
const(double[][7])  testData;

double[][] loadPBM(string fileName, uint characters){
    double[][] data;
    
    auto file = File(fileName);
    
    auto range = file.byLine().drop(2);
    auto dimensionLine = to!string(range.front());
    range.drop(1);
    auto dimensions = to!(uint[])(split(dimensionLine, " "));

    auto charWidth = dimensions[0] / characters;
    data.length = characters;

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

static this() {
    trainingData = loadPBM("examples/assets/mono.pbm", 26);
    testData = loadPBM("examples/assets/arial.pbm", 7);
}

double fitness(Network individual) {
    double total = 0;

    foreach(i, pointList; trainingData) {
        auto result = individual(pointList);
        foreach(j, letterProb; result) {
            if (i == j) {
                total += letterProb;
            }
            else if (letterProb > result[i]) {
                total -= letterProb - result[i];
            }
        }
    }
    return total;
}

void main() {

    auto ga = new NetGA!(1000,
                         fitness,
                         randomConnections!(11*14, 26, 1, 100, 10),
                         topPar!2,
                         randomMerge)(0.05, 10);
    auto best = ga.evolve(500);

    char[] str;
    foreach(pointList; testData) {
        auto result = best(pointList);
        writeln(result, "\n");
        auto pos = minPos!"a > b"(result);
        str ~= to!char(result.length - pos.length + 97);
    }
    writeln(str);
}
