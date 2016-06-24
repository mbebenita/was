CXX = emcc
CXXINCLUDE ?= -I /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/include/
CXXFLAGS = -Wno-deprecated-register -std=c++11 -O2

SOURCES = ../was_driver.cpp \
          ../was_parser.tab.cc \
          ../was_lexer.yy.cc \
          ../main.cpp \
          ../ast.cpp \
          ../ti.cpp \
          $(NULL)

PRE_TEMPLATE = pre.js
POST_TEMPLATE = post.js
EMFLAGS = --memory-init-file 0

.PHONY: build
build: was.js

was.js: $(SOURCES) $(PRE_TEMPLATE) $(POST_TEMPLATE)
	$(CXX) $(CXXFLAGS) $(CXXINCLUDE) $(SOURCES) -o was.js $(EMFLAGS) --pre-js $(PRE_TEMPLATE) --post-js $(POST_TEMPLATE)

.PHONY: clean
clean:
	rm -rf was.js
