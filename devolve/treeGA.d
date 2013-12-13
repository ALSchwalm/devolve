module devolve.treeGA;
import std.traits;
import std.typetuple;

class BaseNode(T) {
    this(string _name) {
        name = _name;
    }

    abstract T eval();
    string name;
}


class Node(T) : BaseNode!(ReturnType!T) {
    this(T t, string _name) {
        super(_name);
        val = t;
    }
    
    override ReturnType!T eval() {
        return val();
    }

    T val; 
    BaseNode children[ParameterTypeTuple!T.length];
}

struct Tree(T) {
    this(BaseNode!T _root){
        root = _root;
    }
    T eval(){return root.eval();}
    
    BaseNode!T root;
}

struct TreeGA(T, uint PopSize) if (PopSize > 0) {

    void addNode(A)(A node)
        if (is(ReturnType!A == T) &&
            EraseAll!(T, staticMap!(Unqual, ParameterTypeTuple!A)).length == 0)
    {
        
    }

    Tree!T functionTree;
}
