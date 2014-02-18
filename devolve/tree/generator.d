module devolve.tree.generator;
import devolve.utils;

import std.traits, std.random, std.conv, std.string, std.functional;

/**
 * Genome used with the TreeGA. 'T' must be the type of the 
 * parameters and return values from the functions composing
 * the tree.
 */
class BaseNode(T) {
    
    protected this(string _name) {
        name = _name;
    }

    ///Evaluate the node by calling the wrapped function with eval of each child
    abstract T eval() const ;

    ///Get the number of children
    abstract uint getNumChildren() const;

    ///
    abstract override string toString() const;

    ///Get the child at index by reference
    abstract ref BaseNode!T getChild(uint index);

    ///Get the child at index by const reference
    abstract ref const(BaseNode!T) getChild(uint index) const;

    ///Set the child at index to node
    abstract void setChild(BaseNode!T node, uint index);

    ///Set the children. The length of children should equal getNumChildren()
    abstract void setChildren(BaseNode!T[] children);

    ///Get the maximum number of nodes from this node to a leaf.
    abstract uint getHeight() const;

    ///Get a deep copy of this node
    abstract BaseNode!T clone(bool = false) const;

    ///
    immutable string name;
}

protected class Node(T, bool constant=false) : BaseNode!(ReturnType!T) {
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

    override string toString() const {
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

/**
 * Generator used to create new trees for the population. 
 * A generator will also be passed to the mutator and
 * crossover functions of the GA.
 */
struct TreeGenerator(T) {

    ///Create a new Tree with a height of height
    auto opCall(uint height) const {
        return getRandomTree(height);
    }

    ///Register a function which cannot be known at compile time
    void register(A)(A func, string name)
        if (is(ReturnType!A == T) &&
            EraseAll!(T, staticMap!(Unqual, ParameterTypeTuple!A)).length == 0) {
            
            addNode!A(func, name);
    }

    ///Register a compile time known function
    void register(alias func)(string name) {
        registerH!(func)(name);
    }

    ///Register a constant value (this will strip the '()' when printing the tree)
    void registerConstant(T constant)() {
        register!constant(to!string(constant));
    }

    ///Register constants in the range [lower, upper). 
    void registerConstantRange(A)(A lower, A upper) {
        T randConst() {return uniform(lower, upper);}
        randomConstants ~= &randConst;
    }

    /**
     * Register an input to the grown algorithm.
     * EXAMPLES:
     * ------------
     *    int x;
     *    TreeGenerator!int gen;
     *
     *    //Same effect as 'register!( () {return x;})("x");
     *    gen.registerInput!x;
     * ------------
     */
    void registerInput(alias input)() {
        auto inputValue() {
            return input;
        }

        terminators ~= new Node!(typeof(&inputValue), true)
            (&inputValue, input.stringof);
    }

    ///Create a random tree with height of exactly height
    BaseNode!T getRandomTree(uint height) const {
        if (height == 1) {
            return getRandomTerminator();
        }

        BaseNode!T root = getRandomNode();

        BaseNode!T[] children;
        children.length = root.getNumChildren();

        for(uint i=0; i < children.length; ++i) {
            children[i] = getRandomTree(height-1);
        }
        root.setChildren(children);
        return root;
    }

    ///Create a random node
    ///WARNING: It is not safe to 'eval' this note immediately
    auto getRandomNode() const {
        assert(nodes.length > 0, "Generator has no registered nodes");
        return nodes[uniform(0, nodes.length)].clone(true);
    }

    ///Create a random terminator from the set of registered terminators
    ///NOTE: This set includes any registered function with 0 parameters, constants, and inputs
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
