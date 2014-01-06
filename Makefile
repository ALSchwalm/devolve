
EXAMPLE_SRC = $(wildcard examples/*.d)
EXAMPLE_OUT = $(EXAMPLE_SRC:.d=.out)

LIB_SRC = $(wildcard devolve/**/*.d) $(wildcard devolve/*.d) 

DFLAGS = -w -wi

all: DFLAGS += -release -O -inline -noboundscheck
all: devolve.a $(EXAMPLE_OUT)

debug: DFLAGS += -debug -g
debug: devolve.a $(EXAMPLE_OUT)

$(EXAMPLE_OUT): %.out: %.d devolve.a
	dmd $< devolve.a -op -of$@ $(DFLAGS)

devolve.a: $(LIB_SRC)
	dmd $(LIB_SRC) $(DFLAGS) -lib -ofdevolve.a 

clean: 
	rm -f devolve.a $(EXAMPLE_OUT) $(EXAMPLE_SRC:.d=.o)
