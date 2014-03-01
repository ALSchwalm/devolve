
EXAMPLE_SRC = $(wildcard examples/*.d)
EXAMPLE_OUT = $(EXAMPLE_SRC:.d=.out)

LIB_SRC = $(wildcard devolve/**/*.d) $(wildcard devolve/*.d) 

DFLAGS = -w -wi

all: DFLAGS += -release -O -inline -noboundscheck -lib
all: libdevolve.a

debug: DFLAGS += -debug -g -lib
debug: libdevolve.a

unittest: DFLAGS += -unittest
unittest: unittest.out
	@./unittest.out ; test $$? -eq 0
	@printf "\nAll tests pass\n"

examples: DFLAGS += -O -inline -noboundscheck
examples: libdevolve.a $(EXAMPLE_OUT)

$(EXAMPLE_OUT): %.out: %.d libdevolve.a
	dmd -op $(DFLAGS) $< libdevolve.a -of$@

libdevolve.a: $(LIB_SRC)
	dmd $(DFLAGS) -lib $(LIB_SRC) -oflibdevolve.a

unittest.out: $(LIB_SRC)
	dmd $(DFLAGS) $(LIB_SRC) -ofunittest.out

clean: 
	rm -f libdevolve.a $(EXAMPLE_OUT) $(EXAMPLE_SRC:.d=.o) unittest.o unittest.out
