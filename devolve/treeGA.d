module devolve.treeGA;
import devolve.tree.generator;

struct TreeGA(T, uint PopSize) if (PopSize > 0) {
    this(TreeGenerator!T g) {
        generator = g;
    }

    TreeGenerator!T generator;
}
