#!/usr/bin/env rdmd

import devolve.list;
import devolve.selector;

import std.algorithm, std.typecons, std.random;
import std.stdio;

immutable NUM_ANTS = 5;
immutable FIELD_SIZE = 1000;

alias Tuple!(int, "x", int, "y") Point;
immutable HOME = Point(FIELD_SIZE/2, FIELD_SIZE/2);
immutable TARGET = Point(HOME.x+1, HOME.y+1);

alias individual = float[NUM_ANTS];

int[FIELD_SIZE][FIELD_SIZE] field;

struct Ant {
    this(float _follow) {follow = _follow;}
    
    float follow; //probability that the ant will follow a path
    bool reverse = false;
    Point[] path = [HOME];

    void move() {
        int x = path[$-1].x;
        int y = path[$-1].y;

        //Get random move
        auto choices = [ Point(x, y+1), Point(x, y-1),
                         Point(x+1, y), Point(x-1, y)];
        randomShuffle(choices);

        Point move = choices[0];
        int moveScore = 0;
        
        foreach(ref choice; choices) {
            if (field[choice.x][choice.y] > moveScore) {
                move = choice;
                moveScore = field[choice.x][choice.y];
            }
        }
        
        path ~= move;
    }
}

uint play(in individual percents) {

    Ant[NUM_ANTS] ants;
    foreach(i, ant; ants) {
        ant = Ant(percents[i]);
    }

    uint trips = 0;
    foreach(turn; 0..100) {
        foreach(ref ant; ants) {
            ant.move();
            if (ant.path.length > 0 &&
                ant.path[$-1] == HOME &&
                find(ant.path, TARGET) != []) {
                trips += 1;
                ant.path = [HOME];
            }
        }
    }
    
    return trips;
}


double fitness(in individual ind){
    uint total = 0;
    foreach(i; 0..10) {
        total += play(ind);
    }
    return total/10.0;
}

void main() {

    auto ga = new ListGA!(
        
        //Population of 10 individuals
        individual, 10,
            
        //Fitness: The above fitness function
        fitness,
            
        //TODO: fix this
        randRange!(individual, NUM_ANTS, 0.1, 1.0),
            
        //Selector: Select the top 2 individuals each generation
        topPar!2,

        //Crossover: Just copy one of the parents
        randomCopy,

        //Mutation: Swap the alleles (cities)
        devolve.list.mutator.randomRange!(0.1, 1.0));

    //Set a 10% mutation rate
    ga.mutationRate = 0.1f;

    //Print statistics every 5 generations
    ga.statFrequency = 5;

    // Run for 30 generations. Converges rapidly on abcd or dcba
    ga.evolve(100);
}
