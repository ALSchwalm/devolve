module devolve.baseGA;

import devolve.statistics, devolve.utils;
import std.functional, std.stdio, std.math;
import std.traits, std.random, std.conv;

///Base class to used for convenience 
class BaseGA(T, uint PopSize,
             alias comp,
             alias fitness = null,
             alias generator = null,
             alias selector = null,
             alias crossover = null,
             alias mutator = null) {

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
    const(T) evolve(uint generations){

        generation();

        //Perform evolution
        foreach(generation; 0..generations) {

            crossingOver();
            mutation();
            selection();

            showStatistics(generation);

            if (!isNaN(m_termination) &&
                !compFun(m_termination, statRecord.last.best.fitness)) {

                showFinalStatistics("Termination criteria met");
                break;
            }

            foreach(callback; generationCallbacks) {
                callback(generation, population);
            }
        }

        showFinalStatistics("Historical Best");

        foreach(callback; terminationCallbacks) {
            callback(generations);
        }

        return statRecord.historicalBest.individual;
    }

    ///Basic property GAs should have
    @property {
        float mutationRate(float rate) {
            return m_mutationRate = rate;
        }

        float mutationRate() const {
            return m_mutationRate;
        }

        float crossoverRate(float rate) {
            return m_crossoverRate = rate;
        }

        float crossoverRate() const {
            return m_crossoverRate;
        }

        uint statFrequency(uint freq) {
            return m_statFrequency = freq;
        }

        uint statFrequency() const {
            return m_statFrequency;
        }

        double terminationValue(double termination) {
            return m_termination = termination;
        }

        double terminationValue() const {
            return m_termination;
        }

        ///Get a handle to the recorded statistics for this genome
        const(StatCollector!(T, comp)) statRecord() const {
            return m_statRecord;
        }
    }

    ///Stores the population being evolved
    T population[];

    ///Register a function to call when the evolution is ended.
    void registerTerminationCallback(void delegate(uint) callback) {
        terminationCallbacks ~= callback;
    }

    ///Register a function to be called every generation
    void registerGenerationCallback(void delegate(uint, T[]) callback) {
        generationCallbacks ~= callback;
    }

protected:

    ///Add initial population using generator
    static if (is(typeof(generator) == typeof(null))) {
        abstract void generation();
    }
    else {
        ///Add initial population using generator
        void generation() {
            //Add initial population
            foreach(i; 0..PopSize) {
                static if (isCallable!generator) {
                    population ~= generator();
                }
                else {
                    population ~= generator!T();
                }
            }
        }
    }

    ///Preform add new members by crossing-over the population left
    ///after selection, keeping 'crossoverRate' precent in the population.
    static if (is(typeof(crossover) == typeof(null))) {
        abstract void crossingOver();
    }
    else {
        void crossingOver() {
            T[] nextPopulation;

            nextPopulation.length = cast(ulong)(population.length*m_crossoverRate);
            nextPopulation[] = population[0..nextPopulation.length];

            while(nextPopulation.length < PopSize) {
                nextPopulation ~= crossover(population[uniform(0, population.length)],
                                            population[uniform(0, population.length)]);
            }

            population = nextPopulation;
        }
    }

    
    ///Preform mutation on members of the population
    static if (is(typeof(mutator) == typeof(null))) {
        abstract void mutation();
    }
    else {
        void mutation() {
            //If multiple mutations are used
            static if (__traits(compiles, mutator.joined)) {
                foreach(mutatorFun; mutator.joined) {
                    foreach(i; 0..to!uint(PopSize*m_mutationRate/mutator.joined.length)) {
                        mutatorFun(population[uniform(0, PopSize)]);
                    }
                }
            }
            else {
                foreach(i; 0..to!uint(PopSize*m_mutationRate)) {
                    mutator(population[uniform(0, PopSize)]);
                }
            }
        }
    }

    ///Select the most fit members of the population
    static if (is(typeof(selector) == typeof(null))) {
        abstract void selection();
    }
    else {
        void selection() {
            //if the user has defined their own selector, just cal it
            static if (isCallable!selector) {
                population = selector(population); 
            }
            else {
                population = selector!(fitness, comp)(population, m_statRecord);
            }
        }
    }

    void showStatistics(int generation) const {
        if (m_statFrequency && generation % m_statFrequency == 0) {
            writefln("(gen %3d) %s", generation, statRecord.last);
        }
    }

    void showFinalStatistics(string cause) const {
        static if (isPrintable!T) {
            writeln("\n(", cause, ") Score: ", statRecord.historicalBest.fitness,
                    ", Individual: ", statRecord.last.best.individual);
        }
        else {
            writeln("\n(", cause, ") Score: ", statRecord.last.best.fitness);
        }
    }

    alias binaryFun!(comp) _compFun;
    bool function(double, double) compFun = &_compFun!(double, double);
    
    double m_termination = double.nan;
    float m_mutationRate = 0.01f;
    float m_crossoverRate = 0.8;
    uint m_statFrequency = 0;
    auto m_statRecord = new StatCollector!(T, comp);

    void delegate(uint)[] terminationCallbacks;
    void delegate(uint, T[])[] generationCallbacks;
}
