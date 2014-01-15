import std.typecons;

/**
 * Abstract class used to describe the nodes which make up 
 * the net.
 */
class Node{
    abstract double eval();

    ///Convenience alias
    alias Tuple!(double, "weight", Node, "node") Connection;

    ///Connected nodes
    Connection[] connections;
}

/**
 * Class for nodes which exist on the hidden, inner layers
 * of the net.
 */
class HiddenNode : Node{
    override double eval() {
        double total = 0;
        foreach(connection; connections) {
            total += connection.node.eval() * connection.weight;
        }
        return total;
    }
}

/**
 * Class for nodes which exist on the input side of the graph
 */
class InputNode : Node {
    this(double value) {val = value;}
    
    override double eval() {
        return val;
    }

    double val;
}

/**
 * Class for nodes which return the values
 */
class OutputNode : Node {
    
}
