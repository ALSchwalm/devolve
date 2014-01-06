
EXAMPLE_SRC = $(wildcard examples/*.d)
EXAMPLE_OUT = $(patsubst examples/%.d,examples/%.out,$(EXAMPLE_SRC))

DFLAGS = -w -wi

all: DFLAGS += -release -O -inline
all: devolve.a $(EXAMPLE_OUT)

debug: DFLAGS += -debug -g
debug: devolve.a $(EXAMPLE_OUT)

$(EXAMPLE_OUT): %.out: %.d devolve.a
	dmd $< devolve.a -op -of$@ $(DFLAGS)

devolve.a:
	dmd $(wildcard devolve/**/*.d) $(wildcard devolve/*.d) $(DFLAGS) -lib -ofdevolve.a 

clean: 
	rm devolve.a $(wildcard examples/*.out) $(wildcard examples/*.o)
