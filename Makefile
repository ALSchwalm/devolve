
EXAMPLE_SRC = $(wildcard examples/*.d)
EXAMPLE_OUT = $(patsubst examples/%.d,examples/%.out,$(EXAMPLE_SRC))

all: devolve.a $(EXAMPLE_OUT)

$(EXAMPLE_OUT): %.out: %.d devolve.a
	dmd $< devolve.a -op -of$@ -w -wi

devolve.a:
	dmd $(wildcard devolve/**/*.d) $(wildcard devolve/*.d) -lib -ofdevolve.a -w -wi

clean: 
	rm devolve.a $(wildcard examples/*.out) $(wildcard examples/*.o)
