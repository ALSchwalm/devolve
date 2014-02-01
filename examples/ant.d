
import devolve.list;
import devolve.selector;

import std.algorithm, std.typecons, std.random;
import std.stdio;

immutable NUM_ANTS = 5;
immutable FIELD_SIZE = 100;

alias Tuple!(int, "x", int, "y") Point;
immutable HOME = Point(0, 0);
immutable TARGET = Point(10, 10);

alias individual = float[NUM_ANTS];

int[FIELD_SIZE][FIELD_SIZE] field;

struct Ant {
    this(float _follow) {follow = _follow;}
    
    float follow; //probability that the ant will follow a path
    Point[] path = [Point(FIELD_SIZE/2, FIELD_SIZE/2)];

    void move() {
        int x = path[$-1].x;
        int y = path[$-1].y;

        Point move = Point(x+uniform(-1, 1), y+uniform(-1, 1));
        int moveScore = 0;
        
        //Get random move
        
        
        foreach(i; [-1, 1]) {
            if (field[x+i][y] > moveScore) {
                //move = Point(x+i, y);
                moveScore = field[x+i][y];
            }
        }

        foreach(i; [-1, 1]) {
            if (field[x][y+i] > moveScore) {
                //move = Point(x, y+i);
                moveScore = field[x][y+i];
            }
        }
        
        path ~= move;
        writeln(path);
    }
}

uint play(in individual percents) {

    Ant[NUM_ANTS] ants;
    foreach(i, ant; ants) {
        ant = Ant(percents[i]);
    }

    uint trips = 0;
    foreach(turn; 0..10) {
        foreach(ant; ants) {
            ant.move();
            if (ant.path[$-1] == HOME &&
                find(ant.path, TARGET) != []) {
                trips += 1;
                ant.path = [];
            }
        }
    }
    
    return trips;
}



double fitness(in individual ind){
    return play(ind);
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
        devolve.list.mutator.randomRange!(0.1, 1.0),

        //Statistics must also know to record the historically lowest value
        //and selector should order with lowest value first (shortest distance)
        "a < b");

    //Set a 10% mutation rate
    ga.mutationRate = 0.1f;

    //Print statistics every 5 generations
    ga.statFrequency = 5;

    // Run for 30 generations. Converges rapidly on abcd or dcba
    ga.evolve(1);
}
