module devolve.treeGA;
import std.traits;
import std.typetuple;

ReturnType!A unpackCall(A, B...)(A func,
                                 BaseNode!(ReturnType!A)[ParameterTypeTuple!A.length] nodes,
                                 B args) {

    static if (args.length == nodes.length) {
        return func(args);
    }
    else {
        return unpackCall(func, nodes, args, nodes[args.length-1].eval());
    }
}

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
        return unpackCall!(typeof(val))(val, children);
    }

    T val; 
    BaseNode!(ReturnType!T) children[ParameterTypeTuple!T.length];
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
