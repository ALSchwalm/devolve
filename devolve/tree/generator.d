
module devolve.tree.generator;
import std.traits;
import std.typetuple;
import std.random;
import std.conv;
import std.string;

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
    abstract uint getNumChildren() const;
    abstract ref BaseNode!T getChild(uint);
    abstract ref const(BaseNode!T) getChild(uint) const;
    abstract void setChild(BaseNode!T, uint);
    abstract void setChildren(BaseNode!T[]);
    abstract uint getHeight() const;
    abstract BaseNode!T clone(bool = false) const;
    string name;
}


class Node(T, bool constant=false) : BaseNode!(ReturnType!T) {
    alias BaseNode!(ReturnType!T) BaseType;
    
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

    override uint getNumChildren() const {
        return ParameterTypeTuple!T.length;
    }

    override void setChild(BaseType node, uint index) {
        children[index] = node;
    }

    override ref BaseType getChild(uint index) {
        return children[index];
    }

    override ref const(BaseType) getChild(uint index) const {
        return children[index];
    }

    override void setChildren(BaseType[] nodes) {
        children[] = nodes[];
    }

    override BaseType clone(bool newCopy) const {
        auto newNode = new Node!(T, constant)(val, name);
        if (!newCopy) {
            foreach(uint i; 0..children.length) {
                newNode.children[i] = children[i].clone();
            }
        }
        return newNode;
    }

    override uint getHeight() const {
        uint max = 0;
        foreach(const ref BaseType node; children) {
            if (node.getHeight() > max) {
                max = node.getHeight();
            }
        }
        return max+1;
    }

    override string toString()  {
        static if (ParameterTypeTuple!T.length == 0) {
            static if (constant) {
                return name;
            }
            else {
                return name ~ "()";
            }
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
    BaseType children[ParameterTypeTuple!T.length];
}

struct TreeGenerator(T) {

    BaseNode!T opCall(uint height) {
        return getRandomTree(height);
    }
    
    void register(A)(A func, string name)
        if (is(ReturnType!A == T) &&
            EraseAll!(T, staticMap!(Unqual, ParameterTypeTuple!A)).length == 0)
    {
        static if (ParameterTypeTuple!A.length > 0) {
            nodes ~= new Node!A(func, name);
        }
        else {
            terminators ~= new Node!A(func, name);
        }
    }

    void registerConstantRange(A)(A lower, A upper) {
        T randConst() {return uniform(lower, upper);};
        randomConstants ~= &randConst;
    }

    void registerInput(alias input)() {
        typeof(input) inputValue() {
            return input;
        }
        auto fullName = fullyQualifiedName!input;
        auto name = fullName[lastIndexOf(fullName, '.')+1..$];
        terminators ~= new Node!(typeof(&inputValue), true)
            (&inputValue, name);
    }

    BaseNode!T getRandomTree(uint depth) {
        if (depth == 1) {
            return getRandomTerminator();
        }

        BaseNode!T root = getRandomNode();

        BaseNode!T[] children;
        children.length = root.getNumChildren();

        for(uint i=0; i < children.length; ++i) {
            children[i] = getRandomTree(depth-1);
        }
        root.setChildren(children);
        return root;
    }

    BaseNode!T getRandomNode() {
        return nodes[uniform(0, nodes.length)].clone(true);
    }

    BaseNode!T getRandomTerminator() {
        assert(randomConstants.length > 0 || terminators.length > 0,
               "Generator has no registered terminators");
        
        if ((randomConstants.length > 0 && uniform(0.0, 1.0) > 0.5) ||
            terminators.length == 0) {
            auto func = randomConstants[uniform(0, randomConstants.length)];
            auto val = func();
            T wrapp() {return val;};
            return new Node!(typeof(&wrapp), true)(&wrapp, to!string(val));
        }
        else {
            return terminators[uniform(0, terminators.length)].clone();
        }
    }

    const(BaseNode!T)[] nodes;
    const(T delegate())[] randomConstants;
    const(BaseNode!T)[] terminators;
}
