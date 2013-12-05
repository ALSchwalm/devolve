module devolve.treeGA;
import std.traits;
import std.typetuple;

struct Node(T) {
    this(T t, string _name) {
        val = t;
        name = _name;
    }
    
    T eval() {
        return val;
    }

    T val;
    uint children[ParameterTypeTuple!T.length];
    string name;
}

struct Tree(T) {
    this(Node!T _root){
        root = _root;
    }
    T eval(){root.eval();}
    
    Node!T root;
}

struct TreeGA(T, uint PopSize) if (PopSize > 0) {
    alias mutateFunc = void function(ref T);
    alias fitnessFunc = double function(ref const T);
    alias selectorFunc = void function(ref T[], fitnessFunc);
    alias crossoverFunc = T function(ref const T, ref const T);
    alias generatorFunc = T function();

    this(fitnessFunc _fitness,
         mutateFunc _mutate,
         selectorFunc _selector,
         crossoverFunc _crossover,
         generatorFunc _generator) {
        mutate=_mutate;
        fitness=_fitness;
        selector=_selector;
        crossover=_crossover;
        generator=_generator;
    }

    void addNode(A)(A node)
        if (is(ReturnType!A == T) &&
            EraseAll!(T, staticMap!(Unqual, ParameterTypeTuple!A)).length == 0)
    {
        
    }
    
    immutable mutateFunc mutate;
    immutable fitnessFunc fitness;
    immutable selectorFunc selector;
    immutable crossoverFunc crossover;
    immutable generatorFunc generator;

    Tree!T functionTree;
}

