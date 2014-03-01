module devolve.baseGA;

import devolve.statistics, devolve.utils;
import std.functional, std.stdio, std.math;

///Abstract class to be used as the base for GAs.
class BaseGA(T, uint PopSize,
             alias comp) {

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

    abstract void generation();
    abstract void crossingOver();
    abstract void mutation();
    abstract void selection();
    
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
