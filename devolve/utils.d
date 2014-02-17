module devolve.utils;

/**
 * Join together mutator functions
 *
 * Examples:
 * --------------------
 * auto ga = ListGA!(int[4], 10, fitness,
 *                   preset!(1, 1, 2, 3),
 *                   Join!(randomSwap, randomRange!(0, 10)));
 * --------------------
 */
template Join(Funcs...) {
    alias joined = Funcs;
}
