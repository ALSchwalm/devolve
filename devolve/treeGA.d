module devolve.treeGA;
import std.traits;
import std.typetuple;
import std.random;
import std.stdio;
ReturnType!A unpackCall(A, B...)(A func,
                                 BaseNode!(ReturnType!A)[ParameterTypeTuple!A.length] nodes,
                                 B args) {

    static if (args.length == nodes.length) {
        return func(args);
    }
    else {
        return unpackCall!(typeof(func))(func, nodes, args, nodes[args.length].eval());
    }
}

class BaseNode(T) {
    this(string _name) {
        name = _name;
    }

    abstract T eval();
    abstract uint getNumChildren();
    abstract void setChildren(BaseNode!T[]);
    abstract BaseNode!T clone();
    string name;
}


class Node(T) : BaseNode!(ReturnType!T) {
    this(T t, string _name) {
        super(_name);
        val = t;
    }

    override ReturnType!T eval() {
        static if (ParameterTypeTuple!T.length > 0) {
            return unpackCall!(typeof(val))(val, children);
        }
        else {
            return val();
        }
    }

    override uint getNumChildren() {
        return ParameterTypeTuple!T.length;
    }

    override void setChildren(BaseNode!(ReturnType!T)[] nodes) {
        children[] = nodes[];
    }

    override BaseNode!(ReturnType!T) clone() {
        static if (ParameterTypeTuple!T.length > 0) {
            auto newNode = new Node!T(val, name);
            for(uint i=0; i < children.length; ++i) {
                newNode.children[i] = children[i];
            }
            return newNode;
        }
        else {
            return this;
        }
    }

    override string toString()  {
        static if (ParameterTypeTuple!T.length == 0) {
            return name ~ "()";
        }
        else {
            string p = name ~ "(";
            for(uint i=0; i < children.length-1; ++i) {
                p ~= children[i].toString() ~ ", ";
            }
            p ~= children[$-1].toString() ~ ")";
            return p;
        }
    }
    
    T val; 
    BaseNode!(ReturnType!T) children[ParameterTypeTuple!T.length];
}

struct Tree(T) {
    this(BaseNode!T _root){
        root = _root;
    }

    T eval(){return root.eval();}
    
    string toString() {
        return root.toString();
    }

    BaseNode!T root;
}

struct TreeGenerator(T) {
    
    void register(A)(A node, string name)
        if (is(ReturnType!A == T) &&
            EraseAll!(T, staticMap!(Unqual, ParameterTypeTuple!A)).length == 0)
    {
        static if (ParameterTypeTuple!A.length > 0) {
            nodes ~= new Node!A(node, name);
        }
        else {
            terminators ~= new Node!A(node, name);
        }
    }

    Tree!T getRandomTree(uint depth) {
        return Tree!T(getRandomSubTree(depth));
    }

    BaseNode!T getRandomSubTree(uint depth) {
        if (depth == 0) {
            return getRandomTerminator();
        }

        BaseNode!T root = getRandomNode();

        BaseNode!T[] children;
        children.length = root.getNumChildren();

        for(uint i=0; i < children.length; ++i) {
            children[i] = getRandomSubTree(depth-1);
        }
        root.setChildren(children);
        return root;
    }

    BaseNode!T getRandomNode() {
        return nodes[uniform(0, nodes.length)].clone();
    }

    BaseNode!T getRandomTerminator() {
        return terminators[uniform(0, terminators.length)].clone(); 
    }

    BaseNode!T[] nodes;
    BaseNode!T[] terminators;
}

struct TreeGA(T, uint PopSize) if (PopSize > 0) {
    this(TreeGenerator!T g) {
        generator = g;
    }

    TreeGenerator!T generator;
}
