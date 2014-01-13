About
=======

devolve is a genetic programming library written in the D programming language.
The core goal of the project is to create a flexible, easy-to-use interface while
still maintaining performance. Inspiration for some of the interface design was
originally taken from [Pyevolve].

[Pyevolve]: http://pyevolve.sourceforge.net/

Documentation
===============

Below is a quick introduction to usage of the library. Documentation generated by
[bootDoc] may be found [here].

[bootDoc]: https://github.com/JakobOvrum/bootDoc
[here]: http://alschwalm.com/devolve/

Basic Usage
=====

Examples of usage can be found in the 'examples' folder. To use the library simply
`import devolve`. If only one genome representation is required, it may be sufficient
to `import devolve.tree`, for example. 

The general usage of the library is as follows:

1. Select a genome representation (i.e., list, tree, etc.). These should typically be
able to represent a solution to your problem easily.

2. Choose from one of the existing generators / mutators / crossover functions. For
example, mutators for the `tree` representation live in `devolve.tree.mutators`.

3. Write a fitness function for your application. This function should accept an individual
of the type chosen in step 1. (so for a `list`, a static or dynamically sized array).

4. Construct a Genetic Algorithm using the parts chosen or written in the above steps.
These follow the convention of 'NameGA', so for `list`, the class is named `ListGA`.

5. Set additional information such as the mutation rate / population ordering (is a
larger or smaller number more or less fit) or termination criteria.

6. Call `evolve()`, specifying the maximum number of generations over which the
algorithm should run.

7. You're finished. Sit back and wait while the algorithm runs.

Contributing
============

Keeping in mind that devolve is still under heavy development, pull requests are
always welcome.

License
=======

This software is released under the MIT license. See [LICENSE] for
more details.

[LICENSE]: https://raw.github.com/ALSchwalm/devolve/master/LICENSE