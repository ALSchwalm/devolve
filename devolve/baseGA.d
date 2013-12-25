module devolve.baseGA;

import std.functional;

class BaseGA(T, uint PopSize, alias comp) {

    abstract T evolve(uint);

    @property {
        float mutationRate(float rate) {
            return m_mutationRate = rate;
        }

        float mutationRate() {
            return m_mutationRate;
        }

        uint statFrequency(uint freq) {
            return m_statFrequency = freq;
        }

        uint statFrequency() {
            return m_statFrequency;
        }

        double terminationValue(double termination) {
            return m_termination = termination;
        }

        double terminationValue() {
            return m_termination;
        }
    }

    void setCompFun(alias _comp)() {
        alias binaryFun!(_comp) _compFun;
        compFun = &_compFun!(double, double);
    }
    
    T population[];
    T best;

protected:
    alias binaryFun!(comp) _compFun;
    bool function(double, double) compFun = &_compFun!(double, double);
    double m_termination = double.nan;

    float m_mutationRate = 0.1f;
    uint m_statFrequency = 0;
    
}
