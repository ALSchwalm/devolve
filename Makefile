
EXAMPLE_SRC = $(wildcard examples/*.d)
EXAMPLE_OUT = $(EXAMPLE_SRC:.d=.out)

LIB_SRC = $(wildcard devolve/**/*.d) $(wildcard devolve/*.d) 

DFLAGS = -w -wi

all: DFLAGS += -release -O -inline -noboundscheck
all: devolve.a

debug: DFLAGS += -debug -g
debug: devolve.a

unittest: DFLAGS += -unittest
unittest: unittest.out
	@./unittest.out ; test $$? -eq 0
	@printf "\nAll tests pass\n"

examples: DFLAGS += -O -inline -noboundscheck
examples: devolve.a $(EXAMPLE_OUT)

$(EXAMPLE_OUT): %.out: %.d devolve.a
	dmd -op $(DFLAGS) $< devolve.a -of$@ 

devolve.a: $(LIB_SRC)
	dmd $(DFLAGS) -lib $(LIB_SRC) -ofdevolve.a 

unittest.out: $(LIB_SRC)
	dmd $(DFLAGS) $(LIB_SRC) -ofunittest.out

clean: 
	rm -f devolve.a $(EXAMPLE_OUT) $(EXAMPLE_SRC:.d=.o) unittest.o unittest.out
