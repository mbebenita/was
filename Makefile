CC    ?= clang
CXX   ?= clang++
FLEX  ?= flex
BISON ?= bison

EXE = was

CDEBUG = -g -Wall

CXXDEBUG = -g -Wall

CSTD = -std=c99
CXXSTD = -std=c++11

CFLAGS = -Wno-deprecated-register -O0  $(CDEBUG) $(CSTD) 
CXXFLAGS = -Wno-deprecated-register -O0  $(CXXDEBUG) $(CXXSTD)


CPPOBJ = main ast ti
SOBJ =  parser lexer

FILES = $(addsuffix .cpp, $(CPPOBJ))

OBJS  = $(addsuffix .o, $(CPPOBJ))

CLEANLIST =  $(addsuffix .o, $(OBJ)) $(OBJS) \
				 was_parser.tab.cc was_parser.tab.hh \
				 location.hh position.hh stack.hh \
				 was_parser.output parser.o was_parser.tab.o \
				 lexer.o was_lexer.yy.o was_lexer.yy.cc $(EXE)\

.PHONY: all
all: was test

was: parser lexer $(FILES)
	$(MAKE) $(SOBJ)
	$(MAKE) $(OBJS)
	$(CXX) $(CXXFLAGS) -o $(EXE) $(OBJS) parser.o lexer.o $(LIBS)


parser: was_parser.yy
	$(BISON) -t -d -v was_parser.yy
	$(CXX) $(CXXFLAGS) -c -o parser.o was_parser.tab.cc

lexer: was_lexer.l
	$(FLEX) --outfile=was_lexer.yy.cc  $<
	$(CXX)  $(CXXFLAGS) -c was_lexer.yy.cc -o lexer.o

.PHONY: test
test:
	cd test && ./check.py

.PHONY: was.js
was.js: parser lexer
	$(MAKE) -C emscripten

.PHONY: clean
clean:
	rm -rf $(CLEANLIST)
	$(MAKE) -C emscripten clean

