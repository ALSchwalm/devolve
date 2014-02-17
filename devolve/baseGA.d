module devolve.baseGA;

import devolve.statistics;
import std.functional, std.stdio, std.math;

///Base class to used for convenience 
class BaseGA(T, uint PopSize, alias comp) {

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
    abstract const(T) evolve(uint generations);

    abstract void generation();
    abstract void crossingOver();
    abstract void mutation();
    abstract void selection();

    ///Basic property GAs should have
    @property {
        float mutationRate(float rate) {
            return m_mutationRate = rate;
        }

        float mutationRate() const {
            return m_mutationRate;
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
    

protected:

    void showStatistics(int generation) const {
        if (m_statFrequency && generation % m_statFrequency == 0) {
            writefln("(gen %3d) %s", generation, statRecord.last);
        }
    }

    alias binaryFun!(comp) _compFun;
    bool function(double, double) compFun = &_compFun!(double, double);
    
    double m_termination = double.nan;
    float m_mutationRate = 0.01f;
    uint m_statFrequency = 0;
    auto m_statRecord = new StatCollector!(T, comp);
}
