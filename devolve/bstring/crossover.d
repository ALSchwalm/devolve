module devolve.bstring.crossover;

individual XOR(individual)(in individual ind1,
                           in individual ind2) {
    return ind1 ^ ind2;
}
