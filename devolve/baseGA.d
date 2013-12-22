module devolve.baseGA;

import std.functional;

class BaseGA(T, uint PopSize, alias comp) {

                
    @property float mutationRate(float rate) {
        return m_mutationRate = rate;
    }

    @property float mutationRate() {
        return m_mutationRate;
    }

    @property uint statFrequency(uint freq) {
        return m_statFrequency = freq;
    }

    @property uint statFrequency() {
        return m_statFrequency;
    }

    @property double terminationValue(double termination) {
        return m_termination = termination;
    }

    @property double terminationValue() {
        return m_termination;
    }

    
    alias binaryFun!(comp) _compFun;
    bool function(double, double) compFun = &_compFun!(double, double);
    double m_termination = double.nan;

    float m_mutationRate = 0.1f;
    uint m_statFrequency = 0;
    T population[];
    T best;
}
