module devolve.utils;
import std.typetuple, std.traits, std.stdio;
import devolve.tree.generator;

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


protected template isPrintable(T) {
    static if (__traits(compiles, &writeln!(const(T)))) {
        immutable isPrintable = true;
    }
    else {
        immutable isPrintable = false;
    }
}

unittest {
    import devolve;
    assert(isPrintable!(BitSet!10));
    assert(isPrintable!(Tree!int));
    assert(isPrintable!int);
    assert(!isPrintable!Network);
}


protected auto unpackCall(A, B...) 
    (in A func,
     in BaseNode!(ReturnType!A)[ParameterTypeTuple!A.length] nodes,
     in B args) {

    static if (args.length == nodes.length) {
        return func(args);
    }
    else {
        return unpackCall!A(func, nodes, args, nodes[args.length].eval());
    }
}

unittest {

    auto del = function(int x, int y) {return x+y;};
    auto term = function() {return 2;};

    auto n = new Node!(typeof(del))(del, "node");
    auto child = new Node!(typeof(term))(term, "child");

    assert(unpackCall!(typeof(del))(del, [child, child]) == 4);
}

version(unittest) {
    protected double testFitness(T)(T){return 1.0;}
}
    
