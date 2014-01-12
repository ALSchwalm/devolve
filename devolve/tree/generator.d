module devolve.tree.generator;

import std.traits;
import std.typetuple;
import std.random;
import std.conv;
import std.string;
import std.functional;

private auto unpackCall(A, B...) 
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

class BaseNode(T) {
    
    this(string _name) {
        name = _name;
    }

    abstract T eval() const ;
    abstract uint getNumChildren() const;
    abstract ref BaseNode!T getChild(uint);
    abstract ref const(BaseNode!T) getChild(uint) const;
    abstract void setChild(BaseNode!T, uint);
    abstract void setChildren(BaseNode!T[]);
    abstract uint getHeight() const;
    abstract BaseNode!T clone(bool = false) const;
    immutable string name;
}


private class Node(T, bool constant=false) : BaseNode!(ReturnType!T) {
    alias BaseNode!(ReturnType!T) BaseType;
    
    this(in T t, in string _name) {
        super(_name);
        val = t;
    }
    
    override ReturnType!T eval() const {
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
            foreach(i; 0..children.length) {
                newNode.children[i] = children[i].clone();
            }
        }
        return newNode;
    }

    override uint getHeight() const {
        uint max = 0;
        foreach(const ref node; children) {
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
    
    const(T) val; 
    BaseType children[ParameterTypeTuple!T.length];
}

unittest {

    auto del = function(int x, int y) {return x+y;};
    auto term = function() {return 2;};
    
    auto n = new Node!(typeof(del))(del, "node");

    assert(n.children.length == 2);

    auto child = new Node!(typeof(term))(term, "child");

    assert(child.children.length == 0);
    n.setChildren([child, child]);
    
    assert(n.getHeight == 2);
    assert(n.eval() == 4);
    assert(n.toString() == "node(child(), child())");
}


struct TreeGenerator(T) {

    auto opCall(uint height) const {
        return getRandomTree(height);
    }

    void register(A)(A func, string name)
        if (is(ReturnType!A == T) &&
            EraseAll!(T, staticMap!(Unqual, ParameterTypeTuple!A)).length == 0) {
            
            addNode!A(func, name);
    }

    void register(alias func)(string name) {
        registerH!(func)(name);
    }
        
    void registerConstant(T constant)() {
        register!constant(to!string(constant));
    }

    void registerConstantRange(A)(A lower, A upper) {
        T randConst() {return uniform(lower, upper);}
        randomConstants ~= &randConst;
    }

    void registerInput(alias input)() {
        auto inputValue() {
            return input;
        }

        terminators ~= new Node!(typeof(&inputValue), true)
            (&inputValue, input.stringof);
    }

        
    BaseNode!T getRandomTree(uint depth) const {
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

    auto getRandomNode() const {
        assert(nodes.length > 0, "Generator has no registered nodes");
        return nodes[uniform(0, nodes.length)].clone(true);
    }

    auto getRandomTerminator() const {
        assert(randomConstants.length > 0 || terminators.length > 0,
               "Generator has no registered terminators");
        
        if ((randomConstants.length > 0 && uniform(0, terminators.length+randomConstants.length)
             < randomConstants.length) || terminators.length == 0) {
            auto func = randomConstants[uniform(0, randomConstants.length)];
            auto val = func();
            T wrapp() {return val;}
            return new Node!(typeof(&wrapp), true)(&wrapp, to!string(val));
        }
        else {
            return terminators[uniform(0, terminators.length)].clone();
        }
    }

private :

    void registerH(alias funcString)(string name) 
        if (!isCallable!(binaryFun!(funcString))) {
            
            static if (indexOf(to!string(funcString), 'b') != -1 ){
                alias temp = binaryFun!funcString;
                auto func = &temp!(T, T);
                
                addNode!(typeof(func))(func, name);
            }
            else static if (indexOf(to!string(funcString), 'a') != -1 ){
                alias temp = unaryFun!funcString;
                auto func = &temp!T;
                
                addNode!(typeof(func))(func, name);
            }
            else {
                auto func = function(){
                    return to!T(funcString);
                };
                addNode!(typeof(func), true)(func, name);
            }            
        }

    void registerH(alias funcString)(string name)
        if (isCallable!(binaryFun!(funcString))) {

            alias func = binaryFun!(funcString);
            addNode!(typeof(func))(func, name);
        }

    void addNode(A, bool removeParens = false)(A func, string name) {
        static if (ParameterTypeTuple!A.length > 0) {
            nodes ~= new Node!A(func, name);
        }
        else {
            terminators ~= new Node!(A, removeParens)(func, name);
        }
    }


    const(BaseNode!T)[] nodes;
    const(T delegate())[] randomConstants;
    const(BaseNode!T)[] terminators;
}

unittest {
    TreeGenerator!int gen;
    
    gen.register!"-a"("negative");
    gen.register!"a+b"("sum");
    gen.registerConstant!2;

    auto t = gen.getRandomTree(4);
    assert(t.getHeight() == 4);
}
