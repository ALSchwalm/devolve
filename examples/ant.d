#!/usr/bin/env rdmd

import devolve.list;

import std.algorithm, std.typecons, std.random;
import std.stdio, std.range;

immutable NUM_ANTS = 50;
immutable FIELD_SIZE = 1000;

alias Tuple!(int, "x", int, "y") Point;
immutable HOME = Point(FIELD_SIZE/2, FIELD_SIZE/2);
immutable TARGET = Point(HOME.x+10, HOME.y+10);

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

        if (!reverse) {
            //Get random move
            auto choices = [ Point(x, y+1), Point(x, y-1),
                             Point(x+1, y), Point(x-1, y)];
            randomShuffle(choices);

            Point move = choices[0];
            int moveScore = -1;

            auto totalScore = reduce!"a+b"(map!(a => field[a.x][a.y])(choices))+4;
            foreach(ref choice; choices) {
                if (field[choice.x][choice.y] > moveScore &&
                    find(path, choice) == [] &&
                    //uniform(0.0, 1.0) < (field[choice.x][choice.y]+1.0)/totalScore &&
                    uniform(0.0, 1.0) < follow) {

                    move = choice;
                    moveScore = field[choice.x][choice.y];
                }
            }

            if (move == TARGET) {
                path = TARGET ~ path;
                reverse = true;
            }
            
            path ~= move;
        }
        else {
            field[x][y] += 1;
            path = path.dropBackOne();
        }
    }
}

immutable TURNS = 200;
uint play(in individual percents) {

    Ant[NUM_ANTS] ants;
    foreach(i, ref ant; ants) {
        ant = Ant(percents[i]);
    }

    uint trips = 0;
    foreach(turn; 0..TURNS) {
        foreach(ref ant; ants) {
            ant.move();
            if (ant.path.length > 0 &&
                ant.path[$-1] == HOME &&
                find(ant.path, TARGET) != []) {
                
                trips += 1;
                ant.path = [HOME];
                ant.reverse = false;
            }
        }
    }
    
    return trips;
}

immutable ROUNDS = 2;
double fitness(in individual ind){
    double total = 0;
    foreach(i; 0..ROUNDS) {
        total += play(ind);
    }
    return total/ROUNDS;
}

void main() {

    auto ga = new ListGA!(
        
        //Population of 10 individuals
        individual, 50,
            
        //Fitness: The above fitness function
        fitness,
            
        //Generator: Each allele is in the range [0.1, 1.0)
        generator.randomRange!(0.1, 1.0),
            
        //Selector: Select the top 2 individuals each generation
        selector.topPar!10,

        //Crossover: Single point combination of the parents
        crossover.singlePoint,

        //Mutation: Create a new value in the range (0.1, 1.0]
        mutator.randomRange!(0.1, 1.0));

    //Set a 10% mutation rate
    ga.mutationRate = 0.1f;

    //Print statistics every 5 generations
    ga.statFrequency = 5;

    // Evolve the population
    ga.evolve(100);
}
