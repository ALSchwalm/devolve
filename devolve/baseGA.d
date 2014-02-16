module devolve.baseGA;

import devolve.statistics;
import std.functional, std.stdio;

///Base class to used for convenience 
class BaseGA(T, uint PopSize, alias comp) {

    ///All GAs must be able to preform an evolution
    abstract T evolve(uint);

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
        StatCollector!(T, comp) statRecord() {
            return m_statRecord;
        }
    }

    ///Stores the population being evolved
    T population[];
    

protected:

    void showStatistics(int generation) {
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
